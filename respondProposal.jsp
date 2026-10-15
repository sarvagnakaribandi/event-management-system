<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>
<%@ page import="database.NotificationDAO" %>

<%
/* =====================================================
   LOGIN CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(session.getAttribute("userId").toString());

String propIdParam = request.getParameter("proposal_id");
String action = request.getParameter("action");

if (propIdParam == null || action == null) {
    response.sendRedirect("myRequests.jsp");
    return;
}

int proposalId;
try {
    proposalId = Integer.parseInt(propIdParam.trim());
} catch (Exception e) {
    response.sendRedirect("myRequests.jsp");
    return;
}

Connection conn = null;
PreparedStatement verifyPs = null;
PreparedStatement acceptPs = null;
PreparedStatement rejectOthersPs = null;
PreparedStatement bookPs = null;
PreparedStatement updateReqPs = null;
PreparedStatement rejectSinglePs = null;
ResultSet verifyRs = null;

try {
    conn = DBConnection.getConnection();
    conn.setAutoCommit(false);

    // Verify ownership of the request for this proposal
    String verifySql =
        "SELECT p.proposal_id, p.request_id, p.organizer_id, p.total_amount, p.advance_amount, p.status AS prop_status, " +
        "r.user_id, r.status AS req_status, r.event_title " +
        "FROM proposals p " +
        "JOIN event_requests r ON p.request_id = r.request_id " +
        "WHERE p.proposal_id = ? AND r.user_id = ?";

    verifyPs = conn.prepareStatement(verifySql);
    verifyPs.setInt(1, proposalId);
    verifyPs.setInt(2, userId);
    verifyRs = verifyPs.executeQuery();

    if (!verifyRs.next()) {
        conn.rollback();
        response.sendRedirect("myRequests.jsp");
        return;
    }

    int requestId = verifyRs.getInt("request_id");
    int organizerId = verifyRs.getInt("organizer_id");
    String eventTitle = verifyRs.getString("event_title");
    double totalAmount = verifyRs.getDouble("total_amount");
    double advanceAmount = verifyRs.getDouble("advance_amount");
    double remainingAmount = Math.max(0, totalAmount - advanceAmount);
    String propStatus = verifyRs.getString("prop_status");

    if ("accept".equalsIgnoreCase(action)) {
        if (!"Pending".equalsIgnoreCase(propStatus)) {
            conn.rollback();
            response.sendRedirect("viewProposals.jsp?request_id=" + requestId);
            return;
        }

        // 1. Accept this proposal
        acceptPs = conn.prepareStatement("UPDATE proposals SET status = 'Accepted' WHERE proposal_id = ?");
        acceptPs.setInt(1, proposalId);
        acceptPs.executeUpdate();

        // 2. Reject other pending proposals for this request
        rejectOthersPs = conn.prepareStatement("UPDATE proposals SET status = 'Rejected' WHERE request_id = ? AND proposal_id != ? AND status = 'Pending'");
        rejectOthersPs.setInt(1, requestId);
        rejectOthersPs.setInt(2, proposalId);
        rejectOthersPs.executeUpdate();

        // 3. Insert confirmed booking record
        String bookSql =
            "INSERT INTO custom_event_bookings " +
            "(request_id, proposal_id, user_id, organizer_id, total_amount, advance_amount, remaining_amount, booking_status) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, 'Confirmed')";

        bookPs = conn.prepareStatement(bookSql);
        bookPs.setInt(1, requestId);
        bookPs.setInt(2, proposalId);
        bookPs.setInt(3, userId);
        bookPs.setInt(4, organizerId);
        bookPs.setDouble(5, totalAmount);
        bookPs.setDouble(6, advanceAmount);
        bookPs.setDouble(7, remainingAmount);
        bookPs.executeUpdate();

        // 4. Update request status
        updateReqPs = conn.prepareStatement("UPDATE event_requests SET status = 'Accepted' WHERE request_id = ?");
        updateReqPs.setInt(1, requestId);
        updateReqPs.executeUpdate();

        // 5. In-App Notifications (Phase 7)
        try {
            NotificationDAO.createNotification(conn, organizerId, "🎉 Proposal Accepted!", 
                "Great news! The customer accepted your proposal for '" + eventTitle + "' (Total: ₹" + String.format("%.2f", totalAmount) + ").", 
                "proposal", "incomingRequests.jsp?tab=sent");

            NotificationDAO.createNotification(conn, userId, "🎉 Custom Event Confirmed!", 
                "You accepted the proposal for '" + eventTitle + "'. Your custom event booking is confirmed!", 
                "proposal", "myRequests.jsp");
        } catch (Exception ignored) {}

        conn.commit();
        response.sendRedirect("myRequests.jsp?msg=accepted");
        return;

    } else if ("reject".equalsIgnoreCase(action)) {
        rejectSinglePs = conn.prepareStatement("UPDATE proposals SET status = 'Rejected' WHERE proposal_id = ? AND status = 'Pending'");
        rejectSinglePs.setInt(1, proposalId);
        rejectSinglePs.executeUpdate();

        // Notification to Organizer
        try {
            NotificationDAO.createNotification(conn, organizerId, "ℹ️ Proposal Declined", 
                "The customer declined your quotation for '" + eventTitle + "'.", 
                "proposal", "incomingRequests.jsp?tab=sent");
        } catch (Exception ignored) {}

        conn.commit();
        response.sendRedirect("viewProposals.jsp?request_id=" + requestId + "&msg=rejected");
        return;
    } else {
        conn.rollback();
        response.sendRedirect("viewProposals.jsp?request_id=" + requestId);
        return;
    }

} catch (Exception e) {
    if (conn != null) {
        try { conn.rollback(); } catch (Exception ignored) {}
    }
    out.println("<h2 style='color:red;'>Error Processing Decision</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
    out.println("<a href='myRequests.jsp'>Back to My Requests</a>");
} finally {
    if (conn != null) {
        try { conn.setAutoCommit(true); } catch (Exception ignored) {}
    }
    DBConnection.close(verifyRs, verifyPs, acceptPs, rejectOthersPs, bookPs, updateReqPs, rejectSinglePs, conn);
}
%>
