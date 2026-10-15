<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   USER LOGIN CHECK
===================================================== */
if(session.getAttribute("userId") == null){
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(session.getAttribute("userId").toString());
String userName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Customer";
String role = session.getAttribute("role") != null ? session.getAttribute("role").toString() : "User";

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

int totalPlatformEvents = 0;
int totalPlatformRegistrations = 0;
int totalPlatformOrganizers = 0;
int verifiedOrganizersCount = 0;

try {
    conn = DBConnection.getConnection();

    // Query platform statistics
    try {
        Statement st = conn.createStatement();
        ResultSet s1 = st.executeQuery("SELECT COUNT(*) FROM events");
        if(s1.next()) totalPlatformEvents = s1.getInt(1);
        s1.close();

        ResultSet s2 = st.executeQuery("SELECT COUNT(*) FROM registrations");
        if(s2.next()) totalPlatformRegistrations = s2.getInt(1);
        s2.close();

        ResultSet s3 = st.executeQuery("SELECT COUNT(*) FROM users WHERE role='Organizer'");
        if(s3.next()) totalPlatformOrganizers = s3.getInt(1);
        s3.close();

        ResultSet s4 = st.executeQuery("SELECT COUNT(*) FROM organizer_profiles WHERE verification_status='Verified'");
        if(s4.next()) verifiedOrganizersCount = s4.getInt(1);
        s4.close();
        st.close();
    } catch(Exception ignored){}

    // Query all upcoming events
    ps = conn.prepareStatement("SELECT * FROM events ORDER BY event_date ASC");
    rs = ps.executeQuery();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customer Dashboard | EventSphere</title>
    <link rel="stylesheet" href="css/dashboard.css">
    <link rel="stylesheet" href="css/notifications.css">
    <link rel="stylesheet" href="css/toast.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        .cat-card { cursor: pointer; user-select: none; transition: transform 0.2s, background 0.2s; }
        .cat-card:hover { transform: scale(1.05); background: #3b2075; }
        .seat-badge { font-size: 12px; padding: 4px 8px; border-radius: 6px; font-weight: 600; }
        .seat-avail { background: #123f2a; color: #57e89b; }
        .seat-full { background: #4b1720; color: #ff7180; }
    </style>
</head>
<body>

<!-- NAVBAR -->
<header class="navbar">
    <div class="logo">
        <h2>EventSphere</h2>
    </div>

    <nav>
        <ul>
            <li><a href="index.jsp">Explore Portal</a></li>
            <li><a href="#events">Events</a></li>
            <li><a href="#categories">Categories</a></li>
            <li><a href="myRequests.jsp">My Custom Requests</a></li>
            <li><a href="myRegistrations.jsp" style="color:#ffd35b; font-weight:600;">My Registrations</a></li>
            <li>
                <jsp:include page="navbarNotification.jsp" />
            </li>
            <li><a href="logout.jsp" style="color:#ff7180;">Logout</a></li>
        </ul>
    </nav>
</header>

<!-- HERO -->
<section class="hero">
    <div class="hero-left">
        <h4>CUSTOMER DASHBOARD</h4>
        <h1>Hello, <span><%= SecurityUtil.escapeHtml(userName) %></span> 👋</h1>
        <h2>Discover Amazing Events & Experiences</h2>
        <p>
            Participate in gaming tournaments, technical hackathons, cultural festivals, workshops, sports competitions, or request custom private events.
        </p>

        <div class="hero-search">
            <input type="text" id="dashboardSearch" placeholder="Search events by title, venue..." onkeyup="filterDashboardEvents()">
            <button type="button" onclick="filterDashboardEvents()">Search</button>
        </div>

        <div class="hero-buttons">
            <a href="#events">Explore Events</a>
            <a href="#categories">Browse Categories</a>
            <a href="requestEvent.jsp" style="background: linear-gradient(135deg, #ff3fa4, #8e3dff); color: white;">🎪 Request Event</a>
        </div>
    </div>

    <div class="hero-right">
        <img src="images/image2.png" alt="EventSphere">
    </div>
</section>

<!-- CATEGORIES -->
<section id="categories" class="categories">
    <h2>Browse Categories (Click to Filter)</h2>

    <div class="category-slider">
        <div class="category-track">
            <div class="cat-card" onclick="filterCategory('ALL')">🌐 All Events</div>
            <div class="cat-card" onclick="filterCategory('Gaming')">🎮 Gaming</div>
            <div class="cat-card" onclick="filterCategory('Technical')">💻 Technical</div>
            <div class="cat-card" onclick="filterCategory('Cultural')">🎭 Cultural</div>
            <div class="cat-card" onclick="filterCategory('Sports')">⚽ Sports</div>
            <div class="cat-card" onclick="filterCategory('Music')">🎵 Music</div>
            <div class="cat-card" onclick="filterCategory('Dance')">💃 Dance</div>
            <div class="cat-card" onclick="filterCategory('Singing')">🎤 Singing</div>
            <div class="cat-card" onclick="filterCategory('Workshop')">🤖 Workshop</div>
            <div class="cat-card" onclick="filterCategory('Hackathon')">🏆 Hackathon</div>
        </div>
    </div>
</section>

<!-- CUSTOM EVENT SERVICES -->
<section class="custom-services">
    <div class="custom-services-header">
        <div class="custom-services-title">
            <span class="custom-small-title">CUSTOM EVENT PLANNING</span>
            <h2>🎪 Request a Tailored Event</h2>
            <p>
                Have a wedding, birthday, college fest, or corporate gathering in mind? Submit your requirements and receive verified quotations directly from specialized organizers.
            </p>
        </div>

        <div class="custom-request-top">
            <a href="requestEvent.jsp">🎪 Request an Event</a>
            <a href="myRequests.jsp" style="background:#202e48; border:1px solid #3d5175; margin-left:10px;">📋 View My Requests</a>
        </div>
    </div>

    <div class="custom-service-grid">
        <div class="custom-service-card">
            <div class="custom-icon">🎂</div>
            <h3>Birthday Party</h3>
            <p>Custom decor, catering, entertainment, and cake setup.</p>
        </div>
        <div class="custom-service-card">
            <div class="custom-icon">💍</div>
            <h3>Wedding & Engagement</h3>
            <p>Professional stage, photography, sound, and guest hosting.</p>
        </div>
        <div class="custom-service-card">
            <div class="custom-icon">🎓</div>
            <h3>College & Fests</h3>
            <p>Workshops, seminars, hackathons, and technical symposiums.</p>
        </div>
        <div class="custom-service-card">
            <div class="custom-icon">🎤</div>
            <h3>Cultural & Music</h3>
            <p>Concerts, DJ nights, competitions, and dance fests.</p>
        </div>
    </div>
</section>

<!-- TRENDING EVENTS -->
<section id="events" class="trending">
    <div class="section-title">
        <h2>🔥 Available Events</h2>
        <p>Explore and register for upcoming events.</p>
    </div>

    <!-- ACTIVE FILTER TOOLBAR -->
    <div id="filterToolbar" style="display:none; margin: -25px auto 35px; text-align:center; padding:12px 24px; background:rgba(20,30,50,0.85); border:1px solid #334460; border-radius:30px; max-width:550px; box-shadow:0 8px 25px rgba(0,0,0,0.4);">
        <span style="color:#cbd5e1; font-size:14px;">Active Filter: <strong id="activeFilterPill" style="color:#ffd369; margin-left:6px;">All Events</strong></span>
        <button type="button" onclick="resetAllFilters()" style="margin-left:15px; padding:5px 14px; background:#7c3aed; color:white; border:none; border-radius:15px; cursor:pointer; font-size:12px; font-weight:600;">✕ Reset Filters</button>
    </div>

    <div id="noEventsMessage" style="display:none; text-align:center; padding:50px; background:#121c2f; border-radius:18px; border:1px dashed #34425d; margin-bottom:30px;">
        <h3 style="color:#ffbd3d;">No matching events found</h3>
        <p style="color:#9daecc;">Try adjusting your search keyword or click "All Events" above.</p>
        <button onclick="resetAllFilters()" style="margin-top:15px; padding:8px 20px; background:#7c3aed; color:white; border:none; border-radius:8px; cursor:pointer;">Reset Filters</button>
    </div>

    <div class="event-container" id="eventCardList">
<%
while(rs.next()){
    int eventId = rs.getInt("event_id");
    String eventName = rs.getString("event_name");
    String category = rs.getString("category");
    String subtitle = rs.getString("subtitle");
    String eventDate = rs.getString("event_date");
    String venue = rs.getString("venue");
    String paymentType = rs.getString("payment_type");
    double fee = rs.getDouble("event_fee");
    int availableSeats = rs.getInt("available_seats");

    String image = rs.getString("banner_image");
    if(image == null || image.trim().isEmpty()){
        image = "image2.png";
    } else {
        image = image.trim();
        if(image.startsWith("images/")){
            image = image.substring("images/".length());
        } else if(image.startsWith("/images/")){
            image = image.substring("/images/".length());
        }
    }
%>
        <!-- EVENT CARD -->
        <div class="event-card" 
             data-name="<%= SecurityUtil.escapeHtml(eventName) %>" 
             data-category="<%= SecurityUtil.escapeHtml(category != null ? category : "") %>" 
             data-venue="<%= SecurityUtil.escapeHtml(venue != null ? venue : "") %>"
             data-description="<%= SecurityUtil.escapeHtml(subtitle != null ? subtitle : "") %>">

            <img src="images/<%= SecurityUtil.escapeHtml(image) %>" alt="<%= SecurityUtil.escapeHtml(eventName) %>" onerror="this.onerror=null;this.src='images/image2.png';">

            <div class="event-content">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                    <span class="badge"><%= SecurityUtil.escapeHtml(category != null ? category : "General") %></span>
                    <% if(availableSeats > 0) { %>
                        <span class="seat-badge seat-avail"><%= availableSeats %> seats left</span>
                    <% } else { %>
                        <span class="seat-badge seat-full">Sold Out</span>
                    <% } %>
                </div>

                <h3><%= SecurityUtil.escapeHtml(eventName) %></h3>
                <p><%= subtitle != null ? SecurityUtil.escapeHtml(subtitle) : "" %></p>
                <p>📅 <%= eventDate %></p>
                <p>📍 <%= venue != null ? SecurityUtil.escapeHtml(venue) : "TBA" %></p>
                <p>💰 <%= "Paid".equalsIgnoreCase(paymentType) ? ("₹" + String.format("%.2f", fee)) : "Free Entry" %></p>

                <a href="eventDetails.jsp?id=<%= eventId %>">View Details & Register</a>
            </div>
        </div>
<%
}
%>
    </div>
</section>

<!-- LIVE PLATFORM STATISTICS -->
<section class="stats">
    <div class="stat-box">
        <h2><%= totalPlatformEvents %>+</h2>
        <p>Events Published</p>
    </div>
    <div class="stat-box">
        <h2><%= totalPlatformRegistrations %>+</h2>
        <p>Total Bookings</p>
    </div>
    <div class="stat-box">
        <h2><%= totalPlatformOrganizers %>+</h2>
        <p>Organizers</p>
    </div>
    <div class="stat-box">
        <h2><%= verifiedOrganizersCount %></h2>
        <p>Verified Organizers</p>
    </div>
</section>

<!-- FOOTER -->
<footer>
    <div class="footer-content">
        <h2>EventSphere</h2>
        <p>Connecting students, attendees, and verified event organizers.</p>
        <p>© <%= java.time.Year.now() %> EventSphere | All Rights Reserved</p>
    </div>
</footer>

<script src="js/dashboard.js"></script>
<script src="js/toast.js"></script>
<script src="js/notifications.js"></script>
</body>
</html>
<%
} catch(Exception e) {
    out.println("<h3 style='color:red;'>Dashboard Error: " + SecurityUtil.escapeHtml(e.getMessage()) + "</h3>");
} finally {
    DBConnection.close(conn, ps, rs);
}
%>