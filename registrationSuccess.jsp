<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%
if(session.getAttribute("userId") == null){

    response.sendRedirect("login.jsp");
    return;
}
%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>
    Registration Successful
</title>

<style>

*{
    box-sizing:border-box;
}

body{

    margin:0;

    background:#0b1220;

    color:white;

    font-family:Arial,sans-serif;

    min-height:100vh;

    display:flex;

    align-items:center;

    justify-content:center;
}


.success-box{

    width:90%;

    max-width:550px;

    background:#18243a;

    border:1px solid #34425c;

    border-radius:20px;

    padding:45px 30px;

    text-align:center;
}


.success-icon{

    font-size:70px;

    margin-bottom:15px;
}


h1{

    color:#55e79d;

    margin-bottom:15px;
}


p{

    color:#cbd5e1;

    line-height:1.7;

    font-size:17px;
}


.buttons{

    margin-top:30px;

    display:flex;

    gap:15px;

    justify-content:center;

    flex-wrap:wrap;
}


.buttons a{

    text-decoration:none;

    padding:13px 24px;

    border-radius:10px;

    font-weight:bold;
}


.dashboard{

    background:#7c3aed;

    color:white;
}


.registrations{

    background:#24344d;

    color:#00eaff;

    border:1px solid #3b506d;
}

</style>

</head>


<body>


<div class="success-box">


<div class="success-icon">

    ✅

</div>


<h1>

    Registration Successful!

</h1>


<p>

    Your registration has been submitted successfully.

</p>


<p>

    If this is a paid event, your payment
    will remain <strong>Pending</strong>
    until the organizer verifies it.

</p>


<div class="buttons">


<a href="userDashboard.jsp"
   class="dashboard">

    Go to Dashboard

</a>


<a href="myRegistrations.jsp"
   class="registrations">

    My Registrations

</a>


</div>


</div>


</body>

</html>