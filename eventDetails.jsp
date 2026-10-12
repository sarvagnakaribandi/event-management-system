<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
String eventIdParam = request.getParameter("id");
if(eventIdParam == null || eventIdParam.trim().isEmpty()){
    response.sendRedirect("index.jsp");
    return;
}

int eventId;
try {
    eventId = Integer.parseInt(eventIdParam.trim());
} catch(Exception e){
    response.sendRedirect("index.jsp");
    return;
}

Integer currentUserId = (Integer) session.getAttribute("userId");
String currentRole = (String) session.getAttribute("role");

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;
PreparedStatement regCheckPs = null;
ResultSet regCheckRs = null;

try{
    conn = DBConnection.getConnection();

    String sql = 
        "SELECT e.*, u.full_name AS organizer_name, u.email AS organizer_email, " +
        "op.verification_status, op.business_name, op.contact_phone AS organizer_phone " +
        "FROM events e " +
        "LEFT JOIN users u ON e.organizer_id = u.id " +
        "LEFT JOIN organizer_profiles op ON u.id = op.organizer_id " +
        "WHERE e.event_id=?";

    ps = conn.prepareStatement(sql);
    ps.setInt(1, eventId);
    rs = ps.executeQuery();

    if(rs.next()){
        String eventName = rs.getString("event_name");
        String subtitle = rs.getString("subtitle");
        String category = rs.getString("category");
        Date eventDate = rs.getDate("event_date");
        Time eventTime = rs.getTime("event_time");
        Date regStart = rs.getDate("registration_start");
        Date regDeadline = rs.getDate("registration_deadline");
        String venue = rs.getString("venue");
        String mode = rs.getString("mode");
        String teamSize = rs.getString("team_size");
        String description = rs.getString("description");
        String eligibility = rs.getString("eligibility");
        String rules = rs.getString("rules");
        String firstPrize = rs.getString("first_prize");
        String secondPrize = rs.getString("second_prize");
        String thirdPrize = rs.getString("third_prize");
        String certificate = rs.getString("certificate");
        String coordinatorName = rs.getString("coordinator_name");
        String coordinatorPhone = rs.getString("coordinator_phone");
        String coordinatorEmail = rs.getString("coordinator_email");
        String bannerImage = rs.getString("banner_image");
        String paymentType = rs.getString("payment_type");
        double eventFee = rs.getDouble("event_fee");
        String upiId = rs.getString("upi_id");
        String qrImage = rs.getString("qr_image");
        int maxCapacity = rs.getInt("max_capacity");
        int availableSeats = rs.getInt("available_seats");

        String organizerName = rs.getString("organizer_name");
        String verificationStatus = rs.getString("verification_status");
        boolean isVerifiedOrganizer = "Verified".equalsIgnoreCase(verificationStatus);

        if(bannerImage == null || bannerImage.trim().isEmpty()){
            bannerImage = "image2.png";
        } else {
            bannerImage = bannerImage.trim();
            if(bannerImage.startsWith("images/")){
                bannerImage = bannerImage.substring("images/".length());
            } else if(bannerImage.startsWith("/images/")){
                bannerImage = bannerImage.substring("/images/".length());
            }
        }

        // Date and capacity validation
        Date today = new Date(System.currentTimeMillis());
        boolean isEventPast = eventDate != null && eventDate.before(today);
        boolean isDeadlinePast = regDeadline != null && regDeadline.before(today);
        boolean isSoldOut = availableSeats <= 0;

        // Check if user is already registered
        boolean alreadyRegistered = false;
        if(currentUserId != null){
            regCheckPs = conn.prepareStatement(
                "SELECT registration_id, payment_status FROM registrations WHERE user_id=? AND event_id=?"
            );
            regCheckPs.setInt(1, currentUserId);
            regCheckPs.setInt(2, eventId);
            regCheckRs = regCheckPs.executeQuery();
            if(regCheckRs.next()){
                alreadyRegistered = true;
            }
        }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= SecurityUtil.escapeHtml(eventName) %> | EventSphere</title>
    <link rel="stylesheet" href="css/eventDetails.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        .verified-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(87, 232, 155, 0.15);
            color: #57e89b;
            border: 1px solid #57e89b;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
        }
        .standard-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(148, 163, 184, 0.15);
            color: #94a3b8;
            border: 1px solid #475569;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 13px;
        }
        .seat-highlight {
            font-weight: 700;
            color: <%= availableSeats > 0 ? "#57e89b" : "#ff7180" %>;
        }
        .btn-disabled {
            display: inline-block;
            padding: 15px 35px;
            background: #334155;
            color: #94a3b8;
            border-radius: 30px;
            text-decoration: none;
            font-weight: 600;
            cursor: not-allowed;
        }
        .btn-registered {
            display: inline-block;
            padding: 15px 35px;
            background: #15803d;
            color: #fff;
            border-radius: 30px;
            text-decoration: none;
            font-weight: 600;
        }
    </style>
