<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
String currentRole = (String) session.getAttribute("role");
Integer currentUserId = (Integer) session.getAttribute("userId");
String currentUserName = (String) session.getAttribute("userName");

String searchParam = request.getParameter("search");
String categoryParam = request.getParameter("category");

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = DBConnection.getConnection();
    
    StringBuilder sql = new StringBuilder(
        "SELECT event_id, event_name, subtitle, category, event_date, event_time, venue, banner_image, payment_type, event_fee, available_seats, max_capacity, registration_deadline " +
        "FROM events WHERE 1=1 "
    );

    if(searchParam != null && !searchParam.trim().isEmpty()){
        sql.append("AND (event_name LIKE ? OR subtitle LIKE ? OR description LIKE ? OR venue LIKE ? OR category LIKE ?) ");
    }
    if(categoryParam != null && !categoryParam.trim().isEmpty()){
        sql.append("AND category = ? ");
    }

    sql.append("ORDER BY (CASE WHEN event_date >= CURDATE() THEN 0 ELSE 1 END), event_date ASC LIMIT 16");

    ps = conn.prepareStatement(sql.toString());

    int paramIndex = 1;
    if(searchParam != null && !searchParam.trim().isEmpty()){
        String kw = "%" + searchParam.trim() + "%";
        ps.setString(paramIndex++, kw);
        ps.setString(paramIndex++, kw);
        ps.setString(paramIndex++, kw);
        ps.setString(paramIndex++, kw);
        ps.setString(paramIndex++, kw);
    }
    if(categoryParam != null && !categoryParam.trim().isEmpty()){
        ps.setString(paramIndex++, categoryParam.trim());
    }

    rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EventSphere — The Universe of Unforgettable Events</title>
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@700;900&family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

