<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   ADMIN LOGIN & ROLE GUARD
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) session.getAttribute("role");
if (role == null || !"Admin".equalsIgnoreCase(role)) {
    response.sendRedirect("login.jsp");
    return;
}

String adminName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Administrator";

Connection conn = null;
Statement st = null;
ResultSet rs = null;

int totalUsers = 0;
int totalOrganizers = 0;
int verifiedOrganizers = 0;
int pendingVerifications = 0;
int totalEvents = 0;
int upcomingEvents = 0;
int totalRegistrations = 0;
double totalRevenue = 0.0;
int totalCustomRequests = 0;
int totalCustomBookings = 0;

try {
    conn = DBConnection.getConnection();
    st = conn.createStatement();

    // 1. Users count
    rs = st.executeQuery("SELECT COUNT(*) FROM users WHERE role = 'User'");
    if (rs.next()) totalUsers = rs.getInt(1);
    rs.close();

    // 2. Organizers count
    rs = st.executeQuery("SELECT COUNT(*) FROM users WHERE role = 'Organizer'");
    if (rs.next()) totalOrganizers = rs.getInt(1);
    rs.close();

    // 3. Organizer Verification stats
    rs = st.executeQuery("SELECT " +
        "SUM(CASE WHEN verification_status = 'Verified' THEN 1 ELSE 0 END), " +
        "SUM(CASE WHEN verification_status = 'Pending' THEN 1 ELSE 0 END) " +
        "FROM organizer_profiles");
    if (rs.next()) {
        verifiedOrganizers = rs.getInt(1);
        pendingVerifications = rs.getInt(2);
    }
    rs.close();

    // 4. Events count
    rs = st.executeQuery("SELECT COUNT(*), SUM(CASE WHEN event_date >= CURDATE() THEN 1 ELSE 0 END) FROM events");
    if (rs.next()) {
        totalEvents = rs.getInt(1);
        upcomingEvents = rs.getInt(2);
    }
    rs.close();

    // 5. Registrations count
    rs = st.executeQuery("SELECT COUNT(*) FROM registrations");
    if (rs.next()) totalRegistrations = rs.getInt(1);
    rs.close();

    // 6. Platform Revenue
    rs = st.executeQuery("SELECT SUM(amount) FROM payments WHERE payment_status = 'Approved'");
    if (rs.next()) totalRevenue = rs.getDouble(1);
    rs.close();

    // 7. Custom Requests & Bookings
    rs = st.executeQuery("SELECT COUNT(*) FROM event_requests");
    if (rs.next()) totalCustomRequests = rs.getInt(1);
    rs.close();

    rs = st.executeQuery("SELECT COUNT(*) FROM custom_event_bookings");
    if (rs.next()) totalCustomBookings = rs.getInt(1);
    rs.close();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Administrator Control Panel | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="css/notifications.css">
    <link rel="stylesheet" href="css/toast.css">
    <style>
        * { margin:0; padding:0; box-sizing:border-box; font-family:'Poppins', sans-serif; }
        body { background:#070d18; color:white; min-height:100vh; }

        /* Navbar */
        .navbar {
            height:75px;
            display:flex;
            justify-content:space-between;
            align-items:center;
            padding:0 50px;
            background:#0f172a;
            border-bottom:1px solid #1e293b;
        }
        .logo {
            font-size:24px;
            font-weight:700;
            background:linear-gradient(90deg, #ff4fa3, #ffd369);
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
            display:flex;
            align-items:center;
            gap:10px;
        }
        .logo-tag {
            font-size:11px;
            background:#311b92;
            color:#b388ff;
            border:1px solid #7c4dff;
            padding:2px 8px;
            border-radius:12px;
            letter-spacing:1px;
        }

        .nav-links { display:flex; gap:25px; align-items:center; }
        .nav-links a { color:#cbd5e8; text-decoration:none; font-size:14px; font-weight:500; transition:0.3s; }
        .nav-links a:hover { color:#ffd369; }
        .nav-links a.active { color:#ffd369; font-weight:700; }

        .container { width:92%; max-width:1300px; margin:40px auto 80px; }

        .page-header {
            display:flex;
            justify-content:space-between;
            align-items:center;
            flex-wrap:wrap;
            gap:20px;
            margin-bottom:30px;
        }
        .page-title { font-size:32px; font-weight:800; color:#fff; }
        .page-subtitle { color:#94a3b8; font-size:15px; margin-top:4px; }

        /* Stats Grid */
        .stats-grid {
            display:grid;
            grid-template-columns:repeat(auto-fit, minmax(220px, 1fr));
            gap:18px;
            margin-bottom:35px;
        }
        .stat-card {
            background:#0f172a;
            border:1px solid #1e293b;
            border-radius:18px;
            padding:22px 24px;
            box-shadow:0 10px 25px rgba(0,0,0,0.3);
            transition:0.25s;
        }
        .stat-card:hover { transform:translateY(-3px); border-color:#38bdf8; }
        .stat-icon { font-size:28px; margin-bottom:10px; }
        .stat-label { color:#94a3b8; font-size:13px; font-weight:500; }
        .stat-value { font-size:28px; font-weight:800; color:#fff; margin-top:4px; }
        .stat-sub { color:#64748b; font-size:12px; margin-top:4px; }

        .stat-highlight {
            border-color:#ca8a04;
            background:linear-gradient(135deg, rgba(234,179,8,0.1), #0f172a);
        }

        /* Section Boxes */
        .section-box {
            background:#0f172a;
            border:1px solid #1e293b;
            border-radius:20px;
            padding:30px;
            margin-bottom:35px;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
        }
        .section-title {
            font-size:20px;
            font-weight:700;
            color:#fff;
            margin-bottom:20px;
            display:flex;
            justify-content:space-between;
            align-items:center;
            flex-wrap:wrap;
            gap:10px;
        }

        table {
            width:100%;
            border-collapse:collapse;
        }
        th {
            background:#1e293b;
            color:#cbd5e1;
            padding:14px 18px;
            text-align:left;
            font-size:12px;
            font-weight:600;
            text-transform:uppercase;
            letter-spacing:0.5px;
        }
        td {
            padding:14px 18px;
            border-top:1px solid #1e293b;
            font-size:13px;
            color:#e2e8f0;
            vertical-align:middle;
        }
        tr:hover td { background:#141f33; }

        .btn-action {
            padding:7px 16px;
            border-radius:8px;
            text-decoration:none;
            font-size:12px;
            font-weight:600;
            display:inline-block;
            transition:0.2s;
        }
        .btn-review {
            background:linear-gradient(135deg, #eab308, #ca8a04);
            color:#000;
        }
        .btn-review:hover { opacity:0.9; }

        .badge-pending {
            background:rgba(234,179,8,0.15);
            color:#facc15;
            border:1px solid #ca8a04;
            padding:4px 10px;
            border-radius:12px;
            font-size:11px;
            font-weight:600;
        }

        @media(max-width:768px){
            .navbar { padding:0 20px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:12px; }
            .page-header { flex-direction:column; align-items:flex-start; }
        }
    </style>
</head>
<body>

<div class="navbar">
    <div class="logo">
        EventSphere
        <span class="logo-tag">ADMIN</span>
    </div>
    <div class="nav-links">
        <a href="adminDashboard.jsp" class="active">Overview</a>
        <a href="adminVerifications.jsp">
            Verifications
            <% if (pendingVerifications > 0) { %>
                <span style="background:#eab308; color:#000; padding:2px 6px; border-radius:10px; font-size:11px; font-weight:700;"><%= pendingVerifications %></span>
            <% } %>
        </a>
        <a href="adminUsers.jsp">Manage Users</a>
        <a href="adminEvents.jsp">Manage Events</a>
        <jsp:include page="navbarNotification.jsp" />
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <div class="page-header">
        <div>
            <h1 class="page-title">Platform Administration</h1>
            <p class="page-subtitle">Welcome back, <%= SecurityUtil.escapeHtml(adminName) %>. Comprehensive oversight of platform trust, users, and transactions.</p>
        </div>
    </div>

    <!-- STATS GRID -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon">👥</div>
            <div class="stat-label">Total Customers</div>
            <div class="stat-value"><%= totalUsers %></div>
            <div class="stat-sub">Active platform users</div>
        </div>

        <div class="stat-card">
            <div class="stat-icon">🎪</div>
            <div class="stat-label">Event Organizers</div>
            <div class="stat-value"><%= totalOrganizers %></div>
            <div class="stat-sub"><%= verifiedOrganizers %> Verified Organizers</div>
        </div>

        <div class="stat-card <%= pendingVerifications > 0 ? "stat-highlight" : "" %>">
            <div class="stat-icon">🛡️</div>
            <div class="stat-label">Pending Verifications</div>
            <div class="stat-value" style="<%= pendingVerifications > 0 ? "color:#facc15;" : "" %>"><%= pendingVerifications %></div>
            <div class="stat-sub"><%= pendingVerifications > 0 ? "⚠️ Review required" : "All queue cleared" %></div>
        </div>

        <div class="stat-card">
            <div class="stat-icon">📅</div>
            <div class="stat-label">Total Events Published</div>
            <div class="stat-value"><%= totalEvents %></div>
            <div class="stat-sub"><%= upcomingEvents %> Upcoming Live</div>
        </div>

        <div class="stat-card">
            <div class="stat-icon">🎟️</div>
            <div class="stat-label">Bookings & Registrations</div>
            <div class="stat-value"><%= totalRegistrations %></div>
            <div class="stat-sub"><%= totalCustomBookings %> Custom Event Bookings</div>
        </div>

        <div class="stat-card">
            <div class="stat-icon">💰</div>
            <div class="stat-label">Total Revenue Processed</div>
            <div class="stat-value" style="color:#4ade80;">₹<%= String.format("%.2f", totalRevenue) %></div>
            <div class="stat-sub">Verified payment transactions</div>
        </div>
    </div>

    <!-- PENDING VERIFICATIONS QUEUE -->
    <div class="section-box">
        <div class="section-title">
            <span>🛡️ Organizer Verification Queue (<%= pendingVerifications %> Awaiting Review)</span>
            <a href="adminVerifications.jsp" style="font-size:13px; color:#38bdf8; text-decoration:none;">View Full Queue →</a>
        </div>

        <div style="overflow-x:auto;">
            <table>
                <thead>
                    <tr>
                        <th>Organizer / Business</th>
                        <th>Email & Phone</th>
                        <th>Experience</th>
                        <th>Status</th>
                        <th>Document Proof</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                <%
                PreparedStatement vPs = conn.prepareStatement(
                    "SELECT u.full_name, u.email, op.organizer_id, op.business_name, op.contact_phone, " +
                    "op.experience_years, op.verification_status, op.id_document, op.updated_at " +
                    "FROM organizer_profiles op " +
                    "JOIN users u ON op.organizer_id = u.id " +
                    "WHERE op.verification_status = 'Pending' " +
                    "ORDER BY op.updated_at ASC LIMIT 5");
                ResultSet vRs = vPs.executeQuery();
                boolean hasQueue = false;

                while (vRs.next()) {
                    hasQueue = true;
                    int orgId = vRs.getInt("organizer_id");
                    String bName = vRs.getString("business_name");
                    String oName = vRs.getString("full_name");
                    String oEmail = vRs.getString("email");
                    String oPhone = vRs.getString("contact_phone");
                    int exp = vRs.getInt("experience_years");
                    String idDoc = vRs.getString("id_document");
                %>
                    <tr>
                        <td>
                            <strong><%= SecurityUtil.escapeHtml(bName != null && !bName.isEmpty() ? bName : oName) %></strong>
                            <small style="display:block; color:#94a3b8;"><%= SecurityUtil.escapeHtml(oName) %></small>
                        </td>
                        <td>
                            <div><%= SecurityUtil.escapeHtml(oEmail) %></div>
                            <small style="color:#94a3b8;"><%= SecurityUtil.escapeHtml(oPhone != null ? oPhone : "N/A") %></small>
                        </td>
                        <td><%= exp %> Years</td>
                        <td><span class="badge-pending">⏳ Pending Review</span></td>
                        <td>
                            <% if (idDoc != null && !idDoc.isEmpty()) { %>
                                <a href="images/<%= SecurityUtil.escapeHtml(idDoc) %>" target="_blank" style="color:#38bdf8; text-decoration:none;">📄 View Proof</a>
                            <% } else { %>
                                <span style="color:#64748b;">No Doc</span>
                            <% } %>
                        </td>
                        <td>
                            <a href="adminVerifications.jsp" class="btn-action btn-review">Review & Verify</a>
                        </td>
                    </tr>
                <%
                }
                vRs.close();
                vPs.close();

                if (!hasQueue) {
                %>
                    <tr>
                        <td colspan="6" style="text-align:center; padding:35px; color:#94a3b8;">
                            🎉 Great job! No pending organizer verification documents awaiting review.
                        </td>
                    </tr>
                <%
                }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- RECENT TRANSACTIONS TABLE -->
    <div class="section-box">
        <div class="section-title">
            <span>💳 Recent Payment Transactions</span>
        </div>

        <div style="overflow-x:auto;">
            <table>
                <thead>
                    <tr>
                        <th>Txn Ref</th>
                        <th>Attendee Name</th>
                        <th>Event</th>
                        <th>Amount</th>
                        <th>Method</th>
                        <th>Status</th>
                        <th>Date</th>
                    </tr>
                </thead>
                <tbody>
                <%
                PreparedStatement pPs = conn.prepareStatement(
                    "SELECT p.*, r.full_name, e.event_name " +
                    "FROM payments p " +
                    "JOIN registrations r ON p.registration_id = r.registration_id " +
                    "JOIN events e ON r.event_id = e.event_id " +
                    "ORDER BY p.payment_date DESC LIMIT 6");
                ResultSet pRs = pPs.executeQuery();
                boolean hasTxns = false;

                while (pRs.next()) {
                    hasTxns = true;
                    String txnId = pRs.getString("transaction_id");
                    String aName = pRs.getString("full_name");
                    String eName = pRs.getString("event_name");
                    double amt = pRs.getDouble("amount");
                    String method = pRs.getString("payment_method");
                    String pStatus = pRs.getString("payment_status");
                    Timestamp pDate = pRs.getTimestamp("payment_date");
                %>
                    <tr>
                        <td style="font-family:monospace; color:#38bdf8;"><%= SecurityUtil.escapeHtml(txnId != null ? txnId : "-") %></td>
                        <td><strong><%= SecurityUtil.escapeHtml(aName) %></strong></td>
                        <td><%= SecurityUtil.escapeHtml(eName) %></td>
                        <td style="color:#4ade80; font-weight:700;">₹<%= String.format("%.2f", amt) %></td>
                        <td><%= SecurityUtil.escapeHtml(method) %></td>
                        <td>
                            <span style="font-size:11px; font-weight:700; padding:3px 10px; border-radius:10px; background:<%= "Approved".equalsIgnoreCase(pStatus) ? "#14532d; color:#4ade80;" : "#713f12; color:#fde047;" %>">
                                <%= SecurityUtil.escapeHtml(pStatus) %>
                            </span>
                        </td>
                        <td><%= pDate != null ? pDate.toString().substring(0, 16) : "N/A" %></td>
                    </tr>
                <%
                }
                pRs.close();
                pPs.close();

                if (!hasTxns) {
                %>
                    <tr>
                        <td colspan="7" style="text-align:center; padding:35px; color:#94a3b8;">
                            No payment transactions recorded yet.
                        </td>
                    </tr>
                <%
                }
                %>
                </tbody>
            </table>
        </div>
    </div>

</div>

<script src="js/toast.js"></script>
<script src="js/notifications.js"></script>
</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:#f87171;padding:30px;'>Error</h2>");
    out.println("<p style='padding:0 30px;color:#cbd5e1;'>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
} finally {
    DBConnection.close(rs, st, conn);
}
%>
