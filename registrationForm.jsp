<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>

<%
/* =====================================================
   LOGIN CHECK
   ===================================================== */

if(session.getAttribute("userId") == null){

    response.sendRedirect("login.jsp");
    return;
}


/* =====================================================
   GET EVENT ID
   ===================================================== */

String eventId = request.getParameter("id");

if(eventId == null || eventId.trim().equals("")){

    response.sendRedirect("userDashboard.jsp");
    return;
}


Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;


try{

    Class.forName(
        "com.mysql.cj.jdbc.Driver"
    );


    conn = DriverManager.getConnection(
        "jdbc:mysql://localhost:3306/eventsphere",
        "root",
        ""
    );


    ps = conn.prepareStatement(
        "SELECT * FROM events WHERE event_id=?"
    );


    ps.setInt(
        1,
        Integer.parseInt(eventId)
    );


    rs = ps.executeQuery();


    if(rs.next()){

        String paymentType =
            rs.getString("payment_type");

        String banner =
            rs.getString("banner_image");

        String qrImage =
            rs.getString("qr_image");

%>

<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>
    Register - <%=rs.getString("event_name")%>
</title>

<link rel="stylesheet"
      href="css/registrationForm.css">

</head>


<body>

<div class="page-container">


<!-- =====================================================
     BACK
     ===================================================== -->

<a href="viewEvent.jsp?id=<%=rs.getInt("event_id")%>"
   class="back-btn">

    ← Back to Event

</a>


<!-- =====================================================
     EVENT HEADER
     ===================================================== -->

<div class="event-header">


<%
if(banner != null &&
   !banner.trim().equals("")){
%>

<img
    src="images/<%=banner%>"
    class="event-banner"
    alt="Event Banner">

<%
}
%>


<div class="event-info">


<span class="category">

    <%=rs.getString("category")%>

</span>


<h1>

    <%=rs.getString("event_name")%>

</h1>


<%
if(rs.getString("subtitle") != null){
%>

<p class="subtitle">

    <%=rs.getString("subtitle")%>

</p>

<%
}
%>


<div class="event-meta">

<span>
    📅 <%=rs.getString("event_date")%>
</span>

<span>
    ⏰ <%=rs.getString("event_time")%>
</span>

<span>
    📍 <%=rs.getString("venue")%>
</span>

</div>


</div>

</div>


<!-- =====================================================
     REGISTRATION FORM
     ===================================================== -->

<form
    action="registerEvent.jsp"
    method="post"
    id="registrationForm">


<input
    type="hidden"
    name="event_id"
    value="<%=rs.getInt("event_id")%>">


<!-- =====================================================
     PARTICIPANT DETAILS
     ===================================================== -->

<div class="section">

<h2>
    👤 Participant Details
</h2>


<div class="form-grid">


<div class="form-group">

<label>
    Full Name
</label>

<input
    type="text"
    name="full_name"
    placeholder="Enter your full name"
    required>

</div>


<div class="form-group">

<label>
    Email
</label>

<input
    type="email"
    name="email"
    placeholder="Enter your email"
    required>

</div>


<div class="form-group">

<label>
    Phone Number
</label>

<input
    type="text"
    name="phone"
    placeholder="10-digit mobile number"
    pattern="[0-9]{10}"
    maxlength="10"
    required>

</div>


<div class="form-group">

<label>
    Gender
</label>

<select
    name="gender"
    required>

<option value="">
    Select Gender
</option>

<option value="Male">
    Male
</option>

<option value="Female">
    Female
</option>

<option value="Other">
    Other
</option>

</select>

</div>


<div class="form-group">

<label>
    Date of Birth
</label>

<input
    type="date"
    name="date_of_birth">

</div>


<div class="form-group">

<label>
    City
</label>

<input
    type="text"
    name="city"
    placeholder="Your city">

</div>


<div class="form-group">

<label>
    State
</label>

<input
    type="text"
    name="state"
    placeholder="Your state">

</div>


<div class="form-group">

<label>
    Country
</label>

<input
    type="text"
    name="country"
    value="India">

</div>


<div class="form-group">

<label>
    Emergency Contact
</label>

<input
    type="text"
    name="emergency_contact"
    placeholder="Emergency contact number">

</div>


<div class="form-group">

<label>
    Team Name
</label>

<input
    type="text"
    name="team_name"
    placeholder="Optional">

</div>


<div class="form-group">

<label>
    Team Members
</label>

<input
    type="number"
    name="team_members"
    min="1"
    value="1">

</div>


</div>


<div class="form-group">

<label>
    Special Requirements
</label>

<textarea
    name="special_requirements"
    rows="5"
    placeholder="Any special requirements?"></textarea>

</div>


</div>


<!-- =====================================================
     PAYMENT
     ===================================================== -->

<div class="section payment-section">


<h2>
    💳 Payment Details
</h2>


<%
if("Paid".equalsIgnoreCase(paymentType)){
%>


<div class="paid-payment">


<div class="payment-info">


<h3>
    Entry Fee
</h3>

<div class="fee">

₹<%=rs.getDouble("event_fee")%>

</div>


<h3>
    UPI ID
</h3>

<p class="upi">

<%=rs.getString("upi_id")%>

</p>


</div>


<!-- =====================================================
     QR
     ===================================================== -->

<%
if(qrImage != null &&
   !qrImage.trim().equals("")){
%>

<div class="qr-section">

<h3>
    Scan QR to Pay
</h3>


<img
    src="images/<%=qrImage%>"
    class="qr-image"
    alt="Payment QR Code">


<p>
    Scan this QR using your UPI app.
</p>

</div>

<%
}
%>


</div>


<!-- =====================================================
     PAYMENT SCREENSHOT
     ===================================================== -->

<div class="screenshot-section">


<h3>
    Payment Screenshot
</h3>


<p class="help-text">

After completing payment, upload your
payment screenshot below.

</p>


<label
    for="paymentFile"
    class="payment-upload"
    id="paymentDropArea">


<div id="paymentUploadContent">

<div class="upload-icon">
    📷
</div>

<h3>
    Drag & Drop Screenshot
</h3>

<p>
    or
</p>

<span>
    Click to Browse
</span>

<small>
    PNG, JPG or JPEG • Maximum 5 MB
</small>

</div>


<img
    id="paymentPreview"
    class="payment-preview"
    alt="Payment Screenshot Preview">

</label>


<input
    type="file"
    id="paymentFile"
    accept="image/png,image/jpeg,image/jpg">


<input
    type="hidden"
    name="payment_screenshot_data"
    id="payment_screenshot_data">


<input
    type="hidden"
    name="payment_screenshot_name"
    id="payment_screenshot_name">


<p
    id="paymentError"
    class="error-message">
</p>


</div>


<%
}else{
%>


<div class="free-payment">

    🎉 This is a free event.
    No payment is required.

</div>


<input
    type="hidden"
    name="payment_screenshot_data"
    value="">


<input
    type="hidden"
    name="payment_screenshot_name"
    value="">


<%
}
%>


</div>


<!-- =====================================================
     REGISTER
     ===================================================== -->

<div class="submit-section">


<button
    type="submit"
    class="register-btn">

    🎟 Register for Event

</button>


</div>


</form>


</div>


<!-- =====================================================
     PAYMENT SCREENSHOT JAVASCRIPT
     ===================================================== -->

<script>

const paymentFile =
    document.getElementById(
        "paymentFile"
    );


const paymentPreview =
    document.getElementById(
        "paymentPreview"
    );


const paymentUploadContent =
    document.getElementById(
        "paymentUploadContent"
    );


const paymentDropArea =
    document.getElementById(
        "paymentDropArea"
    );


const paymentData =
    document.getElementById(
        "payment_screenshot_data"
    );


const paymentName =
    document.getElementById(
        "payment_screenshot_name"
    );


const paymentError =
    document.getElementById(
        "paymentError"
    );


/* =====================================================
   PROCESS PAYMENT SCREENSHOT
   ===================================================== */

function processPaymentFile(file){

    if(!file){
        return;
    }


    const allowedTypes = [

        "image/png",
        "image/jpeg",
        "image/jpg"

    ];


    if(!allowedTypes.includes(file.type)){

        paymentError.innerText =
            "Only PNG, JPG and JPEG images are allowed.";

        paymentError.style.display =
            "block";

        paymentFile.value = "";

        return;
    }


    if(file.size > 5 * 1024 * 1024){

        paymentError.innerText =
            "Screenshot must be less than 5 MB.";

        paymentError.style.display =
            "block";

        paymentFile.value = "";

        return;
    }


    paymentError.style.display =
        "none";


    const reader =
        new FileReader();


    reader.onload =
        function(e){

            paymentPreview.src =
                e.target.result;


            paymentPreview.style.display =
                "block";


            paymentUploadContent.style.display =
                "none";


            paymentData.value =
                e.target.result;


            paymentName.value =
                file.name;

        };


    reader.readAsDataURL(file);

}


/* =====================================================
   BROWSE
   ===================================================== */

if(paymentFile){

    paymentFile.addEventListener(
        "change",
        function(){

            if(this.files &&
               this.files.length > 0){

                processPaymentFile(
                    this.files[0]
                );

            }

        }
    );

}


/* =====================================================
   DRAG OVER
   ===================================================== */

if(paymentDropArea){

    paymentDropArea.addEventListener(
        "dragover",
        function(e){

            e.preventDefault();

            paymentDropArea.classList.add(
                "drag"
            );

        }
    );


    /* =================================================
       DRAG LEAVE
       ================================================= */

    paymentDropArea.addEventListener(
        "dragleave",
        function(){

            paymentDropArea.classList.remove(
                "drag"
            );

        }
    );


    /* =================================================
       DROP
       ================================================= */

    paymentDropArea.addEventListener(
        "drop",
        function(e){

            e.preventDefault();

            paymentDropArea.classList.remove(
                "drag"
            );


            const files =
                e.dataTransfer.files;


            if(files.length > 0){

                processPaymentFile(
                    files[0]
                );

            }

        }
    );

}

</script>


</body>

</html>


<%
    }
    else{

        out.println(
            "<h2>Event not found.</h2>"
        );

    }

}
catch(Exception e){

    out.println(
        "<h2 style='color:red;'>"
        + "Error loading registration form"
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

        if(rs != null)
            rs.close();

    }catch(Exception e){}


    try{

        if(ps != null)
            ps.close();

    }catch(Exception e){}


    try{

        if(conn != null)
            conn.close();

    }catch(Exception e){}

}

%>