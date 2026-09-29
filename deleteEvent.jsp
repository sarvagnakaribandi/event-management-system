<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>

<%
/* =====================================================
   ORGANIZER LOGIN CHECK
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
   GET ORGANIZER ID
   ===================================================== */

int organizerId =
    Integer.parseInt(
        session.getAttribute("userId").toString()
    );


/* =====================================================
   GET EVENT ID
   ===================================================== */

String id =
    request.getParameter("id");


if(id == null ||
   id.trim().equals("")){

    response.sendRedirect("manageEvents.jsp");
    return;
}


int eventId;

try{

    eventId =
        Integer.parseInt(id);

}
catch(Exception e){

    response.sendRedirect("manageEvents.jsp");
    return;
}


Connection conn = null;
PreparedStatement checkPs = null;
PreparedStatement deleteRegistrationsPs = null;
PreparedStatement deleteEventPs = null;
ResultSet checkRs = null;


try{

    /* =================================================
       DATABASE CONNECTION
       ================================================= */

    Class.forName(
        "com.mysql.cj.jdbc.Driver"
    );


    conn =
        DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/eventsphere",
            "root",
            ""
        );


    /* =================================================
       CHECK THAT THIS EVENT BELONGS TO LOGGED-IN
       ORGANIZER
       ================================================= */

    String checkSql =

        "SELECT event_id " +
        "FROM events " +
        "WHERE event_id=? " +
        "AND organizer_id=?";


    checkPs =
        conn.prepareStatement(
            checkSql
        );


    checkPs.setInt(
        1,
        eventId
    );


    checkPs.setInt(
        2,
        organizerId
    );


    checkRs =
        checkPs.executeQuery();


    if(!checkRs.next()){

%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>
    Access Denied
</title>

<style>

body{

    margin:0;

    min-height:100vh;

    display:flex;

    justify-content:center;

    align-items:center;

    background:#0b1220;

    color:white;

    font-family:Arial,sans-serif;

}


.box{

    width:90%;

    max-width:500px;

    padding:40px;

    background:#18243a;

    border:1px solid #34425c;

    border-radius:18px;

    text-align:center;

}


h1{

    color:#ffbd3d;

}


a{

    display:inline-block;

    margin-top:20px;

    padding:12px 24px;

    background:#7c3aed;

    color:white;

    text-decoration:none;

    border-radius:10px;

}

</style>

</head>

<body>

<div class="box">

<h1>
    Access Denied
</h1>

<p>
    You cannot delete this event.
</p>

<p>
    This event belongs to another organizer
    or does not exist.
</p>

<a href="manageEvents.jsp">
    ← Back to Manage Events
</a>

</div>

</body>

</html>

<%

        return;
    }


    /* =================================================
       START TRANSACTION
       ================================================= */

    conn.setAutoCommit(false);


    /* =================================================
       DELETE REGISTRATIONS FIRST
       
       registrations.event_id references
       events.event_id
       ================================================= */

    String deleteRegistrationsSql =

        "DELETE FROM registrations " +
        "WHERE event_id=?";


    deleteRegistrationsPs =
        conn.prepareStatement(
            deleteRegistrationsSql
        );


    deleteRegistrationsPs.setInt(
        1,
        eventId
    );


    deleteRegistrationsPs.executeUpdate();


    /* =================================================
       DELETE EVENT
       
       Organizer ID is included again for security.
       ================================================= */

    String deleteEventSql =

        "DELETE FROM events " +
        "WHERE event_id=? " +
        "AND organizer_id=?";


    deleteEventPs =
        conn.prepareStatement(
            deleteEventSql
        );


    deleteEventPs.setInt(
        1,
        eventId
    );


    deleteEventPs.setInt(
        2,
        organizerId
    );


    int result =
        deleteEventPs.executeUpdate();


    /* =================================================
       CHECK RESULT
       ================================================= */

    if(result > 0){

        conn.commit();


        response.sendRedirect(
            "manageEvents.jsp"
        );

        return;

    }
    else{

        conn.rollback();

%>

<h2 style="color:red;">
    Event could not be deleted.
</h2>

<a href="manageEvents.jsp">
    Back to Manage Events
</a>

<%

    }

}
catch(Exception e){

    /* =================================================
       ROLLBACK IF ERROR
       ================================================= */

    try{

        if(conn != null){

            conn.rollback();

        }

    }
    catch(Exception rollbackError){}

%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>
    Database Error
</title>

<style>

body{

    margin:0;

    padding:40px;

    background:#0b1220;

    color:white;

    font-family:Arial,sans-serif;

}


.error-box{

    max-width:800px;

    margin:auto;

    padding:30px;

    background:#18243a;

    border:1px solid #34425c;

    border-radius:18px;

}


h1{

    color:#ff5b6e;

}


.error{

    color:#ffb4bd;

    line-height:1.6;

}


a{

    display:inline-block;

    margin-top:20px;

    padding:12px 22px;

    background:#7c3aed;

    color:white;

    text-decoration:none;

    border-radius:10px;

}

</style>

</head>

<body>

<div class="error-box">

<h1>
    Database Error
</h1>

<p class="error">

    <%=e.getMessage()%>

</p>

<a href="manageEvents.jsp">

    ← Back to Manage Events

</a>

</div>

</body>

</html>

<%

}
finally{

    try{

        if(checkRs != null)
            checkRs.close();

    }
    catch(Exception e){}


    try{

        if(checkPs != null)
            checkPs.close();

    }
    catch(Exception e){}


    try{

        if(deleteRegistrationsPs != null)
            deleteRegistrationsPs.close();

    }
    catch(Exception e){}


    try{

        if(deleteEventPs != null)
            deleteEventPs.close();

    }
    catch(Exception e){}


    try{

        if(conn != null){

            conn.setAutoCommit(true);

            conn.close();

        }

    }
    catch(Exception e){}

}

%>