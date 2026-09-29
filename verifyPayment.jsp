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
   ORGANIZER ROLE CHECK
   ===================================================== */

String role =
    (String) session.getAttribute("role");

if(role == null ||
   !"Organizer".equalsIgnoreCase(role)){

    response.sendRedirect("login.jsp");
    return;
}


/* =====================================================
   LOGGED-IN ORGANIZER
   ===================================================== */

int organizerId =
    (Integer)session.getAttribute("userId");


/* =====================================================
   PARAMETERS
   ===================================================== */

String registrationIdString =
    request.getParameter("registration_id");

String eventIdString =
    request.getParameter("event_id");

String status =
    request.getParameter("status");


if(registrationIdString == null ||
   eventIdString == null ||
   status == null){

    response.sendRedirect("manageEvents.jsp");
    return;
}


int registrationId;
int eventId;


try{

    registrationId =
        Integer.parseInt(
            registrationIdString
        );

    eventId =
        Integer.parseInt(
            eventIdString
        );

}
catch(Exception e){

    response.sendRedirect("manageEvents.jsp");
    return;
}


/* =====================================================
   ONLY APPROVED / REJECTED ALLOWED
   ===================================================== */

if(!"Approved".equalsIgnoreCase(status) &&
   !"Rejected".equalsIgnoreCase(status)){

    response.sendRedirect(
        "viewParticipants.jsp?id=" + eventId
    );

    return;
}


Connection conn = null;
PreparedStatement ps = null;


try{

    /* =================================================
       DATABASE
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
       SECURE UPDATE

       Registration must belong to the event.

       Event must belong to logged-in organizer.

       This prevents Organizer A from modifying
       Organizer B's registrations.
       ================================================= */

    String sql =

        "UPDATE registrations r " +

        "INNER JOIN events e " +
        "ON r.event_id=e.event_id " +

        "SET r.payment_status=? " +

        "WHERE r.registration_id=? " +

        "AND r.event_id=? " +

        "AND e.organizer_id=?";


    ps =
        conn.prepareStatement(sql);


    ps.setString(
        1,
        status
    );


    ps.setInt(
        2,
        registrationId
    );


    ps.setInt(
        3,
        eventId
    );


    ps.setInt(
        4,
        organizerId
    );


    int result =
        ps.executeUpdate();


    /* =================================================
       SUCCESS
       ================================================= */

    if(result > 0){

        response.sendRedirect(
            "viewParticipants.jsp?id="
            + eventId
            + "&payment=updated"
        );

        return;

    }


    /* =================================================
       FAILED / ACCESS DENIED
       ================================================= */

%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>
Access Denied | EventSphere
</title>

<link rel="stylesheet"
      href="css/viewParticipants.css">

</head>


<body>

<div class="access-card">

    <div class="lock">
        🔒
    </div>

    <h1>
        Access Denied
    </h1>

    <p>
        You cannot modify this registration.
    </p>

    <p>
        The registration does not belong
        to one of your events.
    </p>

    <a href="manageEvents.jsp"
       class="back-btn">

        ← Back to My Events

    </a>

</div>

</body>

</html>

<%

}
catch(Exception e){

    out.println(
        "<h2 style='color:red;'>"
        + "Payment Update Error"
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