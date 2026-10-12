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

String orgIdParam = request.getParameter("organizer_id");
String action = request.getParameter("action");
String reason = request.getParameter("reason");

if (orgIdParam == null || action == null) {
    response.sendRedirect("adminVerifications.jsp");
    return;
}

int organizerId;
try {
    organizerId = Integer.parseInt(orgIdParam.trim());
} catch (Exception e) {
    response.sendRedirect("adminVerifications.jsp");
    return;
}

Connection conn = null;
PreparedStatement ps = null;

try {
    conn = DBConnection.getConnection();

    if ("approve".equalsIgnoreCase(action)) {
        String sql =
            "UPDATE organizer_profiles " +
            "SET verification_status = 'Verified', rejection_reason = NULL, verified_at = CURRENT_TIMESTAMP " +
            "WHERE organizer_id = ?";
        ps = conn.prepareStatement(sql);
        ps.setInt(1, organizerId);
        ps.executeUpdate();

        response.sendRedirect("adminVerifications.jsp?msg=approved");
        return;

    } else if ("reject".equalsIgnoreCase(action)) {
        String sql =
            "UPDATE organizer_profiles " +
            "SET verification_status = 'Rejected', rejection_reason = ?, verified_at = NULL " +
            "WHERE organizer_id = ?";
        ps = conn.prepareStatement(sql);
        ps.setString(1, (reason != null && !reason.trim().isEmpty()) ? reason.trim() : "Documentation insufficient or unverified.");
        ps.setInt(2, organizerId);
        ps.executeUpdate();

        response.sendRedirect("adminVerifications.jsp?msg=rejected");
        return;
    } else {
        response.sendRedirect("adminVerifications.jsp");
        return;
    }

} catch (Exception e) {
    out.println("<h2 style='color:red;'>Error Processing Verification</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
    out.println("<a href='adminVerifications.jsp'>Back to Verifications</a>");
} finally {
    DBConnection.close(ps, conn);
}
%>
