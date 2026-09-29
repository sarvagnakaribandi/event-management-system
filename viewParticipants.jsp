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
   ORGANIZER ID
   ===================================================== */

int organizerId =
    Integer.parseInt(
        session.getAttribute("userId").toString()
    );


/* =====================================================
   EVENT ID
   ===================================================== */

String eventIdParam =
    request.getParameter("id");

if(eventIdParam == null ||
   eventIdParam.trim().equals("")){

    response.sendRedirect("manageEvents.jsp");
    return;
}

int eventId;

try{

    eventId =
        Integer.parseInt(eventIdParam);

}
catch(Exception e){

    response.sendRedirect("manageEvents.jsp");
    return;
}


Connection conn = null;

PreparedStatement eventPs = null;
PreparedStatement participantPs = null;

ResultSet eventRs = null;
ResultSet participantRs = null;


try{

    Class.forName(
        "com.mysql.cj.jdbc.Driver"
    );


    conn = DriverManager.getConnection(
        "jdbc:mysql://localhost:3306/eventsphere",
        "root",
        ""
    );


    /* =================================================
       CHECK EVENT OWNERSHIP
       ================================================= */

    String eventSql =
        "SELECT event_name " +
        "FROM events " +
        "WHERE event_id=? " +
        "AND organizer_id=?";


    eventPs =
        conn.prepareStatement(eventSql);

    eventPs.setInt(1, eventId);
    eventPs.setInt(2, organizerId);

    eventRs =
        eventPs.executeQuery();


    /* =================================================
       EVENT DOES NOT BELONG TO ORGANIZER
       ================================================= */

    if(!eventRs.next()){

%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>Access Denied</title>

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

    text-align:center;

    background:#18243a;

    border:1px solid #34425c;

    border-radius:18px;
}

h1{

    color:#ffbd3d;
}

p{

    color:#cbd5e1;

    line-height:1.6;
}

a{

    display:inline-block;

    margin-top:20px;

    padding:12px 24px;

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
    🔒 Access Denied
</h1>

<p>
    This event belongs to another organizer.
</p>

<p>
    You can only view participants
    for your own events.
</p>

<a href="manageEvents.jsp">
    ← Back to My Events
</a>

</div>

</body>

</html>

<%

        return;
    }


    String eventName =
        eventRs.getString("event_name");


    /* =================================================
       GET PARTICIPANTS
       ================================================= */

    String participantSql =

        "SELECT " +

        "registration_id," +
        "full_name," +
        "email," +
        "phone," +
        "gender," +
        "team_name," +
        "team_members," +
        "registration_date," +
        "payment_status," +
        "payment_screenshot " +

        "FROM registrations " +

        "WHERE event_id=? " +

        "ORDER BY registration_id DESC";


    participantPs =
        conn.prepareStatement(
            participantSql
        );

    participantPs.setInt(
        1,
        eventId
    );

    participantRs =
        participantPs.executeQuery();

%>

<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>
    Participants - <%=eventName%>
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

}


/* ================= NAVBAR ================= */

.navbar{

    background:#121c2e;

    border-bottom:1px solid #293851;

    padding:18px 5%;

    display:flex;

    justify-content:space-between;

    align-items:center;

}

.logo{

    font-size:25px;

    font-weight:bold;

    color:#c76cff;

}

.navbar a{

    color:#cbd5e1;

    text-decoration:none;

    margin-left:20px;

}

.navbar a:hover{

    color:white;

}


/* ================= CONTAINER ================= */

.container{

    width:94%;

    max-width:1300px;

    margin:35px auto;

}

.back{

    color:#00eaff;

    text-decoration:none;

    display:inline-block;

    margin-bottom:20px;

}

h1{

    margin-bottom:8px;

}

.subtitle{

    color:#9eabc0;

    margin-bottom:25px;

}


/* ================= TABLE ================= */

.table-box{

    background:#18243a;

    border:1px solid #34425c;

    border-radius:18px;

    overflow-x:auto;

}

table{

    width:100%;

    min-width:1000px;

    border-collapse:collapse;

}

th{

    background:#202f47;

    color:#cbd5e1;

    padding:15px;

    text-align:left;

}

td{

    padding:15px;

    border-top:1px solid #2d3c54;

}

tr:hover{

    background:#1d2b42;

}


/* ================= STATUS ================= */

.status{

    display:inline-block;

    padding:7px 12px;

    border-radius:20px;

    font-size:12px;

    font-weight:bold;

}

.pending{

    background:#493b15;

    color:#ffd34d;

}

.approved{

    background:#123c2c;

    color:#55e79d;

}

.rejected{

    background:#451d28;

    color:#ff7187;

}

.not-required{

    background:#163a4a;

    color:#4fdfff;

}


/* ================= BUTTONS ================= */

.actions{

    display:flex;

    gap:7px;

    flex-wrap:wrap;

}

.btn{

    text-decoration:none;

    padding:8px 12px;

    border-radius:8px;

    font-size:12px;

    font-weight:bold;

}

.screenshot{

    background:#24344d;

    color:#00eaff;

}

.approve{

    background:#159957;

    color:white;

}

