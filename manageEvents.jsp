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


String role =
    (String) session.getAttribute("role");


if(role == null ||
   !"Organizer".equalsIgnoreCase(role)){

    response.sendRedirect("login.jsp");
    return;
}


/* =====================================================
   LOGGED-IN ORGANIZER ID
   ===================================================== */

int organizerId =
    (Integer) session.getAttribute("userId");


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
       IMPORTANT

       Show ONLY this organizer's events.
       ================================================= */

    String sql =

        "SELECT * FROM events " +

        "WHERE organizer_id=? " +

        "ORDER BY event_date DESC";


    ps =
        conn.prepareStatement(sql);


    ps.setInt(
        1,
        organizerId
    );


    rs =
        ps.executeQuery();

%>


<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>
Manage Events | EventSphere
</title>


<style>

/* =====================================================
   RESET
   ===================================================== */

*{

    margin:0;
    padding:0;
    box-sizing:border-box;

}


body{

    font-family:
        Arial,
        Helvetica,
        sans-serif;

    background:#0b1220;

    color:white;

    min-height:100vh;

}


/* =====================================================
   NAVBAR
   ===================================================== */

.navbar{

    width:100%;

    background:#111b2d;

    border-bottom:
        1px solid #293750;

    padding:
        18px 6%;

    display:flex;

    justify-content:space-between;

    align-items:center;

}


.logo h2{

    color:#ff3fa4;

}


.nav-links{

    display:flex;

    gap:25px;

}


.nav-links a{

    color:#dce4ef;

    text-decoration:none;

    font-weight:500;

}


.nav-links a:hover{

    color:#ff3fa4;

}


/* =====================================================
   MAIN
   ===================================================== */

.container{

    width:90%;

    max-width:1200px;

    margin:40px auto;

}


/* =====================================================
   PAGE HEADER
   ===================================================== */

.page-header{

    margin-bottom:30px;

}


.page-header h1{

    font-size:36px;

    color:#ffffff;

}


.page-header p{

    margin-top:8px;

    color:#94a3b8;

}


/* =====================================================
   TOP CONTROLS
   ===================================================== */

.controls{

    display:flex;

    justify-content:space-between;

    align-items:center;

    gap:15px;

    margin-bottom:30px;

}


#searchBox{

    width:100%;

    max-width:500px;

    padding:14px 18px;

    border:none;

    outline:none;

    border-radius:10px;

    background:#172236;

    color:white;

    border:
        1px solid #30415d;

    font-size:15px;

}


#searchBox::placeholder{

    color:#8492a6;

}


.add-btn{

    background:#ff3fa4;

    color:white;

    text-decoration:none;

    padding:
        13px 20px;

    border-radius:9px;

    font-weight:bold;

    white-space:nowrap;

}


.add-btn:hover{

    background:#e52b91;

}


/* =====================================================
   EVENT GRID
   ===================================================== */

.event-container{

    display:grid;

    grid-template-columns:
        repeat(
            auto-fit,
            minmax(300px,1fr)
        );

    gap:25px;

}


/* =====================================================
   EVENT CARD
   ===================================================== */

.event-card{

    background:#172236;

    border:
        1px solid #2d3c55;

    border-radius:18px;

    overflow:hidden;

    transition:
        transform .2s ease;

}


.event-card:hover{

    transform:
        translateY(-5px);

}


/* =====================================================
   EVENT IMAGE
   ===================================================== */

.event-image{

    width:100%;

    height:200px;

    object-fit:cover;

    display:block;

    background:#202d41;

}


/* =====================================================
   EVENT CONTENT
   ===================================================== */

.event-content{

    padding:22px;

}


.badge{

    display:inline-block;

    background:#29204a;

    color:#c77cff;

    padding:
        6px 12px;

    border-radius:20px;

    font-size:12px;

    font-weight:bold;

    margin-bottom:12px;

}


.event-content h3{

    font-size:22px;

    margin-bottom:12px;

    color:white;

}


.event-content p{

    color:#aab6c8;

    margin:
        8px 0;

    font-size:14px;

}


/* =====================================================
   BUTTONS
   ===================================================== */

.buttons{

    display:flex;

    flex-wrap:wrap;

    gap:10px;

    margin-top:20px;

}


.buttons a{

    flex:1;

    min-width:90px;

    text-align:center;

    text-decoration:none;

    padding:
        10px 12px;

    border-radius:8px;

    font-size:13px;

    font-weight:bold;

}


.edit{

    background:#2455a4;

    color:white;

}


.view{

    background:#159b50;

    color:white;

}


.delete{

    background:#c93448;

    color:white;

}


.buttons a:hover{

    opacity:.85;

}


/* =====================================================
   EMPTY
   ===================================================== */

.empty{

    text-align:center;

    background:#172236;

    border:
        1px solid #2d3c55;

    border-radius:18px;

    padding:70px 20px;

}


.empty h2{

    color:#ff3fa4;

    margin-bottom:10px;

}


.empty p{

    color:#94a3b8;

    margin-bottom:25px;

}


/* =====================================================
   RESPONSIVE
   ===================================================== */

