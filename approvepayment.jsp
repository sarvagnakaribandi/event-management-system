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
   GET PARAMETERS
   ===================================================== */
String registrationParam = request.getParameter("id");
String eventParam = request.getParameter("event_id");

if (registrationParam == null || eventParam == null) {
    response.sendRedirect(request.getContextPath() + "/manageEvents.jsp");
    return;
}

int registrationId;
int eventId;

try {
    registrationId = Integer.parseInt(registrationParam.trim());
    eventId = Integer.parseInt(eventParam.trim());
} catch (Exception e) {
    response.sendRedirect(request.getContextPath() + "/manageEvents.jsp");
    return;
}

Connection conn = null;
PreparedStatement regPs = null;
PreparedStatement payPs = null;

try {
    conn = DBConnection.getConnection();
    conn.setAutoCommit(false);

    /* =================================================
       APPROVE REGISTRATION
       Only the organizer who owns the event can approve.
       ================================================= */
    String regSql =
        "UPDATE registrations r " +
        "INNER JOIN events e ON r.event_id = e.event_id " +
        "SET r.payment_status = 'Approved' " +
        "WHERE r.registration_id = ? " +
        "AND r.event_id = ? " +
        "AND e.organizer_id = ?";

    regPs = conn.prepareStatement(regSql);
    regPs.setInt(1, registrationId);
    regPs.setInt(2, eventId);
    regPs.setInt(3, organizerId);

    int regUpdated = regPs.executeUpdate();

    if (regUpdated > 0) {
        /* =============================================
           APPROVE IN PAYMENTS TABLE
           Keep payments table in sync with registrations
           ============================================= */
        String paySql = "UPDATE payments SET payment_status = 'Approved' WHERE registration_id = ?";
        payPs = conn.prepareStatement(paySql);
        payPs.setInt(1, registrationId);
        payPs.executeUpdate();

        conn.commit();

        response.sendRedirect(request.getContextPath() + "/viewParticipants.jsp?id=" + eventId + "&msg=approved");
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
    <title>Approval Failed | EventSphere</title>
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
    <h1>⚠️ Approval Failed</h1>
    <p>Registration record not found or you do not have permission to approve this registration.</p>
    <a href="<%=request.getContextPath()%>/viewParticipants.jsp?id=<%=eventId%>">← Back to Participants</a>
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
    <title>Error Approving Payment | EventSphere</title>
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
    <h2>Error Approving Payment</h2>
    <p><%=SecurityUtil.escapeHtml(e.getMessage() != null ? e.getMessage() : "An unexpected server error occurred.")%></p>
    <a href="<%=request.getContextPath()%>/viewParticipants.jsp?id=<%=eventId%>">← Back to Participants</a>
</div>
</body>
</html>
<%
} finally {
    if (conn != null) {
        try { conn.setAutoCommit(true); } catch (Exception ignored) {}
    }
    DBConnection.close(regPs, payPs, conn);
}
%>