.reject{

    background:#d33852;

    color:white;

}

.no-file{

    color:#78869c;

    font-size:13px;

}


/* ================= EMPTY ================= */

.empty{

    text-align:center;

    padding:60px;

    color:#9eabc0;

}

</style>

</head>


<body>


<!-- ================= NAVBAR ================= -->

<div class="navbar">

<div class="logo">
    EventSphere
</div>

<div>

<a href="organizerDashboard.jsp">
    Dashboard
</a>

<a href="manageEvents.jsp">
    Manage Events
</a>

<a href="logout.jsp">
    Logout
</a>

</div>

</div>


<!-- ================= MAIN ================= -->

<div class="container">


<a href="manageEvents.jsp"
   class="back">

    ← Back to My Events

</a>


<h1>
    Participants
</h1>

<p class="subtitle">

    Event:
    <strong>
        <%=eventName%>
    </strong>

</p>


<div class="table-box">

<table>

<thead>

<tr>

<th>Name</th>

<th>Email</th>

<th>Phone</th>

<th>Gender</th>

<th>Team</th>

<th>Team Members</th>

<th>Registered On</th>

<th>Payment</th>

<th>Actions</th>

</tr>

</thead>


<tbody>

<%

boolean found = false;


while(participantRs.next()){

    found = true;


    String paymentStatus =
        participantRs.getString(
            "payment_status"
        );


    String statusClass =
        "pending";


    if("Approved".equalsIgnoreCase(
        paymentStatus
    )){

        statusClass =
            "approved";

    }
    else if(
        "Rejected".equalsIgnoreCase(
            paymentStatus
        )
    ){

        statusClass =
            "rejected";

    }
    else if(
        "Not Required".equalsIgnoreCase(
            paymentStatus
        )
    ){

        statusClass =
            "not-required";

    }


    String screenshot =
        participantRs.getString(
            "payment_screenshot"
        );

%>

<tr>


<td>

<strong>
    <%=participantRs.getString(
        "full_name"
    )%>
</strong>

</td>


<td>

<%=participantRs.getString(
    "email"
)%>

</td>


<td>

<%=participantRs.getString(
    "phone"
)%>

</td>


<td>

<%=participantRs.getString(
    "gender"
)%>

</td>


<td>

<%

String team =
    participantRs.getString(
        "team_name"
    );

if(team == null ||
   team.trim().equals("")){

    out.print("Individual");

}
else{

    out.print(team);

}

%>

</td>


<td>

<%=participantRs.getInt(
    "team_members"
)%>

</td>


<td>

<%=participantRs.getTimestamp(
    "registration_date"
)%>

</td>


<td>

<span class="status <%=statusClass%>">

<%
if("Approved".equalsIgnoreCase(
    paymentStatus
)){
%>

    ✅ Approved

<%
}
else if(
    "Rejected".equalsIgnoreCase(
        paymentStatus
    )
){
%>

    ❌ Rejected

<%
}
else if(
    "Not Required".equalsIgnoreCase(
        paymentStatus
    )
){
%>

    🎉 Not Required

<%
}
else{
%>

    🟡 Pending

<%
}
%>

</span>

</td>


<td>

<div class="actions">


<%
if(screenshot != null &&
   !screenshot.trim().equals("")){
%>

<a
    href="images/<%=screenshot%>"
    target="_blank"
    class="btn screenshot">

    🧾 Screenshot

</a>


<%
}
else{
%>

<span class="no-file">
    No screenshot
</span>

<%
}
%>


<%
if("Pending".equalsIgnoreCase(
    paymentStatus
)){
%>

<a
    href="approvePayment.jsp?id=<%=participantRs.getInt("registration_id")%>&event_id=<%=eventId%>"
    class="btn approve"
    onclick="return confirm('Approve this payment?');">

    ✓ Approve

</a>

<a
    href="rejectPayment.jsp?id=<%=participantRs.getInt("registration_id")%>&event_id=<%=eventId%>"
    class="btn reject"
    onclick="return confirm('Reject this payment?');">

    ✕ Reject

</a>

<%
}
%>


</div>

</td>


</tr>


<%
}
%>


<%
if(!found){
%>

<tr>

<td colspan="9"
    class="empty">

    No participants registered
    for this event yet.

</td>

</tr>

<%
}
%>


</tbody>

</table>

</div>


</div>


</body>

</html>

<%

}
catch(Exception e){

    out.println(
        "<h2 style='color:red;padding:30px;'>"
        + "Error loading participants"
        + "</h2>"
    );

    out.println(
        "<p style='padding:0 30px;'>"
        + e.getMessage()
        + "</p>"
    );

}
finally{

    try{

        if(participantRs != null)
            participantRs.close();

    }
    catch(Exception e){}


    try{

        if(eventRs != null)
            eventRs.close();

    }
    catch(Exception e){}


    try{

        if(participantPs != null)
            participantPs.close();

    }
    catch(Exception e){}


    try{

        if(eventPs != null)
            eventPs.close();

    }
    catch(Exception e){}


    try{

        if(conn != null)
            conn.close();

    }
    catch(Exception e){}

}

%>