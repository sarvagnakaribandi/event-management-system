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


/* =====================================================
   GET EVENT ID
   ===================================================== */

String eventIdString =
    request.getParameter("event_id");


if(eventIdString == null ||
   eventIdString.trim().equals("")){

    response.sendRedirect("manageEvents.jsp");
    return;
}


int eventId;

try{

    eventId =
        Integer.parseInt(eventIdString);

}
catch(Exception e){

    response.sendRedirect("manageEvents.jsp");
    return;
}


/* =====================================================
   GET EVENT DETAILS
   ===================================================== */

String eventName =
    request.getParameter("event_name");

String subtitle =
    request.getParameter("subtitle");

String category =
    request.getParameter("category");

String registrationStart =
    request.getParameter("registration_start");

String registrationDeadline =
    request.getParameter("registration_deadline");

String eventDate =
    request.getParameter("event_date");

String eventTime =
    request.getParameter("event_time");

String venue =
    request.getParameter("venue");

String mode =
    request.getParameter("mode");

String teamSize =
    request.getParameter("team_size");

String eligibility =
    request.getParameter("eligibility");

String rules =
    request.getParameter("rules");

String firstPrize =
    request.getParameter("first_prize");

String secondPrize =
    request.getParameter("second_prize");

String thirdPrize =
    request.getParameter("third_prize");

String certificate =
    request.getParameter("certificate");

String coordinatorName =
    request.getParameter("coordinator_name");

String coordinatorPhone =
    request.getParameter("coordinator_phone");

String coordinatorEmail =
    request.getParameter("coordinator_email");

String description =
    request.getParameter("description");

String bannerImage =
    request.getParameter("banner_image");


/* =====================================================
   PAYMENT DETAILS
   ===================================================== */

String paymentType =
    request.getParameter("payment_type");

String eventFee =
    request.getParameter("event_fee");

String upiId =
    request.getParameter("upi_id");

String qrImage =
    request.getParameter("qr_image");


/* =====================================================
   DEFAULT VALUES
   ===================================================== */

if(eventName == null)
    eventName = "";

if(subtitle == null)
    subtitle = "";

if(category == null)
    category = "";

if(registrationStart == null)
    registrationStart = "";

if(registrationDeadline == null)
    registrationDeadline = "";

if(eventDate == null)
    eventDate = "";

if(eventTime == null)
    eventTime = "";

if(venue == null)
    venue = "";

if(mode == null)
    mode = "";

if(teamSize == null)
    teamSize = "";

if(eligibility == null)
    eligibility = "";

if(rules == null)
    rules = "";

if(firstPrize == null)
    firstPrize = "";

if(secondPrize == null)
    secondPrize = "";

if(thirdPrize == null)
    thirdPrize = "";

if(certificate == null)
    certificate = "No";

if(coordinatorName == null)
    coordinatorName = "";

if(coordinatorPhone == null)
    coordinatorPhone = "";

if(coordinatorEmail == null)
    coordinatorEmail = "";

if(description == null)
    description = "";

if(bannerImage == null)
    bannerImage = "";

if(paymentType == null ||
   paymentType.trim().equals("")){

    paymentType = "Free";
}

if(upiId == null)
    upiId = "";

if(qrImage == null)
    qrImage = "";


/* =====================================================
   EVENT FEE
   ===================================================== */

double fee = 0.00;


try{

    if(eventFee != null &&
       !eventFee.trim().equals("")){

        fee =
            Double.parseDouble(eventFee);

    }

}
catch(NumberFormatException e){

    out.println(
        "<h2 style='color:red;'>Invalid Event Fee</h2>"
    );

    out.println(
        "<p>Please enter a valid number.</p>"
    );

    return;
}


/*
   If event is FREE,
   automatically remove payment details.
*/

if("Free".equalsIgnoreCase(paymentType)){

    fee = 0.00;

    upiId = "";

    qrImage = "";

}


/* =====================================================
   DATABASE
   ===================================================== */

Connection conn = null;
PreparedStatement ps = null;


