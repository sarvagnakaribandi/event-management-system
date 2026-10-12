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

int currentUserId = Integer.parseInt(session.getAttribute("userId").toString());
String role = (String) session.getAttribute("role");
boolean isOrganizer = "Organizer".equalsIgnoreCase(role);

String reqIdParam = request.getParameter("request_id");
if (reqIdParam == null || reqIdParam.trim().isEmpty()) {
    response.sendRedirect(isOrganizer ? "incomingRequests.jsp" : "myRequests.jsp");
    return;
}

int requestId;
try {
    requestId = Integer.parseInt(reqIdParam.trim());
} catch (Exception e) {
    response.sendRedirect(isOrganizer ? "incomingRequests.jsp" : "myRequests.jsp");
    return;
}

String msg = request.getParameter("msg");

Connection conn = null;
PreparedStatement reqPs = null;
PreparedStatement propPs = null;
ResultSet reqRs = null;
ResultSet propRs = null;

try {
    conn = DBConnection.getConnection();

    // Query request
    String reqSql =
        "SELECT r.*, t.event_type_name, u.full_name AS customer_name " +
        "FROM event_requests r " +
        "JOIN event_types t ON r.event_type_id = t.event_type_id " +
        "JOIN users u ON r.user_id = u.id " +
        "WHERE r.request_id = ?";

    reqPs = conn.prepareStatement(reqSql);
    reqPs.setInt(1, requestId);
    reqRs = reqPs.executeQuery();

    if (!reqRs.next()) {
        response.sendRedirect(isOrganizer ? "incomingRequests.jsp" : "myRequests.jsp");
        return;
    }

    int requestOwnerId = reqRs.getInt("user_id");
    boolean isOwner = (currentUserId == requestOwnerId);

    // If neither the owner nor an organizer, deny access
    if (!isOwner && !isOrganizer) {
        response.sendRedirect("myRequests.jsp");
        return;
    }

    String title = reqRs.getString("event_title");
    String typeName = reqRs.getString("event_type_name");
    String custName = reqRs.getString("customer_name");
    Date date = reqRs.getDate("event_date");
    Time time = reqRs.getTime("event_time");
    String loc = reqRs.getString("location");
    int guests = reqRs.getInt("guest_count");
    double budget = reqRs.getDouble("budget");
    String reqs = reqRs.getString("requirements");
    String requestStatus = reqRs.getString("status");

    // Query proposals
    String propSql =
        "SELECT p.*, u.full_name AS organizer_name, u.email AS organizer_email " +
        "FROM proposals p " +
        "JOIN users u ON p.organizer_id = u.id " +
        "WHERE p.request_id = ? " +
        "ORDER BY (CASE WHEN p.status = 'Accepted' THEN 0 WHEN p.status = 'Pending' THEN 1 ELSE 2 END), p.total_amount ASC";

    propPs = conn.prepareStatement(propSql);
    propPs.setInt(1, requestId);
    propRs = propPs.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Proposals for <%= SecurityUtil.escapeHtml(title) %> | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin:0; padding:0; box-sizing:border-box; font-family:'Poppins', sans-serif; }
        body { background:#08101f; color:white; min-height:100vh; }

        .navbar {
            height:75px;
            display:flex;
            justify-content:space-between;
            align-items:center;
            padding:0 50px;
            background:#111a2c;
            border-bottom:1px solid #283750;
        }
        .logo {
            font-size:24px;
            font-weight:700;
            background:linear-gradient(90deg, #8f4cff, #ffd369);
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
        }
        .nav-links { display:flex; gap:25px; align-items:center; }
        .nav-links a { color:#cbd5e8; text-decoration:none; font-size:14px; font-weight:500; transition:0.3s; }
        .nav-links a:hover { color:#ffd369; }

        .container { width:92%; max-width:1250px; margin:35px auto 80px; }

        .back-link {
            display:inline-flex;
            align-items:center;
            gap:6px;
            color:#00eaff;
            text-decoration:none;
            font-size:14px;
            margin-bottom:20px;
            font-weight:500;
        }
        .back-link:hover { color:#67e8f9; transform:translateX(-3px); }

        .page-title { font-size:32px; font-weight:700; color:#fff; }
        .page-subtitle { color:#94a3b8; font-size:15px; margin-top:4px; margin-bottom:25px; }

        /* Request Summary Box */
        .req-box {
            background:#111a2d;
            border:1px solid #26354d;
            border-radius:18px;
            padding:24px;
            margin-bottom:35px;
        }
        .req-header {
            display:flex;
            justify-content:space-between;
            align-items:center;
            flex-wrap:wrap;
            gap:15px;
            margin-bottom:15px;
        }
        .req-title { font-size:22px; font-weight:700; color:#fff; }
        .pill { background:#251b47; color:#c084fc; border:1px solid #6b21a8; padding:4px 12px; border-radius:20px; font-size:12px; font-weight:600; }

        .req-grid {
            display:grid;
            grid-template-columns:repeat(auto-fit, minmax(180px, 1fr));
            gap:14px;
            background:#16233b;
            padding:16px;
            border-radius:12px;
            font-size:13px;
        }
        .req-grid span { display:block; color:#94a3b8; font-size:12px; margin-bottom:2px; }
        .req-grid strong { color:#f1f5f9; font-weight:500; }

        /* Proposal Card */
        .proposal-card {
            background:#111a2d;
            border:1px solid #26354d;
            border-radius:20px;
            padding:30px;
            margin-bottom:30px;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
            transition:0.25s;
        }
        .proposal-card.card-accepted {
            border:2px solid #22c55e;
            background:linear-gradient(135deg, #10261f, #111a2d);
        }

        .prop-top {
            display:flex;
            justify-content:space-between;
            align-items:flex-start;
            flex-wrap:wrap;
            gap:15px;
            margin-bottom:18px;
        }
        .prop-title { font-size:22px; font-weight:700; color:#fff; }
        .organizer-info { color:#94a3b8; font-size:13px; margin-top:4px; }
        .organizer-info strong { color:#e2e8f0; }

        /* Status Badge */
        .badge { padding:5px 14px; border-radius:20px; font-size:12px; font-weight:600; }
        .badge-pending { background:rgba(234, 179, 8, 0.15); color:#facc15; border:1px solid rgba(234, 179, 8, 0.4); }
        .badge-accepted { background:rgba(34, 197, 94, 0.2); color:#4ade80; border:1px solid #22c55e; }
        .badge-rejected { background:rgba(239, 68, 68, 0.15); color:#f87171; border:1px solid #ef4444; }

        /* Pricing Strip */
        .pricing-strip {
            display:grid;
            grid-template-columns:repeat(auto-fit, minmax(200px, 1fr));
            gap:15px;
            background:#16233b;
            padding:18px;
            border-radius:14px;
            margin-bottom:22px;
        }
        .price-box span { display:block; color:#94a3b8; font-size:12px; }
        .price-box strong { font-size:22px; font-weight:700; color:#4ade80; }

        .plan-box {
            background:#0c1424;
            border-left:3px solid #7c3aed;
            padding:14px 18px;
            border-radius:0 12px 12px 0;
            font-size:13px;
            color:#cbd5e1;
            margin-bottom:20px;
            line-height:1.6;
        }
        .plan-box strong { color:#e2e8f0; display:block; margin-bottom:5px; font-size:12px; text-transform:uppercase; letter-spacing:0.5px; }

        /* Itemized Table */
        .table-title { font-size:14px; font-weight:600; color:#ffd369; margin-bottom:10px; }
        .item-table {
            width:100%;
            border-collapse:collapse;
            background:#0b1220;
            border-radius:12px;
            overflow:hidden;
            border:1px solid #283750;
            margin-bottom:25px;
        }
        .item-table th {
            background:#18253d;
            color:#cbd5e1;
            padding:12px 16px;
            font-size:12px;
            text-align:left;
            font-weight:600;
            text-transform:uppercase;
        }
        .item-table td {
            padding:12px 16px;
            border-top:1px solid #1f2c44;
            font-size:13px;
            color:#e2e8f0;
        }
        .item-table tr:hover td { background:#141f33; }

        .prop-actions {
            display:flex;
            gap:15px;
            align-items:center;
            flex-wrap:wrap;
            border-top:1px solid #26354d;
            padding-top:20px;
        }

        .btn-accept {
            padding:12px 28px;
            background:linear-gradient(135deg, #10b981, #059669);
            color:white;
            text-decoration:none;
            border-radius:10px;
            font-weight:700;
            font-size:14px;
            transition:0.25s;
            cursor:pointer;
            border:none;
            box-shadow:0 8px 20px rgba(16, 185, 129, 0.35);
        }
        .btn-accept:hover { transform:translateY(-2px); box-shadow:0 12px 25px rgba(16, 185, 129, 0.45); }

        .btn-decline {
            padding:12px 22px;
            background:transparent;
            color:#f87171;
            border:1px solid #dc2626;
            text-decoration:none;
            border-radius:10px;
            font-weight:600;
            font-size:14px;
            transition:0.2s;
            cursor:pointer;
        }
        .btn-decline:hover { background:rgba(239, 68, 68, 0.15); }

        .alert-decline {
            padding:12px 18px;
            background:rgba(239, 68, 68, 0.15);
            border:1px solid #ef4444;
            color:#f87171;
            border-radius:10px;
            font-size:13px;
        }

        .empty-box {
            text-align:center;
            padding:60px 20px;
            background:#111a2d;
            border:1px dashed #2d3e58;
            border-radius:20px;
        }
        .empty-box h3 { color:#ffd369; margin-bottom:10px; }
        .empty-box p { color:#94a3b8; font-size:14px; }

        @media(max-width:768px){
            .navbar { padding:0 20px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:12px; }
            .prop-top { flex-direction:column; }
            .pricing-strip { grid-template-columns:1fr; }
        }
    </style>
</head>
<body>

<div class="navbar">
    <div class="logo">EventSphere</div>
    <div class="nav-links">
        <% if (isOrganizer) { %>
            <a href="organizerDashboard.jsp">Dashboard</a>
            <a href="manageEvents.jsp">Manage Events</a>
            <a href="incomingRequests.jsp" class="active">Custom Requests</a>
        <% } else { %>
            <a href="userDashboard.jsp">Dashboard</a>
            <a href="myRequests.jsp" class="active">My Custom Requests</a>
            <a href="myRegistrations.jsp">My Registrations</a>
        <% } %>
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <a href="<%= isOrganizer ? "incomingRequests.jsp" : "myRequests.jsp" %>" class="back-link">
        ← Back to <%= isOrganizer ? "Custom Requests Marketplace" : "My Requests" %>
    </a>

    <h1 class="page-title">Organizer Proposals & Quotations</h1>
    <p class="page-subtitle">Review, compare itemized breakdowns, and confirm bookings for your custom event.</p>

    <!-- Request Details Summary Card -->
    <div class="req-box">
        <div class="req-header">
            <div>
                <span class="pill"><%= SecurityUtil.escapeHtml(typeName) %></span>
                <span class="req-title" style="margin-left:8px;"><%= SecurityUtil.escapeHtml(title) %></span>
            </div>
            <div style="color:#94a3b8; font-size:13px;">Client: <strong><%= SecurityUtil.escapeHtml(custName) %></strong></div>
        </div>

        <div class="req-grid">
            <div><span>Target Date</span><strong>📅 <%= date != null ? date.toString() : "TBA" %></strong></div>
            <div><span>Target Time</span><strong>⏰ <%= time != null ? time.toString().substring(0, 5) : "Flexible" %></strong></div>
            <div><span>Location</span><strong>📍 <%= SecurityUtil.escapeHtml(loc) %></strong></div>
            <div><span>Guests</span><strong>👥 <%= guests %> Persons</strong></div>
            <div><span>Client Budget</span><strong style="color:#4ade80;"><%= budget > 0 ? ("₹" + String.format("%.2f", budget)) : "Flexible" %></strong></div>
        </div>

        <% if (reqs != null && !reqs.trim().isEmpty()) { %>
            <div style="font-size:13px; color:#cbd5e1; margin-top:14px;">
                <strong style="color:#e2e8f0;">Requirements:</strong> <%= SecurityUtil.escapeHtml(reqs) %>
            </div>
        <% } %>
    </div>

    <!-- PROPOSALS LIST -->
    <%
    boolean hasProposals = false;
    while (propRs.next()) {
        hasProposals = true;
        int propId = propRs.getInt("proposal_id");
        int propOrganizerId = propRs.getInt("organizer_id");
        String pTitle = propRs.getString("proposal_title");
        String pDesc = propRs.getString("description");
        String pPlan = propRs.getString("event_plan");
        double totalAmt = propRs.getDouble("total_amount");
        double advAmt = propRs.getDouble("advance_amount");
        double remAmt = Math.max(0, totalAmt - advAmt);
        Date validUntil = propRs.getDate("valid_until");
        String pStatus = propRs.getString("status");
        String orgName = propRs.getString("organizer_name");
        String orgEmail = propRs.getString("organizer_email");
        Timestamp pCreatedAt = propRs.getTimestamp("created_at");

        boolean isAccepted = "Accepted".equalsIgnoreCase(pStatus);
        boolean isRejected = "Rejected".equalsIgnoreCase(pStatus);
        boolean isPending = "Pending".equalsIgnoreCase(pStatus);

        String badgeClass = "badge-pending";
        String badgeLabel = "🟡 Pending Decision";
        if (isAccepted) {
            badgeClass = "badge-accepted";
            badgeLabel = "🎉 Accepted & Booked";
        } else if (isRejected) {
            badgeClass = "badge-rejected";
            badgeLabel = "❌ Declined";
        }
    %>
        <div class="proposal-card <%= isAccepted ? "card-accepted" : "" %>">
            <div class="prop-top">
                <div>
                    <div class="prop-title"><%= SecurityUtil.escapeHtml(pTitle) %></div>
                    <div class="organizer-info">
                        Offered by: <strong><%= SecurityUtil.escapeHtml(orgName) %></strong> &bull; <%= SecurityUtil.escapeHtml(orgEmail) %>
                    </div>
                </div>
                <div>
                    <span class="badge <%= badgeClass %>"><%= badgeLabel %></span>
                </div>
            </div>

            <!-- Pricing Strip -->
            <div class="pricing-strip">
                <div class="price-box">
                    <span>Total Package Cost</span>
                    <strong>₹<%= String.format("%.2f", totalAmt) %></strong>
                </div>
                <div class="price-box">
                    <span>Advance Required</span>
                    <strong style="color:#38bdf8;">₹<%= String.format("%.2f", advAmt) %></strong>
                </div>
                <div class="price-box">
                    <span>Balance on Event Day</span>
                    <strong style="color:#facc15;">₹<%= String.format("%.2f", remAmt) %></strong>
                </div>
                <div class="price-box">
                    <span>Offer Valid Until</span>
                    <strong style="color:#cbd5e1; font-size:16px;"><%= validUntil != null ? validUntil.toString() : "Flexible" %></strong>
                </div>
            </div>

            <% if (pDesc != null && !pDesc.trim().isEmpty()) { %>
                <div style="font-size:14px; color:#cbd5e1; margin-bottom:15px; line-height:1.6;">
                    <%= SecurityUtil.escapeHtml(pDesc) %>
                </div>
            <% } %>

            <div class="plan-box">
                <strong>Execution Plan & Service Deliverables:</strong>
                <%= SecurityUtil.escapeHtml(pPlan) %>
            </div>

            <!-- Itemized Table -->
            <div class="table-title">🧾 Itemized Cost Breakdown</div>
            <table class="item-table">
                <thead>
                    <tr>
                        <th>Deliverable / Service</th>
                        <th>Specifications</th>
                        <th>Qty</th>
                        <th>Unit Price</th>
                        <th>Subtotal</th>
                    </tr>
                </thead>
                <tbody>
                <%
                PreparedStatement itemPs = null;
                ResultSet itemRs = null;
                try {
                    itemPs = conn.prepareStatement("SELECT * FROM proposal_items WHERE proposal_id = ?");
                    itemPs.setInt(1, propId);
                    itemRs = itemPs.executeQuery();
                    while (itemRs.next()) {
                        String iName = itemRs.getString("item_name");
                        String iDesc = itemRs.getString("description");
                        int iQty = itemRs.getInt("quantity");
                        double iPrice = itemRs.getDouble("price");
                        double subtotal = iQty * iPrice;
                %>
                    <tr>
                        <td><strong><%= SecurityUtil.escapeHtml(iName) %></strong></td>
                        <td><%= SecurityUtil.escapeHtml(iDesc != null ? iDesc : "-") %></td>
                        <td><%= iQty %></td>
                        <td>₹<%= String.format("%.2f", iPrice) %></td>
                        <td style="color:#4ade80; font-weight:600;">₹<%= String.format("%.2f", subtotal) %></td>
                    </tr>
                <%
                    }
                } finally {
                    DBConnection.close(itemRs, itemPs);
                }
                %>
                </tbody>
            </table>

            <!-- Actions -->
            <div class="prop-actions">
                <span style="color:#64748b; font-size:12px;">Submitted on: <%= pCreatedAt != null ? pCreatedAt.toString().substring(0, 16) : "N/A" %></span>

                <% if (isOwner && isPending && !"Accepted".equalsIgnoreCase(requestStatus)) { %>
                    <div style="display:flex; gap:12px; margin-left:auto;">
                        <a href="respondProposal.jsp?proposal_id=<%= propId %>&action=accept" 
                           class="btn-accept"
                           onclick="return confirm('Accept proposal from <%= SecurityUtil.escapeHtml(orgName) %> for ₹<%= String.format("%.2f", totalAmt) %>?\n\nThis will confirm your custom event booking and notify the organizer.');">
                            ✅ Accept Proposal & Confirm Booking
                        </a>
                        <a href="respondProposal.jsp?proposal_id=<%= propId %>&action=reject" 
                           class="btn-decline"
                           onclick="return confirm('Decline this quotation?');">
                            ✕ Decline
                        </a>
                    </div>
                <% } else if (isAccepted) { %>
                    <div style="margin-left:auto;">
                        <span style="color:#4ade80; font-weight:600; font-size:14px;">🎉 Confirmed Booking with this Organizer!</span>
                    </div>
                <% } else if (isRejected) { %>
                    <div style="margin-left:auto;">
                        <span style="color:#f87171; font-size:13px;">❌ This quotation was declined.</span>
                    </div>
                <% } %>
            </div>
        </div>
    <%
    }
    if (!hasProposals) {
    %>
        <div class="empty-box">
            <h3>No Proposals Submitted Yet</h3>
            <p>Organizers are currently reviewing your custom event specifications. You will see proposals and itemized quotes listed here as soon as they are submitted.</p>
        </div>
    <%
    }
    %>

</div>

</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:#f87171;padding:30px;'>Error</h2>");
    out.println("<p style='padding:0 30px;color:#cbd5e1;'>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
} finally {
    DBConnection.close(propRs, reqRs, propPs, reqPs, conn);
}
%>
