<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<!DOCTYPE html>
<html lang="en">
<head>

<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>EventSphere</title>

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

    <a href="#">Home</a>

    <a href="#">Events</a>

    <a href="#">About</a>

    <a href="#">Features</a>

    <a href="#">Contact</a>

</nav>

     
    </header>



    <!-- Hero -->

    <section class="hero">

    <p class="small-title">
        ✦ THE UNIVERSE OF UNFORGETTABLE EVENTS ✦
    </p>

    <h1 class="main-title">
        EVENTSPHERE
    </h1>

    <p class="tagline">
        Where Every Event Creates a Memory
    </p>

    <div class="hero-btn">

        <a href="signup.jsp" class="btn1">
            Sign Up →
        </a>

        <a href="login.jsp" class="btn2">
            Login →
        </a>

    </div>

</section>

  
<footer>

© <%= java.time.Year.now() %> EventSphere | All Rights Reserved

</footer>
<script src="js/script.js"></script>
</body>
</html>