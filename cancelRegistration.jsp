<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>

<%
/* =====================================================
   LOGIN CHECK
   ===================================================== */
if(session.getAttribute("userId") == null){
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(session.getAttribute("userId").toString());
String regIdParam = request.getParameter("registration_id");

if(regIdParam == null || regIdParam.trim().isEmpty()){
    response.sendRedirect("myRegistrations.jsp?error=invalid_id");
    return;
}

int registrationId;
try {
    registrationId = Integer.parseInt(regIdParam.trim());
} catch(Exception e){
    response.sendRedirect("myRegistrations.jsp?error=invalid_id");
    return;
}

Connection conn = null;
PreparedStatement checkPs = null;
ResultSet checkRs = null;
PreparedStatement delPayPs = null;
PreparedStatement delRegPs = null;
PreparedStatement incSeatPs = null;

try {
    conn = DBConnection.getConnection();

    // Verify registration ownership and event status
    String checkSql = 
        "SELECT r.registration_id, r.event_id, e.event_name, e.event_date " +
        "FROM registrations r " +
        "INNER JOIN events e ON r.event_id = e.event_id " +
        "WHERE r.registration_id = ? AND r.user_id = ?";

    checkPs = conn.prepareStatement(checkSql);
    checkPs.setInt(1, registrationId);
    checkPs.setInt(2, userId);
    checkRs = checkPs.executeQuery();

    if(!checkRs.next()){
        // Not found or not owned by user
        response.sendRedirect("myRegistrations.jsp?error=not_found");
        return;
    }

    int eventId = checkRs.getInt("event_id");
    Date eventDate = checkRs.getDate("event_date");
    Date today = new Date(System.currentTimeMillis());

    if(eventDate != null && eventDate.before(today)){
        // Cannot cancel past events
        response.sendRedirect("myRegistrations.jsp?error=event_ended");
        return;
    }

    // Atomically cancel registration and release seat
    conn.setAutoCommit(false);

    // 1. Delete associated payment row if any
    delPayPs = conn.prepareStatement("DELETE FROM payments WHERE registration_id = ?");
    delPayPs.setInt(1, registrationId);
    delPayPs.executeUpdate();

    // 2. Delete registration
    delRegPs = conn.prepareStatement("DELETE FROM registrations WHERE registration_id = ? AND user_id = ?");
    delRegPs.setInt(1, registrationId);
    delRegPs.setInt(2, userId);
    int deletedCount = delRegPs.executeUpdate();

    if(deletedCount > 0){
        // 3. Increment available seat back up
        incSeatPs = conn.prepareStatement(
            "UPDATE events SET available_seats = LEAST(max_capacity, available_seats + 1) WHERE event_id = ?"
        );
        incSeatPs.setInt(1, eventId);
        incSeatPs.executeUpdate();
    }

    conn.commit();
    response.sendRedirect("myRegistrations.jsp?msg=cancelled");
    return;

} catch(Exception e){
    if(conn != null){
        try { conn.rollback(); } catch(Exception ignored){}
    }
    response.sendRedirect("myRegistrations.jsp?error=" + java.net.URLEncoder.encode(e.getMessage() != null ? e.getMessage() : "server_error", "UTF-8"));
} finally {
    if(conn != null){
        try { conn.setAutoCommit(true); } catch(Exception ignored){}
    }
    DBConnection.close(checkRs);
    DBConnection.close(checkPs);
    DBConnection.close(delPayPs);
    DBConnection.close(delRegPs);
    DBConnection.close(incSeatPs);
    DBConnection.close(conn);
}
%>
