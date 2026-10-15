<%@ page contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>
<%@ page import="database.NotificationDAO" %>

<%
response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

/* =====================================================
   ORGANIZER / ADMIN ACCESS GUARD
   ===================================================== */
if (session.getAttribute("userId") == null) {
    out.print("{\"status\": \"UNAUTHORIZED\", \"message\": \"Please log in to perform check-in.\"}");
    return;
}

String sessionRole = session.getAttribute("role") != null ? session.getAttribute("role").toString() : "";
int sessionUserId = Integer.parseInt(session.getAttribute("userId").toString());

if (!"Organizer".equalsIgnoreCase(sessionRole) && !"Admin".equalsIgnoreCase(sessionRole)) {
    out.print("{\"status\": \"FORBIDDEN\", \"message\": \"Only event organizers and admins can scan tickets.\"}");
    return;
}

String token = request.getParameter("token");
String eventIdParam = request.getParameter("event_id");

if (token == null || token.trim().isEmpty() || eventIdParam == null || eventIdParam.trim().isEmpty()) {
    out.print("{\"status\": \"MISSING_PARAM\", \"message\": \"Missing ticket token or event ID.\"}");
    return;
}

token = token.trim();
int eventId;
try {
    eventId = Integer.parseInt(eventIdParam.trim());
} catch (NumberFormatException e) {
    out.print("{\"status\": \"INVALID_PARAM\", \"message\": \"Invalid event ID format.\"}");
    return;
}

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = DBConnection.getConnection();

    // Verify organizer owns this event (Admins can scan any event)
    if (!"Admin".equalsIgnoreCase(sessionRole)) {
        PreparedStatement ownPs = conn.prepareStatement("SELECT event_id FROM events WHERE event_id = ? AND organizer_id = ?");
        ownPs.setInt(1, eventId);
        ownPs.setInt(2, sessionUserId);
        ResultSet ownRs = ownPs.executeQuery();
        if (!ownRs.next()) {
            ownRs.close();
            ownPs.close();
            out.print("{\"status\": \"FORBIDDEN\", \"message\": \"You can only check in attendees for your own events.\"}");
            return;
        }
        ownRs.close();
        ownPs.close();
    }

    // Clean token if a full URL was scanned
    if (token.contains("token=")) {
        token = token.substring(token.indexOf("token=") + 6);
        if (token.contains("&")) token = token.substring(0, token.indexOf("&"));
    } else if (token.contains("id=")) {
        token = token.substring(token.indexOf("id=") + 3);
        if (token.contains("&")) token = token.substring(0, token.indexOf("&"));
    }

    // Lookup registration by ticket_token (or transaction_id or registration_id fallback)
    String sql =
        "SELECT r.registration_id, r.user_id, r.event_id, r.full_name, r.email, r.payment_status, " +
        "r.ticket_token, r.check_in_status, r.checked_in_at, e.event_name " +
        "FROM registrations r " +
        "JOIN events e ON r.event_id = e.event_id " +
        "WHERE r.ticket_token = ? OR r.transaction_id = ? OR CAST(r.registration_id AS CHAR) = ?";

    ps = conn.prepareStatement(sql);
    ps.setString(1, token);
    ps.setString(2, token);
    ps.setString(3, token);
    rs = ps.executeQuery();

    if (!rs.next()) {
        out.print("{\"status\": \"INVALID_TOKEN\", \"message\": \"Ticket token '" + SecurityUtil.escapeHtml(token) + "' not found in system.\"}");
        return;
    }

    int regId = rs.getInt("registration_id");
    int attendeeUserId = rs.getInt("user_id");
    int regEventId = rs.getInt("event_id");
    String attendeeName = rs.getString("full_name");
    String attendeeEmail = rs.getString("email");
    String paymentStatus = rs.getString("payment_status");
    String ticketToken = rs.getString("ticket_token");
    String checkInStatus = rs.getString("check_in_status");
    Timestamp checkedInAt = rs.getTimestamp("checked_in_at");
    String eventName = rs.getString("event_name");

    // Check 1: Event Match
    if (regEventId != eventId) {
        out.print("{\"status\": \"WRONG_EVENT\", \"message\": \"Wrong Event! This ticket is registered for '" + SecurityUtil.escapeHtml(eventName) + "', not this event.\"}");
        return;
    }

    // Check 2: Payment Approval
    if (!"Approved".equalsIgnoreCase(paymentStatus) && !"Not Required".equalsIgnoreCase(paymentStatus)) {
        out.print("{\"status\": \"PAYMENT_NOT_APPROVED\", \"message\": \"Admission Denied: Payment is '" + paymentStatus + "'. Please verify payment first.\"}");
        return;
    }

    // Check 3: Already Checked In (Duplicate Prevention)
    if ("Checked In".equalsIgnoreCase(checkInStatus)) {
        String timeStr = checkedInAt != null ? new java.text.SimpleDateFormat("hh:mm a, MMM dd").format(checkedInAt) : "Earlier";
        out.print("{\"status\": \"ALREADY_CHECKED_IN\", \"message\": \"Duplicate Ticket! " + SecurityUtil.escapeHtml(attendeeName) + " already checked in at " + timeStr + ".\", \"attendeeName\": \"" + SecurityUtil.escapeHtml(attendeeName) + "\", \"checkedInAt\": \"" + timeStr + "\"}");
        return;
    }

    // All checks passed -> Mark as Checked In
    PreparedStatement updatePs = conn.prepareStatement(
        "UPDATE registrations SET check_in_status = 'Checked In', checked_in_at = CURRENT_TIMESTAMP, checked_in_by = ? WHERE registration_id = ?"
    );
    updatePs.setInt(1, sessionUserId);
    updatePs.setInt(2, regId);
    int updated = updatePs.executeUpdate();
    updatePs.close();

    if (updated > 0) {
        // Send notification to attendee
        try {
            NotificationDAO.createNotification(conn, attendeeUserId, "🎟️ Checked In at Gate!", 
                "Your admission to '" + eventName + "' was verified at the entrance gate. Enjoy the event!", 
                "booking", "viewTicket.jsp?id=" + regId);
        } catch (Exception ignored) {}

        String nowTime = new java.text.SimpleDateFormat("hh:mm a").format(new java.util.Date());
        out.print("{\"status\": \"SUCCESS\", \"message\": \"Admission Granted! Welcome " + SecurityUtil.escapeHtml(attendeeName) + ".\", \"attendeeName\": \"" + SecurityUtil.escapeHtml(attendeeName) + "\", \"email\": \"" + SecurityUtil.escapeHtml(attendeeEmail) + "\", \"ticketToken\": \"" + ticketToken + "\", \"checkedInAt\": \"" + nowTime + "\", \"regId\": " + regId + "}");
    } else {
        out.print("{\"status\": \"ERROR\", \"message\": \"Failed to update check-in record. Please retry.\"}");
    }

} catch (Exception e) {
    out.print("{\"status\": \"ERROR\", \"message\": \"" + SecurityUtil.escapeHtml(e.getMessage()) + "\"}");
} finally {
    DBConnection.close(conn, ps, rs);
}
%>
