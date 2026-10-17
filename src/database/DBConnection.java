package database;

import java.net.URI;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class DBConnection {

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            System.err.println("DBConnection: MySQL JDBC Driver not found: " + e.getMessage());
        }
    }

    public static Connection getConnection() throws SQLException {
        Connection conn = null;
        String attemptedTarget = "unknown";
        Exception lastException = null;

        try {
            // 1. Check for full cloud database connection URL (Render / Railway / Heroku format)
            String envUrl = System.getenv("MYSQL_URL");
            if (envUrl == null || envUrl.isBlank()) {
                envUrl = System.getenv("DATABASE_URL");
            }

            if (envUrl != null && !envUrl.isBlank()) {
                envUrl = envUrl.trim();
                attemptedTarget = "Cloud URL (" + envUrl.replaceAll(":[^:@]+@", ":****@") + ")";
                
                try {
                    String cleanUrl = envUrl.startsWith("jdbc:") ? envUrl.substring(5) : envUrl;
                    
                    if (cleanUrl.startsWith("mysql://")) {
                        URI uri = new URI(cleanUrl);
                        String host = uri.getHost();
                        int port = uri.getPort() == -1 ? 3306 : uri.getPort();
                        String path = uri.getPath();
                        String dbName = (path != null && path.length() > 1) ? path.substring(1) : "eventsphere";
                        
                        if (dbName.contains("?")) {
                            dbName = dbName.substring(0, dbName.indexOf('?'));
                        }

                        String user = "";
                        String pass = "";
                        if (uri.getUserInfo() != null) {
                            String[] parts = uri.getUserInfo().split(":", 2);
                            user = parts[0];
                            if (parts.length > 1) pass = parts[1];
                        }

                        String query = uri.getQuery();
                        StringBuilder jdbcUrl = new StringBuilder("jdbc:mysql://").append(host).append(":").append(port).append("/").append(dbName);
                        jdbcUrl.append("?allowPublicKeyRetrieval=true&serverTimezone=UTC");
                        
                        if (query != null && !query.isBlank()) {
                            if (!query.contains("useSSL")) {
                                jdbcUrl.append("&useSSL=false");
                            }
                            jdbcUrl.append("&").append(query);
                        } else {
                            jdbcUrl.append("&useSSL=false");
                        }

                        attemptedTarget = "Cloud URL (" + host + ":" + port + "/" + dbName + ")";
                        conn = DriverManager.getConnection(jdbcUrl.toString(), user, pass);
                    } else {
                        String jdbcUrl = envUrl.startsWith("jdbc:") ? envUrl : "jdbc:" + envUrl;
                        if (!jdbcUrl.contains("allowPublicKeyRetrieval")) {
                            jdbcUrl += (jdbcUrl.contains("?") ? "&" : "?") + "allowPublicKeyRetrieval=true&serverTimezone=UTC&useSSL=false";
                        }
                        conn = DriverManager.getConnection(jdbcUrl);
                    }
                } catch (Exception parseEx) {
                    lastException = parseEx;
                    String jdbcUrl = envUrl.startsWith("jdbc:") ? envUrl : "jdbc:" + envUrl;
                    if (!jdbcUrl.contains("allowPublicKeyRetrieval")) {
                        jdbcUrl += (jdbcUrl.contains("?") ? "&" : "?") + "allowPublicKeyRetrieval=true&serverTimezone=UTC&useSSL=false";
                    }
                    conn = DriverManager.getConnection(jdbcUrl);
                }
            } else {
                // 2. Check for Railway / cloud individual environment variables
                String host = System.getenv("MYSQLHOST");
                if (host == null || host.isBlank()) host = System.getenv().getOrDefault("DB_HOST", "localhost");

                String port = System.getenv("MYSQLPORT");
                if (port == null || port.isBlank()) port = System.getenv().getOrDefault("DB_PORT", "3306");

                String dbName = System.getenv("MYSQLDATABASE");
                if (dbName == null || dbName.isBlank()) dbName = System.getenv().getOrDefault("DB_NAME", "eventsphere");

                String user = System.getenv("MYSQLUSER");
                if (user == null || user.isBlank()) user = System.getenv().getOrDefault("DB_USER", "root");

                String pass = System.getenv("MYSQLPASSWORD");
                if (pass == null) pass = System.getenv().getOrDefault("DB_PASSWORD", "");

                attemptedTarget = host + ":" + port + "/" + dbName + " (user: " + user + ")";

                String jdbcUrl = "jdbc:mysql://" + host + ":" + port + "/" + dbName
                               + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
                conn = DriverManager.getConnection(jdbcUrl, user, pass);
            }
        } catch (Exception e) {
            lastException = e;
            System.err.println("DBConnection error connecting to " + attemptedTarget + ": " + e.getMessage());
        }

        if (conn == null) {
            String details = (lastException != null) ? lastException.getMessage() : "Unknown connection error";
            throw new SQLException("Could not connect to MySQL database at [" + attemptedTarget + "]: " + details + 
                ". If running on Render, set MYSQL_URL in environment variables or ensure database server is running.", lastException);
        }

        return conn;
    }

    public static void close(AutoCloseable... closeables) {
        if (closeables == null) return;
        for (AutoCloseable c : closeables) {
            if (c != null) {
                try {
                    c.close();
                } catch (Exception ignored) {}
            }
        }
    }

    public static void close(Connection conn) {
        close((AutoCloseable) conn);
    }

    public static void close(Statement stmt) {
        close((AutoCloseable) stmt);
    }

    public static void close(ResultSet rs) {
        close((AutoCloseable) rs);
    }

    public static void close(Connection conn, Statement stmt, ResultSet rs) {
        close(rs);
        close(stmt);
        close(conn);
    }

    public static void main(String[] args) {
        System.out.println("=== DBConnection Self-Test ===");
        try (Connection conn = getConnection()) {
            System.out.println("[OK] Successfully connected to database: " + conn.getCatalog());
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM events")) {
                if (rs.next()) {
                    System.out.println("[OK] Total events in database: " + rs.getInt(1));
                }
            }
            System.out.println("[OK] DBConnection test PASSED!");
        } catch (Exception e) {
            System.err.println("[FAIL] DBConnection test FAILED: " + e.getMessage());
            e.printStackTrace();
        }
    }
}