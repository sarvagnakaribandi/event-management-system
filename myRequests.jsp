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
String userName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Customer";
String msg = request.getParameter("msg");

Connection conn = null;
PreparedStatement reqPs = null;
PreparedStatement bookPs = null;
ResultSet reqRs = null;
ResultSet bookRs = null;

try {
    conn = DBConnection.getConnection();

    // Query all custom requests for this user
    String reqSql =
        "SELECT r.*, t.event_type_name, " +
        "(SELECT COUNT(*) FROM proposals p WHERE p.request_id = r.request_id) AS proposal_count " +
        "FROM event_requests r " +
        "JOIN event_types t ON r.event_type_id = t.event_type_id " +
        "WHERE r.user_id = ? " +
        "ORDER BY r.created_at DESC";

    reqPs = conn.prepareStatement(reqSql);
    reqPs.setInt(1, userId);
    reqRs = reqPs.executeQuery();

    // Query confirmed custom event bookings
    String bookSql =
        "SELECT b.*, r.event_title, r.event_date, r.location, u.full_name AS organizer_name, u.email AS organizer_email, p.proposal_title " +
        "FROM custom_event_bookings b " +
        "JOIN event_requests r ON b.request_id = r.request_id " +
        "JOIN proposals p ON b.proposal_id = p.proposal_id " +
        "JOIN users u ON b.organizer_id = u.id " +
        "WHERE b.user_id = ? " +
        "ORDER BY b.booking_date DESC";

    bookPs = conn.prepareStatement(bookSql);
    bookPs.setInt(1, userId);
    bookRs = bookPs.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Custom Event Requests | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="css/notifications.css">
    <link rel="stylesheet" href="css/toast.css">
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

        .page-header {
            display:flex;
            justify-content:space-between;
            align-items:center;
            flex-wrap:wrap;
            gap:20px;
            margin-bottom:30px;
        }
        .page-title { font-size:32px; font-weight:700; color:#fff; }
        .page-subtitle { color:#94a3b8; font-size:15px; margin-top:4px; }

        .btn-new-request {
            padding:12px 24px;
            background:linear-gradient(135deg, #ec4899, #8b5cf6);
            color:white;
            text-decoration:none;
            border-radius:12px;
            font-weight:600;
            font-size:14px;
            transition:0.3s;
            display:inline-flex;
            align-items:center;
            gap:8px;
            box-shadow:0 8px 20px rgba(236,72,153,0.3);
        }
        .btn-new-request:hover { transform:translateY(-2px); box-shadow:0 12px 25px rgba(236,72,153,0.45); }

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

        /* Section Titles */
        .section-heading {
            font-size:22px;
            font-weight:700;
            margin:40px 0 20px;
            color:#ffd369;
            display:flex;
            align-items:center;
            gap:10px;
        }

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
        
        /* Status Badges */
        .status-badge { padding:5px 14px; border-radius:20px; font-size:12px; font-weight:600; }
        .status-pending { background:rgba(234, 179, 8, 0.15); color:#facc15; border:1px solid rgba(234, 179, 8, 0.4); }
        .status-proposals { background:rgba(168, 85, 247, 0.2); color:#d8b4fe; border:1px solid #a855f7; }
        .status-accepted { background:rgba(34, 197, 94, 0.15); color:#4ade80; border:1px solid #22c55e; }
        .status-rejected { background:rgba(239, 68, 68, 0.15); color:#f87171; border:1px solid #ef4444; }
        .status-cancelled { background:#1e293b; color:#94a3b8; border:1px solid #475569; }

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

        .btn-proposals {
            padding:10px 22px;
            background:linear-gradient(135deg, #7c3aed, #a855f7);
            color:white;
            text-decoration:none;
            border-radius:10px;
            font-weight:600;
            font-size:13px;
            transition:0.25s;
            display:inline-flex;
            align-items:center;
            gap:6px;
        }
        .btn-proposals:hover { opacity:0.9; transform:translateY(-2px); box-shadow:0 6px 16px rgba(124, 58, 237, 0.4); }

        .btn-cancel-req {
            padding:10px 18px;
            background:transparent;
            color:#f87171;
            border:1px solid #dc2626;
            border-radius:10px;
            font-weight:600;
            font-size:13px;
            text-decoration:none;
            transition:0.2s;
            cursor:pointer;
        }
        .btn-cancel-req:hover { background:rgba(239, 68, 68, 0.15); }

        /* Booking Cards */
        .booking-card {
            background:linear-gradient(135deg, #10233d, #141f36);
            border:1px solid #0284c7;
            border-radius:20px;
            padding:26px;
            margin-bottom:20px;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
        }

        .empty-box {
            text-align:center;
            padding:60px 20px;
            background:#111a2d;
            border:1px dashed #2d3e58;
            border-radius:20px;
        }
        .empty-box h3 { color:#ffd369; margin-bottom:10px; }
        .empty-box p { color:#94a3b8; font-size:14px; margin-bottom:20px; }

        @media(max-width:768px){
            .navbar { padding:0 20px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:12px; }
            .page-header { flex-direction:column; align-items:flex-start; }
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
        <a href="index.jsp">Explore Portal</a>
        <a href="userDashboard.jsp">Dashboard</a>
        <a href="myRequests.jsp" class="active">My Custom Requests</a>
        <a href="myRegistrations.jsp">My Registrations</a>
        <jsp:include page="navbarNotification.jsp" />
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <div class="page-header">
        <div>
            <h1 class="page-title">Custom Event Requests</h1>
            <p class="page-subtitle">Track custom event quotations, negotiate proposals with verified organizers, and manage bookings.</p>
        </div>
        <a href="requestEvent.jsp" class="btn-new-request">🎪 + Request a New Event</a>
    </div>

    <!-- Feedback messages -->
    <% if ("created".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-success">
            <span>✅ Custom event request submitted successfully! Verified organizers will review your specifications and submit quotations.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } else if ("cancelled".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-info">
            <span>ℹ️ Your custom event request has been cancelled.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } else if ("accepted".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-success">
            <span>🎉 Proposal accepted successfully! Your custom event booking is confirmed with the organizer. Check details under Confirmed Bookings below.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } %>

    <!-- SECTION: CONFIRMED BOOKINGS (IF ANY) -->
    <%
    boolean hasBookings = false;
    while (bookRs.next()) {
        if (!hasBookings) {
            hasBookings = true;
    %>
        <h2 class="section-heading">🎉 Confirmed Custom Event Bookings</h2>
    <%
        }
        int bId = bookRs.getInt("booking_id");
        String bTitle = bookRs.getString("event_title");
        Date bDate = bookRs.getDate("event_date");
        String bLocation = bookRs.getString("location");
        String bOrgName = bookRs.getString("organizer_name");
        String bOrgEmail = bookRs.getString("organizer_email");
        String bPropTitle = bookRs.getString("proposal_title");
        double bTotal = bookRs.getDouble("total_amount");
        double bAdvance = bookRs.getDouble("advance_amount");
        double bRemaining = bookRs.getDouble("remaining_amount");
        String bStatus = bookRs.getString("booking_status");
        Timestamp bTime = bookRs.getTimestamp("booking_date");
    %>
        <div class="booking-card">
            <div class="card-top">
                <div>
                    <div class="request-title"><%= SecurityUtil.escapeHtml(bTitle) %></div>
                    <div class="tags-row">
                        <span class="category-pill" style="border-color:#38bdf8; color:#38bdf8; background:#0c2a47;">Booking #BK-<%= bId %></span>
                        <span style="color:#94a3b8; font-size:13px;">Proposal: <strong><%= SecurityUtil.escapeHtml(bPropTitle) %></strong></span>
                    </div>
                </div>
                <div>
                    <span class="status-badge status-accepted">✅ <%= bStatus %></span>
                </div>
            </div>

            <div class="details-grid">
                <div class="grid-item">
                    Event Date
                    <strong>📅 <%= bDate != null ? bDate.toString() : "TBA" %></strong>
                </div>
                <div class="grid-item">
                    Location
                    <strong>📍 <%= SecurityUtil.escapeHtml(bLocation) %></strong>
                </div>
                <div class="grid-item">
                    Organizer
                    <strong>👤 <%= SecurityUtil.escapeHtml(bOrgName) %></strong>
                    <small style="color:#94a3b8;"><%= SecurityUtil.escapeHtml(bOrgEmail) %></small>
                </div>
                <div class="grid-item">
                    Agreed Quotation
                    <strong style="color:#4ade80;">₹<%= String.format("%.2f", bTotal) %></strong>
                </div>
                <div class="grid-item">
                    Advance Paid
                    <strong style="color:#38bdf8;">₹<%= String.format("%.2f", bAdvance) %></strong>
                </div>
                <div class="grid-item">
                    Remaining Balance
                    <strong style="color:#facc15;">₹<%= String.format("%.2f", bRemaining) %></strong>
                </div>
            </div>

            <div style="font-size:12px; color:#64748b;">
                Booked on: <%= bTime != null ? bTime.toString().substring(0, 16) : "N/A" %>
            </div>
        </div>
    <%
    }
    %>

    <!-- SECTION: ACTIVE REQUESTS -->
    <h2 class="section-heading">📋 My Submitted Event Requests</h2>

    <%
    boolean hasRequests = false;
    while (reqRs.next()) {
        hasRequests = true;
        int reqId = reqRs.getInt("request_id");
        String title = reqRs.getString("event_title");
        String typeName = reqRs.getString("event_type_name");
        Date date = reqRs.getDate("event_date");
        Time time = reqRs.getTime("event_time");
        String loc = reqRs.getString("location");
        int guests = reqRs.getInt("guest_count");
        double budget = reqRs.getDouble("budget");
        String reqs = reqRs.getString("requirements");
        String notes = reqRs.getString("additional_notes");
        String status = reqRs.getString("status");
        int propCount = reqRs.getInt("proposal_count");
        Timestamp createdAt = reqRs.getTimestamp("created_at");

        String statusClass = "status-pending";
        String statusLabel = "🟡 Pending Organizer Review";

        if ("Proposal Received".equalsIgnoreCase(status) || propCount > 0 && "Pending".equalsIgnoreCase(status)) {
            statusClass = "status-proposals";
            statusLabel = "📬 Proposals Received (" + propCount + ")";
        } else if ("Accepted".equalsIgnoreCase(status)) {
            statusClass = "status-accepted";
            statusLabel = "🎉 Proposal Accepted";
        } else if ("Rejected".equalsIgnoreCase(status)) {
            statusClass = "status-rejected";
            statusLabel = "❌ Rejected";
        } else if ("Cancelled".equalsIgnoreCase(status)) {
            statusClass = "status-cancelled";
            statusLabel = "⚪ Cancelled";
        }
    %>
        <div class="request-card">
            <div class="card-top">
                <div>
                    <div class="request-title"><%= SecurityUtil.escapeHtml(title) %></div>
                    <div class="tags-row">
                        <span class="category-pill"><%= SecurityUtil.escapeHtml(typeName) %></span>
                        <span style="color:#94a3b8; font-size:13px;">Request #REQ-<%= reqId %></span>
                    </div>
                </div>
                <div>
                    <span class="status-badge <%= statusClass %>"><%= statusLabel %></span>
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
                    Preferred Location
                    <strong>📍 <%= SecurityUtil.escapeHtml(loc) %></strong>
                </div>
                <div class="grid-item">
                    Expected Guests
                    <strong>👥 <%= guests %> Persons</strong>
                </div>
                <div class="grid-item">
                    Estimated Budget
                    <strong style="color:#4ade80;"><%= budget > 0 ? ("₹" + String.format("%.2f", budget)) : "Flexible" %></strong>
                </div>
            </div>

            <% if (reqs != null && !reqs.trim().isEmpty()) { %>
                <div class="text-box">
                    <strong>Specific Requirements & Services:</strong>
                    <%= SecurityUtil.escapeHtml(reqs) %>
                </div>
            <% } %>

            <% if (notes != null && !notes.trim().isEmpty()) { %>
                <div class="text-box" style="border-left-color:#38bdf8;">
                    <strong>Additional Notes:</strong>
                    <%= SecurityUtil.escapeHtml(notes) %>
                </div>
            <% } %>

            <div class="actions-bar">
                <div class="created-time">
                    Submitted on: <%= createdAt != null ? createdAt.toString().substring(0, 16) : "N/A" %>
                </div>

                <div style="display:flex; gap:12px; align-items:center;">
                    <% if (propCount > 0) { %>
                        <a href="viewProposals.jsp?request_id=<%= reqId %>" class="btn-proposals">
                            📬 View <%= propCount %> Proposal<%= propCount > 1 ? "s" : "" %>
                        </a>
                    <% } else if ("Pending".equalsIgnoreCase(status)) { %>
                        <span style="color:#facc15; font-size:13px;">⏳ Waiting for organizer quotations</span>
                    <% } %>

                    <% if ("Pending".equalsIgnoreCase(status) || "Proposal Received".equalsIgnoreCase(status)) { %>
                        <a href="cancelEventRequest.jsp?request_id=<%= reqId %>" 
                           class="btn-cancel-req"
                           onclick="return confirm('Are you sure you want to cancel this event request?');">
                            ✕ Cancel Request
                        </a>
                    <% } %>
                </div>
            </div>
        </div>
    <%
    }
    if (!hasRequests) {
    %>
        <div class="empty-box">
            <h3>No Custom Event Requests Yet</h3>
            <p>Looking to host a birthday party, wedding, hackathon, or cultural fest? Submit a custom event request and verified organizers will provide tailor-made proposals.</p>
            <a href="requestEvent.jsp" class="btn-new-request">🎪 Request an Event Now</a>
        </div>
    <%
    }
    %>
</div>

<script src="js/toast.js"></script>
<script src="js/notifications.js"></script>
</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:#f87171;padding:30px;'>Error Loading Requests</h2>");
    out.println("<p style='padding:0 30px;color:#cbd5e1;'>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
} finally {
    DBConnection.close(reqRs, bookRs, reqPs, bookPs, conn);
}
%>
