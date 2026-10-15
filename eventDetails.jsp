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
PreparedStatement psReviewsList = null;
ResultSet rsReviewsList = null;

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

        // Phase 10: Reviews & Ratings Aggregations
        double avgRating = 0.0;
        int totalReviews = 0;
        int[] starCounts = new int[6];

        PreparedStatement psRating = conn.prepareStatement(
            "SELECT AVG(rating) as avg_score, COUNT(*) as total_count FROM event_reviews WHERE event_id = ?"
        );
        psRating.setInt(1, eventId);
        ResultSet rsRating = psRating.executeQuery();
        if (rsRating.next()) {
            avgRating = rsRating.getDouble("avg_score");
            totalReviews = rsRating.getInt("total_count");
        }
        rsRating.close();
        psRating.close();

        PreparedStatement psStarBreakdown = conn.prepareStatement(
            "SELECT rating, COUNT(*) as cnt FROM event_reviews WHERE event_id = ? GROUP BY rating"
        );
        psStarBreakdown.setInt(1, eventId);
        ResultSet rsBreakdown = psStarBreakdown.executeQuery();
        while (rsBreakdown.next()) {
            int r = rsBreakdown.getInt("rating");
            if (r >= 1 && r <= 5) {
                starCounts[r] = rsBreakdown.getInt("cnt");
            }
        }
        rsBreakdown.close();
        psStarBreakdown.close();

        // User's own review if logged in
        int myRating = 5;
        String myReviewTitle = "";
        String myReviewText = "";
        boolean hasReviewed = false;
        if (currentUserId != null) {
            PreparedStatement psMyReview = conn.prepareStatement(
                "SELECT * FROM event_reviews WHERE event_id = ? AND user_id = ?"
            );
            psMyReview.setInt(1, eventId);
            psMyReview.setInt(2, currentUserId);
            ResultSet rsMyReview = psMyReview.executeQuery();
            if (rsMyReview.next()) {
                hasReviewed = true;
                myRating = rsMyReview.getInt("rating");
                myReviewTitle = rsMyReview.getString("review_title");
                myReviewText = rsMyReview.getString("review_text");
            }
            rsMyReview.close();
            psMyReview.close();
        }

        // List of recent reviews
        psReviewsList = conn.prepareStatement(
            "SELECT er.*, u.full_name AS reviewer_name, r.check_in_status " +
            "FROM event_reviews er " +
            "JOIN users u ON er.user_id = u.id " +
            "LEFT JOIN registrations r ON er.registration_id = r.registration_id " +
            "WHERE er.event_id = ? " +
            "ORDER BY er.created_at DESC LIMIT 10"
        );
        psReviewsList.setInt(1, eventId);
        rsReviewsList = psReviewsList.executeQuery();
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

        .rating-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(245, 158, 11, 0.15);
            border: 1px solid rgba(245, 158, 11, 0.4);
            color: #fbbf24;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 700;
        }

        /* Reviews Section */
        .reviews-container {
            background: #10172a;
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 20px;
            padding: 35px;
            margin-top: 40px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.3);
        }

        .reviews-header-line {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            flex-wrap: wrap;
            gap: 15px;
        }

        .reviews-header-line h2 {
            font-size: 24px;
            color: #fff;
            margin: 0;
        }

        .reviews-summary {
            display: grid;
            grid-template-columns: 240px 1fr;
            gap: 35px;
            padding-bottom: 30px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            margin-bottom: 30px;
        }

        .rating-score-box {
            text-align: center;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 255, 255, 0.06);
            border-radius: 16px;
            padding: 20px;
        }

        .score-num {
            font-size: 46px;
            font-weight: 800;
            color: #fbbf24;
            line-height: 1;
        }

        .stars-row {
            color: #fbbf24;
            font-size: 18px;
            margin: 8px 0;
            letter-spacing: 2px;
        }

        .breakdown-row {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 8px;
            font-size: 13px;
            color: #94a3b8;
        }

        .progress-track {
            flex: 1;
            height: 8px;
            background: rgba(255, 255, 255, 0.06);
            border-radius: 4px;
            overflow: hidden;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #f59e0b, #fbbf24);
            border-radius: 4px;
            transition: width 0.3s ease;
        }

        /* Review Form */
        .review-form-card {
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(99, 102, 241, 0.3);
            border-radius: 16px;
            padding: 25px;
            margin-bottom: 35px;
        }

        .star-rating-select {
            display: flex;
            gap: 8px;
            margin: 10px 0 16px 0;
            font-size: 26px;
            cursor: pointer;
        }

        .star-rating-select .star-item {
            color: #475569;
            transition: color 0.15s, transform 0.15s;
        }

        .star-rating-select .star-item:hover,
        .star-rating-select .star-item.active {
            color: #fbbf24;
            transform: scale(1.15);
        }

        .review-input {
            width: 100%;
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            padding: 12px 16px;
            color: #fff;
            font-family: inherit;
            font-size: 14px;
            margin-bottom: 12px;
            outline: none;
            transition: border-color 0.2s;
        }

        .review-input:focus {
            border-color: #6366f1;
            background: rgba(99, 102, 241, 0.05);
        }

        .btn-submit-review {
            background: linear-gradient(135deg, #6366f1, #4f46e5);
            color: #fff;
            border: none;
            padding: 12px 28px;
            border-radius: 10px;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-submit-review:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(99, 102, 241, 0.4);
        }

        /* Reviews List */
        .review-item {
            padding: 20px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.06);
        }
        .review-item:last-child {
            border-bottom: none;
        }

        .review-user-line {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
            flex-wrap: wrap;
            gap: 10px;
        }

        .reviewer-name {
            font-weight: 600;
            color: #fff;
            font-size: 15px;
        }

        .verified-attendee-tag {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: rgba(16, 185, 129, 0.15);
            border: 1px solid rgba(16, 185, 129, 0.3);
            color: #34d399;
            font-size: 11px;
            font-weight: 600;
            padding: 2px 8px;
            border-radius: 20px;
            margin-left: 8px;
        }

        .review-date {
            color: #64748b;
            font-size: 12px;
        }

        .review-text-body {
            color: #cbd5e1;
            font-size: 14px;
            line-height: 1.6;
            margin-top: 6px;
        }

        @media (max-width: 768px) {
            .reviews-summary { grid-template-columns: 1fr; }
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

    <!-- Feedback Alerts -->
    <% 
    String revMsg = request.getParameter("msg");
    String revErr = request.getParameter("error");
    if ("review_success".equalsIgnoreCase(revMsg)) { 
    %>
        <div style="background:rgba(34,197,94,0.15); border:1px solid #22c55e; color:#4ade80; padding:14px 20px; border-radius:12px; margin-bottom:25px; text-align:center; font-weight:500;">
            ✅ Thank you! Your verified attendee review has been published successfully.
        </div>
    <% } else if ("not_registered_attendee".equalsIgnoreCase(revErr)) { %>
        <div style="background:rgba(239,68,68,0.15); border:1px solid #ef4444; color:#f87171; padding:14px 20px; border-radius:12px; margin-bottom:25px; text-align:center; font-weight:500;">
            ⚠️ Reviews are exclusively open to verified attendees who registered for this event.
        </div>
    <% } %>

    <!-- Event Header -->
    <div class="event-header">
        <div style="display:flex; justify-content:center; align-items:center; gap:10px; margin-bottom:12px; flex-wrap:wrap;">
            <span class="category"><%= SecurityUtil.escapeHtml(category != null ? category : "General") %></span>
            <% if (totalReviews > 0) { %>
                <a href="#reviews" class="rating-badge" style="text-decoration:none;">
                    ★ <%= String.format("%.1f", avgRating) %> (<%= totalReviews %> review<%= totalReviews > 1 ? "s" : "" %>)
                </a>
            <% } else { %>
                <span class="rating-badge" style="background:rgba(255,255,255,0.05); border-color:rgba(255,255,255,0.15); color:#94a3b8;">
                    ★ New Event
                </span>
            <% } %>
        </div>
        <h1><%= SecurityUtil.escapeHtml(eventName) %></h1>
        <h3><%= subtitle != null ? SecurityUtil.escapeHtml(subtitle) : "" %></h3>

        <!-- Organizer Profile Card -->
        <div style="margin-top: 15px; display:flex; align-items:center; gap:15px; flex-wrap:wrap; justify-content:center;">
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

    <!-- =====================================================
         PHASE 10: ATTENDEE REVIEWS & RATINGS SECTION
         ===================================================== -->
    <div class="reviews-container" id="reviews">
        <div class="reviews-header-line">
            <h2>⭐ Attendee Ratings & Reviews</h2>
            <% if (totalReviews > 0) { %>
                <span style="color:#94a3b8; font-size:14px;"><%= totalReviews %> verified attendee review<%= totalReviews > 1 ? "s" : "" %></span>
            <% } %>
        </div>

        <!-- Summary Row -->
        <div class="reviews-summary">
            <div class="rating-score-box">
                <div class="score-num"><%= totalReviews > 0 ? String.format("%.1f", avgRating) : "-" %></div>
                <div class="stars-row">
                    <%
                    int fullStars = (int) Math.round(avgRating);
                    for (int s = 1; s <= 5; s++) {
                        if (s <= fullStars) {
                            out.print("★");
                        } else {
                            out.print("<span style='color:#475569;'>★</span>");
                        }
                    }
                    %>
                </div>
                <div style="font-size:12px; color:#94a3b8; margin-top:4px;">
                    <%= totalReviews > 0 ? ("Based on " + totalReviews + " review" + (totalReviews > 1 ? "s" : "")) : "No reviews yet" %>
                </div>
            </div>

            <!-- Breakdown Bars -->
            <div>
                <%
                for (int star = 5; star >= 1; star--) {
                    int cnt = starCounts[star];
                    int pct = totalReviews > 0 ? (int) Math.round((cnt * 100.0) / totalReviews) : 0;
                %>
                <div class="breakdown-row">
                    <span style="width: 35px; font-weight:600;"><%= star %> ★</span>
                    <div class="progress-track">
                        <div class="progress-fill" style="width: <%= pct %>%;"></div>
                    </div>
                    <span style="width: 45px; text-align:right; font-size:12px;"><%= cnt %> (<%= pct %>%)</span>
                </div>
                <% } %>
            </div>
        </div>

        <!-- Review Form (For Verified Attendees) -->
        <% if (alreadyRegistered) { %>
            <div class="review-form-card">
                <h3 style="color:#fff; font-size:17px; margin-bottom:8px;">
                    <%= hasReviewed ? "✏️ Edit Your Verified Review" : "⭐ Leave a Verified Attendee Review" %>
                </h3>
                <p style="color:#94a3b8; font-size:13px; margin-bottom:15px;">
                    Share your experience to help future attendees and assist the organizer in improving their event.
                </p>

                <form action="submitReview.jsp" method="POST">
                    <input type="hidden" name="event_id" value="<%= eventId %>">
                    <input type="hidden" name="rating" id="ratingInput" value="<%= myRating > 0 ? myRating : 5 %>">

                    <label style="font-size:13px; color:#cbd5e1; font-weight:500;">Your Overall Rating:</label>
                    <div class="star-rating-select" id="starSelector">
                        <% for (int i = 1; i <= 5; i++) { %>
                            <span class="star-item <%= i <= (myRating > 0 ? myRating : 5) ? "active" : "" %>" onclick="setRating(<%= i %>)">★</span>
                        <% } %>
                    </div>

                    <input type="text" name="review_title" class="review-input" placeholder="Title of your review (e.g. Excellent workshop and great networking!)" value="<%= SecurityUtil.escapeHtml(myReviewTitle) %>" required>

                    <textarea name="review_text" class="review-input" rows="4" placeholder="What did you like or think could be improved? (Venue, content, organization, etc.)" required><%= SecurityUtil.escapeHtml(myReviewText) %></textarea>

                    <button type="submit" class="btn-submit-review">
                        <%= hasReviewed ? "Update My Review" : "Publish Verified Review" %>
                    </button>
                </form>
            </div>
        <% } else if (currentUserId != null) { %>
            <div style="text-align:center; padding:18px; margin-bottom:25px; color:#94a3b8; font-size:13px; background:rgba(255,255,255,0.02); border-radius:12px; border:1px dashed rgba(255,255,255,0.1);">
                🔒 <strong>Verified Attendee Reviews:</strong> Only attendees with confirmed bookings can write reviews for this event.
            </div>
        <% } else { %>
            <div style="text-align:center; padding:18px; margin-bottom:25px; color:#94a3b8; font-size:13px; background:rgba(255,255,255,0.02); border-radius:12px; border:1px dashed rgba(255,255,255,0.1);">
                <a href="login.jsp" style="color:#818cf8; font-weight:600; text-decoration:none;">Log in</a> to write a review if you are a registered participant.
            </div>
        <% } %>

        <!-- Reviews List -->
        <div class="reviews-list">
            <%
            boolean hasReviewRows = false;
            while (rsReviewsList.next()) {
                hasReviewRows = true;
                String revName = rsReviewsList.getString("reviewer_name");
                int revScore = rsReviewsList.getInt("rating");
                String revTitle = rsReviewsList.getString("review_title");
                String revBody = rsReviewsList.getString("review_text");
                Timestamp revDate = rsReviewsList.getTimestamp("created_at");
                String checkIn = rsReviewsList.getString("check_in_status");
                boolean gateChecked = "Checked In".equalsIgnoreCase(checkIn);
            %>
            <div class="review-item">
                <div class="review-user-line">
                    <div>
                        <span class="reviewer-name"><%= SecurityUtil.escapeHtml(revName) %></span>
                        <span class="verified-attendee-tag">
                            ✓ Verified Attendee <%= gateChecked ? "• Gate Attended" : "" %>
                        </span>
                    </div>
                    <span class="review-date"><%= revDate != null ? new java.text.SimpleDateFormat("MMM dd, yyyy").format(revDate) : "" %></span>
                </div>

                <div style="color:#fbbf24; font-size:14px; margin-bottom:4px;">
                    <% for (int s = 1; s <= 5; s++) { %>
                        <%= s <= revScore ? "★" : "<span style='color:#475569;'>★</span>" %>
                    <% } %>
                    <strong style="color:#fff; font-size:14px; margin-left:6px;"><%= SecurityUtil.escapeHtml(revTitle) %></strong>
                </div>

                <p class="review-text-body"><%= SecurityUtil.escapeHtml(revBody) %></p>
            </div>
            <% } %>

            <% if (!hasReviewRows) { %>
                <div style="text-align:center; padding:40px 20px; color:#94a3b8; font-size:14px;">
                    🌟 Be the first verified attendee to rate and review this event!
                </div>
            <% } %>
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

<script>
function setRating(val) {
    document.getElementById('ratingInput').value = val;
    const stars = document.querySelectorAll('#starSelector .star-item');
    stars.forEach((s, idx) => {
        if (idx < val) {
            s.classList.add('active');
        } else {
            s.classList.remove('active');
        }
    });
}
</script>
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
    DBConnection.close(rsReviewsList);
    DBConnection.close(psReviewsList);
    DBConnection.close(regCheckRs);
    DBConnection.close(regCheckPs);
    DBConnection.close(rs);
    DBConnection.close(ps);
    DBConnection.close(conn);
}
%>