</head>
<body>

<!-- Banner -->
<section class="banner">
    <img src="images/<%= SecurityUtil.escapeHtml(bannerImage) %>" alt="<%= SecurityUtil.escapeHtml(eventName) %>" onerror="this.onerror=null;this.src='images/image2.png';">
</section>

<div class="container">
    <a href="javascript:history.back()" style="display:inline-block; margin-bottom:20px; color:#cbb8ff; text-decoration:none;">← Go Back</a>

    <!-- Event Header -->
    <div class="event-header">
        <span class="category"><%= SecurityUtil.escapeHtml(category != null ? category : "General") %></span>
        <h1><%= SecurityUtil.escapeHtml(eventName) %></h1>
        <h3><%= subtitle != null ? SecurityUtil.escapeHtml(subtitle) : "" %></h3>

        <!-- Organizer Profile Card -->
        <div style="margin-top: 15px; display:flex; align-items:center; gap:15px; flex-wrap:wrap;">
            <span style="color:#cbd5e1;">Organized by: <strong><%= SecurityUtil.escapeHtml(organizerName != null ? organizerName : "EventSphere Organizer") %></strong></span>
            <% if(isVerifiedOrganizer) { %>
                <span class="verified-badge">✔ Verified Organizer</span>
            <% } else { %>
                <span class="standard-badge">Standard Organizer</span>
            <% } %>
        </div>
    </div>

    <!-- Information Grid -->
    <div class="info-grid">
        <div class="info-card">
            <h4>📅 Event Date</h4>
            <p><%= eventDate %></p>
        </div>

        <div class="info-card">
            <h4>⏰ Event Time</h4>
            <p><%= eventTime != null ? eventTime.toString().substring(0, 5) : "TBA" %></p>
        </div>

        <div class="info-card">
            <h4>📍 Venue</h4>
            <p><%= venue != null ? SecurityUtil.escapeHtml(venue) : "TBA" %></p>
        </div>

        <div class="info-card">
            <h4>🌐 Mode</h4>
            <p><%= mode != null ? SecurityUtil.escapeHtml(mode) : "Offline" %></p>
        </div>

        <div class="info-card">
            <h4>👥 Team Size</h4>
            <p><%= teamSize != null ? SecurityUtil.escapeHtml(teamSize) : "1 Member" %></p>
        </div>

        <div class="info-card">
            <h4>🎟 Remaining Seats</h4>
            <p class="seat-highlight"><%= availableSeats %> / <%= maxCapacity %> seats available</p>
        </div>

        <div class="info-card">
            <h4>🗓 Registration Deadline</h4>
            <p><%= regDeadline != null ? regDeadline.toString() : "Until Event Date" %></p>
        </div>

        <div class="info-card">
            <h4>💰 Registration Fee</h4>
            <p style="font-weight:700; color:<%= "Paid".equalsIgnoreCase(paymentType) ? "#ffd35b" : "#57e89b" %>;">
                <%= "Paid".equalsIgnoreCase(paymentType) ? ("₹" + String.format("%.2f", eventFee)) : "Free Entry" %>
            </p>
        </div>
    </div>

    <!-- About Section -->
    <div class="section">
        <h2>About Event</h2>
        <div style="color:#cbd5e1; line-height:1.8; white-space:pre-wrap;"><%= description != null ? SecurityUtil.escapeHtml(description) : "No description provided." %></div>
    </div>

    <!-- Eligibility -->
    <% if(eligibility != null && !eligibility.trim().isEmpty()) { %>
    <div class="section">
        <h2>Eligibility</h2>
        <p><%= SecurityUtil.escapeHtml(eligibility) %></p>
    </div>
    <% } %>

    <!-- Rules -->
    <% if(rules != null && !rules.trim().isEmpty()) { %>
    <div class="section">
        <h2>Rules & Guidelines</h2>
        <p><%= SecurityUtil.escapeHtml(rules) %></p>
    </div>
    <% } %>

    <!-- Prize Pool -->
    <% if((firstPrize != null && !firstPrize.trim().isEmpty()) || (secondPrize != null && !secondPrize.trim().isEmpty())) { %>
    <div class="section">
        <h2>Prize Pool</h2>
        <div class="prizes">
            <div class="prize-card">
                🥇
                <h3>First Prize</h3>
                <p><%= firstPrize != null ? SecurityUtil.escapeHtml(firstPrize) : "-" %></p>
            </div>
            <div class="prize-card">
                🥈
                <h3>Second Prize</h3>
                <p><%= secondPrize != null ? SecurityUtil.escapeHtml(secondPrize) : "-" %></p>
            </div>
            <div class="prize-card">
                🥉
                <h3>Third Prize</h3>
                <p><%= thirdPrize != null ? SecurityUtil.escapeHtml(thirdPrize) : "-" %></p>
            </div>
        </div>
    </div>
    <% } %>

    <!-- Certificate -->
    <div class="section">
        <h2>Participation Certificate</h2>
        <p><%= "Yes".equalsIgnoreCase(certificate) ? "✔ Certificate of participation will be provided to all attendees." : "No certificate issued for this event." %></p>
    </div>

    <!-- Coordinator -->
    <div class="section">
        <h2>Event Coordinator</h2>
        <div class="coordinator">
            <h3><%= coordinatorName != null ? SecurityUtil.escapeHtml(coordinatorName) : "Event Coordinator" %></h3>
            <p>📞 <%= coordinatorPhone != null ? SecurityUtil.escapeHtml(coordinatorPhone) : "N/A" %></p>
            <p>✉ <%= coordinatorEmail != null ? SecurityUtil.escapeHtml(coordinatorEmail) : "N/A" %></p>
        </div>
    </div>

    <!-- Booking / Action Section -->
    <div class="register-section" style="text-align:center; padding: 40px 0;">
        <% if(alreadyRegistered) { %>
            <a class="btn-registered" href="myRegistrations.jsp">
                ✅ You are Registered (View Ticket)
            </a>
        <% } else if(isEventPast) { %>
            <span class="btn-disabled">
                ❌ This Event has Ended
            </span>
        <% } else if(isDeadlinePast) { %>
            <span class="btn-disabled">
                ❌ Registration Deadline has Passed
            </span>
        <% } else if(isSoldOut) { %>
            <span class="btn-disabled">
                🚫 Event is Fully Booked (0 Seats Left)
            </span>
        <% } else if(currentUserId == null) { %>
            <a class="register-btn" href="login.jsp">
                🔒 Login to Register
            </a>
        <% } else { %>
            <a class="register-btn" href="registrationForm.jsp?id=<%= eventId %>">
                🎟 Register Now (<%= "Paid".equalsIgnoreCase(paymentType) ? ("₹" + String.format("%.2f", eventFee)) : "Free" %>)
            </a>
        <% } %>
    </div>
</div>

</body>
</html>

<%
    } else {
        out.println("<h2 style='text-align:center; margin-top:50px; color:#ff7180;'>Event Not Found</h2>");
        out.println("<p style='text-align:center;'><a href='index.jsp'>Back to Events</a></p>");
    }
} catch(Exception e) {
    out.println("<h3 style='color:red;'>Error : " + SecurityUtil.escapeHtml(e.getMessage()) + "</h3>");
} finally {
    DBConnection.close(regCheckRs);
    DBConnection.close(regCheckPs);
    DBConnection.close(rs);
    DBConnection.close(ps);
    DBConnection.close(conn);
}
%>