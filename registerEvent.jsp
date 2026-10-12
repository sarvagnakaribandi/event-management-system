<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

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


/* =====================================================
   DATABASE VARIABLES
   ===================================================== */

Connection conn = null;

PreparedStatement checkPs = null;
PreparedStatement eventPs = null;
PreparedStatement insertPs = null;

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
            "SELECT event_id, event_name, payment_type, event_fee, available_seats, event_date, registration_deadline " +
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

    String eventName =
        eventRs.getString("event_name");

    String paymentType =
        eventRs.getString("payment_type");

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
       PAYMENT STATUS
       ================================================= */

    String paymentStatus;


    if("Paid".equalsIgnoreCase(
        paymentType
    )){

        paymentStatus =
            "Pending";

    }
    else{

        paymentStatus =
            "Not Required";

    }


    /* =================================================
       PAYMENT SCREENSHOT
       ================================================= */

    String savedScreenshot =
        null;


    /*
       Only paid events need
       payment screenshot.
    */

    if("Paid".equalsIgnoreCase(
        paymentType
    )){


        if(paymentScreenshotData != null &&
           !paymentScreenshotData.trim().equals("")){


            /* =========================================
               PAYMENT UPLOAD FOLDER
               ========================================= */

            String uploadPath =
                application.getRealPath(
                    "/payment_uploads"
                );


            File uploadFolder =
                new File(
                    uploadPath
                );


            /*
               Create folder automatically
               if it doesn't exist.
            */

            if(!uploadFolder.exists()){

                uploadFolder.mkdirs();

            }


            /* =========================================
               REMOVE DATA URL PREFIX
               ========================================= */

            String[] parts =
                paymentScreenshotData.split(
                    ","
                );


            String base64Data =
                parts.length > 1
                ? parts[1]
                : parts[0];


            /* =========================================
               DECODE BASE64
               ========================================= */

            byte[] imageBytes =
                Base64.getDecoder().decode(
                    base64Data
                );


            /* =========================================
               DETERMINE FILE EXTENSION
               ========================================= */

            String extension =
                ".jpg";


            if(paymentScreenshotName != null){

                String lowerName =
                    paymentScreenshotName
                        .toLowerCase();


                if(lowerName.endsWith(
                    ".png"
                )){

                    extension =
                        ".png";

                }
                else if(
                    lowerName.endsWith(
                        ".jpeg"
                    )
                ){

                    extension =
                        ".jpeg";

                }
                else if(
                    lowerName.endsWith(
                        ".jpg"
                    )
                ){

                    extension =
                        ".jpg";

                }

            }


            /* =========================================
               UNIQUE FILE NAME
               ========================================= */

            savedScreenshot =
                "payment_" +
                UUID.randomUUID()
                    .toString() +
                extension;


            /* =========================================
               SAVE SCREENSHOT
               ========================================= */

            File screenshotFile =
                new File(

                    uploadFolder,

                    savedScreenshot
                );


            FileOutputStream output =
                null;


            try{

                output =
                    new FileOutputStream(
                        screenshotFile
                    );


                output.write(
                    imageBytes
                );

            }
            finally{

                if(output != null){

                    output.close();

                }

            }

        }

    }


    /* =================================================
       INSERT REGISTRATION
       ================================================= */

    String sql =

        "INSERT INTO registrations (" +

        "user_id," +
        "event_id," +
        "full_name," +
        "email," +
        "phone," +
        "gender," +
        "date_of_birth," +
        "city," +
        "state," +
        "country," +
        "emergency_contact," +
        "team_name," +
        "team_members," +
        "special_requirements," +
        "payment_status," +
        "payment_screenshot" +

        ") VALUES (" +

        "?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?" +

        ")";


    insertPs =
        conn.prepareStatement(
            sql,
            Statement.RETURN_GENERATED_KEYS
        );


    /* =================================================
       1. USER ID
       ================================================= */

    insertPs.setInt(
        1,
        userId
    );


    /* =================================================
       2. EVENT ID
       ================================================= */

    insertPs.setInt(
        2,
        eventIdInt
    );


    /* =================================================
       3. FULL NAME
       ================================================= */

    insertPs.setString(
        3,
        fullName
    );


    /* =================================================
       4. EMAIL
       ================================================= */

    insertPs.setString(
        4,
        email
    );


    /* =================================================
       5. PHONE
       ================================================= */

    insertPs.setString(
        5,
        phone
    );


    /* =================================================
       6. GENDER
       ================================================= */

    insertPs.setString(
        6,
        gender
    );


    /* =================================================
       7. DATE OF BIRTH
       ================================================= */

    if(dateOfBirth == null ||
       dateOfBirth.trim().equals("")){

        insertPs.setNull(
            7,
            Types.DATE
        );

    }
    else{

        insertPs.setDate(

            7,

            java.sql.Date.valueOf(
                dateOfBirth
            )
        );

    }


    /* =================================================
       8. CITY
       ================================================= */

    insertPs.setString(
        8,
        city
    );


    /* =================================================
       9. STATE
       ================================================= */

    insertPs.setString(
        9,
        state
    );


    /* =================================================
       10. COUNTRY
       ================================================= */

    insertPs.setString(
        10,
        country
    );


    /* =================================================
       11. EMERGENCY CONTACT
       ================================================= */

    insertPs.setString(
        11,
        emergencyContact
    );


    /* =================================================
       12. TEAM NAME
       ================================================= */

    insertPs.setString(
        12,
        teamName
    );


    /* =================================================
       13. TEAM MEMBERS
       ================================================= */

    if(teamMembers == null ||
       teamMembers.trim().equals("")){

        insertPs.setInt(
            13,
            1
        );

    }
    else{

        insertPs.setInt(

            13,

            Integer.parseInt(
                teamMembers
            )
        );

    }


    /* =================================================
       14. SPECIAL REQUIREMENTS
       ================================================= */

    insertPs.setString(
        14,
        specialRequirements
    );


    /* =================================================
       15. PAYMENT STATUS
       ================================================= */

    insertPs.setString(
        15,
        paymentStatus
    );


    /* =================================================
       16. PAYMENT SCREENSHOT
       ================================================= */

    if(savedScreenshot == null){

        insertPs.setNull(
            16,
            Types.VARCHAR
        );

    }
    else{

        insertPs.setString(
            16,
            savedScreenshot
        );

    }


    /* =================================================
       SAVE REGISTRATION
       ================================================= */

    int result =
        insertPs.executeUpdate();


    if(result > 0){
        // Decrement available seats atomically
        PreparedStatement seatPs = null;
        try {
            seatPs = conn.prepareStatement(
                "UPDATE events SET available_seats = GREATEST(0, available_seats - 1) WHERE event_id = ? AND available_seats > 0"
            );
            seatPs.setInt(1, eventIdInt);
            seatPs.executeUpdate();
        } catch(Exception ignored){
        } finally {
            DBConnection.close(seatPs);
        }

        response.sendRedirect(
            "registrationSuccess.jsp?id="
            + eventIdInt
        );

        return;

    }
    else{

        out.println(
            "<h2>Registration failed.</h2>"
        );

    }


}
catch(NumberFormatException e){

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
    DBConnection.close(checkRs);
    DBConnection.close(eventRs);
    DBConnection.close(checkPs);
    DBConnection.close(eventPs);
    DBConnection.close(insertPs);
    DBConnection.close(conn);
}
%>