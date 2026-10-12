<%@ page language="java" contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>

<%
if(session.getAttribute("userId") == null || session.getAttribute("role") == null || !"Organizer".equalsIgnoreCase(session.getAttribute("role").toString())){
    response.sendRedirect("login.jsp");
    return;
}

int organizerId = Integer.parseInt(session.getAttribute("userId").toString());
String userName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Organizer";

Connection conn = DBConnection.getConnection();

/* Total Events */
PreparedStatement ps1 = conn.prepareStatement("SELECT COUNT(*) FROM events WHERE organizer_id=?");
ps1.setInt(1, organizerId);
ResultSet rs1 = ps1.executeQuery();
int totalEvents = 0;
if(rs1.next()) totalEvents = rs1.getInt(1);

/* Registrations for this organizer's events */
PreparedStatement ps2 = conn.prepareStatement(
    "SELECT COUNT(*) FROM registrations r INNER JOIN events e ON r.event_id=e.event_id WHERE e.organizer_id=?");
ps2.setInt(1, organizerId);
ResultSet rs2 = ps2.executeQuery();
int totalRegistrations = 0;
if(rs2.next()) totalRegistrations = rs2.getInt(1);

/* Upcoming */
PreparedStatement ps3 = conn.prepareStatement(
    "SELECT COUNT(*) FROM events WHERE organizer_id=? AND event_date>=CURDATE()");
ps3.setInt(1, organizerId);
ResultSet rs3 = ps3.executeQuery();
int upcoming = 0;
if(rs3.next()) upcoming = rs3.getInt(1);

/* Completed */
PreparedStatement ps4 = conn.prepareStatement(
    "SELECT COUNT(*) FROM events WHERE organizer_id=? AND event_date<CURDATE()");
ps4.setInt(1, organizerId);
ResultSet rs4 = ps4.executeQuery();
int completed = 0;
if(rs4.next()) completed = rs4.getInt(1);
%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>Organizer Dashboard</title>

<link rel="stylesheet"
href="css/organizerDashboard.css">

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
rel="stylesheet">

</head>

<body>

<!-- ================= NAVBAR ================= -->

<nav class="navbar">

<div class="logo">

<h2>EventSphere</h2>

</div>

<ul>

<li>

<a href="organizerDashboard.jsp">

Dashboard

</a>

</li>

<li>

<a href="addEvent.jsp">

Add Event

</a>

</li>

<li>

<a href="manageEvents.jsp">

Manage Events

</a>

</li>

<li>

<a href="logout.jsp">

Logout

</a>

</li>

</ul>

</nav>

<!-- ================= HERO ================= -->

<section class="hero">

<div class="hero-left">

<h4>WELCOME ORGANIZER</h4>

<h1>

Hello,

<span><%=userName%></span>

👋

</h1>

<p>

Manage your college events with ease.
Create events, monitor registrations,
edit existing events and keep everything
organized from one dashboard.

</p>

<div class="hero-buttons">

<a href="addEvent.jsp">

➕ Add Event

</a>

<a href="manageEvents.jsp">

📅 Manage Events

</a>

</div>

</div>

<div class="hero-right">

<img src="images/image2.png">

</div>

</section>

<!-- ================= STATISTICS ================= -->

<section class="stats">

<div class="stat-box">

<h2><%=totalEvents%></h2>

<p>Total Events</p>

</div>

<div class="stat-box">

<h2><%=totalRegistrations%></h2>

<p>Registrations</p>

</div>

<div class="stat-box">

<h2><%=upcoming%></h2>

<p>Upcoming Events</p>

</div>

<div class="stat-box">

<h2><%=completed%></h2>

<p>Completed Events</p>

</div>

</section>

<!-- ================= QUICK ACTIONS ================= -->

<section class="quick">

<h2>

Quick Actions

</h2>

<div class="quick-grid">

<a href="addEvent.jsp" class="quick-card">

<h3>➕</h3>

<p>Add Event</p>

</a>

<a href="manageEvents.jsp" class="quick-card">

<h3>📅</h3>

<p>Manage Events</p>

</a>

<a href="manageEvents.jsp" class="quick-card">

<h3>👥</h3>

<p>View Attendees</p>

</a>

</div>

</section>
<%
PreparedStatement recentStmt = conn.prepareStatement(
"SELECT * FROM events WHERE organizer_id=? ORDER BY event_date DESC LIMIT 6");
recentStmt.setInt(1, organizerId);

ResultSet recentRs = recentStmt.executeQuery();
%>

<section class="recent-events">

    <div class="section-title">
        <h2>Recent Events</h2>
        <p>Manage your recently created events.</p>
    </div>

    <div class="event-grid">

<%
boolean hasRecent = false;
while(recentRs.next())
{
    hasRecent = true;
    String rBanner = recentRs.getString("banner_image");
    if(rBanner == null || rBanner.trim().isEmpty()){
        rBanner = "image2.png";
    }
%>

<div class="event-card">

    <img src="images/<%=rBanner%>" alt="Event Banner">

    <div class="event-content">

        <span class="category">
            <%=recentRs.getString("category")%>
        </span>

        <h3>
            <%=recentRs.getString("event_name")%>
        </h3>

        <p>📅 <%=recentRs.getString("event_date")%></p>

        <p>📍 <%=recentRs.getString("venue")%></p>

        <div class="card-buttons">

            <a href="editEvent.jsp?id=<%=recentRs.getInt("event_id")%>"
               class="edit-btn">
               Edit
            </a>

            <a href="deleteEvent.jsp?id=<%=recentRs.getInt("event_id")%>"
               class="delete-btn"
               onclick="return confirm('Delete this event?')">
               Delete
            </a>

        </div>

    </div>

</div>

<%
}
if(!hasRecent){
%>
<div style="grid-column: 1/-1; text-align: center; padding: 40px; background: #121c2f; border-radius: 14px; border: 1px dashed #34425d;">
    <p style="color: #94a3b8; font-size: 16px;">You haven't published any events yet.</p>
    <a href="addEvent.jsp" style="display: inline-block; margin-top: 12px; padding: 10px 20px; background: #ff3fa4; color: white; text-decoration: none; border-radius: 8px; font-weight: 600;">+ Create Your First Event</a>
</div>
<%
}
%>

</div>

</section>

<!-- ================= FOOTER ================= -->

<footer>

<h2>EventSphere</h2>

<p>

Designed for College Event Management

</p>

</footer>

<script src="js/organizerDashboard.js"></script>

<%
DBConnection.close(recentRs, rs1, rs2, rs3, rs4, recentStmt, ps1, ps2, ps3, ps4, conn);
%>
</body>

</html>