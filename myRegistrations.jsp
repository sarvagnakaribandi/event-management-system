<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>

<%
/* =========================================================
   CHECK LOGIN
   ========================================================= */

if(session.getAttribute("userId") == null){
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(
    session.getAttribute("userId").toString()
);


/* =========================================================
   DATABASE CONNECTION
   ========================================================= */

Class.forName("com.mysql.cj.jdbc.Driver");

Connection conn = DriverManager.getConnection(
    "jdbc:mysql://localhost:3306/eventsphere",
    "root",
    ""
);


/* =========================================================
   GET USER REGISTRATIONS + EVENT DETAILS
   ========================================================= */

PreparedStatement ps = conn.prepareStatement(

    "SELECT " +

    "r.registration_id, " +
    "r.event_id, " +
    "r.payment_status, " +
    "r.registration_date, " +

    "e.event_name, " +
    "e.category, " +
    "e.event_date, " +
    "e.event_time, " +
    "e.venue, " +
    "e.banner_image, " +
    "e.payment_type, " +
    "e.event_fee " +

    "FROM registrations r " +

    "INNER JOIN events e " +
    "ON r.event_id = e.event_id " +

    "WHERE r.user_id = ? " +

    "ORDER BY e.event_date ASC"
);

ps.setInt(1, userId);

ResultSet rs = ps.executeQuery();

boolean hasRegistrations = false;

%>


<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>My Registrations - EventSphere</title>


<style>

/* =========================================================
   RESET
   ========================================================= */

*{
    margin:0;
    padding:0;
    box-sizing:border-box;
}

body{

    font-family:'Poppins',Arial,sans-serif;

    background:#08101f;

    color:white;

    min-height:100vh;
}


/* =========================================================
   NAVBAR
   ========================================================= */

.navbar{

    height:70px;

    display:flex;

    justify-content:space-between;

    align-items:center;

    padding:0 60px;

    background:#111a2c;

    border-bottom:1px solid #34425d;

}


.logo{

    font-size:28px;

    font-weight:700;

    background:linear-gradient(
        90deg,
        #8f4cff,
        #e36cff
    );

    -webkit-background-clip:text;

    -webkit-text-fill-color:transparent;
}


.nav-links{

    display:flex;

    gap:35px;

}


.nav-links a{

    color:#d7def0;

    text-decoration:none;

    font-size:16px;

    transition:0.3s;

}


.nav-links a:hover{

    color:#a866ff;

}


/* =========================================================
   MAIN CONTAINER
   ========================================================= */

.container{

    width:90%;

    max-width:1400px;

    margin:50px auto;

}


.page-title{

    font-size:42px;

    margin-bottom:10px;

}


.page-subtitle{

    color:#9daecc;

    font-size:18px;

    margin-bottom:40px;

}


/* =========================================================
   REGISTRATION CARD
   ========================================================= */

.registration-card{

    display:flex;

    width:100%;

    min-height:400px;

    background:#18243a;

    border:1px solid #3a4a67;

    border-radius:22px;

    overflow:hidden;

    margin-bottom:30px;

    box-shadow:0 15px 40px rgba(0,0,0,0.25);

}


/* =========================================================
   EVENT IMAGE
   ========================================================= */

.banner{

    width:35%;

    min-width:350px;

    background:#10192b;

    overflow:hidden;

}


.banner img{

    width:100%;

    height:100%;

    min-height:400px;

    object-fit:cover;

    display:block;

}


/* =========================================================
   EVENT CONTENT
   ========================================================= */

.event-content{

    flex:1;

    padding:35px 40px;

}


.category{

    display:inline-block;

    padding:8px 18px;

    border-radius:20px;

    background:#452080;

    color:#d89cff;

    font-weight:600;

    margin-bottom:20px;

}


.event-content h2{

    font-size:32px;

    margin-bottom:25px;

}


.details{

    display:grid;

    grid-template-columns:1fr 1fr;

    gap:18px;

    margin-bottom:25px;

}


.detail{

    color:#cbd5e8;

    font-size:17px;

}


.detail strong{

    color:#ffffff;

    margin-left:5px;

}


.registered{

    color:#91a3c4;

    margin-bottom:25px;

}


/* =========================================================
   PAYMENT BOX
   ========================================================= */

.payment-box{

    background:#101a2d;

    border:1px solid #34445f;

    border-radius:15px;

    padding:20px;

    margin-bottom:25px;

}


.payment-title{

    color:#aab9d3;

    margin-bottom:12px;

}


.status{

    display:inline-block;

    padding:10px 18px;

    border-radius:25px;

    font-weight:600;

}


.status.pending{

    background:#4b3a0a;

    color:#ffd34d;

}


.status.approved{

    background:#123f2a;

    color:#57e89b;

}


.status.rejected{

    background:#4b1720;

    color:#ff7180;

}


.status.free{

    background:#123c36;

    color:#55e6cf;

}


/* =========================================================
   BUTTON
   ========================================================= */

.actions{

    display:flex;

    gap:15px;

}


.btn{

    display:inline-block;

    padding:13px 25px;

    border-radius:10px;

    text-decoration:none;

    color:white;

    font-weight:600;

    background:linear-gradient(
        135deg,
        #7138ff,
        #9c42ff
    );

    transition:0.3s;

}


.btn:hover{

    transform:translateY(-2px);

    box-shadow:0 8px 20px rgba(113,56,255,0.4);

}


/* =========================================================
   EMPTY STATE
   ========================================================= */

.empty-box{

    text-align:center;

    padding:80px 20px;

    background:#121c2f;

    border:1px solid #34425d;

    border-radius:20px;

}


.empty-box h2{

    margin-bottom:15px;

}


.empty-box p{

    color:#9eabc0;

}


.browse-btn{

    display:inline-block;

    margin-top:20px;

    padding:12px 25px;

    background:#7138ff;

    color:white;

    text-decoration:none;

    border-radius:10px;

}


/* =========================================================
   MOBILE
   ========================================================= */

@media(max-width:800px){

    .navbar{

        height:auto;

        padding:20px;

        flex-direction:column;

        gap:15px;

    }


    .nav-links{

        gap:15px;

        flex-wrap:wrap;

        justify-content:center;

    }


    .container{

        width:94%;

        margin:30px auto;

    }


    .page-title{

        font-size:32px;

    }


    .registration-card{

        flex-direction:column;

    }


    .banner{

        width:100%;

        min-width:0;

        height:250px;

    }


    .banner img{

        min-height:250px;

    }


    .event-content{

        padding:25px;

    }


    .details{

        grid-template-columns:1fr;

    }

}

</style>

</head>


<body>


<!-- =========================================================
     NAVBAR
     ========================================================= -->

<div class="navbar">

    <div class="logo">
        EventSphere
    </div>


    <div class="nav-links">

        <a href="userDashboard.jsp">
            Dashboard
        </a>


        <a href="myRegistrations.jsp">
            My Registrations
        </a>


        <a href="logout.jsp">
            Logout
        </a>

    </div>

</div>


<!-- =========================================================
     MAIN
     ========================================================= -->

<div class="container">


<h1 class="page-title">
    My Registrations
</h1>


<p class="page-subtitle">
    View your registered events and payment status.
</p>


<%

while(rs.next()){

    hasRegistrations = true;


    /* =====================================================
       GET ORGANIZER'S EVENT BANNER
       ===================================================== */

    String banner =
        rs.getString("banner_image");


    /*
       If organizer did not upload an image,
       use default image.
    */

    if(banner == null ||
       banner.trim().equals("")){

        banner = "image2.png";

    }


    /*
       IMPORTANT:

       Handle both database formats:

       1. event.jpg

       2. images/event.jpg

       So we don't accidentally create:

       images/images/event.jpg
    */

    String imageUrl;


    banner = banner.trim();


    if(banner.startsWith("images/")){

        imageUrl =
            request.getContextPath()
            + "/"
            + banner;

    }
    else if(banner.startsWith("/images/")){

        imageUrl =
            request.getContextPath()
            + banner;

    }
    else{

        imageUrl =
            request.getContextPath()
            + "/images/"
            + banner;

    }


    /* =====================================================
       PAYMENT STATUS
       ===================================================== */

    String paymentStatus =
        rs.getString("payment_status");


    String statusClass =
        "pending";


    String statusText =
        "🟡 Pending";


    if("Approved".equalsIgnoreCase(
        paymentStatus
    )){

        statusClass =
            "approved";

        statusText =
            "✅ Approved";

    }

    else if("Rejected".equalsIgnoreCase(
        paymentStatus
    )){

        statusClass =
            "rejected";

        statusText =
            "❌ Rejected";

    }

    else if("Not Required".equalsIgnoreCase(
        paymentStatus
    )){

        statusClass =
            "free";

        statusText =
            "🎉 Registered";

    }

%>


<!-- =====================================================
     REGISTRATION CARD
     ===================================================== -->

<div class="registration-card">


    <!-- =================================================
         ORGANIZER'S EVENT IMAGE
         ================================================= -->

    <div class="banner">

        <img

            src="<%=imageUrl%>"

            alt="<%=rs.getString("event_name")%> Event Banner"

            onerror="
                this.onerror=null;
                this.src='<%=request.getContextPath()%>/images/image2.png';
            "

        >

    </div>


    <!-- =================================================
         EVENT CONTENT
         ================================================= -->

    <div class="event-content">


        <span class="category">

            <%=rs.getString("category")%>

        </span>


        <h2>

            <%=rs.getString("event_name")%>

        </h2>


        <div class="details">


            <div class="detail">

                📅

                <strong>
                    Date:
                </strong>

                <%=rs.getString("event_date")%>

            </div>


            <div class="detail">

                ⏰

                <strong>
                    Time:
                </strong>

                <%=rs.getString("event_time")%>

            </div>


            <div class="detail">

                📍

                <strong>
                    Venue:
                </strong>

                <%=rs.getString("venue")%>

            </div>


            <div class="detail">

                💰

                <strong>
                    Fee:
                </strong>


                <%

                String paymentType =
                    rs.getString("payment_type");


                if("Paid".equalsIgnoreCase(
                    paymentType
                )){

                %>

                    ₹<%=rs.getDouble("event_fee")%>

                <%

                }

                else{

                %>

                    Free

                <%

                }

                %>

            </div>


        </div>


        <div class="registered">

            Registered on:

            <%=rs.getTimestamp(
                "registration_date"
            )%>

        </div>


        <!-- =================================================
             PAYMENT STATUS
             ================================================= -->

        <div class="payment-box">


            <div class="payment-title">

                Payment Status

            </div>


            <span class="status <%=statusClass%>">

                <%=statusText%>

            </span>


        </div>


        <!-- =================================================
             VIEW EVENT
             ================================================= -->

        <div class="actions">


            <a

                href="eventDetails.jsp?id=<%=rs.getInt("event_id")%>"

                class="btn"

            >

                👁 View Event

            </a>


        </div>


    </div>

</div>


<%

}

%>


<!-- =========================================================
     NO REGISTRATIONS
     ========================================================= -->

<%

if(!hasRegistrations){

%>


<div class="empty-box">

    <h2>
        No Registrations Yet
    </h2>


    <p>
        You haven't registered for any events yet.
    </p>


    <a
        href="userDashboard.jsp"
        class="browse-btn"
    >
        Browse Events
    </a>

</div>


<%

}

%>


</div>


</body>

</html>


<%

/* =========================================================
   CLOSE DATABASE RESOURCES
   ========================================================= */

try{

    rs.close();

}
catch(Exception e){}


try{

    ps.close();

}
catch(Exception e){}


try{

    conn.close();

}
catch(Exception e){}

%>