<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =========================================================
   CHECK LOGIN
   ========================================================= */
if(session.getAttribute("userId") == null){
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(session.getAttribute("userId").toString());
String userName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Customer";

String msg = request.getParameter("msg");
String error = request.getParameter("error");

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

boolean hasRegistrations = false;
java.sql.Date today = new java.sql.Date(System.currentTimeMillis());

try {
    conn = DBConnection.getConnection();

    ps = conn.prepareStatement(
        "SELECT " +
        "r.registration_id, " +
        "r.event_id, " +
        "r.payment_status, " +
        "r.payment_method, " +
        "r.transaction_id, " +
        "r.registration_date, " +
        "r.full_name, " +
        "r.team_name, " +
        "r.team_members, " +
        "r.ticket_token, " +
        "r.check_in_status, " +
        "r.checked_in_at, " +
        "r.certificate_id, " +
        "e.event_name, " +
        "e.category, " +
        "e.event_date, " +
        "e.event_time, " +
        "e.venue, " +
        "e.banner_image, " +
        "e.payment_type, " +
        "e.event_fee " +
        "FROM registrations r " +
        "INNER JOIN events e ON r.event_id = e.event_id " +
        "WHERE r.user_id = ? " +
        "ORDER BY (CASE WHEN e.event_date >= CURDATE() THEN 0 ELSE 1 END), e.event_date ASC"
    );

    ps.setInt(1, userId);
    rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Registrations | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="css/notifications.css">
    <link rel="stylesheet" href="css/toast.css">
    <style>
        * { margin:0; padding:0; box-sizing:border-box; font-family:'Poppins', sans-serif; }
        body { background:#08101f; color:white; min-height:100vh; }
        
        .navbar {
            height:75px;
            display:flex;
            justify-content:space-between;
            align-items:center;
            padding:0 60px;
            background:#111a2c;
            border-bottom:1px solid #283750;
        }
        .logo {
            font-size:26px;
            font-weight:700;
            background:linear-gradient(90deg, #8f4cff, #ffd369);
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
        }
        .nav-links { display:flex; gap:30px; align-items:center; }
        .nav-links a { color:#cbd5e8; text-decoration:none; font-size:15px; transition:0.3s; font-weight:500; }
        .nav-links a:hover { color:#ffd369; }
        .nav-links a.active { color:#ffd369; font-weight:700; }

        .container { width:90%; max-width:1250px; margin:40px auto 80px; }
        .page-header { margin-bottom:30px; }
        .page-title { font-size:36px; font-weight:700; color:#fff; }
        .page-subtitle { color:#94a3b8; font-size:16px; margin-top:5px; }

        /* Notification Alerts */
        .alert {
            padding:14px 20px;
            border-radius:12px;
            margin-bottom:25px;
            font-size:15px;
            font-weight:500;
            display:flex;
            align-items:center;
            justify-content:space-between;
        }
        .alert-success { background:rgba(34,197,94,0.15); border:1px solid #22c55e; color:#4ade80; }
        .alert-error { background:rgba(239,68,68,0.15); border:1px solid #ef4444; color:#f87171; }

        /* Registration Card */
        .registration-card {
            display:flex;
            background:#131d31;
            border:1px solid #26354d;
            border-radius:20px;
            overflow:hidden;
            margin-bottom:30px;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
            transition:transform 0.25s ease, border-color 0.25s ease;
        }
        .registration-card:hover {
            transform:translateY(-4px);
            border-color:#7c3aed;
        }
        .banner { width:320px; min-width:300px; background:#0b1220; overflow:hidden; }
        .banner img { width:100%; height:100%; min-height:280px; object-fit:cover; display:block; }
        .event-content { flex:1; padding:30px 35px; display:flex; flex-direction:column; }
        
        .meta-tags { display:flex; gap:12px; align-items:center; margin-bottom:15px; flex-wrap:wrap; }
        .category-badge { background:#2e2055; color:#d89cff; padding:5px 14px; border-radius:20px; font-size:12px; font-weight:600; }
        
        .status-badge { padding:5px 14px; border-radius:20px; font-size:12px; font-weight:600; }
        .status-pending { background:#4b3a0a; color:#ffd34d; border:1px solid #854d0e; }
        .status-approved { background:#123f2a; color:#57e89b; border:1px solid #166534; }
        .status-rejected { background:#4b1720; color:#ff7180; border:1px solid #991b1b; }
        .status-free { background:#133c36; color:#55e6cf; border:1px solid #115e59; }

        .event-content h2 { font-size:24px; color:#fff; margin-bottom:18px; font-weight:600; }
        
        .details-grid { display:grid; grid-template-columns:repeat(auto-fit, minmax(200px, 1fr)); gap:14px; margin-bottom:20px; }
        .detail-item { color:#94a3b8; font-size:14px; }
        .detail-item strong { color:#e2e8f0; margin-left:4px; font-weight:500; }

        .reg-timestamp { color:#64748b; font-size:13px; margin-bottom:22px; }

        .actions { display:flex; gap:15px; align-items:center; margin-top:auto; flex-wrap:wrap; }
        .btn-view {
            padding:11px 22px;
            border-radius:10px;
            text-decoration:none;
            color:white;
            font-weight:600;
            font-size:14px;
            background:linear-gradient(135deg, #7c3aed, #a855f7);
            transition:0.3s;
        }
        .btn-view:hover { opacity:0.9; transform:translateY(-2px); }

        .btn-ticket {
            padding:11px 20px;
            border-radius:10px;
            text-decoration:none;
            color:white;
            font-weight:600;
            font-size:14px;
            background:linear-gradient(135deg, #0ea5e9, #0284c7);
            box-shadow:0 4px 15px rgba(14, 165, 233, 0.3);
            display:inline-flex;
            align-items:center;
            gap:6px;
            transition:0.3s;
        }
        .btn-ticket:hover { opacity:0.95; transform:translateY(-2px); box-shadow:0 6px 20px rgba(14, 165, 233, 0.45); }

        .btn-cert {
            padding:11px 20px;
            border-radius:10px;
            text-decoration:none;
            color:#1e1b4b;
            font-weight:700;
            font-size:14px;
            background:linear-gradient(135deg, #fbbf24, #d97706);
            box-shadow:0 4px 15px rgba(245, 158, 11, 0.35);
            display:inline-flex;
            align-items:center;
            gap:6px;
            transition:0.3s;
        }
        .btn-cert:hover { opacity:0.95; transform:translateY(-2px); box-shadow:0 6px 20px rgba(245, 158, 11, 0.5); }

        .btn-cancel {
            padding:11px 22px;
            border-radius:10px;
            border:none;
            color:white;
            font-weight:600;
            font-size:14px;
            background:linear-gradient(135deg, #e11d48, #be123c);
            cursor:pointer;
            transition:0.3s;
        }
        .btn-cancel:hover {
            background:linear-gradient(135deg, #f43f5e, #e11d48);
            transform:translateY(-2px);
            box-shadow:0 8px 20px rgba(225, 29, 72, 0.4);
        }

        .badge-completed {
            display:inline-block;
            padding:10px 18px;
            background:#1e293b;
            color:#94a3b8;
            border:1px solid #334155;
            border-radius:10px;
            font-size:13px;
            font-weight:600;
        }

        /* Empty State */
        .empty-box {
            text-align:center;
            padding:80px 20px;
            background:#121c2f;
            border:1px dashed #30415d;
            border-radius:20px;
        }
        .empty-box h2 { color:#ffd369; margin-bottom:10px; font-size:24px; }
        .empty-box p { color:#94a3b8; font-size:16px; margin-bottom:25px; }
        .browse-btn {
            display:inline-block;
            padding:12px 30px;
            background:linear-gradient(135deg, #7c3aed, #9333ea);
            color:white;
            text-decoration:none;
            border-radius:30px;
            font-weight:600;
            transition:0.3s;
        }
        .browse-btn:hover { transform:scale(1.05); }

        @media(max-width:850px){
            .navbar { padding:0 25px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:12px; }
            .registration-card { flex-direction:column; }
            .banner { width:100%; min-width:auto; height:200px; }
            .banner img { min-height:200px; }
            .event-content { padding:22px; }
        }
    </style>
</head>
<body>

<!-- Navbar -->
<div class="navbar">
    <div class="logo">
        EventSphere
    </div>
    <div class="nav-links">
        <a href="index.jsp">Explore Events</a>
        <a href="userDashboard.jsp">Dashboard</a>
        <a href="myRequests.jsp">My Custom Requests</a>
        <a href="myRegistrations.jsp" class="active">My Registrations</a>
        <jsp:include page="navbarNotification.jsp" />
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">

    <div class="page-header">
        <h1 class="page-title">My Registrations</h1>
        <p class="page-subtitle">Manage your booked events, check admission status, and cancel bookings anytime.</p>
    </div>

    <!-- Feedback messages -->
    <% if("cancelled".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-success">
            <span>✅ Your registration has been successfully cancelled and your reserved seat has been released.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } %>

    <% if(error != null && !error.trim().isEmpty()) { %>
        <div class="alert alert-error">
            <span>
                <% if("not_found".equalsIgnoreCase(error)) { %>
                    ❌ Registration record not found or already cancelled.
                <% } else if("event_ended".equalsIgnoreCase(error)) { %>
                    ❌ Cannot cancel registration for an event that has already ended.
                <% } else if("unauthorized".equalsIgnoreCase(error)) { %>
                    ❌ Unauthorized cancellation request.
                <% } else { %>
                    ❌ Cancellation failed: <%= SecurityUtil.escapeHtml(error) %>
                <% } %>
            </span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } %>

    <%
    while(rs.next()){
        hasRegistrations = true;
        int regId = rs.getInt("registration_id");
        int eventId = rs.getInt("event_id");
        String eventName = rs.getString("event_name");
        String category = rs.getString("category");
        Date eventDate = rs.getDate("event_date");
        Time eventTime = rs.getTime("event_time");
        String venue = rs.getString("venue");
        String paymentType = rs.getString("payment_type");
        double eventFee = rs.getDouble("event_fee");
        Timestamp regDate = rs.getTimestamp("registration_date");
        String paymentStatus = rs.getString("payment_status");
        String paymentMethod = rs.getString("payment_method");
        String transactionId = rs.getString("transaction_id");
        String banner = rs.getString("banner_image");
        String ticketToken = rs.getString("ticket_token");
        String checkInStatus = rs.getString("check_in_status");
        Timestamp checkedInAt = rs.getTimestamp("checked_in_at");
        String certificateId = rs.getString("certificate_id");
        boolean isCheckedIn = "Checked In".equalsIgnoreCase(checkInStatus);
        boolean isApproved = "Approved".equalsIgnoreCase(paymentStatus) || "Not Required".equalsIgnoreCase(paymentStatus);

        boolean isPast = eventDate != null && eventDate.before(today);

        if(banner == null || banner.trim().isEmpty()){
            banner = "image2.png";
        } else {
            banner = banner.trim();
            if(banner.startsWith("images/")){
                banner = banner.substring("images/".length());
            } else if(banner.startsWith("/images/")){
                banner = banner.substring("/images/".length());
            }
        }

        String statusClass = "status-pending";
        String statusLabel = "🟡 Payment Pending";
        if("Approved".equalsIgnoreCase(paymentStatus)){
            statusClass = "status-approved";
            statusLabel = "✅ Confirmed";
        } else if("Rejected".equalsIgnoreCase(paymentStatus)){
            statusClass = "status-rejected";
            statusLabel = "❌ Rejected";
        } else if("Not Required".equalsIgnoreCase(paymentStatus)){
            statusClass = "status-free";
            statusLabel = "🎉 Registered (Free)";
        }
    %>

    <div class="registration-card">
        <div class="banner">
            <img src="images/<%= SecurityUtil.escapeHtml(banner) %>" 
                 alt="<%= SecurityUtil.escapeHtml(eventName) %>" 
                 onerror="this.onerror=null;this.src='images/image2.png';">
        </div>

        <div class="event-content">
            <div class="meta-tags">
                <span class="category-badge"><%= SecurityUtil.escapeHtml(category != null ? category : "General") %></span>
                <span class="status-badge <%= statusClass %>"><%= statusLabel %></span>
                <% if(isCheckedIn) { %>
                    <span class="status-badge" style="background:#064e3b; color:#34d399; border:1px solid #059669;">✓ Gate Checked In</span>
                <% } else if(isApproved) { %>
                    <span class="status-badge" style="background:rgba(14, 165, 233, 0.15); color:#38bdf8; border:1px solid #0284c7;">🎟️ Gate Ready</span>
                <% } %>
                <% if(isPast) { %>
                    <span class="status-badge" style="background:#1e293b; color:#94a3b8; border:1px solid #475569;">Past Event</span>
                <% } %>
            </div>

            <h2><%= SecurityUtil.escapeHtml(eventName) %></h2>

            <div class="details-grid">
                <div class="detail-item">
                    📅 Date: <strong><%= eventDate %></strong>
                </div>
                <div class="detail-item">
                    ⏰ Time: <strong><%= eventTime != null ? eventTime.toString().substring(0, 5) : "TBA" %></strong>
                </div>
                <div class="detail-item">
                    📍 Venue: <strong><%= SecurityUtil.escapeHtml(venue != null ? venue : "TBA") %></strong>
                </div>
                <div class="detail-item">
                    💰 Fee: <strong><%= "Paid".equalsIgnoreCase(paymentType) ? ("₹" + String.format("%.2f", eventFee)) : "Free" %></strong>
                </div>
                <div class="detail-item">
                    💳 Method: <strong><%= SecurityUtil.escapeHtml(paymentMethod != null ? paymentMethod : ("Paid".equalsIgnoreCase(paymentType) ? "UPI" : "Free")) %></strong>
                </div>
                <% if(transactionId != null && !transactionId.trim().isEmpty()) { %>
                <div class="detail-item">
                    🔖 Ref: <strong style="font-family:monospace; color:#38bdf8;"><%= SecurityUtil.escapeHtml(transactionId) %></strong>
                </div>
                <% } %>
            </div>

            <div class="reg-timestamp">
                Registered on: <%= regDate != null ? regDate.toString() : "N/A" %>
            </div>

            <div class="actions">
                <a href="eventDetails.jsp?id=<%= eventId %>" class="btn-view">👁 View Details</a>

                <% if(isApproved) { %>
                    <a href="viewTicket.jsp?id=<%= regId %>" class="btn-ticket">
                        🎟️ E-Ticket Pass
                    </a>
                <% } %>

                <% if(isCheckedIn) { %>
                    <a href="certificate.jsp?id=<%= regId %>" target="_blank" class="btn-cert">
                        🎓 View Certificate
                    </a>
                <% } %>

                <% if(!isPast && !isCheckedIn) { %>
                    <form action="cancelRegistration.jsp" method="post" style="display:inline;" 
                          onsubmit="return confirm('Are you sure you want to cancel your registration for <%= SecurityUtil.escapeHtml(eventName) %>?\n\nYour seat will be released immediately and this action cannot be undone.');">
                        <input type="hidden" name="registration_id" value="<%= regId %>">
                        <button type="submit" class="btn-cancel">❌ Cancel</button>
                    </form>
                <% } else if(isPast) { %>
                    <span class="badge-completed">Event Completed</span>
                <% } %>
            </div>
        </div>
    </div>

    <%
    }
    if(!hasRegistrations){
    %>
    <div class="empty-box">
        <h2>No Event Registrations Yet</h2>
        <p>You haven't signed up for any events yet. Explore tech hackathons, esports, concerts, and cultural festivals!</p>
        <a href="userDashboard.jsp#events" class="browse-btn">Explore Events →</a>
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
} catch(Exception e){
    out.println("<h3 style='color:red;'>Error: " + SecurityUtil.escapeHtml(e.getMessage()) + "</h3>");
} finally {
    DBConnection.close(conn, ps, rs);
}
%>