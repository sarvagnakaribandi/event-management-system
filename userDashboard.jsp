<%@ page language="java" contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>

<%
/* =====================================================
   USER LOGIN CHECK
===================================================== */

if(session.getAttribute("userId") == null){
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(
    session.getAttribute("userId").toString()
);

String userName =
    session.getAttribute("userName").toString();
%>


<%
/* =====================================================
   DATABASE CONNECTION
===================================================== */

Class.forName("com.mysql.cj.jdbc.Driver");

Connection conn = DriverManager.getConnection(
    "jdbc:mysql://localhost:3306/eventsphere",
    "root",
    ""
);


/* =====================================================
   GET ALL EVENTS
===================================================== */

PreparedStatement ps = conn.prepareStatement(
    "SELECT * FROM events ORDER BY event_date ASC"
);

ResultSet rs = ps.executeQuery();
%>


<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>EventSphere Dashboard</title>


<link rel="stylesheet"
      href="css/dashboard.css">


<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap"
      rel="stylesheet">

</head>


<body>


<!-- =====================================================
                    NAVBAR
===================================================== -->

<header class="navbar">

    <div class="logo">

        <h2>EventSphere</h2>

    </div>


    <nav>

        <ul>

            <li>
                <a href="#">
                    Home
                </a>
            </li>


            <li>
                <a href="#events">
                    Events
                </a>
            </li>


            <li>
                <a href="#categories">
                    Categories
                </a>
            </li>


            <li>
                <a href="#">
                    About
                </a>
            </li>


            <!-- MY REGISTRATIONS
                 KEEP THIS BUTTON -->

            <li>

                <a href="myRegistrations.jsp">

                    My Registrations

                </a>

            </li>


            <li>

                <a href="logout.jsp">

                    Logout

                </a>

            </li>

        </ul>

    </nav>

</header>



<!-- =====================================================
                    HERO
===================================================== -->

<section class="hero">


    <div class="hero-left">


        <h4>
            WELCOME
        </h4>


        <h1>

            Hello,

            <span>

                <%=userName%>

            </span>

        </h1>


        <h2>

            Discover Amazing College Events

        </h2>


        <p>

            Participate in gaming tournaments, workshops,
            hackathons, cultural fests, sports competitions,
            technical events and much more.

        </p>


        <div class="hero-search">


            <input
                type="text"
                placeholder="Search Events...">


            <button>

                Search

            </button>


        </div>


        <div class="hero-buttons">


            <a href="#events">

                Explore Events

            </a>


            <a href="#categories">

                Categories

            </a>


        </div>


    </div>



    <div class="hero-right">


        <img
            src="images/image2.png"
            alt="EventSphere">


    </div>


</section>



<!-- =====================================================
                    CATEGORIES
===================================================== -->

<section
    id="categories"
    class="categories">


    <h2>

        Browse Categories

    </h2>



    <div class="category-slider">


        <div class="category-track">


            <div class="cat-card">

                🎮 Gaming

            </div>


            <div class="cat-card">

                💻 Technical

            </div>


            <div class="cat-card">

                🎭 Cultural

            </div>


            <div class="cat-card">

                ⚽ Sports

            </div>


            <div class="cat-card">

                🎵 Music

            </div>


            <div class="cat-card">

                💃 Dance

            </div>


            <div class="cat-card">

                🎤 Singing

            </div>


            <div class="cat-card">

                🤖 Workshop

            </div>


            <div class="cat-card">

                🏆 Competition

            </div>


            <div class="cat-card">

                🎲 Fun Games

            </div>



            <!-- DUPLICATE CARDS FOR SLIDER -->


            <div class="cat-card">

                🎮 Gaming

            </div>


            <div class="cat-card">

                💻 Technical

            </div>


            <div class="cat-card">

                🎭 Cultural

            </div>


            <div class="cat-card">

                ⚽ Sports

            </div>


            <div class="cat-card">

                🎵 Music

            </div>


            <div class="cat-card">

                💃 Dance

            </div>


            <div class="cat-card">

                🎤 Singing

            </div>


            <div class="cat-card">

                🤖 Workshop

            </div>


            <div class="cat-card">

                🏆 Competition

            </div>


            <div class="cat-card">

                🎲 Fun Games

            </div>


        </div>


    </div>


</section>
<!-- =====================================================
        CUSTOM EVENT SERVICES
===================================================== -->

<section class="custom-services">

    <!-- HEADER -->

    <div class="custom-services-header">

        <div class="custom-services-title">

            <span class="custom-small-title">
                EVENT PLANNING
            </span>

            <h2>
                🎪 Custom Event Services
            </h2>

            <p>
                Have a special event in mind?
                Tell us your requirements and connect
                with the right event organizer.
            </p>

        </div>


        <!-- REQUEST BUTTON AT TOP -->

        <div class="custom-request-top">

            <a href="requestEvent.jsp">

                🎪 Request an Event

            </a>

        </div>

    </div>


    <!-- SERVICE CARDS -->

    <div class="custom-service-grid">


        <!-- BIRTHDAY -->

        <div class="custom-service-card">

            <div class="custom-icon">
                🎂
            </div>

            <h3>
                Birthday Party
            </h3>

            <p>
                Plan birthdays, private parties
                and special celebrations.
            </p>

        </div>


        <!-- WEDDING -->

        <div class="custom-service-card">

            <div class="custom-icon">
                💍
            </div>

            <h3>
                Wedding & Engagement
            </h3>

            <p>
                Get professional organizers
                for weddings and celebrations.
            </p>

        </div>


        <!-- COLLEGE -->

        <div class="custom-service-card">

            <div class="custom-icon">
                🎓
            </div>

            <h3>
                College Events
            </h3>

            <p>
                Plan fests, workshops,
                seminars and college programs.
            </p>

        </div>


        <!-- ENTERTAINMENT -->

        <div class="custom-service-card">

            <div class="custom-icon">
                🎤
            </div>

            <h3>
                Cultural & Entertainment
            </h3>

            <p>
                Music, dance, DJ and
                entertainment events.
            </p>

        </div>


    </div>

</section>


<!-- =====================================================
                TRENDING EVENTS
===================================================== -->

<section
    id="events"
    class="trending">


    <div class="section-title">


        <h2>

            🔥 Trending Events

        </h2>


        <p>

            Explore the most popular events happening now.

        </p>


    </div>



    <div class="event-container">


<%
while(rs.next()){


    String image =
        rs.getString("banner_image");


    if(image == null ||
       image.trim().equals("")){

        image = "image2.png";

    }

%>


        <!-- EVENT CARD -->


        <div class="event-card">


            <img
                src="images/<%=image%>"
                alt="Event">



            <div class="event-content">


                <span class="badge">

                    <%=rs.getString("category")%>

                </span>



                <h3>

                    <%=rs.getString("event_name")%>

                </h3>



                <p>

                    <%=rs.getString("subtitle")%>

                </p>



                <p>

                    📅

                    <%=rs.getString("event_date")%>

                </p>



                <p>

                    📍

                    <%=rs.getString("venue")%>

                </p>



                <a
                    href="eventDetails.jsp?id=<%=rs.getInt("event_id")%>">

                    View Details

                </a>


            </div>


        </div>


<%
}

rs.close();
ps.close();

conn.close();
%>


    </div>


</section>



<!-- =====================================================
                    STATISTICS
===================================================== -->

<section class="stats">


    <div class="stat-box">


        <h2>

            250+

        </h2>


        <p>

            Events Conducted

        </p>


    </div>



    <div class="stat-box">


        <h2>

            5000+

        </h2>


        <p>

            Participants

        </p>


    </div>



    <div class="stat-box">


        <h2>

            100+

        </h2>


        <p>

            Organizers

        </p>


    </div>



    <div class="stat-box">


        <h2>

            50+

        </h2>


        <p>

            Colleges Connected

        </p>


    </div>


</section>



<!-- =====================================================
                    FOOTER
===================================================== -->

<footer>


    <div class="footer-content">


        <h2>

            EventSphere

        </h2>


        <p>

            Connecting students through exciting events,
            competitions, workshops and cultural festivals.

        </p>


        <p>

            © 2026 EventSphere | All Rights Reserved

        </p>


    </div>


</footer>



<script src="js/dashboard.js"></script>


</body>

</html>