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
   ORGANIZER CHECK
   ===================================================== */

String role =
    (String) session.getAttribute("role");

if(role == null ||
   !"Organizer".equalsIgnoreCase(role)){

    response.sendRedirect("login.jsp");
    return;
}


/* =====================================================
   ORGANIZER ID
   ===================================================== */

int organizerId =
    Integer.parseInt(
        session.getAttribute("userId").toString()
    );


/* =====================================================
   GET REGISTRATION ID
   ===================================================== */

String registrationParam =
    request.getParameter("id");

String eventParam =
    request.getParameter("event_id");


if(registrationParam == null ||
   eventParam == null){

    response.sendRedirect(
        request.getContextPath()
        + "/manageEvents.jsp"
    );

    return;
}


int registrationId;
int eventId;


try{

    registrationId =
        Integer.parseInt(
            registrationParam
        );

    eventId =
        Integer.parseInt(
            eventParam
        );

}
catch(Exception e){

    response.sendRedirect(
        request.getContextPath()
        + "/manageEvents.jsp"
    );

    return;
}


Connection conn = null;
PreparedStatement ps = null;


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
       APPROVE PAYMENT

       Only the organizer who owns the event
       can approve the registration.
       ================================================= */

    String sql =

        "UPDATE registrations r " +

        "INNER JOIN events e " +
        "ON r.event_id = e.event_id " +

        "SET r.payment_status = 'Approved' " +

        "WHERE r.registration_id = ? " +

        "AND r.event_id = ? " +

        "AND e.organizer_id = ?";


    ps =
        conn.prepareStatement(sql);


    ps.setInt(
        1,
        registrationId
    );


    ps.setInt(
        2,
        eventId
    );


    ps.setInt(
        3,
        organizerId
    );


    int result =
        ps.executeUpdate();


    /* =================================================
       SUCCESS
       ================================================= */

    if(result > 0){

       response.sendRedirect(
    request.getContextPath()
    + "/viewParticipants.jsp?id="
    + eventId
);

        return;
    }

%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>
    Approval Failed
</title>

<style>

body{

    margin:0;

    min-height:100vh;

    background:#0b1220;

    color:white;

    font-family:Arial,sans-serif;

    display:flex;

    justify-content:center;

    align-items:center;
}


.box{

    width:90%;

    max-width:500px;

    padding:40px;

    text-align:center;

    background:#18243a;

    border:1px solid #34425c;

    border-radius:18px;
}


h1{

    color:#ffbd3d;
}


a{

    display:inline-block;

    margin-top:20px;

    padding:12px 25px;

    background:#7138ff;

    color:white;

    text-decoration:none;

    border-radius:10px;
}

</style>

</head>


<body>

<div class="box">

<h1>
    ⚠ Approval Failed
</h1>

<p>
    Registration not found or
    you do not have permission
    to approve this payment.
</p>

<a href="<%=request.getContextPath()%>/viewParticipants.jsp?id=<%=eventId%>">

    ← Back to Participants

</a>

</div>

</body>

</html>

<%

}

catch(Exception e){

%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>
    Error
</title>

</head>


<body>

<h2 style="color:red;">
    Error Approving Payment
</h2>

<p>
    <%=e.getMessage()%>
</p>

<a href="<%=request.getContextPath()%>/viewParticipants.jsp?id=<%=eventId%>">

    ← Back to Participants

</a>

</body>

</html>

<%

}

finally{

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