<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>

<%
/* =====================================================
   LOGIN CHECK
   ===================================================== */

if(session.getAttribute("userId") == null){

    response.sendRedirect("login.jsp");
    return;
}


/* =====================================================
   GET EVENT ID
   ===================================================== */

String eventId =
    request.getParameter("id");


if(eventId == null ||
   eventId.trim().equals("")){

    response.sendRedirect("userDashboard.jsp");
    return;
}


Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;


try{

    /* =================================================
       DATABASE CONNECTION
       ================================================= */

    Class.forName(
        "com.mysql.cj.jdbc.Driver"
    );


    conn = DriverManager.getConnection(

        "jdbc:mysql://localhost:3306/eventsphere",

        "root",

        ""
    );


    /* =================================================
       GET EVENT
       ================================================= */

    String sql =
        "SELECT * FROM events WHERE event_id=?";


    ps =
        conn.prepareStatement(sql);


    ps.setInt(
        1,
        Integer.parseInt(eventId)
    );


    rs =
        ps.executeQuery();


    /* =================================================
       EVENT FOUND
       ================================================= */

    if(rs.next()){


        String banner =
            rs.getString("banner_image");


        String category =
            rs.getString("category");


        String eventName =
            rs.getString("event_name");


        String subtitle =
            rs.getString("subtitle");


        String paymentType =
            rs.getString("payment_type");


        String qrImage =
            rs.getString("qr_image");

%>


<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>
    <%=eventName%> | EventSphere
</title>


<link rel="stylesheet"
      href="css/viewEvent.css">


</head>


<body>


<div class="page-container">


<!-- =================================================
     BACK BUTTON
     ================================================= -->

<div class="back-section">

<a href="javascript:history.back()"
   class="back-btn">

    ← Back

</a>

</div>


<!-- =================================================
     EVENT HEADER
     ================================================= -->

<div class="event-header">


<!-- BANNER -->

<div class="banner-container">

<%
if(banner != null &&
   !banner.trim().equals("")){
%>

<img
    src="images/<%=banner%>"
    alt="<%=eventName%>"
    class="event-banner">

<%
}else{
%>

<div class="no-banner">

    No Banner Available

</div>

<%
}
%>

</div>


<!-- EVENT TITLE -->

<div class="title-section">


<span class="category-badge">

    <%=category%>

</span>


<h1>

    <%=eventName%>

</h1>


<%
if(subtitle != null &&
   !subtitle.trim().equals("")){
%>

<p class="subtitle">

    <%=subtitle%>

</p>

<%
}
%>


</div>

</div>


<!-- =================================================
     EVENT INFORMATION
     ================================================= -->

<div class="info-grid">


<div class="info-card">

<span>
    📅
</span>

<div>

<strong>
    Date
</strong>

<p>
    <%=rs.getString("event_date")%>
</p>

</div>

</div>


<div class="info-card">

<span>
    ⏰
</span>

<div>

<strong>
    Time
</strong>

<p>
    <%=rs.getString("event_time")%>
</p>

</div>

</div>


<div class="info-card">

<span>
    📍
</span>

<div>

<strong>
    Venue
</strong>

<p>
    <%=rs.getString("venue")%>
</p>

</div>

</div>


<div class="info-card">

<span>
    🌐
</span>

<div>

<strong>
    Mode
</strong>

<p>
    <%=rs.getString("mode")%>
</p>

</div>

</div>


<div class="info-card">

<span>
    👥
</span>

<div>

<strong>
    Team Size
</strong>

<p>
    <%=rs.getString("team_size")%>
</p>

</div>

</div>


<div class="info-card">

<span>
    🎓
</span>

<div>

<strong>
    Certificate
</strong>

<p>
    <%=rs.getString("certificate")%>
</p>

</div>

</div>


</div>


<!-- =================================================
     DESCRIPTION
     ================================================= -->

<div class="content-section">


<h2>
    About the Event
</h2>


<p>

<%
String description =
    rs.getString("description");

if(description != null &&
   !description.trim().equals("")){
%>

<%=description%>

<%
}else{
%>

No description available.

<%
}
%>

</p>


</div>


<!-- =================================================
     ELIGIBILITY
     ================================================= -->

<div class="content-section">


<h2>
    Eligibility
</h2>


<p>

<%
String eligibility =
    rs.getString("eligibility");

if(eligibility != null &&
   !eligibility.trim().equals("")){
%>

<%=eligibility%>

<%
}else{
%>

Eligibility details are not available.

<%
}
%>

</p>


</div>


<!-- =================================================
     RULES
     ================================================= -->

<div class="content-section">


<h2>
    Rules & Guidelines
</h2>


<p>

<%
String rules =
    rs.getString("rules");

if(rules != null &&
   !rules.trim().equals("")){
%>

<%=rules%>

<%
}else{
%>

No rules have been provided.

<%
}
%>

</p>


</div>


<!-- =================================================
     PRIZES
     ================================================= -->

<div class="content-section">


<h2>
    🏆 Prizes
</h2>


<div class="prize-grid">


<div class="prize-card first">

<h3>
    🥇 First Prize
</h3>

<p>
    <%=rs.getString("first_prize")%>
</p>

</div>


<div class="prize-card second">

<h3>
    🥈 Second Prize
</h3>

<p>
    <%=rs.getString("second_prize")%>
</p>

</div>


<div class="prize-card third">

<h3>
    🥉 Third Prize
</h3>

<p>
    <%=rs.getString("third_prize")%>
</p>

</div>


</div>

</div>


<!-- =================================================
     PAYMENT
     ================================================= -->

<div class="payment-section">


<h2>
    💳 Payment Details
</h2>


<%
if("Paid".equalsIgnoreCase(paymentType)){
%>


<div class="payment-content">


<div class="payment-info">


<h3>

Entry Fee

</h3>


<div class="fee">

₹<%=rs.getDouble("event_fee")%>

</div>


<h3>
    UPI ID
</h3>


<p class="upi">

<%=rs.getString("upi_id")%>

</p>


</div>


<!-- QR -->

<%
if(qrImage != null &&
   !qrImage.trim().equals("")){
%>

<div class="qr-section">


<h3>
    Scan to Pay
</h3>


<img
    src="images/<%=qrImage%>"
    alt="Payment QR Code"
    class="qr-image">


</div>


<%
}
%>


</div>


<%
}else{
%>


<div class="free-payment">

    🎉 This event is free!

</div>


<%
}
%>


</div>


<!-- =================================================
     COORDINATOR
     ================================================= -->

<div class="content-section">


<h2>
    👤 Coordinator Details
</h2>


<div class="coordinator">


<div>

<strong>
    Name
</strong>

<p>
    <%=rs.getString("coordinator_name")%>
</p>

</div>


<div>

<strong>
    Phone
</strong>

<p>
    <%=rs.getString("coordinator_phone")%>
</p>

</div>


<div>

<strong>
    Email
</strong>

<p>
    <%=rs.getString("coordinator_email")%>
</p>

</div>


</div>

</div>


<!-- =================================================
     REGISTER
     ================================================= -->

<div class="register-section">


<a
    href="registrationForm.jsp?id=<%=rs.getInt("event_id")%>"
    class="register-btn">

    🎟 Register Now

</a>


</div>


</div>


</body>

</html>


<%
    }
    else{

        out.println(
            "<h2>Event not found.</h2>"
        );

    }


}
catch(Exception e){

    out.println(
        "<h2 style='color:red;'>"
        + "Error loading event"
        + "</h2>"
    );

    out.println(
        "<p>"
        + e.getMessage()
        + "</p>"
    );

}
finally{


    try{

        if(rs != null)
            rs.close();

    }
    catch(Exception e){}


    try{

        if(ps != null)
            ps.close();

    }
    catch(Exception e){}


    try{

        if(conn != null)
            conn.close();

    }
    catch(Exception e){}

}

%>