@media(max-width:700px){

    .navbar{

        flex-direction:column;

        gap:15px;

    }


    .nav-links{

        gap:15px;

        flex-wrap:wrap;

        justify-content:center;

    }


    .controls{

        flex-direction:column;

        align-items:stretch;

    }


    #searchBox{

        max-width:none;

    }


    .add-btn{

        text-align:center;

    }

}

</style>

</head>


<body>


<!-- =====================================================
     NAVBAR
     ===================================================== -->

<header class="navbar">

    <div class="logo">

        <h2>
            EventSphere
        </h2>

    </div>


    <div class="nav-links">

        <a href="organizerDashboard.jsp">
            Dashboard
        </a>

        <a href="addEvent.jsp">
            Add Event
        </a>

        <a href="logout.jsp">
            Logout
        </a>

    </div>

</header>



<!-- =====================================================
     MAIN
     ===================================================== -->

<main class="container">


    <!-- PAGE HEADER -->

    <div class="page-header">

        <h1>
            Manage Events
        </h1>

        <p>
            View, edit, delete and manage
            registrations for your events.
        </p>

    </div>



    <!-- CONTROLS -->

    <div class="controls">

        <input
            type="text"
            id="searchBox"
            placeholder="🔍 Search your events..."
            onkeyup="searchEvents()"
        >


        <a
            href="addEvent.jsp"
            class="add-btn">

            + Add Event

        </a>

    </div>



    <!-- =================================================
         EVENTS
         ================================================= -->

    <div
        class="event-container"
        id="eventContainer">


<%

boolean hasEvents = false;


while(rs.next()){

    hasEvents = true;


    String image =
        rs.getString("banner_image");


    if(image == null ||
       image.trim().equals("")){

        image = "default.jpg";

    }

%>


        <!-- EVENT CARD -->

        <div
            class="event-card"
            data-name="<%=rs.getString("event_name")%>"
            data-category="<%=rs.getString("category")%>"
        >


            <!-- EVENT IMAGE -->

            <img
                class="event-image"
                src="images/<%=image%>"
                alt="Event Banner"
            >



            <!-- EVENT CONTENT -->

            <div class="event-content">


                <span class="badge">

                    <%=rs.getString("category")%>

                </span>


                <h3>

                    <%=rs.getString("event_name")%>

                </h3>


                <p>

                    📅
                    <%=rs.getString("event_date")%>

                </p>


                <p>

                    ⏰
                    <%=rs.getString("event_time")%>

                </p>


                <p>

                    📍
                    <%=rs.getString("venue")%>

                </p>


                <p>

                    💰
                    <%=rs.getString("payment_type")%>

                    <%

                    if("Paid".equalsIgnoreCase(
                        rs.getString("payment_type")
                    )){

                    %>

                    — ₹<%=rs.getDouble("event_fee")%>

                    <%

                    }

                    %>

                </p>



                <!-- ACTION BUTTONS -->

                <div class="buttons">
                    <a href="viewEvent.jsp?id=<%=rs.getInt("event_id")%>"
       class="view-event">
        👁 View Event
    </a>


                    <a
                        href="editEvent.jsp?id=<%=rs.getInt("event_id")%>"
                        class="edit">

                        ✏ Edit

                    </a>


                    <a
                        href="viewParticipants.jsp?id=<%=rs.getInt("event_id")%>"
                        class="view">

                        👥 Participants

                    </a>

                    <a
                        href="gateScanner.jsp?id=<%=rs.getInt("event_id")%>"
                        class="scanner-btn"
                        style="background:#0d9488; color:white;">

                        📲 Gate Scan

                    </a>


                    <a
                        href="deleteEvent.jsp?id=<%=rs.getInt("event_id")%>"
                        class="delete"
                        onclick="return confirm('Are you sure you want to delete this event?');">

                        🗑 Delete

                    </a>

                </div>


            </div>


        </div>


<%

}


if(!hasEvents){

%>


        <!-- NO EVENTS -->

        <div class="empty">

            <h2>
                No Events Found
            </h2>

            <p>
                You haven't created any events yet.
            </p>

            <a
                href="addEvent.jsp"
                class="add-btn">

                + Create Your First Event

            </a>

        </div>


<%

}

%>


    </div>


</main>



<!-- =====================================================
     SEARCH JAVASCRIPT
     ===================================================== -->

<script>

function searchEvents(){

    let input =
        document
        .getElementById("searchBox")
        .value
        .toLowerCase();


    let cards =
        document
        .querySelectorAll(".event-card");


    cards.forEach(function(card){

        let name =
            card
            .getAttribute("data-name")
            .toLowerCase();


        let category =
            card
            .getAttribute("data-category")
            .toLowerCase();


        if(
            name.includes(input) ||
            category.includes(input)
        ){

            card.style.display = "";

        }
        else{

            card.style.display = "none";

        }

    });

}

</script>


</body>

</html>


<%

}
catch(Exception e){

    out.println(
        "<h3 style='color:red;'>"
        + "Error loading events: "
        + e.getMessage()
        + "</h3>"
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