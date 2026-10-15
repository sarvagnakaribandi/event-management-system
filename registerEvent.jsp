<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>
<%@ page import="database.NotificationDAO" %>

<%
/* =====================================================
   LOGIN CHECK
   ===================================================== */

if(session.getAttribute("userId") == null){

    response.sendRedirect("login.jsp");
    return;
}


/* =====================================================
   GET USER ID
   ===================================================== */

Object userObject =
    session.getAttribute("userId");

int userId;

try{

    userId =
        Integer.parseInt(
            userObject.toString()
        );

}
catch(Exception e){

    response.sendRedirect("login.jsp");
    return;
}


/* =====================================================
   GET EVENT ID
   ===================================================== */

String eventId =
    request.getParameter("event_id");


if(eventId == null ||
   eventId.trim().equals("")){

    response.sendRedirect("userDashboard.jsp");
    return;
}


/* =====================================================
   PARTICIPANT DETAILS
   ===================================================== */

String fullName =
    request.getParameter("full_name");

String email =
    request.getParameter("email");

String phone =
    request.getParameter("phone");

String gender =
    request.getParameter("gender");

String dateOfBirth =
    request.getParameter("date_of_birth");

String city =
    request.getParameter("city");

String state =
    request.getParameter("state");

String country =
    request.getParameter("country");

String emergencyContact =
    request.getParameter("emergency_contact");

String teamName =
    request.getParameter("team_name");

String teamMembers =
    request.getParameter("team_members");

String specialRequirements =
    request.getParameter("special_requirements");


/* =====================================================
   PAYMENT SCREENSHOT DATA
   ===================================================== */

String paymentScreenshotData =
    request.getParameter(
        "payment_screenshot_data"
    );

String paymentScreenshotName =
    request.getParameter(
        "payment_screenshot_name"
    );

String paymentMethodParam =
    request.getParameter("payment_method");

String upiTransactionId =
    request.getParameter("upi_transaction_id");


/* =====================================================
   DATABASE VARIABLES
   ===================================================== */

Connection conn = null;

PreparedStatement checkPs = null;
PreparedStatement eventPs = null;
PreparedStatement decrPs = null;
PreparedStatement insertPs = null;
PreparedStatement payPs = null;

ResultSet checkRs = null;
ResultSet eventRs = null;


