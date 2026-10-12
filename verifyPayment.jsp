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

/* =====================================================
   ORGANIZER ROLE CHECK
   ===================================================== */
String role = (String) session.getAttribute("role");
if (role == null || !"Organizer".equalsIgnoreCase(role)) {
    response.sendRedirect("login.jsp");
    return;
}

int organizerId = Integer.parseInt(session.getAttribute("userId").toString());

/* =====================================================
   PARAMETERS
   ===================================================== */
String registrationIdString = request.getParameter("registration_id");
String eventIdString = request.getParameter("event_id");
String status = request.getParameter("status");

if (registrationIdString == null || eventIdString == null || status == null) {
    response.sendRedirect("manageEvents.jsp");
    return;
}

int registrationId;
int eventId;

try {
    registrationId = Integer.parseInt(registrationIdString.trim());
    eventId = Integer.parseInt(eventIdString.trim());
} catch (Exception e) {
    response.sendRedirect("manageEvents.jsp");
    return;
}

/* =====================================================
   ONLY APPROVED / REJECTED ALLOWED
   ===================================================== */
if (!"Approved".equalsIgnoreCase(status) && !"Rejected".equalsIgnoreCase(status)) {
    response.sendRedirect("viewParticipants.jsp?id=" + eventId);
    return;
}

Connection conn = null;
PreparedStatement ps = null;
PreparedStatement payPs = null;
PreparedStatement seatPs = null;

try {
    conn = DBConnection.getConnection();
    conn.setAutoCommit(false);

    /* =================================================
       SECURE UPDATE IN REGISTRATIONS
       ================================================= */
    String sql =
        "UPDATE registrations r " +
        "INNER JOIN events e ON r.event_id=e.event_id " +
        "SET r.payment_status=? " +
        "WHERE r.registration_id=? " +
        "AND r.event_id=? " +
        "AND e.organizer_id=?";

    ps = conn.prepareStatement(sql);
    ps.setString(1, status);
    ps.setInt(2, registrationId);
    ps.setInt(3, eventId);
    ps.setInt(4, organizerId);

    int result = ps.executeUpdate();

    if (result > 0) {
        // Sync payments table
        String paySql = "UPDATE payments SET payment_status=? WHERE registration_id=?";
        payPs = conn.prepareStatement(paySql);
        payPs.setString(1, status);
        payPs.setInt(2, registrationId);
        payPs.executeUpdate();

        // If rejected, restore seat
        if ("Rejected".equalsIgnoreCase(status)) {
            String seatSql = "UPDATE events SET available_seats = LEAST(max_capacity, available_seats + 1) WHERE event_id = ?";
            seatPs = conn.prepareStatement(seatSql);
            seatPs.setInt(1, eventId);
            seatPs.executeUpdate();
        }

        conn.commit();

        response.sendRedirect("viewParticipants.jsp?id=" + eventId + "&msg=" + status.toLowerCase());
        return;
    } else {
        conn.rollback();
    }

%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Access Denied | EventSphere</title>
    <style>
        body { margin:0; min-height:100vh; background:#0b1220; color:white; font-family:Arial,sans-serif; display:flex; justify-content:center; align-items:center; }
        .box { width:90%; max-width:500px; padding:40px; text-align:center; background:#18243a; border:1px solid #34425c; border-radius:18px; }
        h1 { color:#ffbd3d; margin-bottom:15px; }
        p { color:#cbd5e1; line-height:1.6; margin-bottom:25px; }
        a { display:inline-block; padding:12px 25px; background:#7138ff; color:white; text-decoration:none; border-radius:10px; font-weight:bold; }
    </style>
</head>
<body>
<div class="box">
    <h1>🔒 Access Denied</h1>
    <p>You cannot modify this registration. It does not belong to one of your events.</p>
    <a href="manageEvents.jsp">← Back to My Events</a>
</div>
</body>
</html>
<%
} catch (Exception e) {
    if (conn != null) {
        try { conn.rollback(); } catch (Exception ignored) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Payment Update Error | EventSphere</title>
    <style>
        body { margin:0; min-height:100vh; background:#0b1220; color:white; font-family:Arial,sans-serif; display:flex; justify-content:center; align-items:center; }
        .box { width:90%; max-width:500px; padding:40px; text-align:center; background:#18243a; border:1px solid #34425c; border-radius:18px; }
        h2 { color:#ff7180; margin-bottom:15px; }
        p { color:#cbd5e1; line-height:1.6; margin-bottom:25px; }
        a { display:inline-block; padding:12px 25px; background:#7138ff; color:white; text-decoration:none; border-radius:10px; font-weight:bold; }
    </style>
</head>
<body>
<div class="box">
    <h2>Payment Update Error</h2>
    <p><%=SecurityUtil.escapeHtml(e.getMessage() != null ? e.getMessage() : "")%></p>
    <a href="viewParticipants.jsp?id=<%=eventId%>">← Back to Participants</a>
</div>
</body>
</html>
<%
} finally {
    if (conn != null) {
        try { conn.setAutoCommit(true); } catch (Exception ignored) {}
    }
    DBConnection.close(ps, payPs, seatPs, conn);
}
%>