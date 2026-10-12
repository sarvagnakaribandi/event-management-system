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

int currentAdminId = Integer.parseInt(session.getAttribute("userId").toString());
String targetIdParam = request.getParameter("id");

if (targetIdParam == null || targetIdParam.trim().isEmpty()) {
    response.sendRedirect("adminUsers.jsp");
    return;
}

int targetUserId;
try {
    targetUserId = Integer.parseInt(targetIdParam.trim());
} catch (Exception e) {
    response.sendRedirect("adminUsers.jsp");
    return;
}

if (targetUserId == currentAdminId) {
    response.sendRedirect("adminUsers.jsp?error=cannot_delete_self");
    return;
}

Connection conn = null;

try {
    conn = DBConnection.getConnection();
    conn.setAutoCommit(false);

    // 1. Delete payments for user's registrations
    try (PreparedStatement ps = conn.prepareStatement(
            "DELETE FROM payments WHERE registration_id IN (SELECT registration_id FROM registrations WHERE user_id = ?)")) {
        ps.setInt(1, targetUserId);
        ps.executeUpdate();
    }

    // 2. Delete user's registrations
    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM registrations WHERE user_id = ?")) {
        ps.setInt(1, targetUserId);
        ps.executeUpdate();
    }

    // 3. Delete proposals & items for this organizer
    try (PreparedStatement ps = conn.prepareStatement(
            "DELETE FROM proposal_items WHERE proposal_id IN (SELECT proposal_id FROM proposals WHERE organizer_id = ?)")) {
        ps.setInt(1, targetUserId);
        ps.executeUpdate();
    }
    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM proposals WHERE organizer_id = ?")) {
        ps.setInt(1, targetUserId);
        ps.executeUpdate();
    }

    // 4. Delete organizer profile
    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM organizer_profiles WHERE organizer_id = ?")) {
        ps.setInt(1, targetUserId);
        ps.executeUpdate();
    }

    // 5. Delete events created by organizer (cascade payments & registrations of those events first)
    try (PreparedStatement ps = conn.prepareStatement(
            "DELETE FROM payments WHERE registration_id IN (SELECT registration_id FROM registrations WHERE event_id IN (SELECT event_id FROM events WHERE organizer_id = ?))")) {
        ps.setInt(1, targetUserId);
        ps.executeUpdate();
    }
    try (PreparedStatement ps = conn.prepareStatement(
            "DELETE FROM registrations WHERE event_id IN (SELECT event_id FROM events WHERE organizer_id = ?)")) {
        ps.setInt(1, targetUserId);
        ps.executeUpdate();
    }
    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM events WHERE organizer_id = ?")) {
        ps.setInt(1, targetUserId);
        ps.executeUpdate();
    }

    // 6. Delete user account
    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM users WHERE id = ?")) {
        ps.setInt(1, targetUserId);
        ps.executeUpdate();
    }

    conn.commit();
    response.sendRedirect("adminUsers.jsp?msg=deleted");
    return;

} catch (Exception e) {
    if (conn != null) {
        try { conn.rollback(); } catch (Exception ignored) {}
    }
    out.println("<h2 style='color:red;'>Error Deleting User</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
    out.println("<a href='adminUsers.jsp'>Back to Users</a>");
} finally {
    if (conn != null) {
        try { conn.setAutoCommit(true); } catch (Exception ignored) {}
    }
    DBConnection.close(conn);
}
%>
