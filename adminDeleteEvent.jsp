<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   ADMIN LOGIN & ROLE GUARD
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) session.getAttribute("role");
if (role == null || !"Admin".equalsIgnoreCase(role)) {
    response.sendRedirect("login.jsp");
    return;
}

String eventIdParam = request.getParameter("id");
if (eventIdParam == null || eventIdParam.trim().isEmpty()) {
    response.sendRedirect("adminEvents.jsp");
    return;
}

int eventId;
try {
    eventId = Integer.parseInt(eventIdParam.trim());
} catch (Exception e) {
    response.sendRedirect("adminEvents.jsp");
    return;
}

Connection conn = null;

try {
    conn = DBConnection.getConnection();
    conn.setAutoCommit(false);

    // 1. Delete payments first
    try (PreparedStatement ps = conn.prepareStatement(
            "DELETE FROM payments WHERE registration_id IN (SELECT registration_id FROM registrations WHERE event_id = ?)")) {
        ps.setInt(1, eventId);
        ps.executeUpdate();
    }

    // 2. Delete registrations
    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM registrations WHERE event_id = ?")) {
        ps.setInt(1, eventId);
        ps.executeUpdate();
    }

    // 3. Delete event
    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM events WHERE event_id = ?")) {
        ps.setInt(1, eventId);
        ps.executeUpdate();
    }

    conn.commit();
    response.sendRedirect("adminEvents.jsp?msg=deleted");
    return;

} catch (Exception e) {
    if (conn != null) {
        try { conn.rollback(); } catch (Exception ignored) {}
    }
    out.println("<h2 style='color:red;'>Error Deleting Event</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
    out.println("<a href='adminEvents.jsp'>Back to Events</a>");
} finally {
    if (conn != null) {
        try { conn.setAutoCommit(true); } catch (Exception ignored) {}
    }
    DBConnection.close(conn);
}
%>