try{

    /* =================================================
       DATABASE CONNECTION
       ================================================= */

    conn = DBConnection.getConnection();


    /* =================================================
       EVENT ID
       ================================================= */

    int eventIdInt =
        Integer.parseInt(eventId);


    /* =================================================
       CHECK EVENT
       ================================================= */

    eventPs =
        conn.prepareStatement(
            "SELECT event_id, event_name, payment_type, event_fee, available_seats, event_date, registration_deadline, organizer_id " +
            "FROM events WHERE event_id=?"
        );

    eventPs.setInt(
        1,
        eventIdInt
    );

    eventRs =
        eventPs.executeQuery();

    if(!eventRs.next()){
        out.println(
            "<h2>Event not found.</h2>"
        );
        return;
    }

    int organizerId = eventRs.getInt("organizer_id");

    String eventName =
        eventRs.getString("event_name");

    String paymentType =
        eventRs.getString("payment_type");

    double eventFee =
        eventRs.getDouble("event_fee");

    int availableSeats = eventRs.getInt("available_seats");
    java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
    java.sql.Date eDate = eventRs.getDate("event_date");
    java.sql.Date eDeadline = eventRs.getDate("registration_deadline");

    if(eDate != null && eDate.before(today)){
        out.println("<script>alert('This event has already ended.'); history.back();</script>");
        return;
    }
    if(eDeadline != null && eDeadline.before(today)){
        out.println("<script>alert('Registration deadline has passed.'); history.back();</script>");
        return;
    }
    if(availableSeats <= 0){
        out.println("<script>alert('Sorry, this event is fully booked (0 seats remaining).'); history.back();</script>");
        return;
    }


    /* =================================================
       CHECK DUPLICATE REGISTRATION
       ================================================= */

    checkPs =
        conn.prepareStatement(

            "SELECT registration_id " +
            "FROM registrations " +
            "WHERE user_id=? " +
            "AND event_id=?"
        );


    checkPs.setInt(
        1,
        userId
    );


    checkPs.setInt(
        2,
        eventIdInt
    );


    checkRs =
        checkPs.executeQuery();


    if(checkRs.next()){

%>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>
    Already Registered
</title>

<style>

body{

    margin:0;

    background:#0b1220;

    color:white;

    font-family:Arial,sans-serif;

    display:flex;

    justify-content:center;

    align-items:center;

    min-height:100vh;

}


.box{

    width:90%;

    max-width:500px;

    background:#18243a;

    border:1px solid #34425c;

    border-radius:20px;

    padding:40px;

    text-align:center;

}


h1{

    color:#ffbd3d;

}


p{

    color:#cbd5e1;

    line-height:1.7;

}


a{

    display:inline-block;

    margin-top:20px;

    padding:13px 25px;

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
    Already Registered
</h1>

<p>

    You have already registered for

    <strong>
        <%=eventName%>
    </strong>.

</p>

<a href="userDashboard.jsp">

    Go to Dashboard

</a>

</div>

</body>

</html>

<%

        return;
    }


    /* =================================================
       PAYMENT STATUS & METHOD RESOLUTION (PHASE 4)
       ================================================= */

    String paymentStatus;
    String paymentMethod;
    String transactionId;
    String savedScreenshot = null;

    if ("Free".equalsIgnoreCase(paymentType) || eventFee <= 0) {
        paymentStatus = "Not Required";
        paymentMethod = "Free";
        transactionId = "FREE-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    } else {
        if ("Gateway".equalsIgnoreCase(paymentMethodParam)) {
            // Instant Sandbox Gateway Checkout
            paymentStatus = "Approved";
            paymentMethod = "Sandbox Gateway";
            transactionId = "SBX-" + UUID.randomUUID().toString().substring(0, 10).toUpperCase();
        } else {
            // Manual UPI / QR code transfer
            paymentStatus = "Pending";
            paymentMethod = "UPI";
            if (upiTransactionId != null && !upiTransactionId.trim().isEmpty()) {
                transactionId = upiTransactionId.trim();
            } else {
                transactionId = "UPI-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
            }

            // Save Screenshot if provided
            if (paymentScreenshotData != null && !paymentScreenshotData.trim().isEmpty()) {
                String uploadPath = application.getRealPath("/images");
                File uploadFolder = new File(uploadPath);
                if (!uploadFolder.exists()) {
                    uploadFolder.mkdirs();
                }

                String[] parts = paymentScreenshotData.split(",");
                String base64Data = parts.length > 1 ? parts[1] : parts[0];
                byte[] imageBytes = Base64.getDecoder().decode(base64Data);

                String extension = ".jpg";
                if (paymentScreenshotName != null) {
                    String lowerName = paymentScreenshotName.toLowerCase();
                    if (lowerName.endsWith(".png")) extension = ".png";
                    else if (lowerName.endsWith(".jpeg")) extension = ".jpeg";
                }

                savedScreenshot = "payment_" + UUID.randomUUID().toString() + extension;
                File screenshotFile = new File(uploadFolder, savedScreenshot);
                try (FileOutputStream output = new FileOutputStream(screenshotFile)) {
                    output.write(imageBytes);
                }
            }
        }
    }

    /* =================================================
       ATOMIC TRANSACTION: CAPACITY DECREMENT & BOOKING
       ================================================= */

    conn.setAutoCommit(false);

    // 1. Enforce atomic capacity decrement (guards against overbooking)
    decrPs = conn.prepareStatement(
        "UPDATE events SET available_seats = available_seats - 1 WHERE event_id = ? AND available_seats > 0"
    );
    decrPs.setInt(1, eventIdInt);
    int seatUpdated = decrPs.executeUpdate();
    decrPs.close();

    if (seatUpdated <= 0) {
        conn.rollback();
        out.println("<script>alert('Sorry, this event is fully booked! No seats remaining.'); history.back();</script>");
        return;
    }

    // 2. Insert into registrations table
    String sql =
        "INSERT INTO registrations (" +
        "user_id, event_id, full_name, email, phone, gender, date_of_birth, " +
        "city, state, country, emergency_contact, team_name, team_members, " +
        "special_requirements, payment_status, payment_screenshot, payment_method, transaction_id" +
        ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

    insertPs = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
    insertPs.setInt(1, userId);
    insertPs.setInt(2, eventIdInt);
    insertPs.setString(3, fullName);
    insertPs.setString(4, email);
    insertPs.setString(5, phone);
    insertPs.setString(6, gender);

    if (dateOfBirth == null || dateOfBirth.trim().isEmpty()) {
        insertPs.setNull(7, Types.DATE);
    } else {
        insertPs.setDate(7, java.sql.Date.valueOf(dateOfBirth));
    }

    insertPs.setString(8, city);
    insertPs.setString(9, state);
    insertPs.setString(10, country);
    insertPs.setString(11, emergencyContact);
    insertPs.setString(12, teamName);
    insertPs.setInt(13, (teamMembers == null || teamMembers.trim().isEmpty()) ? 1 : Integer.parseInt(teamMembers.trim()));
    insertPs.setString(14, specialRequirements);
    insertPs.setString(15, paymentStatus);

    if (savedScreenshot == null) {
        insertPs.setNull(16, Types.VARCHAR);
    } else {
        insertPs.setString(16, savedScreenshot);
    }

    insertPs.setString(17, paymentMethod);
    insertPs.setString(18, transactionId);

    int regResult = insertPs.executeUpdate();

    ResultSet genKeys = insertPs.getGeneratedKeys();
    int newRegistrationId = 0;
    if (genKeys.next()) {
        newRegistrationId = genKeys.getInt(1);
    }
    genKeys.close();

    // 3. Automatically populate payments table for every transaction
    payPs = conn.prepareStatement(
        "INSERT INTO payments (registration_id, amount, payment_status, payment_method, transaction_id) " +
        "VALUES (?, ?, ?, ?, ?)"
    );
    payPs.setInt(1, newRegistrationId);
    payPs.setDouble(2, ("Paid".equalsIgnoreCase(paymentType) && eventFee > 0) ? eventFee : 0.00);
    payPs.setString(3, paymentStatus);
    payPs.setString(4, paymentMethod);
    payPs.setString(5, transactionId);
    payPs.executeUpdate();
    payPs.close();

    // 4. In-App Notifications (Phase 7)
    if ("Pending".equalsIgnoreCase(paymentStatus)) {
        NotificationDAO.createNotification(conn, userId, "⏳ Payment Under Review", 
            "Your registration for '" + eventName + "' has been submitted and is awaiting organizer payment approval.", 
            "payment", "myRegistrations.jsp");
    } else {
        NotificationDAO.createNotification(conn, userId, "🎟️ Registration Confirmed!", 
            "Your booking for '" + eventName + "' is confirmed. Access your ticket from My Registrations.", 
            "booking", "myRegistrations.jsp");
    }

    if (organizerId > 0) {
        NotificationDAO.createNotification(conn, organizerId, "🎟️ New Registration", 
            fullName + " registered for your event '" + eventName + "'.", 
            "booking", "viewParticipants.jsp?event_id=" + eventIdInt);
    }

    // Commit atomic transaction
    conn.commit();

    response.sendRedirect("registrationSuccess.jsp?id=" + eventIdInt + "&reg_id=" + newRegistrationId);
    return;


}
catch(NumberFormatException e){
    if (conn != null) {
        try { conn.rollback(); } catch(Exception ignored){}
    }

%>

<!DOCTYPE html>

<html>

<head>

<title>
    Invalid Data
</title>

</head>

<body>

<h2 style="color:red;">
    Invalid Data
</h2>

<p>
    Please check the event ID,
    team size and date fields.
</p>

<a href="userDashboard.jsp">
    Back to Dashboard
</a>

</body>

</html>

<%

}
catch(SQLException e){
    if (conn != null) {
        try { conn.rollback(); } catch(Exception ignored){}
    }

%>

<!DOCTYPE html>

<html>

<head>

<title>
    Database Error
</title>

</head>

<body>

<h2 style="color:red;">
    Database Error
</h2>

<p>
    <%=e.getMessage()%>
</p>

<a href="userDashboard.jsp">
    Back to Dashboard
</a>

</body>

</html>

<%

}
catch(Exception e){
    if (conn != null) {
        try { conn.rollback(); } catch(Exception ignored){}
    }

%>

<!DOCTYPE html>

<html>

<head>

<title>
    Registration Error
</title>

</head>

<body>

<h2 style="color:red;">
    Registration Error
</h2>

<p>
    <%=e.getMessage()%>
</p>

<a href="userDashboard.jsp">
    Back to Dashboard
</a>

</body>

</html>

<%

}
finally{
    if (conn != null) {
        try { conn.setAutoCommit(true); } catch(Exception ignored){}
    }
    DBConnection.close(checkRs, eventRs, checkPs, eventPs, decrPs, insertPs, payPs, conn);
}
%>