<div class="container">

    <!-- Navbar -->
    <header class="navbar">
        <div class="logo">
            <span class="circle"></span>
            <h2>Event<span>Sphere</span></h2>
        </div>

        <nav class="menu">
            <a href="index.jsp">Home</a>
            <a href="#events">Explore Events</a>
            <a href="#categories">Categories</a>
            <a href="#custom-events">Custom Events</a>
            <% if(currentUserId != null) { %>
                <% if("Admin".equalsIgnoreCase(currentRole)) { %>
                    <a href="adminDashboard.jsp" style="color:#ffd35b; font-weight:600;">Admin Panel</a>
                <% } else if("Organizer".equalsIgnoreCase(currentRole)) { %>
                    <a href="organizerDashboard.jsp" style="color:#ffd35b; font-weight:600;">Organizer Panel</a>
                <% } else { %>
                    <a href="userDashboard.jsp" style="color:#ffd35b; font-weight:600;">Dashboard</a>
                    <a href="myRegistrations.jsp" style="color:#ffd35b; font-weight:600;">My Registrations</a>
                <% } %>
                <a href="logout.jsp" style="color:#ff7180;">Logout (<%=SecurityUtil.escapeHtml(currentUserName)%>)</a>
            <% } else { %>
                <a href="login.jsp">Login</a>
                <a href="signup.jsp" style="color:#f5c24b; font-weight:600;">Sign Up</a>
            <% } %>
        </nav>
    </header>

    <!-- Hero Section -->
    <section class="hero">
        <p class="small-title">✦ THE UNIVERSE OF UNFORGETTABLE EVENTS ✦</p>
        <h1 class="main-title">EVENTSPHERE</h1>
        <p class="tagline">Where Every Event Creates a Memory</p>

        <!-- Search Form -->
        <form action="index.jsp#events" method="get" class="hero-search">
            <input type="text" name="search" placeholder="Search concerts, hackathons, sports..." value="<%= searchParam != null ? SecurityUtil.escapeHtml(searchParam) : "" %>">
            <button type="submit">🔍 Search</button>
        </form>

        <div class="hero-btn">
            <a href="#events" class="btn1">Explore Events →</a>
            <% if(currentUserId == null) { %>
                <a href="signup.jsp" class="btn2">Join as Organizer →</a>
            <% } else { %>
                <a href="requestEvent.jsp" class="btn2">Request Custom Event →</a>
            <% } %>
        </div>
    </section>

    <!-- Categories Section -->
    <section id="categories" class="section-wrapper">
        <div class="section-header">
            <h2>Popular <span>Event Categories</span></h2>
            <p>Select a category to discover curated experiences</p>
        </div>

        <div class="category-grid">
            <a href="index.jsp#events" class="category-card <%= (categoryParam == null || categoryParam.isEmpty()) ? "active" : "" %>">
                <div class="category-icon">🌐</div>
                <h4>All Events</h4>
            </a>
            <a href="index.jsp?category=Technical#events" class="category-card <%= "Technical".equalsIgnoreCase(categoryParam) ? "active" : "" %>">
                <div class="category-icon">💻</div>
                <h4>Technical</h4>
            </a>
            <a href="index.jsp?category=Gaming#events" class="category-card <%= "Gaming".equalsIgnoreCase(categoryParam) ? "active" : "" %>">
                <div class="category-icon">🎮</div>
                <h4>Gaming</h4>
            </a>
            <a href="index.jsp?category=Cultural#events" class="category-card <%= "Cultural".equalsIgnoreCase(categoryParam) ? "active" : "" %>">
                <div class="category-icon">🎭</div>
                <h4>Cultural</h4>
            </a>
            <a href="index.jsp?category=Sports#events" class="category-card <%= "Sports".equalsIgnoreCase(categoryParam) ? "active" : "" %>">
                <div class="category-icon">⚽</div>
                <h4>Sports</h4>
            </a>
            <a href="index.jsp?category=Music#events" class="category-card <%= "Music".equalsIgnoreCase(categoryParam) ? "active" : "" %>">
                <div class="category-icon">🎵</div>
                <h4>Music & Concerts</h4>
            </a>
            <a href="index.jsp?category=Workshop#events" class="category-card <%= "Workshop".equalsIgnoreCase(categoryParam) ? "active" : "" %>">
                <div class="category-icon">🤖</div>
                <h4>Workshops</h4>
            </a>
            <a href="index.jsp?category=Dance#events" class="category-card <%= "Dance".equalsIgnoreCase(categoryParam) ? "active" : "" %>">
                <div class="category-icon">💃</div>
                <h4>Dance</h4>
            </a>
            <a href="index.jsp?category=Hackathon#events" class="category-card <%= "Hackathon".equalsIgnoreCase(categoryParam) ? "active" : "" %>">
                <div class="category-icon">🏆</div>
                <h4>Hackathons</h4>
            </a>
        </div>
    </section>

    <!-- Upcoming Events Section -->
    <section id="events" class="section-wrapper">
        <div class="section-header">
            <h2>Upcoming & Trending <span>Events</span></h2>
            <p>
                <% if(categoryParam != null && !categoryParam.isEmpty()) { %>
                    Showing category: <strong><%= SecurityUtil.escapeHtml(categoryParam) %></strong> (<a href="index.jsp#events" style="color:#ff3fa4;">Clear Filter</a>)
                <% } else if(searchParam != null && !searchParam.isEmpty()) { %>
                    Showing search results for: "<strong><%= SecurityUtil.escapeHtml(searchParam) %></strong>" (<a href="index.jsp#events" style="color:#ff3fa4;">Clear Search</a>)
                <% } else { %>
                    Discover top events happening around you
                <% } %>
            </p>
        </div>

        <div class="event-grid">
            <%
            boolean foundEvents = false;
            java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
            while(rs.next()){
                foundEvents = true;
                int eId = rs.getInt("event_id");
                String eName = rs.getString("event_name");
                String eSub = rs.getString("subtitle");
                String eCat = rs.getString("category");
                java.sql.Date eDate = rs.getDate("event_date");
                Time eTime = rs.getTime("event_time");
                java.sql.Date regDeadline = rs.getDate("registration_deadline");
                String eVenue = rs.getString("venue");
                String eBanner = rs.getString("banner_image");
                String ePayType = rs.getString("payment_type");
                double eFee = rs.getDouble("event_fee");
                int seatsLeft = rs.getInt("available_seats");

                boolean isPast = eDate != null && eDate.before(today);
                boolean isDeadlinePast = regDeadline != null && regDeadline.before(today);

                if(eBanner == null || eBanner.trim().isEmpty()){
                    eBanner = "image2.png";
                } else {
                    eBanner = eBanner.trim();
                    if(eBanner.startsWith("images/")){
                        eBanner = eBanner.substring("images/".length());
                    } else if(eBanner.startsWith("/images/")){
                        eBanner = eBanner.substring("/images/".length());
                    }
                }
            %>
            <div class="event-card">
                <img src="images/<%= SecurityUtil.escapeHtml(eBanner) %>" alt="<%= SecurityUtil.escapeHtml(eName) %>" onerror="this.onerror=null;this.src='images/image2.png';">
                <div class="event-card-body">
                    <div class="event-meta-top">
                        <span class="badge-cat"><%= SecurityUtil.escapeHtml(eCat != null ? eCat : "General") %></span>
                        <% if("Paid".equalsIgnoreCase(ePayType)) { %>
                            <span class="badge-fee paid">₹<%= String.format("%.2f", eFee) %></span>
                        <% } else { %>
                            <span class="badge-fee">Free</span>
                        <% } %>
                    </div>
                    <h3><%= SecurityUtil.escapeHtml(eName) %></h3>
                    <p class="subtitle"><%= eSub != null ? SecurityUtil.escapeHtml(eSub) : "No subtitle provided." %></p>
                    
                    <div class="event-info-line">
                        <span>📅</span>
                        <span><%= eDate %> <%= eTime != null ? ("at " + eTime.toString().substring(0, 5)) : "" %></span>
                    </div>
                    <div class="event-info-line">
                        <span>📍</span>
                        <span><%= SecurityUtil.escapeHtml(eVenue != null ? eVenue : "TBA") %></span>
                    </div>
                    <div class="event-info-line" style="margin-top:4px;">
                        <span>🎟</span>
                        <% if(isPast) { %>
                            <span class="badge-status ended">Event Ended</span>
                        <% } else if(isDeadlinePast) { %>
                            <span class="badge-status closed">Deadline Passed</span>
                        <% } else if(seatsLeft <= 0) { %>
                            <span class="badge-status soldout">Fully Booked</span>
                        <% } else { %>
                            <span class="badge-status open"><%= seatsLeft %> seats available</span>
                        <% } %>
                    </div>

                    <div class="event-card-action">
                        <a href="eventDetails.jsp?id=<%= eId %>" class="btn-view">View Details & Register →</a>
                    </div>
                </div>
            </div>
            <%
            }
            if(!foundEvents){
            %>
            <div style="grid-column:1/-1; text-align:center; padding:60px 20px; background:#121b2d; border-radius:18px; border:1px dashed #30415d;">
                <h3 style="color:#ffbd3d; font-size:22px; margin-bottom:10px;">No Events Found</h3>
                <p style="color:#94a3b8; margin-bottom:20px;">We couldn't find any events matching your criteria.</p>
                <a href="index.jsp#events" style="display:inline-block; padding:10px 22px; background:#7c3aed; color:white; text-decoration:none; border-radius:8px; font-weight:600;">View All Events</a>
            </div>
            <%
            }
            %>
        </div>
    </section>

    <!-- Custom Events CTA Section -->
    <section id="custom-events" class="section-wrapper">
        <div class="cta-box">
            <div class="cta-text">
                <h3>Planning a Special Occasion? 🎪</h3>
                <p>
                    From dream weddings and birthday bashes to college fests and corporate galas, submit your custom requirements and get competitive proposals from verified organizers.
                </p>
            </div>
            <a href="requestEvent.jsp" class="cta-btn">Request Custom Event →</a>
        </div>
    </section>

    <!-- Footer -->
    <footer>
        <div class="footer-content">
            <div class="footer-col">
                <div class="logo" style="margin-bottom:15px;">
                    <span class="circle"></span>
                    <h2>Event<span>Sphere</span></h2>
                </div>
                <p style="max-width:320px; line-height:1.6;">
                    The complete platform connecting students, attendees, and verified event organizers for seamless experiences.
                </p>
            </div>
            <div class="footer-col">
                <h3>Quick Links</h3>
                <a href="index.jsp">Home</a>
                <a href="#events">Browse Events</a>
                <a href="#categories">Event Categories</a>
                <a href="requestEvent.jsp">Request Custom Event</a>
            </div>
            <div class="footer-col">
                <h3>Portals</h3>
                <a href="login.jsp">Customer Login</a>
                <a href="signup.jsp">Organizer Registration</a>
                <a href="login.jsp">Administrator Access</a>
            </div>
            <div class="footer-col">
                <h3>Contact & Support</h3>
                <p>📍 Andhra Pradesh, India</p>
                <p>✉ support@eventsphere.com</p>
                <p>📞 +91 98765 43210</p>
            </div>
        </div>

        <div class="footer-bottom">
            © <%= java.time.Year.now() %> EventSphere | Secure Event Management Platform | All Rights Reserved
        </div>
    </footer>

</div>

<script src="js/script.js"></script>
</body>
</html>
<%
} catch(Exception e) {
    out.println("<h3 style='color:red;'>Error loading page: " + SecurityUtil.escapeHtml(e.getMessage()) + "</h3>");
} finally {
    DBConnection.close(conn, ps, rs);
}
%>