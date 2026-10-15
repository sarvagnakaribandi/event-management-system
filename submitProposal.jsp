<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>
<%@ page import="database.NotificationDAO" %>

<%
/* =====================================================
   ORGANIZER LOGIN CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) session.getAttribute("role");
if (role == null || !"Organizer".equalsIgnoreCase(role)) {
    response.sendRedirect("login.jsp");
    return;
}

int organizerId = Integer.parseInt(session.getAttribute("userId").toString());

/* =====================================================
   GET PARAMETERS
   ===================================================== */
String reqIdParam = request.getParameter("request_id");
String proposalTitle = request.getParameter("proposal_title");
String description = request.getParameter("description");
String eventPlan = request.getParameter("event_plan");
String validUntilStr = request.getParameter("valid_until");
String advanceStr = request.getParameter("advance_amount");
String totalStr = request.getParameter("total_amount");

String[] itemNames = request.getParameterValues("item_name");
String[] itemDescs = request.getParameterValues("item_desc");
String[] itemQtys = request.getParameterValues("item_qty");
String[] itemPrices = request.getParameterValues("item_price");

if (reqIdParam == null || proposalTitle == null || eventPlan == null ||
    proposalTitle.trim().isEmpty() || eventPlan.trim().isEmpty()) {
    response.sendRedirect("incomingRequests.jsp");
    return;
}

int requestId;
double totalAmount = 0.0;
double advanceAmount = 0.0;
Date validUntil = null;

try {
    requestId = Integer.parseInt(reqIdParam.trim());
    if (totalStr != null && !totalStr.trim().isEmpty()) {
        totalAmount = Double.parseDouble(totalStr.trim());
    }
    if (advanceStr != null && !advanceStr.trim().isEmpty()) {
        advanceAmount = Double.parseDouble(advanceStr.trim());
    }
    if (validUntilStr != null && !validUntilStr.trim().isEmpty()) {
        validUntil = Date.valueOf(validUntilStr.trim());
    }
} catch (Exception e) {
    response.sendRedirect("incomingRequests.jsp");
    return;
}

Connection conn = null;
PreparedStatement checkPs = null;
PreparedStatement propPs = null;
PreparedStatement itemPs = null;
PreparedStatement statusPs = null;
ResultSet checkRs = null;

try {
    conn = DBConnection.getConnection();
    conn.setAutoCommit(false);

    // 1. Guard against duplicate proposal
    checkPs = conn.prepareStatement("SELECT proposal_id FROM proposals WHERE request_id = ? AND organizer_id = ?");
    checkPs.setInt(1, requestId);
    checkPs.setInt(2, organizerId);
    checkRs = checkPs.executeQuery();

    if (checkRs.next()) {
        conn.rollback();
        response.sendRedirect("incomingRequests.jsp?tab=sent");
        return;
    }

    // 2. Insert into proposals table
    String propSql =
        "INSERT INTO proposals " +
        "(request_id, organizer_id, proposal_title, description, event_plan, total_amount, advance_amount, valid_until, status) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Pending')";

    propPs = conn.prepareStatement(propSql, Statement.RETURN_GENERATED_KEYS);
    propPs.setInt(1, requestId);
    propPs.setInt(2, organizerId);
    propPs.setString(3, proposalTitle.trim());
    propPs.setString(4, description != null ? description.trim() : "");
    propPs.setString(5, eventPlan.trim());
    propPs.setDouble(6, totalAmount);
    propPs.setDouble(7, advanceAmount);

    if (validUntil != null) {
        propPs.setDate(8, validUntil);
    } else {
        propPs.setNull(8, Types.DATE);
    }

    propPs.executeUpdate();

    int proposalId = 0;
    try (ResultSet genKeys = propPs.getGeneratedKeys()) {
        if (genKeys.next()) {
            proposalId = genKeys.getInt(1);
        }
    }

    if (proposalId <= 0) {
        conn.rollback();
        throw new SQLException("Failed to generate proposal record.");
    }

    // 3. Insert line items
    if (itemNames != null && itemNames.length > 0) {
        String itemSql =
            "INSERT INTO proposal_items (proposal_id, item_name, description, quantity, price) " +
            "VALUES (?, ?, ?, ?, ?)";
        itemPs = conn.prepareStatement(itemSql);

        for (int i = 0; i < itemNames.length; i++) {
            String iName = itemNames[i] != null ? itemNames[i].trim() : "";
            if (iName.isEmpty()) continue;

            String iDesc = (itemDescs != null && i < itemDescs.length && itemDescs[i] != null) ? itemDescs[i].trim() : "";
            int iQty = 1;
            if (itemQtys != null && i < itemQtys.length && itemQtys[i] != null && !itemQtys[i].trim().isEmpty()) {
                try { iQty = Integer.parseInt(itemQtys[i].trim()); } catch (Exception ignored) {}
            }
            double iPrice = 0.0;
            if (itemPrices != null && i < itemPrices.length && itemPrices[i] != null && !itemPrices[i].trim().isEmpty()) {
                try { iPrice = Double.parseDouble(itemPrices[i].trim()); } catch (Exception ignored) {}
            }

            itemPs.setInt(1, proposalId);
            itemPs.setString(2, iName);
            itemPs.setString(3, iDesc);
            itemPs.setInt(4, iQty);
            itemPs.setDouble(5, iPrice);
            itemPs.addBatch();
        }
        itemPs.executeBatch();
    }

    // 4. Update request status to 'Proposal Received' if still Pending
    statusPs = conn.prepareStatement("UPDATE event_requests SET status = 'Proposal Received' WHERE request_id = ? AND status = 'Pending'");
    statusPs.setInt(1, requestId);
    statusPs.executeUpdate();

    // 5. In-App Notification (Phase 7)
    try {
        PreparedStatement reqPs = conn.prepareStatement("SELECT user_id, event_title FROM event_requests WHERE request_id = ?");
        reqPs.setInt(1, requestId);
        ResultSet reqRs = reqPs.executeQuery();
        if (reqRs.next()) {
            int customerId = reqRs.getInt("user_id");
            String reqTitle = reqRs.getString("event_title");
            NotificationDAO.createNotification(conn, customerId, "📝 New Quotation Received!", 
                "An organizer submitted a quotation for '" + reqTitle + "' totaling ₹" + String.format("%.2f", totalAmount) + ". Click to view the proposal.", 
                "proposal", "viewProposals.jsp?request_id=" + requestId);
        }
        reqRs.close();
        reqPs.close();
    } catch (Exception ignored) {}

    // Commit atomic transaction
    conn.commit();

    response.sendRedirect("incomingRequests.jsp?msg=proposal_sent&tab=sent");
    return;

} catch (Exception e) {
    if (conn != null) {
        try { conn.rollback(); } catch (Exception ignored) {}
    }
    out.println("<h2 style='color:red;'>Error Submitting Proposal</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
    out.println("<a href='createProposal.jsp?request_id=" + requestId + "'>Back to Proposal Form</a>");
} finally {
    if (conn != null) {
        try { conn.setAutoCommit(true); } catch (Exception ignored) {}
    }
    DBConnection.close(checkRs, checkPs, propPs, itemPs, statusPs, conn);
}
%>
