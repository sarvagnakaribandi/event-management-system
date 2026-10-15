<%@ page contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="database.NotificationDAO" %>
<%
response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    out.print("{\"success\": false, \"error\": \"Unauthorized\"}");
    return;
}

String action = request.getParameter("action");
String idParam = request.getParameter("id");

boolean success = false;

if ("all".equalsIgnoreCase(action)) {
    success = NotificationDAO.markAllAsRead(userId);
} else if ("delete".equalsIgnoreCase(action) && idParam != null) {
    try {
        int notifId = Integer.parseInt(idParam);
        success = NotificationDAO.deleteNotification(notifId, userId);
    } catch (NumberFormatException ignored) {}
} else if (idParam != null) {
    try {
        int notifId = Integer.parseInt(idParam);
        success = NotificationDAO.markAsRead(notifId, userId);
    } catch (NumberFormatException ignored) {}
}

int newUnreadCount = NotificationDAO.getUnreadCount(userId);
out.print("{\"success\": " + success + ", \"unreadCount\": " + newUnreadCount + "}");
%>
