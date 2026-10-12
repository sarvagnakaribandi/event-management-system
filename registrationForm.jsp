<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>
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

int userId = Integer.parseInt(session.getAttribute("userId").toString());

/* =====================================================
   GET EVENT ID
   ===================================================== */

String eventId = request.getParameter("id");

if(eventId == null || eventId.trim().equals("")){
    response.sendRedirect("userDashboard.jsp");
    return;
}

int eventIdInt;
try {
    eventIdInt = Integer.parseInt(eventId.trim());
} catch(Exception e) {
    response.sendRedirect("userDashboard.jsp");
    return;
}

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;
PreparedStatement regCheckPs = null;
ResultSet regCheckRs = null;

try{
    conn = DBConnection.getConnection();

    ps = conn.prepareStatement(
        "SELECT * FROM events WHERE event_id=?"
    );

    ps.setInt(1, eventIdInt);
    rs = ps.executeQuery();

    if(rs.next()){
        Date eventDate = rs.getDate("event_date");
        Date regDeadline = rs.getDate("registration_deadline");
        int availableSeats = rs.getInt("available_seats");
        Date today = new Date(System.currentTimeMillis());

        boolean isEventPast = eventDate != null && eventDate.before(today);
        boolean isDeadlinePast = regDeadline != null && regDeadline.before(today);
        boolean isSoldOut = availableSeats <= 0;

        // Check duplicate registration
        regCheckPs = conn.prepareStatement(
            "SELECT registration_id FROM registrations WHERE user_id=? AND event_id=?"
        );
        regCheckPs.setInt(1, userId);
        regCheckPs.setInt(2, eventIdInt);
        regCheckRs = regCheckPs.executeQuery();
        boolean alreadyRegistered = regCheckRs.next();

        if(alreadyRegistered || isEventPast || isDeadlinePast || isSoldOut){
            response.sendRedirect("eventDetails.jsp?id=" + eventIdInt);
            return;
        }

        String paymentType = rs.getString("payment_type");
        double eventFee = rs.getDouble("event_fee");
        String upiId = rs.getString("upi_id");
        String banner = rs.getString("banner_image");
        String qrImage = rs.getString("qr_image");

        if(banner == null || banner.trim().isEmpty()){
            banner = "image2.png";
        } else {
            banner = banner.trim();
            if(banner.startsWith("images/")){
                banner = banner.substring("images/".length());
            } else if(banner.startsWith("/images/")){
                banner = banner.substring("/images/".length());
            }
        }
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

<a href="eventDetails.jsp?id=<%=rs.getInt("event_id")%>"
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
if("Paid".equalsIgnoreCase(paymentType) && eventFee > 0){
%>

<!-- PAYMENT METHOD CHOOSER -->
<div class="payment-method-selector">
    <div class="pay-method-tab active" id="tabGateway" onclick="selectPaymentMethod('Gateway')">
        <input type="radio" name="payment_method" id="payRadioGateway" value="Gateway" checked style="display:none;">
        <span class="pay-icon">💳</span>
        <div>
            <strong>Instant Gateway (Sandbox)</strong>
            <small>Instant Approval & Ticket Confirmation</small>
        </div>
    </div>

    <div class="pay-method-tab" id="tabUPI" onclick="selectPaymentMethod('UPI')">
        <input type="radio" name="payment_method" id="payRadioUPI" value="UPI" style="display:none;">
        <span class="pay-icon">📱</span>
        <div>
            <strong>UPI / QR Transfer</strong>
            <small>Scan QR & Submit UTR / Screenshot</small>
        </div>
    </div>
</div>

<!-- OPTION 1: INSTANT GATEWAY SANDBOX -->
<div id="sectionGateway" class="payment-sub-section">
    <div class="sandbox-card">
        <div class="sandbox-header">
            <span class="sandbox-badge">GATEWAY SANDBOX SIMULATOR</span>
            <span class="amount-badge">Payable: ₹<%= String.format("%.2f", eventFee) %></span>
        </div>
        <p class="sandbox-desc">
            ⚡ <strong>Instant Confirmation Mode:</strong> Simulates an authorized payment gateway checkout (Debit/Credit Card, NetBanking, Instant UPI). Your seat is confirmed immediately upon submitting.
        </p>

        <div class="sandbox-grid">
            <div class="form-group">
                <label>Cardholder / Account Name</label>
                <input type="text" id="cardName" placeholder="Name on Card" value="<%= SecurityUtil.escapeHtml(session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Cardholder") %>">
            </div>
            <div class="form-group">
                <label>Demo Card Number</label>
                <input type="text" id="cardNumber" placeholder="4532 •••• •••• 8892" value="4532 8920 1204 8892" maxlength="19">
            </div>
            <div class="form-group">
                <label>Expiry (MM/YY)</label>
                <input type="text" id="cardExpiry" placeholder="12/28" value="12/28" maxlength="5">
            </div>
            <div class="form-group">
                <label>CVV / CVC</label>
                <input type="password" id="cardCvv" placeholder="•••" value="888" maxlength="4">
            </div>
        </div>

        <div class="instant-guarantee">
            ✔ Instant payment verification with unique Transaction ID recorded automatically.
        </div>
    </div>
</div>

<!-- OPTION 2: MANUAL UPI / QR TRANSFER -->
<div id="sectionUPI" class="payment-sub-section" style="display:none;">
    <div class="paid-payment">
        <div class="payment-info">
            <h3>Entry Fee</h3>
            <div class="fee">₹<%= String.format("%.2f", eventFee) %></div>

            <h3>Organizer UPI ID</h3>
            <p class="upi"><%= SecurityUtil.escapeHtml(upiId != null && !upiId.trim().isEmpty() ? upiId : "eventsphere@upi") %></p>
        </div>

        <%
        if(qrImage != null && !qrImage.trim().isEmpty()){
        %>
        <div class="qr-section">
            <h3>Scan QR to Pay</h3>
            <img src="images/<%= SecurityUtil.escapeHtml(qrImage) %>" class="qr-image" alt="Payment QR Code" onerror="this.onerror=null;this.src='images/image2.png';">
            <p>Scan using GPay, PhonePe, Paytm, or BHIM.</p>
        </div>
        <%
        }
        %>
    </div>

    <!-- UTR Reference input -->
    <div class="form-group" style="margin-top:20px;">
        <label>UPI Reference / UTR Number <span style="color:#ff4fa3;">*</span></label>
        <input type="text" name="upi_transaction_id" id="upi_transaction_id" placeholder="Enter 12-digit UTR / UPI Reference ID" maxlength="35">
        <small style="color:#9ba8bd; display:block; margin-top:5px;">Check your payment app receipt for the 12-digit UPI Reference Number / UTR.</small>
    </div>

    <!-- Payment Screenshot Upload -->
    <div class="screenshot-section" style="margin-top:20px;">
        <h3>Payment Screenshot <span style="color:#ff4fa3;">*</span></h3>
        <p class="help-text">Upload screenshot of the completed UPI transaction for organizer review.</p>

        <label for="paymentFile" class="payment-upload" id="paymentDropArea">
            <div id="paymentUploadContent">
                <div class="upload-icon">📷</div>
                <h3>Drag & Drop Screenshot</h3>
                <p>or</p>
                <span>Click to Browse</span>
                <small>PNG, JPG or JPEG • Maximum 5 MB</small>
            </div>
            <img id="paymentPreview" class="payment-preview" alt="Payment Screenshot Preview">
        </label>

        <input type="file" id="paymentFile" accept="image/png,image/jpeg,image/jpg">
        <input type="hidden" name="payment_screenshot_data" id="payment_screenshot_data">
        <input type="hidden" name="payment_screenshot_name" id="payment_screenshot_name">
        <p id="paymentError" class="error-message"></p>
    </div>
</div>

<%
} else {
%>

<!-- FREE EVENT -->
<div class="free-payment">
    🎉 <strong>Free Event Registration</strong>
    <p style="margin-top:8px; font-size:15px; color:#cbd5e1;">This event has no entry fee. Your seat will be confirmed instantly upon submitting!</p>
</div>

<input type="hidden" name="payment_method" value="Free">
<input type="hidden" name="upi_transaction_id" value="">
<input type="hidden" name="payment_screenshot_data" value="">
<input type="hidden" name="payment_screenshot_name" value="">

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

function selectPaymentMethod(method) {
    const tabGateway = document.getElementById("tabGateway");
    const tabUPI = document.getElementById("tabUPI");
    const secGateway = document.getElementById("sectionGateway");
    const secUPI = document.getElementById("sectionUPI");
    const radioGateway = document.getElementById("payRadioGateway");
    const radioUPI = document.getElementById("payRadioUPI");

    if (method === 'Gateway') {
        if(tabGateway) tabGateway.classList.add("active");
        if(tabUPI) tabUPI.classList.remove("active");
        if(secGateway) secGateway.style.display = "block";
        if(secUPI) secUPI.style.display = "none";
        if(radioGateway) radioGateway.checked = true;
    } else {
        if(tabUPI) tabUPI.classList.add("active");
        if(tabGateway) tabGateway.classList.remove("active");
        if(secUPI) secUPI.style.display = "block";
        if(secGateway) secGateway.style.display = "none";
        if(radioUPI) radioUPI.checked = true;
    }
}

document.getElementById("registrationForm")?.addEventListener("submit", function(e) {
    const radioUPI = document.getElementById("payRadioUPI");
    if (radioUPI && radioUPI.checked) {
        const utr = document.getElementById("upi_transaction_id")?.value.trim();
        const screenshot = document.getElementById("payment_screenshot_data")?.value.trim();

        if (!utr) {
            e.preventDefault();
            alert("Please enter the UPI Reference / UTR Number before submitting.");
            document.getElementById("upi_transaction_id")?.focus();
            return false;
        }

        if (!screenshot) {
            e.preventDefault();
            alert("Please upload your UPI payment screenshot before submitting.");
            return false;
        }
    }
});

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
    DBConnection.close(regCheckRs);
    DBConnection.close(regCheckPs);
    DBConnection.close(rs);
    DBConnection.close(ps);
    DBConnection.close(conn);
}
%>