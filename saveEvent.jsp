<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Base64" %>

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
    (Integer) session.getAttribute("userId");


/* =====================================================
   EVENT DETAILS
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


/* =====================================================
   PAYMENT DETAILS
   ===================================================== */

String paymentType =
    request.getParameter("payment_type");

String eventFee =
    request.getParameter("event_fee");

String upiId =
    request.getParameter("upi_id");


/* =====================================================
   BANNER BASE64 DATA
   ===================================================== */

String bannerImageData =
    request.getParameter("banner_image_data");

String bannerOriginalName =
    request.getParameter("banner_image_name");


/* =====================================================
   QR BASE64 DATA
   ===================================================== */

String qrImageData =
    request.getParameter("qr_image_data");

String qrOriginalName =
    request.getParameter("qr_image_name");


/* =====================================================
   DEFAULT IMAGE FILENAMES
   ===================================================== */

String bannerImage = null;

String qrImage = null;


Connection conn = null;

PreparedStatement ps = null;


try{


    /* =================================================
       DATABASE CONNECTION
       ================================================= */

    Class.forName(
        "com.mysql.cj.jdbc.Driver"
    );


    conn = DriverManager.getConnection(

        "jdbc:mysql://localhost:3306/eventsphere",

        "root",

        ""
    );


    /* =================================================
       PAYMENT TYPE
       ================================================= */

    if(paymentType == null ||
       paymentType.trim().equals("")){

        paymentType = "Free";

    }


    /* =================================================
       EVENT FEE
       ================================================= */

    double fee = 0.00;


    if(eventFee != null &&
       !eventFee.trim().equals("")){

        fee =
            Double.parseDouble(eventFee);

    }


    /* =================================================
       FREE EVENT
       ================================================= */

    if("Free".equalsIgnoreCase(paymentType)){

        fee = 0.00;

        upiId = null;

        qrImageData = null;

        qrOriginalName = null;

    }


    /* =================================================
       IMAGES DIRECTORY
       ================================================= */

    String imagePath =
        application.getRealPath("/images");


    File imageFolder =
        new File(imagePath);


    if(!imageFolder.exists()){

        imageFolder.mkdirs();

    }


    /* =================================================
       SAVE BANNER IMAGE
       ================================================= */

    if(bannerImageData != null &&
       !bannerImageData.trim().equals("")){


        try{

            String[] parts =
                bannerImageData.split(",");


            String base64Data =
                parts.length > 1
                ? parts[1]
                : parts[0];


            byte[] imageBytes =
                Base64.getDecoder().decode(
                    base64Data
                );


            String extension =
                ".jpg";


            if(bannerOriginalName != null){

                String lower =
                    bannerOriginalName.toLowerCase();


                if(lower.endsWith(".png")){

                    extension = ".png";

                }
                else if(lower.endsWith(".jpeg")){

                    extension = ".jpeg";

                }
                else if(lower.endsWith(".jpg")){

                    extension = ".jpg";

                }

            }


            bannerImage =
                "banner_" +
                UUID.randomUUID().toString() +
                extension;


            File bannerFile =
                new File(
                    imageFolder,
                    bannerImage
                );


            FileOutputStream bannerOutput =
                new FileOutputStream(
                    bannerFile
                );


            bannerOutput.write(
                imageBytes
            );


            bannerOutput.close();

        }
        catch(Exception imageError){

            throw new Exception(
                "Unable to save banner image: "
                + imageError.getMessage()
            );

        }

    }


    /* =================================================
       SAVE QR IMAGE
       ================================================= */

    if("Paid".equalsIgnoreCase(paymentType) &&
       qrImageData != null &&
       !qrImageData.trim().equals("")){


        try{

            String[] parts =
                qrImageData.split(",");


            String base64Data =
                parts.length > 1
                ? parts[1]
                : parts[0];


            byte[] imageBytes =
                Base64.getDecoder().decode(
                    base64Data
                );


            String extension =
                ".jpg";


            if(qrOriginalName != null){

                String lower =
                    qrOriginalName.toLowerCase();


                if(lower.endsWith(".png")){

                    extension = ".png";

                }
                else if(lower.endsWith(".jpeg")){

                    extension = ".jpeg";

                }
                else if(lower.endsWith(".jpg")){

                    extension = ".jpg";

                }

            }


            qrImage =
                "qr_" +
                UUID.randomUUID().toString() +
                extension;


            File qrFile =
                new File(
                    imageFolder,
                    qrImage
                );


            FileOutputStream qrOutput =
                new FileOutputStream(
                    qrFile
                );


            qrOutput.write(
                imageBytes
            );


            qrOutput.close();

        }
        catch(Exception imageError){

            throw new Exception(
                "Unable to save QR image: "
                + imageError.getMessage()
            );

        }

    }


    /* =================================================
       INSERT EVENT
       ================================================= */

    String sql =

        "INSERT INTO events (" +

        "event_name," +
        "subtitle," +
        "category," +
        "registration_start," +
        "registration_deadline," +
        "event_date," +
        "event_time," +
        "venue," +
        "mode," +
        "team_size," +
        "eligibility," +
        "rules," +
        "first_prize," +
        "second_prize," +
        "third_prize," +
        "certificate," +
        "coordinator_name," +
        "coordinator_phone," +
        "coordinator_email," +
        "banner_image," +
        "description," +
        "organizer_id," +
        "event_fee," +
        "payment_type," +
        "upi_id," +
        "qr_image" +

        ") VALUES (" +

        "?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?" +

        ")";


    ps =
        conn.prepareStatement(sql);


    /* =================================================
       EVENT INFORMATION
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

    ps.setString(
        4,
        registrationStart
    );

    ps.setString(
        5,
        registrationDeadline
    );

    ps.setString(
        6,
        eventDate
    );

    ps.setString(
        7,
        eventTime
    );

    ps.setString(
        8,
        venue
    );

    ps.setString(
        9,
        mode
    );

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
       BANNER FILENAME
       ================================================= */

    if(bannerImage == null){

        ps.setNull(
            20,
            Types.VARCHAR
        );

    }
    else{

        ps.setString(
            20,
            bannerImage
        );

    }


    /* =================================================
       DESCRIPTION
       ================================================= */

    ps.setString(
        21,
        description
    );


    /* =================================================
       ORGANIZER ID
       ================================================= */

    ps.setInt(
        22,
        organizerId
    );


    /* =================================================
       EVENT FEE
       ================================================= */

    ps.setDouble(
        23,
        fee
    );


    /* =================================================
       PAYMENT TYPE
       ================================================= */

    ps.setString(
        24,
        paymentType
    );


    /* =================================================
       UPI ID
       ================================================= */

    if(upiId == null ||
       upiId.trim().equals("")){

        ps.setNull(
            25,
            Types.VARCHAR
        );

    }
    else{

        ps.setString(
            25,
            upiId
        );

    }


    /* =================================================
       QR IMAGE FILENAME
       ================================================= */

    if(qrImage == null){

        ps.setNull(
            26,
            Types.VARCHAR
        );

    }
    else{

        ps.setString(
            26,
            qrImage
        );

    }


    /* =================================================
       EXECUTE
       ================================================= */

    int result =
        ps.executeUpdate();


    if(result > 0){

        response.sendRedirect(
            "manageEvents.jsp"
        );

        return;

    }
    else{

        out.println(
            "<h2>Event was not saved.</h2>"
        );

    }


}
catch(NumberFormatException e){

    out.println(
        "<h2 style='color:red;'>"
        + "Invalid Event Fee"
        + "</h2>"
    );

    out.println(
        "<p>Please enter a valid number.</p>"
    );

}
catch(SQLException e){

    out.println(
        "<h2 style='color:red;'>"
        + "Database Error"
        + "</h2>"
    );

    out.println(
        "<p>"
        + e.getMessage()
        + "</p>"
    );

}
catch(Exception e){

    out.println(
        "<h2 style='color:red;'>"
        + "Error Saving Event"
        + "</h2>"
    );

    out.println(
        "<p>"
        + e.getMessage()
        + "</p>"
    );

}
finally{


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