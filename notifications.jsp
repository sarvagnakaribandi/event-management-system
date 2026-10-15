<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>
<%@ page import="database.NotificationDAO" %>

<%
/* =====================================================
   AUTHENTICATION CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(session.getAttribute("userId").toString());
String userName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "User";
String role = session.getAttribute("role") != null ? session.getAttribute("role").toString() : "User";

String filter = request.getParameter("filter");
if (filter == null || filter.trim().isEmpty()) {
    filter = "all";
}
filter = filter.trim().toLowerCase();

String dashboardUrl = "userDashboard.jsp";
if ("Admin".equalsIgnoreCase(role)) {
    dashboardUrl = "adminDashboard.jsp";
} else if ("Organizer".equalsIgnoreCase(role)) {
    dashboardUrl = "organizerDashboard.jsp";
}

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

List<Map<String, Object>> notifList = new ArrayList<>();
int totalCount = 0;
int unreadCount = 0;

try {
    conn = DBConnection.getConnection();
    
    // Total & unread counts
    ps = conn.prepareStatement("SELECT COUNT(*), SUM(CASE WHEN is_read=0 THEN 1 ELSE 0 END) FROM notifications WHERE user_id = ?");
    ps.setInt(1, userId);
    rs = ps.executeQuery();
    if (rs.next()) {
        totalCount = rs.getInt(1);
        unreadCount = rs.getInt(2);
    }
    rs.close();
    ps.close();

    // Query filtered notifications
    String sql;
    if ("unread".equals(filter)) {
        sql = "SELECT * FROM notifications WHERE user_id = ? AND is_read = 0 ORDER BY created_at DESC";
        ps = conn.prepareStatement(sql);
        ps.setInt(1, userId);
    } else if ("booking".equals(filter) || "payment".equals(filter) || "proposal".equals(filter) || "verification".equals(filter)) {
        sql = "SELECT * FROM notifications WHERE user_id = ? AND type = ? ORDER BY created_at DESC";
        ps = conn.prepareStatement(sql);
        ps.setInt(1, userId);
        ps.setString(2, filter);
    } else {
        sql = "SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 100";
        ps = conn.prepareStatement(sql);
        ps.setInt(1, userId);
    }

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
        map.put("timeAgo", NotificationDAO.getTimeAgo(ts));
        map.put("createdAt", ts);
        notifList.add(map);
    }

} catch (Exception e) {
    e.printStackTrace();
} finally {
    DBConnection.close(conn, ps, rs);
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Notification Center | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="css/toast.css">
    <link rel="stylesheet" href="css/notifications.css">
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Poppins', sans-serif;
        }

        body {
            background: radial-gradient(circle at top, #1a0b2e 0%, #0d0618 60%, #05020a 100%);
            color: #e2e8f0;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* Top Navbar */
        .navbar {
            background: rgba(13, 6, 24, 0.85);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            padding: 16px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .logo h2 {
            font-size: 24px;
            font-weight: 800;
            background: linear-gradient(135deg, #ff4fa3, #8b5cf6, #38bdf8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            letter-spacing: 0.5px;
        }

        .nav-links {
            display: flex;
            align-items: center;
            gap: 20px;
            list-style: none;
        }

        .nav-links a {
            color: #cbd5e1;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            transition: color 0.2s;
        }

        .nav-links a:hover {
            color: #ffffff;
        }

        .btn-dash {
            background: rgba(139, 92, 246, 0.15);
            color: #c084fc !important;
            border: 1px solid rgba(139, 92, 246, 0.4);
            padding: 8px 18px;
            border-radius: 20px;
            transition: all 0.2s;
        }

        .btn-dash:hover {
            background: #8b5cf6 !important;
            color: white !important;
        }

        /* Main Container */
        .main-container {
            flex: 1;
            max-width: 960px;
            width: 100%;
            margin: 40px auto;
            padding: 0 25px;
        }

        .page-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 30px;
        }

        .page-header h1 {
            font-size: 28px;
            font-weight: 800;
            color: #ffffff;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .header-actions {
            display: flex;
            gap: 12px;
        }

        .btn-action {
            background: rgba(255, 255, 255, 0.08);
            color: #cbd5e1;
            border: 1px solid rgba(255, 255, 255, 0.15);
            padding: 9px 18px;
            border-radius: 12px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .btn-action:hover {
            background: rgba(255, 255, 255, 0.16);
            color: #ffffff;
            border-color: #a855f7;
        }

        /* Filter Tabs */
        .filter-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 25px;
            overflow-x: auto;
            padding-bottom: 5px;
        }

        .tab-btn {
            background: rgba(255, 255, 255, 0.04);
            color: #94a3b8;
            border: 1px solid rgba(255, 255, 255, 0.08);
            padding: 8px 18px;
            border-radius: 25px;
            font-size: 13px;
            font-weight: 500;
            text-decoration: none;
            transition: all 0.2s;
            white-space: nowrap;
        }

        .tab-btn:hover {
            background: rgba(255, 255, 255, 0.08);
            color: #ffffff;
        }

        .tab-btn.active {
            background: linear-gradient(135deg, rgba(236, 72, 153, 0.2), rgba(139, 92, 246, 0.2));
            color: #f472b6;
            border-color: #ec4899;
            font-weight: 600;
        }

        /* Notifications Card Wrapper */
        .notifs-card {
            background: rgba(25, 14, 45, 0.7);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 20px;
            backdrop-filter: blur(12px);
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
        }

        .notif-row {
            display: flex;
            align-items: flex-start;
            gap: 18px;
            padding: 20px 24px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            transition: background 0.2s;
            position: relative;
        }

        .notif-row:hover {
            background: rgba(255, 255, 255, 0.04);
        }

        .notif-row.unread-row {
            background: rgba(139, 92, 246, 0.07);
        }

        .notif-row.unread-row::before {
            content: '';
            position: absolute;
            left: 0;
            top: 0;
            bottom: 0;
            width: 4px;
            background: linear-gradient(to bottom, #ec4899, #8b5cf6);
        }

        .row-icon {
            width: 44px;
            height: 44px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            flex-shrink: 0;
        }

        .row-details {
            flex: 1;
            min-width: 0;
        }

        .row-title-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
            flex-wrap: wrap;
            gap: 8px;
        }

        .row-title {
            font-size: 15px;
            font-weight: 600;
            color: #f8fafc;
        }

        .row-time {
            font-size: 12px;
            color: #64748b;
        }

        .row-message {
            font-size: 13.5px;
            color: #cbd5e1;
            line-height: 1.5;
            margin-bottom: 12px;
        }

        .row-actions {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .link-action {
            background: rgba(56, 189, 248, 0.1);
            color: #38bdf8;
            border: 1px solid rgba(56, 189, 248, 0.3);
            padding: 5px 14px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.2s;
        }

        .link-action:hover {
            background: #38bdf8;
            color: #0b0f19;
        }

        .btn-row-action {
            background: transparent;
            border: none;
            color: #94a3b8;
            font-size: 12px;
            cursor: pointer;
            padding: 5px 10px;
            border-radius: 6px;
            transition: all 0.2s;
        }

        .btn-row-action:hover {
            color: #f87171;
            background: rgba(239, 68, 68, 0.1);
        }

        /* Empty State */
        .empty-container {
            text-align: center;
            padding: 70px 20px;
        }

        .empty-icon {
            font-size: 55px;
            margin-bottom: 15px;
            opacity: 0.6;
        }

        .empty-title {
            font-size: 20px;
            font-weight: 700;
            color: #ffffff;
            margin-bottom: 8px;
        }

        .empty-desc {
            font-size: 14px;
            color: #94a3b8;
            max-width: 440px;
            margin: 0 auto 20px auto;
            line-height: 1.5;
        }
    </style>
</head>
<body>

<!-- NAVBAR -->
<header class="navbar">
    <div class="logo">
        <h2>EventSphere</h2>
    </div>

    <ul class="nav-links">
        <li><a href="<%= dashboardUrl %>" class="btn-dash">← Back to Dashboard</a></li>
        <li><a href="logout.jsp" style="color:#f87171;">Logout</a></li>
    </ul>
</header>

<main class="main-container">
    <div class="page-header">
        <div>
            <h1>🔔 Notifications Center</h1>
            <p style="color: #94a3b8; font-size: 14px; margin-top: 4px;">
                You have <%= unreadCount %> unread notification<%= unreadCount == 1 ? "" : "s" %>
            </p>
        </div>

        <div class="header-actions">
            <% if (unreadCount > 0) { %>
                <button class="btn-action" onclick="markAllNotificationsRead(); setTimeout(() => location.reload(), 400);">
                    ✓ Mark All as Read
                </button>
            <% } %>
        </div>
    </div>

    <!-- Filter Tabs -->
    <div class="filter-tabs">
        <a href="notifications.jsp?filter=all" class="tab-btn <%= "all".equals(filter) ? "active" : "" %>">
            All (<%= totalCount %>)
        </a>
        <a href="notifications.jsp?filter=unread" class="tab-btn <%= "unread".equals(filter) ? "active" : "" %>">
            Unread (<%= unreadCount %>)
        </a>
        <a href="notifications.jsp?filter=booking" class="tab-btn <%= "booking".equals(filter) ? "active" : "" %>">
            🎟️ Bookings
        </a>
        <a href="notifications.jsp?filter=payment" class="tab-btn <%= "payment".equals(filter) ? "active" : "" %>">
            💳 Payments
        </a>
        <a href="notifications.jsp?filter=proposal" class="tab-btn <%= "proposal".equals(filter) ? "active" : "" %>">
            📝 Proposals
        </a>
        <a href="notifications.jsp?filter=verification" class="tab-btn <%= "verification".equals(filter) ? "active" : "" %>">
            🛡️ Verification
        </a>
    </div>

    <!-- Notifications List -->
    <div class="notifs-card">
        <% if (notifList.isEmpty()) { %>
            <div class="empty-container">
                <div class="empty-icon">🔕</div>
                <div class="empty-title">No notifications found</div>
                <div class="empty-desc">
                    <% if ("unread".equals(filter)) { %>
                        Hooray! You're completely up to date with no pending notifications.
                    <% } else { %>
                        No notifications match this category yet. When updates arrive, they'll appear right here.
                    <% } %>
                </div>
                <a href="<%= dashboardUrl %>" class="btn-action">Return to Dashboard</a>
            </div>
        <% } else { %>
            <% for (Map<String, Object> n : notifList) { 
                int notifId = (Integer) n.get("id");
                String title = (String) n.get("title");
                String message = (String) n.get("message");
                String type = (String) n.get("type");
                String targetUrl = (String) n.get("url");
                boolean isRead = (Boolean) n.get("isRead");
                String timeAgo = (String) n.get("timeAgo");

                String iconEmoji = "🔔";
                String iconCls = "notif-icon-system";
                if ("booking".equalsIgnoreCase(type)) {
                    iconEmoji = "🎟️";
                    iconCls = "notif-icon-booking";
                } else if ("payment".equalsIgnoreCase(type)) {
                    iconEmoji = "💳";
                    iconCls = "notif-icon-payment";
                } else if ("proposal".equalsIgnoreCase(type)) {
                    iconEmoji = "📝";
                    iconCls = "notif-icon-proposal";
                } else if ("verification".equalsIgnoreCase(type)) {
                    iconEmoji = "🛡️";
                    iconCls = "notif-icon-verification";
                }
            %>
                <div class="notif-row <%= !isRead ? "unread-row" : "" %>" id="notif-row-<%= notifId %>">
                    <div class="row-icon <%= iconCls %>">
                        <%= iconEmoji %>
                    </div>
                    <div class="row-details">
                        <div class="row-title-bar">
                            <span class="row-title"><%= SecurityUtil.escapeHtml(title) %></span>
                            <span class="row-time"><%= SecurityUtil.escapeHtml(timeAgo) %></span>
                        </div>
                        <div class="row-message">
                            <%= SecurityUtil.escapeHtml(message) %>
                        </div>
                        <div class="row-actions">
                            <% if (targetUrl != null && !targetUrl.trim().isEmpty()) { %>
                                <a href="<%= SecurityUtil.escapeHtml(targetUrl) %>" class="link-action" onclick="markSingleRead(<%= notifId %>)">
                                    View Details &rarr;
                                </a>
                            <% } %>
                            <% if (!isRead) { %>
                                <button class="btn-row-action" onclick="markSingleRead(<%= notifId %>)">
                                    Mark as read
                                </button>
                            <% } %>
                            <button class="btn-row-action" onclick="deleteNotif(<%= notifId %>)">
                                Delete
                            </button>
                        </div>
                    </div>
                </div>
            <% } %>
        <% } %>
    </div>
</main>

<script src="js/toast.js"></script>
<script src="js/notifications.js"></script>
<script>
function markSingleRead(id) {
    fetch('markNotificationRead.jsp?id=' + id)
        .then(res => res.json())
        .then(data => {
            const row = document.getElementById('notif-row-' + id);
            if (row) {
                row.classList.remove('unread-row');
            }
            if (window.showToast) {
                showToast('info', 'Notification marked as read', 'Updated');
            }
        });
}

function deleteNotif(id) {
    if (!confirm('Are you sure you want to delete this notification?')) return;
    fetch('markNotificationRead.jsp?action=delete&id=' + id)
        .then(res => res.json())
        .then(data => {
            const row = document.getElementById('notif-row-' + id);
            if (row) {
                row.style.opacity = '0';
                setTimeout(() => row.remove(), 250);
            }
            if (window.showToast) {
                showToast('success', 'Notification deleted', 'Deleted');
            }
        });
}
</script>

</body>
</html>
