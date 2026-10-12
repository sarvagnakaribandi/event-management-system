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

/* =====================================================
   EVENT ID PARAMETER
   ===================================================== */
String eventIdParam = request.getParameter("id");
if (eventIdParam == null || eventIdParam.trim().isEmpty()) {
    response.sendRedirect("manageEvents.jsp");
    return;
}

int eventId;
try {
    eventId = Integer.parseInt(eventIdParam.trim());
} catch (Exception e) {
    response.sendRedirect("manageEvents.jsp");
    return;
}

String msg = request.getParameter("msg");

Connection conn = null;
PreparedStatement eventPs = null;
PreparedStatement participantPs = null;
ResultSet eventRs = null;
ResultSet participantRs = null;

try {
    conn = DBConnection.getConnection();

    /* =================================================
       CHECK EVENT OWNERSHIP & DETAILS
       ================================================= */
    String eventSql =
        "SELECT event_name, event_date, event_time, venue, category, payment_type, event_fee, max_capacity, available_seats " +
        "FROM events " +
        "WHERE event_id=? AND organizer_id=?";

    eventPs = conn.prepareStatement(eventSql);
    eventPs.setInt(1, eventId);
    eventPs.setInt(2, organizerId);
    eventRs = eventPs.executeQuery();

    if (!eventRs.next()) {
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Access Denied | EventSphere</title>
    <style>
        body { margin:0; min-height:100vh; display:flex; justify-content:center; align-items:center; background:#0b1220; color:white; font-family:'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .box { width:90%; max-width:480px; padding:40px; text-align:center; background:#18243a; border:1px solid #34425c; border-radius:18px; }
        h1 { color:#ffbd3d; margin-bottom:15px; font-size:24px; }
        p { color:#cbd5e1; line-height:1.6; margin-bottom:20px; }
        a { display:inline-block; padding:12px 24px; background:#7138ff; color:white; text-decoration:none; border-radius:10px; font-weight:600; }
    </style>
</head>
<body>
<div class="box">
    <h1>🔒 Access Denied</h1>
    <p>This event belongs to another organizer or does not exist.</p>
    <a href="manageEvents.jsp">← Back to My Events</a>
</div>
</body>
</html>
<%
        return;
    }

    String eventName = eventRs.getString("event_name");
    Date eventDate = eventRs.getDate("event_date");
    Time eventTime = eventRs.getTime("event_time");
    String venue = eventRs.getString("venue");
    String category = eventRs.getString("category");
    String paymentType = eventRs.getString("payment_type");
    double eventFee = eventRs.getDouble("event_fee");
    int maxCapacity = eventRs.getInt("max_capacity");
    int availableSeats = eventRs.getInt("available_seats");

    /* =================================================
       GET PARTICIPANTS FOR EVENT
       ================================================= */
    String participantSql =
        "SELECT " +
        "registration_id, full_name, email, phone, gender, " +
        "team_name, team_members, registration_date, " +
        "payment_status, payment_screenshot, payment_method, transaction_id " +
        "FROM registrations " +
        "WHERE event_id=? " +
        "ORDER BY registration_id DESC";

    participantPs = conn.prepareStatement(participantSql);
    participantPs.setInt(1, eventId);
    participantRs = participantPs.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Participants - <%= SecurityUtil.escapeHtml(eventName) %> | EventSphere</title>
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

        /* Container */
        .container { width:94%; max-width:1380px; margin:35px auto 70px; }

        .back-link {
            display:inline-flex;
            align-items:center;
            gap:6px;
            color:#00eaff;
            text-decoration:none;
            font-size:14px;
            margin-bottom:20px;
            font-weight:500;
            transition:0.2s;
        }
        .back-link:hover { color:#67e8f9; transform:translateX(-3px); }

        .header-section {
            display:flex;
            justify-content:space-between;
            align-items:flex-start;
            flex-wrap:wrap;
            gap:20px;
            margin-bottom:25px;
        }
        .page-title { font-size:30px; font-weight:700; color:#fff; }
        .event-meta { color:#94a3b8; font-size:14px; margin-top:4px; display:flex; gap:16px; flex-wrap:wrap; }
        .event-meta span { display:inline-flex; align-items:center; gap:5px; }

        /* Stat Cards */
        .stats-grid {
            display:grid;
            grid-template-columns:repeat(auto-fit, minmax(200px, 1fr));
            gap:16px;
            margin-bottom:30px;
        }
        .stat-card {
            background:#131d31;
            border:1px solid #26354d;
            border-radius:14px;
            padding:18px 22px;
        }
        .stat-label { color:#94a3b8; font-size:13px; font-weight:500; }
        .stat-value { font-size:24px; font-weight:700; color:#fff; margin-top:6px; }

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

        /* Table Box */
        .table-box {
            background:#131d31;
            border:1px solid #26354d;
            border-radius:18px;
            overflow-x:auto;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
        }
        table {
            width:100%;
            min-width:1150px;
            border-collapse:collapse;
        }
        th {
            background:#1b2842;
            color:#cbd5e1;
            padding:16px 18px;
            text-align:left;
            font-size:13px;
            font-weight:600;
            text-transform:uppercase;
            letter-spacing:0.5px;
            border-bottom:1px solid #283750;
        }
        td {
            padding:16px 18px;
            border-top:1px solid #1f2c44;
            font-size:13px;
            color:#e2e8f0;
            vertical-align:middle;
        }
        tr:hover td {
            background:#18253d;
        }

        .user-name { font-weight:600; color:#fff; font-size:14px; }
        .user-contact { color:#94a3b8; font-size:12px; margin-top:2px; }

        /* Status Badges */
        .badge {
            display:inline-block;
            padding:5px 12px;
            border-radius:20px;
            font-size:11px;
            font-weight:600;
            white-space:nowrap;
        }
        .badge-pending { background:rgba(234, 179, 8, 0.15); color:#facc15; border:1px solid rgba(234, 179, 8, 0.4); }
        .badge-approved { background:rgba(34, 197, 94, 0.15); color:#4ade80; border:1px solid rgba(34, 197, 94, 0.4); }
        .badge-rejected { background:rgba(239, 68, 68, 0.15); color:#f87171; border:1px solid rgba(239, 68, 68, 0.4); }
        .badge-free { background:rgba(6, 182, 212, 0.15); color:#22d3ee; border:1px solid rgba(6, 182, 212, 0.4); }

        .method-badge {
            background:#1e293b;
            color:#93c5fd;
            border:1px solid #334155;
            padding:3px 8px;
            border-radius:6px;
            font-size:11px;
            font-weight:500;
        }
        .txn-code {
            display:block;
            font-family:monospace;
            color:#94a3b8;
            font-size:11px;
            margin-top:4px;
        }

        /* Action Buttons */
        .actions-cell {
            display:flex;
            gap:8px;
            align-items:center;
            flex-wrap:wrap;
        }
        .btn-action {
            display:inline-block;
            padding:7px 14px;
            border-radius:8px;
            font-size:12px;
            font-weight:600;
            text-decoration:none;
            transition:0.2s;
            cursor:pointer;
        }
        .btn-proof {
            background:#1e293b;
            color:#38bdf8;
            border:1px solid #38bdf8;
        }
        .btn-proof:hover { background:rgba(56, 189, 248, 0.2); }

        .btn-approve {
            background:#16a34a;
            color:white;
            border:none;
        }
        .btn-approve:hover { background:#22c55e; }

        .btn-reject {
            background:#dc2626;
            color:white;
            border:none;
        }
        .btn-reject:hover { background:#ef4444; }

        .empty-row {
            text-align:center;
            padding:60px 20px;
            color:#94a3b8;
            font-size:15px;
        }

        @media(max-width:768px){
            .navbar { padding:0 20px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:10px; }
            .header-section { flex-direction:column; }
        }
    </style>
</head>
<body>

<!-- Navbar -->
<div class="navbar">
    <div class="logo">EventSphere</div>
    <div class="nav-links">
        <a href="organizerDashboard.jsp">Dashboard</a>
        <a href="manageEvents.jsp">Manage Events</a>
        <a href="createEvent.jsp">+ Create Event</a>
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <a href="manageEvents.jsp" class="back-link">← Back to My Events</a>

    <div class="header-section">
        <div>
            <h1 class="page-title">Participants & Bookings</h1>
            <div class="event-meta">
                <span>🎯 <%= SecurityUtil.escapeHtml(eventName) %></span>
                <span>📅 <%= eventDate != null ? eventDate.toString() : "TBA" %></span>
                <span>💰 <%= "Paid".equalsIgnoreCase(paymentType) ? ("₹" + String.format("%.2f", eventFee)) : "Free" %></span>
                <span>🪑 Capacity: <%= (maxCapacity - availableSeats) %> / <%= maxCapacity %> Booked (<%= availableSeats %> Left)</span>
            </div>
        </div>
    </div>

    <!-- Feedback messages -->
    <% if ("approved".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-success">
            <span>✅ Payment approved successfully. The participant's status has been updated to Confirmed.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } else if ("rejected".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-info">
            <span>ℹ️ Payment rejected. 1 seat has been returned to the available event capacity.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } %>

    <!-- Table -->
    <div class="table-box">
        <table>
            <thead>
                <tr>
                    <th>Participant</th>
                    <th>Gender</th>
                    <th>Team Info</th>
                    <th>Registered On</th>
                    <th>Payment Details</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <%
            boolean hasRows = false;
            while (participantRs.next()) {
                hasRows = true;
                int regId = participantRs.getInt("registration_id");
                String fullName = participantRs.getString("full_name");
                String email = participantRs.getString("email");
                String phone = participantRs.getString("phone");
                String gender = participantRs.getString("gender");
                String teamName = participantRs.getString("team_name");
                int teamMembers = participantRs.getInt("team_members");
                Timestamp regDate = participantRs.getTimestamp("registration_date");
                String payStatus = participantRs.getString("payment_status");
                String screenshot = participantRs.getString("payment_screenshot");
                String payMethod = participantRs.getString("payment_method");
                String txnId = participantRs.getString("transaction_id");

                String badgeClass = "badge-pending";
                String badgeText = "🟡 Pending";
                if ("Approved".equalsIgnoreCase(payStatus)) {
                    badgeClass = "badge-approved";
                    badgeText = "✅ Approved";
                } else if ("Rejected".equalsIgnoreCase(payStatus)) {
                    badgeClass = "badge-rejected";
                    badgeText = "❌ Rejected";
                } else if ("Not Required".equalsIgnoreCase(payStatus)) {
                    badgeClass = "badge-free";
                    badgeText = "🎉 Not Required";
                }
            %>
                <tr>
                    <td>
                        <div class="user-name"><%= SecurityUtil.escapeHtml(fullName) %></div>
                        <div class="user-contact"><%= SecurityUtil.escapeHtml(email) %> &bull; <%= SecurityUtil.escapeHtml(phone) %></div>
                    </td>
                    <td><%= SecurityUtil.escapeHtml(gender != null ? gender : "N/A") %></td>
                    <td>
                        <div><%= (teamName != null && !teamName.trim().isEmpty()) ? SecurityUtil.escapeHtml(teamName) : "Individual" %></div>
                        <small style="color:#94a3b8;"><%= teamMembers %> member<%= teamMembers > 1 ? "s" : "" %></small>
                    </td>
                    <td><%= regDate != null ? regDate.toString().substring(0, 16) : "N/A" %></td>
                    <td>
                        <span class="method-badge"><%= SecurityUtil.escapeHtml(payMethod != null ? payMethod : ("Paid".equalsIgnoreCase(paymentType) ? "UPI" : "Free")) %></span>
                        <% if (txnId != null && !txnId.trim().isEmpty()) { %>
                            <span class="txn-code">Ref: <%= SecurityUtil.escapeHtml(txnId) %></span>
                        <% } %>
                    </td>
                    <td>
                        <span class="badge <%= badgeClass %>"><%= badgeText %></span>
                    </td>
                    <td>
                        <div class="actions-cell">
                            <% if (screenshot != null && !screenshot.trim().isEmpty()) { %>
                                <a href="images/<%= SecurityUtil.escapeHtml(screenshot.trim()) %>" target="_blank" class="btn-action btn-proof" title="View payment proof screenshot">
                                    🧾 Proof
                                </a>
                            <% } %>

                            <% if ("Pending".equalsIgnoreCase(payStatus)) { %>
                                <a href="approvepayment.jsp?id=<%= regId %>&event_id=<%= eventId %>" 
                                   class="btn-action btn-approve"
                                   onclick="return confirm('Confirm approval for <%= SecurityUtil.escapeHtml(fullName) %>?');">
                                    ✓ Approve
                                </a>
                                <a href="rejectPayment.jsp?id=<%= regId %>&event_id=<%= eventId %>" 
                                   class="btn-action btn-reject"
                                   onclick="return confirm('Reject payment for <%= SecurityUtil.escapeHtml(fullName) %>?\nThis will release their reserved seat back to available capacity.');">
                                    ✕ Reject
                                </a>
                            <% } %>
                        </div>
                    </td>
                </tr>
            <%
            }
            if (!hasRows) {
            %>
                <tr>
                    <td colspan="7" class="empty-row">
                        No participants have registered for this event yet.
                    </td>
                </tr>
            <%
            }
            %>
            </tbody>
        </table>
    </div>
</div>

</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:#f87171;padding:30px;'>Error loading participants</h2>");
    out.println("<p style='padding:0 30px;color:#cbd5e1;'>" + SecurityUtil.escapeHtml(e.getMessage() != null ? e.getMessage() : "") + "</p>");
} finally {
    DBConnection.close(participantRs, eventRs, participantPs, eventPs, conn);
}
%>