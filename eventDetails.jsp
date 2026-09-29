<%@ page language="java" contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>

<%
Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

String eventId = request.getParameter("id");

if(eventId == null){
    response.sendRedirect("userDashboard.jsp");
    return;
}

try{

    Class.forName("com.mysql.cj.jdbc.Driver");

    conn = DriverManager.getConnection(
        "jdbc:mysql://localhost:3306/eventsphere",
        "root",
        ""
    );

    String sql = "SELECT * FROM events WHERE event_id=?";

    ps = conn.prepareStatement(sql);
    ps.setInt(1, Integer.parseInt(eventId));

    rs = ps.executeQuery();

    if(rs.next()){
%>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title><%=rs.getString("event_name")%> | EventSphere</title>

<link rel="stylesheet" href="css/eventDetails.css">

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">

</head>

<body>

<!-- Banner -->

<section class="banner">
<%
String image = rs.getString("banner_image");

if(image == null || image.trim().equals("")){
    image = "image2.png";
}
%>

<img src="images/<%=image%>" alt="Banner">

   
</section>

<div class="container">

    <!-- Event Header -->

    <div class="event-header">

        <span class="category">
            <%=rs.getString("category")%>
        </span>

        <h1>
            <%=rs.getString("event_name")%>
        </h1>

        <h3>
            <%=rs.getString("subtitle")%>
        </h3>

    </div>

    <!-- Information -->

    <div class="info-grid">

        <div class="info-card">
            <h4>📅 Event Date</h4>
            <p><%=rs.getDate("event_date")%></p>
        </div>

        <div class="info-card">
            <h4>⏰ Event Time</h4>
            <p><%=rs.getTime("event_time")%></p>
        </div>

        <div class="info-card">
            <h4>📍 Venue</h4>
            <p><%=rs.getString("venue")%></p>
        </div>

        <div class="info-card">
            <h4>🌐 Mode</h4>
            <p><%=rs.getString("mode")%></p>
        </div>

        <div class="info-card">
            <h4>👥 Team Size</h4>
            <p><%=rs.getString("team_size")%></p>
        </div>
        <div class="info-card">

    <h4>📅 Registration Starts</h4>

    <p><%=rs.getDate("registration_start")%></p>

</div>

        <div class="info-card">
            <h4>🗓 Registration Deadline</h4>
            <p><%=rs.getDate("registration_deadline")%></p>
        </div>

    </div>

    <!-- About -->

    <div class="section">

        <h2>About Event</h2>

        <pre class="description">

            <%=rs.getString("description")%>

        </pre>

    </div>

    <!-- Eligibility -->

    <div class="section">

        <h2>Eligibility</h2>

        <p>
            <%=rs.getString("eligibility")%>
        </p>

    </div>

    <!-- Rules -->

    <div class="section">

        <h2>Rules & Guidelines</h2>

        <p>
            <%=rs.getString("rules")%>
        </p>

    </div>

    <!-- Prize -->

    <div class="section">

        <h2>Prize Pool</h2>

        <div class="prizes">


            <div class="prize-card">

                🥇

                <h3>First Prize</h3>

                <p><%=rs.getString("first_prize")%></p>

            </div>

            <div class="prize-card">

                🥈

                <h3>Second Prize</h3>

                <p><%=rs.getString("second_prize")%></p>

            </div>

            <div class="prize-card">

                🥉

                <h3>Third Prize</h3>

                <p><%=rs.getString("third_prize")%></p>

            </div>

        </div>

    </div>

    <!-- Certificate -->

<div class="section">

    <h2>Certificate</h2>

    <p>

        <%=rs.getString("certificate")%>

    </p>

</div>

    <!-- Coordinator -->

    <div class="section">

        <h2>Coordinator</h2>

        <div class="coordinator">

            <h3><%=rs.getString("coordinator_name")%></h3>

            <p>📞 <%=rs.getString("coordinator_phone")%></p>

            <p>✉ <%=rs.getString("coordinator_email")%></p>

        </div>

    </div>

    <!-- Register Button -->

    <div class="register-section">

        <a class="register-btn"
           href="registrationForm.jsp?id=<%=rs.getInt("event_id")%>">

            Register Now

        </a>

    </div>

</div>

</body>

</html>

<%
    }else{
%>

<h2 style="text-align:center;">Event Not Found</h2>

<%
    }

}catch(Exception e){

    out.println("<h3>Error : " + e.getMessage() + "</h3>");

}finally{

    try{

        if(rs!=null)
            rs.close();

    }catch(Exception e){}

    try{

        if(ps!=null)
            ps.close();

    }catch(Exception e){}

    try{

        if(conn!=null)
            conn.close();

    }catch(Exception e){}

}

%>