try{

    conn = database.DBConnection.getConnection();


    /* =================================================
       IMPORTANT SECURITY

       UPDATE ONLY IF:

       event_id belongs to
       logged-in organizer.
       ================================================= */

    String sql =

        "UPDATE events SET " +

        "event_name=?," +
        "subtitle=?," +
        "category=?," +
        "registration_start=?," +
        "registration_deadline=?," +
        "event_date=?," +
        "event_time=?," +
        "venue=?," +
        "mode=?," +
        "team_size=?," +
        "eligibility=?," +
        "rules=?," +
        "first_prize=?," +
        "second_prize=?," +
        "third_prize=?," +
        "certificate=?," +
        "coordinator_name=?," +
        "coordinator_phone=?," +
        "coordinator_email=?," +
        "banner_image=?," +
        "description=?," +
        "event_fee=?," +
        "payment_type=?," +
        "upi_id=?," +
        "qr_image=? " +

        "WHERE event_id=? " +

        "AND organizer_id=?";


    ps =
        conn.prepareStatement(sql);


    /* =================================================
       EVENT DETAILS
       ================================================= */

    ps.setString(
        1,
        eventName
    );


    ps.setString(
        2,
        subtitle
    );


    ps.setString(
        3,
        category
    );


    /* =================================================
       REGISTRATION START
       ================================================= */

    if(registrationStart == null ||
       registrationStart.trim().equals("")){

        ps.setNull(
            4,
            Types.DATE
        );

    }
    else{

        ps.setDate(
            4,
            Date.valueOf(registrationStart)
        );

    }


    /* =================================================
       REGISTRATION DEADLINE
       ================================================= */

    if(registrationDeadline == null ||
       registrationDeadline.trim().equals("")){

        ps.setNull(
            5,
            Types.DATE
        );

    }
    else{

        ps.setDate(
            5,
            Date.valueOf(registrationDeadline)
        );

    }


    /* =================================================
       EVENT DATE
       ================================================= */

    if(eventDate == null ||
       eventDate.trim().equals("")){

        ps.setNull(
            6,
            Types.DATE
        );

    }
    else{

        ps.setDate(
            6,
            Date.valueOf(eventDate)
        );

    }


    /* =================================================
       EVENT TIME
       ================================================= */

    if(eventTime == null ||
       eventTime.trim().equals("")){

        ps.setNull(
            7,
            Types.TIME
        );

    }
    else{

        ps.setTime(
            7,
            Time.valueOf(eventTime)
        );

    }


    /* =================================================
       OTHER EVENT DETAILS
       ================================================= */

    ps.setString(
        8,
        venue
    );


    ps.setString(
        9,
        mode
    );


    /*
       team_size is VARCHAR.
       Example:
       single
       1-4 members
       2-5 members
    */

    ps.setString(
        10,
        teamSize
    );


    ps.setString(
        11,
        eligibility
    );


    ps.setString(
        12,
        rules
    );


    /* =================================================
       PRIZES
       ================================================= */

    ps.setString(
        13,
        firstPrize
    );


    ps.setString(
        14,
        secondPrize
    );


    ps.setString(
        15,
        thirdPrize
    );


    ps.setString(
        16,
        certificate
    );


    /* =================================================
       COORDINATOR
       ================================================= */

    ps.setString(
        17,
        coordinatorName
    );


    ps.setString(
        18,
        coordinatorPhone
    );


    ps.setString(
        19,
        coordinatorEmail
    );


    /* =================================================
       BANNER
       ================================================= */

    ps.setString(
        20,
        bannerImage
    );


    /* =================================================
       DESCRIPTION
       ================================================= */

    ps.setString(
        21,
        description
    );


    /* =================================================
       PAYMENT
       ================================================= */

    ps.setDouble(
        22,
        fee
    );


    ps.setString(
        23,
        paymentType
    );


    /* =================================================
       UPI
       ================================================= */

    if(upiId.trim().equals("")){

        ps.setNull(
            24,
            Types.VARCHAR
        );

    }
    else{

        ps.setString(
            24,
            upiId
        );

    }


    /* =================================================
      