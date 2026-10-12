<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

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
String userName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Organizer";
String msg = request.getParameter("msg");
String tab = request.getParameter("tab");
if (tab == null || tab.trim().isEmpty()) {
    tab = "open";
}

Connection conn = null;
PreparedStatement openPs = null;
PreparedStatement myPropPs = null;
ResultSet openRs = null;
ResultSet myPropRs = null;

try {
    conn = DBConnection.getConnection();

    // Query open requests
    String openSql =
        "SELECT r.*, t.event_type_name, u.full_name AS customer_name, " +
        "(SELECT COUNT(*) FROM proposals p WHERE p.request_id = r.request_id) AS total_proposals, " +
        "(SELECT proposal_id FROM proposals p WHERE p.request_id = r.request_id AND p.organizer_id = ?) AS my_proposal_id " +
        "FROM event_requests r " +
        "JOIN event_types t ON r.event_type_id = t.event_type_id " +
        "JOIN users u ON r.user_id = u.id " +
        "WHERE r.status IN ('Pending', 'Proposal Received') " +
        "ORDER BY r.created_at DESC";

    openPs = conn.prepareStatement(openSql);
    openPs.setInt(1, organizerId);
    openRs = openPs.executeQuery();

    // Query proposals submitted by this organizer
    String myPropSql =
        "SELECT p.*, r.event_title, r.event_date, r.location, t.event_type_name, u.full_name AS customer_name " +
        "FROM proposals p " +
        "JOIN event_requests r ON p.request_id = r.request_id " +
        "JOIN event_types t ON r.event_type_id = t.event_type_id " +
        "JOIN users u ON r.user_id = u.id " +
        "WHERE p.organizer_id = ? " +
        "ORDER BY p.created_at DESC";

    myPropPs = conn.prepareStatement(myPropSql);
    myPropPs.setInt(1, organizerId);
    myPropRs = myPropPs.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Custom Event Requests | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin:0; padding:0; box-sizing:border-box; font-family:'Poppins', sans-serif; }
        body { background:#08101f; color:white; min-height:100vh; }

        /* Navbar */
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
        .nav-links a.active { color:#ffd369; font-weight:700; }

        .container { width:92%; max-width:1250px; margin:40px auto 80px; }

        .page-header { margin-bottom:25px; }
        .page-title { font-size:32px; font-weight:700; color:#fff; }
        .page-subtitle { color:#94a3b8; font-size:15px; margin-top:4px; }

        /* Alerts */
        .alert {
            padding:14px 20px;
            border-radius:12px;
            margin-bottom:25px;
            font-size:14px;
            font-weight:500;
            display:flex;
            align-items:center;
            justify-content:space-between;
        }
        .alert-success { background:rgba(34,197,94,0.15); border:1px solid #22c55e; color:#4ade80; }
        .alert-info { background:rgba(56,189,248,0.15); border:1px solid #38bdf8; color:#38bdf8; }

        /* Tabs */
        .tabs-nav {
            display:flex;
            gap:15px;
            border-bottom:1px solid #24354f;
            margin-bottom:30px;
        }
        .tab-btn {
            padding:12px 22px;
            text-decoration:none;
            color:#94a3b8;
            font-size:15px;
            font-weight:600;
            border-bottom:3px solid transparent;
            transition:0.25s;
        }
        .tab-btn:hover { color:#fff; }
        .tab-btn.active { color:#ffd369; border-bottom-color:#ffd369; }

        /* Cards */
        .request-card {
            background:#111a2d;
            border:1px solid #26354d;
            border-radius:20px;
            padding:28px;
            margin-bottom:25px;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
            transition:0.25s;
        }
        .request-card:hover { border-color:#7c3aed; transform:translateY(-3px); }

        .card-top {
            display:flex;
            justify-content:space-between;
            align-items:flex-start;
            flex-wrap:wrap;
            gap:15px;
            margin-bottom:18px;
        }
        .request-title { font-size:22px; font-weight:700; color:#fff; }
        .tags-row { display:flex; gap:10px; align-items:center; flex-wrap:wrap; margin-top:6px; }
        .category-pill { background:#251b47; color:#c084fc; border:1px solid #6b21a8; padding:4px 12px; border-radius:20px; font-size:12px; font-weight:600; }
        .customer-pill { background:#16233b; color:#93c5fd; border:1px solid #334155; padding:4px 12px; border-radius:20px; font-size:12px; font-weight:500; }

        .details-grid {
            display:grid;
            grid-template-columns:repeat(auto-fit, minmax(200px, 1fr));
            gap:15px;
            margin-bottom:20px;
            background:#16233b;
            padding:18px;
            border-radius:14px;
        }
        .grid-item { font-size:13px; color:#94a3b8; }
        .grid-item strong { display:block; color:#f1f5f9; font-size:14px; margin-top:3px; }

        .text-box {
            background:#0c1424;
            border-left:3px solid #7c3aed;
            padding:12px 16px;
            border-radius:0 10px 10px 0;
            font-size:13px;
            color:#cbd5e1;
            margin-bottom:18px;
            line-height:1.6;
        }
        .text-box strong { color:#e2e8f0; display:block; margin-bottom:4px; font-size:12px; text-transform:uppercase; letter-spacing:0.5px; }

        .actions-bar {
            display:flex;
            justify-content:space-between;
            align-items:center;
            flex-wrap:wrap;
            gap:15px;
            border-top:1px solid #24354f;
            padding-top:18px;
        }
        .created-time { color:#64748b; font-size:12px; }

        .btn-create-proposal {
            padding:11px 24px;
            background:linear-gradient(135deg, #10b981, #059669);
            color:white;
            text-decoration:none;
            border-radius:10px;
            font-weight:600;
            font-size:13px;
            transition:0.25s;
            display:inline-flex;
            align-items:center;
            gap:6px;
            box-shadow:0 6px 16px rgba(16, 185, 129, 0.3);
        }
        .btn-create-proposal:hover { transform:translateY(-2px); box-shadow:0 10px 20px rgba(16, 185, 129, 0.4); }

        .submitted-badge {
            background:rgba(56, 189, 248, 0.15);
            border:1px solid #38bdf8;
            color:#38bdf8;
            padding:8px 16px;
            border-radius:10px;
            font-size:13px;
            font-weight:600;
        }

        /* Status Badges for Sent Proposals */
        .status-badge { padding:5px 14px; border-radius:20px; font-size:12px; font-weight:600; }
        .status-pending { background:rgba(234, 179, 8, 0.15); color:#facc15; border:1px solid rgba(234, 179, 8, 0.4); }
        .status-accepted { background:rgba(34, 197, 94, 0.15); color:#4ade80; border:1px solid #22c55e; }
        .status-rejected { background:rgba(239, 68, 68, 0.15); color:#f87171; border:1px solid #ef4444; }

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
            .card-top { flex-direction:column; }
            .actions-bar { flex-direction:column; align-items:flex-start; }
        }
    </style>
</head>
<body>

<!-- Navbar -->
<div class="navbar">
    <div class="logo">EventSphere</div>
    <div class="nav-links">
        <a href="organizerDashboard.jsp">Dashboard</a>
        <a href="addEvent.jsp">Add Event</a>
        <a href="manageEvents.jsp">Manage Events</a>
        <a href="incomingRequests.jsp" class="active">Custom Requests</a>
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <div class="page-header">
        <h1 class="page-title">Custom Event Requests Marketplace</h1>
        <p class="page-subtitle">Review incoming event requirements posted by customers, submit itemized quotations, and win custom bookings.</p>
    </div>

    <% if ("proposal_sent".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-success">
            <span>✅ Proposal quotation submitted successfully! The customer has been notified and can review your itemized offer.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } %>

    <!-- Tabs Navigation -->
    <div class="tabs-nav">
        <a href="incomingRequests.jsp?tab=open" class="tab-btn <%= "open".equalsIgnoreCase(tab) ? "active" : "" %>">
            🎯 Open Opportunities
        </a>
        <a href="incomingRequests.jsp?tab=sent" class="tab-btn <%= "sent".equalsIgnoreCase(tab) ? "active" : "" %>">
            📤 My Submitted Proposals
        </a>
    </div>

    <!-- TAB 1: OPEN OPPORTUNITIES -->
    <% if ("open".equalsIgnoreCase(tab)) { %>
        <%
        boolean hasOpen = false;
        while (openRs.next()) {
            hasOpen = true;
            int reqId = openRs.getInt("request_id");
            String title = openRs.getString("event_title");
            String typeName = openRs.getString("event_type_name");
            String custName = openRs.getString("customer_name");
            Date date = openRs.getDate("event_date");
            Time time = openRs.getTime("event_time");
            String loc = openRs.getString("location");
            int guests = openRs.getInt("guest_count");
            double budget = openRs.getDouble("budget");
            String reqs = openRs.getString("requirements");
            String notes = openRs.getString("additional_notes");
            int totalProps = openRs.getInt("total_proposals");
            int myPropId = openRs.getInt("my_proposal_id");
            Timestamp createdAt = openRs.getTimestamp("created_at");
        %>
            <div class="request-card">
                <div class="card-top">
                    <div>
                        <div class="request-title"><%= SecurityUtil.escapeHtml(title) %></div>
                        <div class="tags-row">
                            <span class="category-pill"><%= SecurityUtil.escapeHtml(typeName) %></span>
                            <span class="customer-pill">👤 Client: <%= SecurityUtil.escapeHtml(custName) %></span>
                            <span style="color:#94a3b8; font-size:13px;">Request #REQ-<%= reqId %></span>
                        </div>
                    </div>
                    <div>
                        <span style="background:#1e293b; color:#cbd5e1; border:1px solid #334155; padding:5px 12px; border-radius:15px; font-size:12px;">
                            <%= totalProps %> Proposal<%= totalProps != 1 ? "s" : "" %> Received
                        </span>
                    </div>
                </div>

                <div class="details-grid">
                    <div class="grid-item">
                        Target Date
                        <strong>📅 <%= date != null ? date.toString() : "TBA" %></strong>
                    </div>
                    <div class="grid-item">
                        Target Time
                        <strong>⏰ <%= time != null ? time.toString().substring(0, 5) : "Flexible" %></strong>
                    </div>
                    <div class="grid-item">
                        Location / Venue
                        <strong>📍 <%= SecurityUtil.escapeHtml(loc) %></strong>
                    </div>
                    <div class="grid-item">
                        Expected Guests
                        <strong>👥 <%= guests %> Persons</strong>
                    </div>
                    <div class="grid-item">
                        Customer Budget
                        <strong style="color:#4ade80;"><%= budget > 0 ? ("₹" + String.format("%.2f", budget)) : "Flexible / Open" %></strong>
                    </div>
                </div>

                <% if (reqs != null && !reqs.trim().isEmpty()) { %>
                    <div class="text-box">
                        <strong>Requested Services & Requirements:</strong>
                        <%= SecurityUtil.escapeHtml(reqs) %>
                    </div>
                <% } %>

                <% if (notes != null && !notes.trim().isEmpty()) { %>
                    <div class="text-box" style="border-left-color:#38bdf8;">
                        <strong>Special Notes from Client:</strong>
                        <%= SecurityUtil.escapeHtml(notes) %>
                    </div>
                <% } %>

                <div class="actions-bar">
                    <div class="created-time">
                        Posted on: <%= createdAt != null ? createdAt.toString().substring(0, 16) : "N/A" %>
                    </div>

                    <div>
                        <% if (myPropId > 0) { %>
                            <span class="submitted-badge">✓ You submitted a quotation for this request</span>
                        <% } else { %>
                            <a href="createProposal.jsp?request_id=<%= reqId %>" class="btn-create-proposal">
                                📝 Create & Send Proposal Quotation
                            </a>
                        <% } %>
                    </div>
                </div>
            </div>
        <%
        }
        if (!hasOpen) {
        %>
            <div class="empty-box">
                <h3>No Open Custom Requests Right Now</h3>
                <p>Check back soon. Customers regularly post custom event inquiries for birthdays, weddings, conferences, and technical fests.</p>
            </div>
        <%
        }
        %>
    <% } else { %>
        <!-- TAB 2: MY SUBMITTED PROPOSALS -->
        <%
        boolean hasSent = false;
        while (myPropRs.next()) {
            hasSent = true;
            int propId = myPropRs.getInt("proposal_id");
            String pTitle = myPropRs.getString("proposal_title");
            String reqTitle = myPropRs.getString("event_title");
            String typeName = myPropRs.getString("event_type_name");
            String custName = myPropRs.getString("customer_name");
            Date eDate = myPropRs.getDate("event_date");
            double totalAmt = myPropRs.getDouble("total_amount");
            double advAmt = myPropRs.getDouble("advance_amount");
            Date validUntil = myPropRs.getDate("valid_until");
            String pStatus = myPropRs.getString("status");
            Timestamp pCreatedAt = myPropRs.getTimestamp("created_at");

            String statusClass = "status-pending";
            String statusLabel = "🟡 Under Review";
            if ("Accepted".equalsIgnoreCase(pStatus)) {
                statusClass = "status-accepted";
                statusLabel = "🎉 Accepted & Booked";
            } else if ("Rejected".equalsIgnoreCase(pStatus)) {
                statusClass = "status-rejected";
                statusLabel = "❌ Declined";
            }
        %>
            <div class="request-card">
                <div class="card-top">
                    <div>
                        <div class="request-title"><%= SecurityUtil.escapeHtml(pTitle) %></div>
                        <div class="tags-row">
                            <span class="category-pill"><%= SecurityUtil.escapeHtml(typeName) %></span>
                            <span class="customer-pill">Client: <%= SecurityUtil.escapeHtml(custName) %></span>
                            <span style="color:#94a3b8; font-size:13px;">For Event: <strong><%= SecurityUtil.escapeHtml(reqTitle) %></strong></span>
                        </div>
                    </div>
                    <div>
                        <span class="status-badge <%= statusClass %>"><%= statusLabel %></span>
                    </div>
                </div>

                <div class="details-grid">
                    <div class="grid-item">
                        Target Event Date
                        <strong>📅 <%= eDate != null ? eDate.toString() : "TBA" %></strong>
                    </div>
                    <div class="grid-item">
                        Quotation Total
                        <strong style="color:#4ade80;">₹<%= String.format("%.2f", totalAmt) %></strong>
                    </div>
                    <div class="grid-item">
                        Advance Deposit
                        <strong style="color:#38bdf8;">₹<%= String.format("%.2f", advAmt) %></strong>
                    </div>
                    <div class="grid-item">
                        Valid Until
                        <strong>⏳ <%= validUntil != null ? validUntil.toString() : "No Expiry" %></strong>
                    </div>
                </div>

                <div class="actions-bar">
                    <div class="created-time">
                        Submitted on: <%= pCreatedAt != null ? pCreatedAt.toString().substring(0, 16) : "N/A" %>
                    </div>
                    <div>
                        <span style="color:#94a3b8; font-size:13px;">Quotation #PROP-<%= propId %></span>
                    </div>
                </div>
            </div>
        <%
        }
        if (!hasSent) {
        %>
            <div class="empty-box">
                <h3>No Proposals Submitted Yet</h3>
                <p>Browse open opportunities in the first tab and start submitting customized quotes to prospective clients.</p>
                <a href="incomingRequests.jsp?tab=open" style="display:inline-block; margin-top:15px; color:#ffd369; text-decoration:none; font-weight:600;">
                    ← View Open Opportunities
                </a>
            </div>
        <%
        }
        %>
    <% } %>

</div>

</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:#f87171;padding:30px;'>Error Loading Requests</h2>");
    out.println("<p style='padding:0 30px;color:#cbd5e1;'>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
} finally {
    DBConnection.close(openRs, myPropRs, openPs, myPropPs, conn);
}
%>
