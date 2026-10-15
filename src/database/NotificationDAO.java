package database;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Data Access Object for In-App Notifications (Phase 7).
 */
public class NotificationDAO {

    /**
     * Create a notification using a standalone connection.
     */
    public static boolean createNotification(int userId, String title, String message, String type, String referenceUrl) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) return false;
            return createNotification(conn, userId, title, message, type, referenceUrl);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            DBConnection.close(conn, ps, null);
        }
    }

    /**
     * Create a notification within an existing transactional connection.
     */
    public static boolean createNotification(Connection conn, int userId, String title, String message, String type, String referenceUrl) {
        if (conn == null || userId <= 0) return false;
        PreparedStatement ps = null;
        try {
            String sql = "INSERT INTO notifications (user_id, title, message, type, reference_url, is_read, created_at) " +
                         "VALUES (?, ?, ?, ?, ?, 0, NOW())";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ps.setString(2, title);
            ps.setString(3, message);
            ps.setString(4, (type != null && !type.isEmpty()) ? type : "system");
            ps.setString(5, referenceUrl);
            int rows = ps.executeUpdate();
            return rows > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            if (ps != null) {
                try { ps.close(); } catch (Exception ignored) {}
            }
        }
    }

    /**
     * Count unread notifications for a user.
     */
    public static int getUnreadCount(int userId) {
        if (userId <= 0) return 0;
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) return 0;
            String sql = "SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            DBConnection.close(conn, ps, rs);
        }
        return 0;
    }

    /**
     * Retrieve recent notifications for a user.
     */
    public static List<Map<String, Object>> getRecentNotifications(int userId, int limit) {
        List<Map<String, Object>> list = new ArrayList<>();
        if (userId <= 0) return list;
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) return list;
            String sql = "SELECT notification_id, title, message, type, reference_url, is_read, created_at " +
                         "FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ps.setInt(2, limit > 0 ? limit : 20);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("id", rs.getInt("notification_id"));
                map.put("title", rs.getString("title"));
                map.put("message", rs.getString("message"));
                map.put("type", rs.getString("type"));
                map.put("url", rs.getString("reference_url"));
                map.put("isRead", rs.getBoolean("is_read"));
                Timestamp ts = rs.getTimestamp("created_at");
                map.put("createdAt", ts);
                map.put("timeAgo", getTimeAgo(ts));
                list.add(map);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            DBConnection.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * Mark a specific notification as read.
     */
    public static boolean markAsRead(int notificationId, int userId) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) return false;
            String sql = "UPDATE notifications SET is_read = 1 WHERE notification_id = ? AND user_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, notificationId);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            DBConnection.close(conn, ps, null);
        }
    }

    /**
     * Mark all unread notifications for a user as read.
     */
    public static boolean markAllAsRead(int userId) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) return false;
            String sql = "UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            DBConnection.close(conn, ps, null);
        }
    }

    /**
     * Delete a notification.
     */
    public static boolean deleteNotification(int notificationId, int userId) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) return false;
            String sql = "DELETE FROM notifications WHERE notification_id = ? AND user_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, notificationId);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            DBConnection.close(conn, ps, null);
        }
    }

    /**
     * Format a timestamp into a human-friendly relative time string.
     */
    public static String getTimeAgo(Timestamp ts) {
        if (ts == null) return "";
        long now = System.currentTimeMillis();
        long diff = now - ts.getTime();
        long seconds = diff / 1000;
        long minutes = seconds / 60;
        long hours = minutes / 60;
        long days = hours / 24;

        if (seconds < 60) {
            return "Just now";
        } else if (minutes < 60) {
            return minutes + "m ago";
        } else if (hours < 24) {
            return hours + "h ago";
        } else if (days == 1) {
            return "Yesterday";
        } else if (days < 7) {
            return days + "d ago";
        } else {
            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("MMM d, yyyy");
            return sdf.format(ts);
        }
    }
}
