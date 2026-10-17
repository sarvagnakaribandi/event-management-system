package database;

import java.net.URI;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class DBConnection {

    public static Connection getConnection() {
        Connection conn = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            // 1. Check for full cloud database connection URL (Render / Railway / Heroku format)
            String envUrl = System.getenv("MYSQL_URL");
            if (envUrl == null || envUrl.isBlank()) {
                envUrl = System.getenv("DATABASE_URL");
            }

            if (envUrl != null && !envUrl.isBlank()) {
                try {
                    String cleanUrl = envUrl.replace("jdbc:", "");
                    URI uri = new URI(cleanUrl);
                    String host = uri.getHost();
                    int port = uri.getPort() == -1 ? 3306 : uri.getPort();
                    String dbName = uri.getPath() != null && uri.getPath().length() > 1 
                                    ? uri.getPath().substring(1) 
                                    : "eventsphere";
                    String user = "";
                    String pass = "";
                    if (uri.getUserInfo() != null) {
                        String[] parts = uri.getUserInfo().split(":", 2);
                        user = parts[0];
                        if (parts.length > 1) pass = parts[1];
                    }
                    String jdbcUrl = "jdbc:mysql://" + host + ":" + port + "/" + dbName
                                   + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
                    conn = DriverManager.getConnection(jdbcUrl, user, pass);
                } catch (Exception parseEx) {
                    // Fallback to direct JDBC string if URI parsing is skipped
                    String jdbcUrl = envUrl.startsWith("jdbc:") ? envUrl : "jdbc:" + envUrl;
                    if (!jdbcUrl.contains("?")) {
                        jdbcUrl += "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
                    }
                    conn = DriverManager.getConnection(jdbcUrl);
                }
            } else {
                // 2. Individual environment variables with safe localhost defaults for local development
                String host = System.getenv().getOrDefault("DB_HOST", "localhost");
                String port = System.getenv().getOrDefault("DB_PORT", "3306");
                String dbName = System.getenv().getOrDefault("DB_NAME", "eventsphere");
                String user = System.getenv().getOrDefault("DB_USER", "root");
                String pass = System.getenv().getOrDefault("DB_PASSWORD", "");

                String jdbcUrl = "jdbc:mysql://" + host + ":" + port + "/" + dbName
                               + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
                conn = DriverManager.getConnection(jdbcUrl, user, pass);
            }
        } catch (Exception e) {
            System.err.println("DBConnection error: " + e.getMessage());
            e.printStackTrace();
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
}