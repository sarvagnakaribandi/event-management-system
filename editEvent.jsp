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

String role = (String) session.getAttribute("role");

if(role == null || !"Organizer".equalsIgnoreCase(role)){
    response.sendRedirect("login.jsp");
    return;
}


/* =====================================================
   LOGGED-IN ORGANIZER
   ===================================================== */

int organizerId = (Integer) session.getAttribute("userId");


/* =====================================================
   GET EVENT ID
   ===================================================== */

String idString = request.getParameter("id");

if(idString == null || idString.trim().equals("")){
    response.sendRedirect("manageEvents.jsp");
    return;
}

int eventId;

try {
    eventId = Integer.parseInt(idString);
}
catch(Exception e){
    response.sendRedirect("manageEvents.jsp");
    return;
}


/* =====================================================
   DATABASE
   ===================================================== */

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {

    conn = database.DBConnection.getConnection();


    /*
       IMPORTANT SECURITY:
       Event must belong to logged-in organizer.
    */

    String sql =
        "SELECT * FROM events " +
        "WHERE event_id=? AND organizer_id=?";

    ps = conn.prepareStatement(sql);

    ps.setInt(1, eventId);
    ps.setInt(2, organizerId);

    rs = ps.executeQuery();


    if(rs.next()){

        String category = rs.getString("category");
        String mode = rs.getString("mode");
        String certificate = rs.getString("certificate");
        String paymentType = rs.getString("payment_type");

        String bannerImage = rs.getString("banner_image");
        String upiId = rs.getString("upi_id");
        String qrImage = rs.getString("qr_image");

        if(bannerImage == null){
            bannerImage = "";
        }

        if(upiId == null){
            upiId = "";
        }

        if(qrImage == null){
            qrImage = "";
        }
%>

<!DOCTYPE html>
<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>Edit Event | EventSphere</title>

<link rel="stylesheet"
      href="css/editEvent.css">

</head>

<body>

<div class="container">

    <!-- HEADER -->

    <div class="page-header">

        <div>

            <h1>Edit Event</h1>

            <p>
                Update your event details
            </p>

        </div>

        <a href="manageEvents.jsp"
           class="back-btn">

            ← Back to My Events

        </a>

    </div>


    <!-- FORM -->

    <div class="form-card">

        <form action="updateEvent.jsp"
              method="post">


            <!-- EVENT ID -->

            <input type="hidden"
                   name="event_id"
                   value="<%=rs.getInt("event_id")%>">


            <!-- =========================
                 EVENT DETAILS
                 ========================= -->

            <div class="section">

                <h2>Event Details</h2>


                <label>Event Name</label>

                <input
                    type="text"
                    name="event_name"
                    value="<%=rs.getString("event_name")%>"
                    required>


                <label>Subtitle</label>

                <input
                    type="text"
                    name="subtitle"
                    value="<%=rs.getString("subtitle")%>">


                <label>Category</label>

                <select name="category" required>

                    <option value="Gaming"
                        <%= "Gaming".equals(category) ? "selected" : "" %>>
                        Gaming
                    </option>

                    <option value="Technical"
                        <%= "Technical".equals(category) ? "selected" : "" %>>
                        Technical
                    </option>

                    <option value="Cultural"
                        <%= "Cultural".equals(category) ? "selected" : "" %>>
                        Cultural
                    </option>

                    <option value="Sports"
                        <%= "Sports".equals(category) ? "selected" : "" %>>
                        Sports
                    </option>

                    <option value="Music"
                        <%= "Music".equals(category) ? "selected" : "" %>>
                        Music
                    </option>

                    <option value="Dance"
                        <%= "Dance".equals(category) ? "selected" : "" %>>
                        Dance
                    </option>

                    <option value="Singing"
                        <%= "Singing".equals(category) ? "selected" : "" %>>
                        Singing
                    </option>

                    <option value="Workshop"
                        <%= "Workshop".equals(category) ? "selected" : "" %>>
                        Workshop
                    </option>

                    <option value="Competition"
                        <%= "Competition".equals(category) ? "selected" : "" %>>
                        Competition
                    </option>

                    <option value="Fun Games"
                        <%= "Fun Games".equals(category) ? "selected" : "" %>>
                        Fun Games
                    </option>

                </select>


                <div class="grid">

                    <div>

                        <label>
                            Registration Start
                        </label>

                        <input
                            type="date"
                            name="registration_start"
                            value="<%=rs.getDate("registration_start")%>">

                    </div>


                    <div>

                        <label>
                            Registration Deadline
                        </label>

                        <input
                            type="date"
                            name="registration_deadline"
                            value="<%=rs.getDate("registration_deadline")%>">

                    </div>


                    <div>

                        <label>
                            Event Date
                        </label>

                        <input
                            type="date"
                            name="event_date"
                            value="<%=rs.getDate("event_date")%>"
                            required>

                    </div>


                    <div>

                        <label>
                            Event Time
                        </label>

                        <input
                            type="time"
                            name="event_time"
                            value="<%=rs.getTime("event_time")%>"
                            required>

                    </div>

                </div>

            </div>


            <!-- =========================
                 LOCATION
                 ========================= -->

            <div class="section">

                <h2>Location & Format</h2>


                <label>Venue</label>

                <input
                    type="text"
                    name="venue"
                    value="<%=rs.getString("venue")%>">


                <div class="grid">

                    <div>

                        <label>Mode</label>

                        <select name="mode">

                            <option value="Online"
                                <%= "Online".equals(mode)
                                    ? "selected" : "" %>>
                                Online
                            </option>

                            <option value="Offline"
                                <%= "Offline".equals(mode)
                                    ? "selected" : "" %>>
                                Offline
                            </option>

                        </select>

                    </div>


                    <div>

                        <label>Team Size</label>

                        <!-- IMPORTANT:
                             team_size is VARCHAR
                             therefore getString()
                        -->

                        <input
                            type="text"
                            name="team_size"
                            value="<%=rs.getString("team_size")%>">

                    </div>

                </div>

            </div>


            <!-- =========================
                 ELIGIBILITY & RULES
                 ========================= -->

            <div class="section">

                <h2>Eligibility & Rules</h2>


                <label>Eligibility</label>

                <textarea
                    name="eligibility"><%=rs.getString("eligibility")%></textarea>


                <label>Rules & Guidelines</label>

                <textarea
                    name="rules"><%=rs.getString("rules")%></textarea>

            </div>


            <!-- =========================
                 PRIZES
                 ========================= -->

            <div class="section">

                <h2>Prize Details</h2>


                <label>First Prize</label>

                <input
                    type="text"
                    name="first_prize"
                    value="<%=rs.getString("first_prize")%>">


                <label>Second Prize</label>

                <input
                    type="text"
                    name="second_prize"
                    value="<%=rs.getString("second_prize")%>">


                <label>Third Prize</label>

                <input
                    type="text"
                    name="third_prize"
                    value="<%=rs.getString("third_prize")%>">


                <label>Certificate</label>

                <select name="certificate">

                    <option value="Yes"
                        <%= "Yes".equals(certificate)
                            ? "selected" : "" %>>
                        Yes
                    </option>

                    <option value="No"
                        <%= "No".equals(certificate)
                            ? "selected" : "" %>>
                        No
                    </option>

                </select>

            </div>


            <!-- =========================
                 COORDINATOR
                 ========================= -->

            <div class="section">

                <h2>Coordinator Details</h2>


                <label>Coordinator Name</label>

                <input
                    type="text"
                    name="coordinator_name"
                    value="<%=rs.getString("coordinator_name")%>">


                <label>Coordinator Phone</label>

                <input
                    type="text"
                    name="coordinator_phone"
                    value="<%=rs.getString("coordinator_phone")%>">


                <label>Coordinator Email</label>

                <input
                    type="email"
                    name="coordinator_email"
                    value="<%=rs.getString("coordinator_email")%>">

            </div>


            <!-- =========================
                 DESCRIPTION
                 ========================= -->

            <div class="section">

                <h2>Description</h2>

                <textarea
                    name="description"
                    rows="7"><%=rs.getString("description")%></textarea>

            </div>


            <!-- =========================
                 BANNER
                 ========================= -->

            <div class="section">

                <h2>Banner Image</h2>

                <label>Banner Image Filename</label>

                <input
                    type="text"
                    name="banner_image"
                    value="<%=bannerImage%>"
                    placeholder="Example: event1.png">

            </div>


            <!-- =========================
                 PAYMENT
                 ========================= -->

            <div class="section">

                <h2>Payment Details</h2>


                <label>Payment Type</label>

                <select
                    name="payment_type"
                    id="payment_type"
                    onchange="togglePaymentFields()">

                    <option value="Free"
                        <%= "Free".equals(paymentType)
                            ? "selected" : "" %>>
                        Free
                    </option>

                    <option value="Paid"
                        <%= "Paid".equals(paymentType)
                            ? "selected" : "" %>>
                        Paid
                    </option>

                </select>


                <div id="paidFields"
                     class="payment-box"
                     style="<%= "Paid".equals(paymentType)
                            ? "" : "display:none;" %>">

                    <h3>
                        Paid Event Details
                    </h3>


                    <label>
                        Event Fee (₹)
                    </label>

                    <input
                        type="number"
                        name="event_fee"
                        min="0"
                        step="0.01"
                        value="<%=rs.getDouble("event_fee")%>">


                    <label>
                        UPI ID
                    </label>

                    <input
                        type="text"
                        name="upi_id"
                        value="<%=upiId%>"
                        placeholder="example@upi">


                    <label>
                        QR Image Filename
                    </label>

                    <input
                        type="text"
                        name="qr_image"
                        value="<%=qrImage%>"
                        placeholder="Example: payment1.png">


                    <% if(!qrImage.trim().equals("")){ %>

                    <div class="current-qr">

                        <p>
                            Current QR Code
                        </p>

                        <img
                            src="images/<%=qrImage%>"
                            alt="Current Payment QR">

                    </div>

                    <% } %>

                </div>

            </div>


            <!-- BUTTONS -->

            <div class="button-row">

                <a
                    href="manageEvents.jsp"
                    class="cancel-btn">

                    Cancel

                </a>


                <button
                    type="submit"
                    class="save-btn">

                    💾 Save Changes

                </button>

            </div>


        </form>

    </div>

</div>


<script>

function togglePaymentFields(){

    const paymentType =
        document.getElementById("payment_type").value;

    const paidFields =
        document.getElementById("paidFields");

    if(paymentType === "Paid"){

        paidFields.style.display = "block";

    }
    else{

        paidFields.style.display = "none";

    }

}

</script>

</body>

</html>

<%

    }
    else{

%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>Access Denied | EventSphere</title>

<link rel="stylesheet"
      href="css/editEvent.css">

</head>

<body>

<div class="access-denied">

    <div class="denied-card">

        <div class="denied-icon">
            🔒
        </div>

        <h1>
            Access Denied
        </h1>

        <p>
            You cannot edit this event.
        </p>

        <p>
            This event belongs to another organizer.
        </p>

        <a href="manageEvents.jsp">
            ← Back to My Events
        </a>

    </div>

</div>

</body>

</html>

<%

    }

}
catch(Exception e){

    out.println(
        "<h3 style='color:red;'>"
        + "Error loading event: "
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