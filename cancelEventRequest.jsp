<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   LOGIN CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(session.getAttribute("userId").toString());
String reqIdParam = request.getParameter("request_id");

if (reqIdParam == null || reqIdParam.trim().isEmpty()) {
    response.sendRedirect("myRequests.jsp");
    return;
}

int requestId;
try {
    requestId = Integer.parseInt(reqIdParam.trim());
} catch (Exception e) {
    response.sendRedirect("myRequests.jsp");
    return;
}

Connection conn = null;
PreparedStatement ps = null;

try {
    conn = DBConnection.getConnection();

    String sql =
        "UPDATE event_requests " +
        "SET status = 'Cancelled' " +
        "WHERE request_id = ? AND user_id = ? AND status IN ('Pending', 'Proposal Received', 'Under Review')";

    ps = conn.prepareStatement(sql);
    ps.setInt(1, requestId);
    ps.setInt(2, userId);

    int rows = ps.executeUpdate();

    response.sendRedirect("myRequests.jsp?msg=cancelled");
    return;

} catch (Exception e) {
    out.println("<h2 style='color:red;'>Error Cancelling Request</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
    out.println("<a href='myRequests.jsp'>Back to My Requests</a>");
} finally {
    DBConnection.close(ps, conn);
}
%>
