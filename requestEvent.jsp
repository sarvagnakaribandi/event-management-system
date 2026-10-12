<%@ page language="java" contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
if(session.getAttribute("userId") == null){
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(
    session.getAttribute("userId").toString()
);

Connection conn = DBConnection.getConnection();

PreparedStatement typePs = conn.prepareStatement(
    "SELECT * FROM event_types ORDER BY event_type_name"
);

ResultSet typeRs = typePs.executeQuery();
%>

<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>Request an Event - EventSphere</title>

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
      rel="stylesheet">

<style>

*{
    margin:0;
    padding:0;
    box-sizing:border-box;
}

body{

    font-family:'Poppins',Arial,sans-serif;

    min-height:100vh;

    background:
        linear-gradient(
            rgba(5,8,20,0.72),
            rgba(5,8,20,0.72)
        ),
        url("images/cosmic-bg.png");

    background-size:cover;

    background-position:center;

    background-attachment:fixed;

    color:white;

}


/* ================= CONTAINER ================= */

.container{

    width:90%;

    max-width:950px;

    margin:50px auto;

}


/* ================= BACK BUTTON ================= */

.back-btn{

    display:inline-block;

    margin-bottom:25px;

    color:#cbb8ff;

    text-decoration:none;

    font-size:14px;

}

.back-btn:hover{

    color:#ffffff;

}


/* ================= FORM CARD ================= */

.form-card{

    background:rgba(13,20,38,0.88);

    border:1px solid rgba(255,255,255,0.12);

    border-radius:25px;

    padding:45px;

    box-shadow:
        0 20px 50px rgba(0,0,0,0.35);

    backdrop-filter:blur(15px);

}


/* ================= HEADING ================= */

.form-card h1{

    font-size:36px;

    color:#FFD369;

    margin-bottom:10px;

}

.subtitle{

    color:#aeb8cc;

    line-height:1.7;

    margin-bottom:35px;

}


/* ================= FORM ================= */

.form-group{

    margin-bottom:22px;

}

label{

    display:block;

    margin-bottom:8px;

    color:#ffffff;

    font-size:14px;

    font-weight:500;

}


input,
select,
textarea{

    width:100%;

    padding:13px 15px;

    border-radius:10px;

    border:1px solid #394761;

    background:#10192b;

    color:white;

    outline:none;

    font-family:inherit;

}


input:focus,
select:focus,
textarea:focus{

    border-color:#8E3DFF;

    box-shadow:
        0 0 0 2px rgba(142,61,255,0.15);

}


select option{

    background:#10192b;

    color:white;

}


textarea{

    min-height:130px;

    resize:vertical;

}


/* ================= TWO COLUMNS ================= */

.form-row{

    display:grid;

    grid-template-columns:1fr 1fr;

    gap:20px;

}


/* ================= BUTTON ================= */

.submit-btn{

    width:100%;

    padding:15px;

    border:none;

    border-radius:30px;

    background:
        linear-gradient(
            135deg,
            #FF4FA1,
            #8E3DFF
        );

    color:white;

    font-size:15px;

    font-weight:600;

    cursor:pointer;

    transition:0.3s;

}

.submit-btn:hover{

    transform:translateY(-2px);

    box-shadow:
        0 10px 30px rgba(142,61,255,0.35);

}


/* ================= MOBILE ================= */

@media(max-width:650px){

    .container{

        width:94%;

        margin:25px auto;

    }

    .form-card{

        padding:25px;

    }

    .form-card h1{

        font-size:28px;

    }

    .form-row{

        grid-template-columns:1fr;

        gap:0;

    }

}

</style>

</head>


<body>


<div class="container">


<a href="userDashboard.jsp"
   class="back-btn">

    ← Back to Dashboard

</a>


<div class="form-card">


<h1>
    🎪 Request an Event
</h1>


<p class="subtitle">

    Tell us about the event you want to organize.
    Our specialized organizers can review your
    requirements and provide an event plan and
    estimated cost.

</p>


<form action="submitEventRequest.jsp"
      method="post">


<!-- ================= EVENT TYPE ================= -->

<div class="form-group">

<label>
    Event Type *
</label>

<select name="event_type_id"
        required>

<option value="">
    Select Event Type
</option>

<%
while(typeRs.next()){
%>

<option value="<%=typeRs.getInt("event_type_id")%>">

    <%=typeRs.getString("event_type_name")%>

</option>

<%
}
%>

</select>

</div>


<!-- ================= EVENT TITLE ================= -->

<div class="form-group">

<label>
    Event Title *
</label>

<input type="text"
       name="event_title"
       placeholder="Example: My Birthday Party"
       required>

</div>


<!-- ================= DATE & TIME ================= -->

<div class="form-row">


<div class="form-group">

<label>
    Event Date *
</label>

<input type="date"
       name="event_date"
       required>

</div>


<div class="form-group">

<label>
    Preferred Time
</label>

<input type="time"
       name="event_time">

</div>


</div>


<!-- ================= LOCATION & GUESTS ================= -->

<div class="form-row">


<div class="form-group">

<label>
    Location *
</label>

<input type="text"
       name="location"
       placeholder="Example: Hyderabad"
       required>

</div>


<div class="form-group">

<label>
    Expected Guests *
</label>

<input type="number"
       name="guest_count"
       min="1"
       placeholder="Example: 50"
       required>

</div>


</div>


<!-- ================= BUDGET ================= -->

<div class="form-group">

<label>
    Estimated Budget (₹)
</label>

<input type="number"
       name="budget"
       min="0"
       step="0.01"
       placeholder="Example: 50000">

</div>


<!-- ================= REQUIREMENTS ================= -->

<div class="form-group">

<label>
    Event Requirements
</label>

<textarea name="requirements"
          placeholder="Example: Decoration, catering, photography, DJ, cake, stage setup..."></textarea>

</div>


<!-- ================= ADDITIONAL NOTES ================= -->

<div class="form-group">

<label>
    Additional Requirements / Notes
</label>

<textarea name="additional_notes"
          placeholder="Tell the organizer anything else they should know..."></textarea>

</div>


<!-- ================= SUBMIT ================= -->

<button type="submit"
        class="submit-btn">

    🎪 Submit Event Request

</button>


</form>


</div>


</div>


</body>

</html>

<%
DBConnection.close(typeRs, typePs, conn);
%>