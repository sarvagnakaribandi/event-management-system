<%@ page contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="database.NotificationDAO" %>
<%@ page import="database.SecurityUtil" %>
<%
response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setDateHeader("Expires", 0);

Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    out.print("{\"authenticated\": false, \"unreadCount\": 0, \"notifications\": []}");
    return;
}

int unreadCount = NotificationDAO.getUnreadCount(userId);
List<Map<String, Object>> list = NotificationDAO.getRecentNotifications(userId, 15);

StringBuilder json = new StringBuilder();
json.append("{");
json.append("\"authenticated\": true,");
json.append("\"unreadCount\": ").append(unreadCount).append(",");
json.append("\"notifications\": [");

for (int i = 0; i < list.size(); i++) {
    Map<String, Object> n = list.get(i);
    if (i > 0) json.append(",");
    
    int notifId = (Integer) n.get("id");
    String title = (String) n.get("title");
    String message = (String) n.get("message");
    String type = (String) n.get("type");
    String url = (String) n.get("url");
    boolean isRead = (Boolean) n.get("isRead");
    String timeAgo = (String) n.get("timeAgo");

    json.append("{");
    json.append("\"id\": ").append(notifId).append(",");
    json.append("\"title\": \"").append(title != null ? title.replace("\"", "\\\"").replace("\n", " ") : "").append("\",");
    json.append("\"message\": \"").append(message != null ? message.replace("\"", "\\\"").replace("\n", " ") : "").append("\",");
    json.append("\"type\": \"").append(type != null ? type : "system").append("\",");
    json.append("\"url\": \"").append(url != null ? url.replace("\"", "\\\"") : "").append("\",");
    json.append("\"isRead\": ").append(isRead).append(",");
    json.append("\"timeAgo\": \"").append(timeAgo != null ? timeAgo : "").append("\"");
    json.append("}");
}

json.append("]}");
out.print(json.toString());
%>
