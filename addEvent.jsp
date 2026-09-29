<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%
/* =====================================================
   ORGANIZER LOGIN CHECK
   ===================================================== */

if(session.getAttribute("userId") == null){

    response.sendRedirect("login.jsp");
    return;
}

String role =
    (String)session.getAttribute("role");

if(role == null ||
   !"Organizer".equalsIgnoreCase(role)){

    response.sendRedirect("login.jsp");
    return;
}

%>

<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>Add New Event | EventSphere</title>


<link rel="stylesheet"
      href="css/event.css">


<link rel="preconnect"
      href="https://fonts.googleapis.com">

<link rel="preconnect"
      href="https://fonts.gstatic.com"
      crossorigin>

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
      rel="stylesheet">


<style>

/* =====================================================
   QR UPLOAD
   ===================================================== */

.qr-upload-area{
    width:100%;
}

.qr-upload-box{

    width:100%;
    min-height:260px;

    border:2px dashed #8d6bb8;

    border-radius:18px;

    display:flex;

    align-items:center;
    justify-content:center;

    text-align:center;

    cursor:pointer;

    transition:0.3s;

    padding:20px;

    box-sizing:border-box;
}

.qr-upload-box:hover{

    border-color:#ff4fa3;

    background:rgba(255,255,255,0.04);
}

.qr-upload-box.drag{

    border-color:#00eaff;

    background:rgba(0,234,255,0.08);
}

.qr-icon{

    font-size:50px;

    margin-bottom:10px;
}

.qr-upload-box h3{

    margin:8px 0;
}

.qr-upload-box p{

    margin:5px 0;
}

.qr-upload-box span{

    display:inline-block;

    margin-top:10px;

    padding:10px 20px;

    border-radius:10px;

    background:#ff4fa3;

    color:white;

    font-weight:600;
}

.qr-upload-box small{

    display:block;

    margin-top:10px;

    opacity:0.7;
}

.qr-preview{

    display:none;

    max-width:250px;
    max-height:250px;

    object-fit:contain;

    border-radius:12px;
}


/* =====================================================
   BANNER UPLOAD
   ===================================================== */

.banner-preview{

    display:none;

    width:100%;

    max-height:350px;

    object-fit:cover;

    border-radius:14px;
}


/* =====================================================
   PAYMENT
   ===================================================== */

.payment-section{

    margin-top:30px;
}

.payment-note{

    font-size:13px;

    opacity:0.75;

    margin-top:8px;
}


/* =====================================================
   UPLOAD ERROR
   ===================================================== */

.upload-error{

    color:#ff6b81;

    margin-top:8px;

    display:none;

    font-size:13px;
}

</style>

</head>


<body>


<div class="container">

<div class="event-card">


<h1>
    Add New Event
</h1>


<!-- =====================================================
     MAIN FORM
     ===================================================== -->

<form action="saveEvent.jsp"
      method="post">


<!-- =====================================================
     HIDDEN BANNER DATA
     ===================================================== -->

<input type="hidden"
       name="banner_image_data"
       id="banner_image_data">

<input type="hidden"
       name="banner_image_name"
       id="banner_image_name">


<!-- =====================================================
     HIDDEN QR DATA
     ===================================================== -->

<input type="hidden"
       name="qr_image_data"
       id="qr_image_data">

<input type="hidden"
       name="qr_image_name"
       id="qr_image_name">


<!-- =====================================================
     BASIC EVENT DETAILS
     ===================================================== -->

<div class="top-section">


<!-- =====================================================
     LEFT SECTION
     ===================================================== -->

<div class="left-section">


<!-- EVENT NAME -->

<div class="form-group">

<label>
    Event Name
</label>

<input
    type="text"
    name="event_name"
    placeholder="Enter Event Name"
    required>

</div>


<!-- SUBTITLE -->

<div class="form-group">

<label>
    Subtitle
</label>

<input
    type="text"
    name="subtitle"
    placeholder="Enter Subtitle">

</div>


<!-- CATEGORY -->

<div class="form-group">

<label>
    Category
</label>

<select
    name="category"
    required>

<option value="">
    Select Category
</option>

<option value="Technical">
    Technical
</option>

<option value="Non-Technical">
    Non-Technical
</option>

<option value="Cultural">
    Cultural
</option>

<option value="Workshop">
    Workshop
</option>

<option value="Seminar">
    Seminar
</option>

<option value="Hackathon">
    Hackathon
</option>

<option value="Gaming">
    Gaming
</option>

<option value="Sports">
    Sports
</option>

<option value="Dance">
    Dance
</option>

<option value="Music">
    Music
</option>

</select>

</div>


</div>


<!-- =====================================================
     RIGHT SECTION - BANNER
     ===================================================== -->

<div class="right-section">

<label>
    Upload Banner
</label>


<div class="upload-area">


<label
    for="banner"
    class="upload-box"
    id="dropArea">


<img
    id="previewImage"
    class="banner-preview"
    alt="Banner Preview">


<div id="uploadContent">

<div class="icon">
    📷
</div>


<h3>
    Drag & Drop Banner
</h3>


<p>
    or
</p>


<span>
    Click to Browse
</span>

</div>


</label>


<input
    type="file"
    id="banner"
    accept="image/png,image/jpeg,image/jpg">


<p
    id="bannerError"
    class="upload-error">

</p>


</div>

</div>


</div>


<!-- =====================================================
     EVENT INFORMATION
     ===================================================== -->

<div class="form-grid">


<!-- REGISTRATION START -->

<div class="form-group">

<label>
    Registration Start
</label>

<input
    type="date"
    name="registration_start"
    required>

</div>


<!-- REGISTRATION DEADLINE -->

<div class="form-group">

<label>
    Registration Deadline
</label>

<input
    type="date"
    name="registration_deadline"
    required>

</div>


<!-- EVENT DATE -->

<div class="form-group">

<label>
    Event Date
</label>

<input
    type="date"
    name="event_date"
    required>

</div>


<!-- EVENT TIME -->

<div class="form-group">

<label>
    Event Time
</label>

<input
    type="time"
    name="event_time"
    required>

</div>


<!-- VENUE -->

<div class="form-group">

<label>
    Venue
</label>

<input
    type="text"
    name="venue"
    placeholder="Enter Event Venue"
    required>

</div>


<!-- MODE -->

<div class="form-group">

<label>
    Mode
</label>

<select
    name="mode"
    required>

<option value="">
    Select Mode
</option>

<option value="Offline">
    Offline
</option>

<option value="Online">
    Online
</option>

</select>

</div>


<!-- TEAM SIZE -->

<div class="form-group">

<label>
    Team Size
</label>

<input
    type="text"
    name="team_size"
    placeholder="Example: 1-4 Members">

</div>


<!-- CERTIFICATE -->

<div class="form-group">

<label>
    Certificate
</label>

<select
    name="certificate"
    required>

<option value="">
    Select
</option>

<option value="Yes">
    Yes
</option>

<option value="No">
    No
</option>

</select>

</div>


<!-- FIRST PRIZE -->

<div class="form-group">

<label>
    First Prize
</label>

<input
    type="text"
    name="first_prize"
    placeholder="₹5000 / Trophy">

</div>


<!-- SECOND PRIZE -->

<div class="form-group">

<label>
    Second Prize
</label>

<input
    type="text"
    name="second_prize"
    placeholder="₹3000 / Trophy">

</div>


<!-- THIRD PRIZE -->

<div class="form-group">

<label>
    Third Prize
</label>

<input
    type="text"
    name="third_prize"
    placeholder="₹1000 / Trophy">

</div>


<!-- COORDINATOR NAME -->

<div class="form-group">

<label>
    Coordinator Name
</label>

<input
    type="text"
    name="coordinator_name"
    placeholder="Coordinator Full Name"
    required>

</div>


<!-- COORDINATOR PHONE -->

<div class="form-group">

<label>
    Coordinator Phone
</label>

<input
    type="tel"
    name="coordinator_phone"
    placeholder="9876543210"
    pattern="[0-9]{10}"
    maxlength="10"
    required>

</div>


<!-- COORDINATOR EMAIL -->

<div class="form-group">

<label>
    Coordinator Email
</label>

<input
    type="email"
    name="coordinator_email"
    placeholder="coordinator@example.com"
    required>

</div>


</div>


<!-- =====================================================
     PAYMENT DETAILS
     ===================================================== -->

<div class="full-width payment-section">


<h2>
    Payment Details
</h2>


<!-- PAYMENT TYPE -->

<div class="form-group">

<label>
    Event Type
</label>

<select
    name="payment_type"
    id="payment_type"
    onchange="togglePaymentFields()"
    required>

<option value="Free">
    Free
</option>

<option value="Paid">
    Paid
</option>

</select>

</div>


<!-- =====================================================
     PAID EVENT FIELDS
     ===================================================== -->

<div id="paidFields"
     style="display:none;">


<!-- EVENT FEE -->

<div class="form-group">

<label>
    Event Fee (₹)
</label>

<input
    type="number"
    name="event_fee"
    id="event_fee"
    min="0"
    step="0.01"
    placeholder="Enter registration fee">

</div>


<!-- UPI -->

<div class="form-group">

<label>
    UPI ID
</label>

<input
    type="text"
    name="upi_id"
    id="upi_id"
    placeholder="example@upi">

</div>


<!-- =====================================================
     QR CODE
     ===================================================== -->

<div class="form-group">

<label>
    QR Code
</label>


<div class="qr-upload-area">


<label
    for="qrFile"
    class="qr-upload-box"
    id="qrDropArea">


<div id="qrUploadContent">

<div class="qr-icon">
    📱
</div>


<h3>
    Upload QR Code
</h3>


<p>
    Drag & Drop your QR image here
</p>


<span>
    Click to Browse Image
</span>


<small>
    PNG, JPG or JPEG
</small>

</div>


<img
    id="qrPreview"
    class="qr-preview"
    alt="QR Preview">


</label>


<input
    type="file"
    id="qrFile"
    accept="image/png,image/jpeg,image/jpg">


<p
    id="qrError"
    class="upload-error">

</p>


</div>


<p class="payment-note">

Upload the QR code that participants should use
to make payment.

</p>


</div>


</div>


</div>


<!-- =====================================================
     ELIGIBILITY
     ===================================================== -->

<div class="full-width">

<label>
    Eligibility
</label>

<textarea
    name="eligibility"
    rows="4"
    placeholder="Example: Open for students, Individual/Team participation, etc."
    required></textarea>

</div>


<!-- =====================================================
     RULES
     ===================================================== -->

<div class="full-width">

<label>
    Rules & Guidelines
</label>

<textarea
    name="rules"
    rows="6"
    placeholder="Enter all event rules and guidelines..."
    required></textarea>

</div>


<!-- =====================================================
     DESCRIPTION
     ===================================================== -->

<div class="full-width">

<label>
    Event Description
</label>

<textarea
    name="description"
    rows="8"
    placeholder="Write a detailed description of your event..."
    required></textarea>

</div>


<!-- =====================================================
     SAVE BUTTON
     ===================================================== -->

<div class="button-section">

<button
    type="submit"
    class="save-btn">

    🚀 Save Event

</button>

</div>


</form>

</div>

</div>


<!-- =====================================================
     BANNER JAVASCRIPT
     ===================================================== -->

<script>

const fileInput =
    document.getElementById("banner");

const preview =
    document.getElementById("previewImage");

const uploadContent =
    document.getElementById("uploadContent");

const dropArea =
    document.getElementById("dropArea");

const bannerData =
    document.getElementById(
        "banner_image_data"
    );

const bannerName =
    document.getElementById(
        "banner_image_name"
    );

const bannerError =
    document.getElementById(
        "bannerError"
    );


/* =====================================================
   PROCESS BANNER
   ===================================================== */

function processBannerFile(file){

    if(!file){
        return;
    }


    const allowedTypes = [

        "image/png",
        "image/jpeg",
        "image/jpg"

    ];


    /* FILE TYPE */

    if(!allowedTypes.includes(file.type)){

        bannerError.innerText =
            "Only PNG, JPG and JPEG images are allowed.";

        bannerError.style.display =
            "block";

        fileInput.value = "";

        return;
    }


    /* FILE SIZE */

    if(file.size > 5 * 1024 * 1024){

        bannerError.innerText =
            "Banner image must be less than 5 MB.";

        bannerError.style.display =
            "block";

        fileInput.value = "";

        return;
    }


    bannerError.style.display =
        "none";


    const reader =
        new FileReader();


    reader.onload =
        function(e){

            /* PREVIEW */

            preview.src =
                e.target.result;

            preview.style.display =
                "block";


            uploadContent.style.display =
                "none";


            /* BASE64 */

            bannerData.value =
                e.target.result;


            /* ORIGINAL NAME */

            bannerName.value =
                file.name;

        };


    reader.readAsDataURL(file);

}


/* =====================================================
   BANNER BROWSE
   ===================================================== */

fileInput.addEventListener(
    "change",
    function(){

        if(this.files &&
           this.files.length > 0){

            processBannerFile(
                this.files[0]
            );

        }

    }
);


/* =====================================================
   BANNER DRAG OVER
   ===================================================== */

dropArea.addEventListener(
    "dragover",
    function(e){

        e.preventDefault();

        dropArea.classList.add(
            "drag"
        );

    }
);


/* =====================================================
   BANNER DRAG LEAVE
   ===================================================== */

dropArea.addEventListener(
    "dragleave",
    function(){

        dropArea.classList.remove(
            "drag"
        );

    }
);


/* =====================================================
   BANNER DROP
   ===================================================== */

dropArea.addEventListener(
    "drop",
    function(e){

        e.preventDefault();

        dropArea.classList.remove(
            "drag"
        );


        const files =
            e.dataTransfer.files;


        if(files.length > 0){

            processBannerFile(
                files[0]
            );

        }

    }
);

</script>


<!-- =====================================================
     PAYMENT JAVASCRIPT
     ===================================================== -->

<script>

function togglePaymentFields(){

    const paymentType =
        document.getElementById(
            "payment_type"
        ).value;


    const paidFields =
        document.getElementById(
            "paidFields"
        );


    const fee =
        document.getElementById(
            "event_fee"
        );


    const upi =
        document.getElementById(
            "upi_id"
        );


    const qrData =
        document.getElementById(
            "qr_image_data"
        );


    const qrFile =
        document.getElementById(
            "qrFile"
        );


    if(paymentType === "Paid"){

        paidFields.style.display =
            "block";

        fee.required =
            true;

        upi.required =
            true;

        qrData.required =
            true;

    }

    else{

        paidFields.style.display =
            "none";

        fee.required =
            false;

        upi.required =
            false;

        qrData.required =
            false;


        fee.value =
            "";

        upi.value =
            "";

        qrData.value =
            "";


        document.getElementById(
            "qr_image_name"
        ).value =
            "";


        qrFile.value =
            "";


        document.getElementById(
            "qrPreview"
        ).style.display =
            "none";


        document.getElementById(
            "qrUploadContent"
        ).style.display =
            "block";

    }

}


/* =====================================================
   QR VARIABLES
   ===================================================== */

const qrFile =
    document.getElementById(
        "qrFile"
    );


const qrPreview =
    document.getElementById(
        "qrPreview"
    );


const qrUploadContent =
    document.getElementById(
        "qrUploadContent"
    );


const qrDropArea =
    document.getElementById(
        "qrDropArea"
    );


const qrImageData =
    document.getElementById(
        "qr_image_data"
    );


const qrImageName =
    document.getElementById(
        "qr_image_name"
    );


const qrError =
    document.getElementById(
        "qrError"
    );


/* =====================================================
   PROCESS QR
   ===================================================== */

function processQRFile(file){

    if(!file){
        return;
    }


    const allowedTypes = [

        "image/png",
        "image/jpeg",
        "image/jpg"

    ];


    /* FILE TYPE */

    if(!allowedTypes.includes(file.type)){

        qrError.innerText =
            "Only PNG, JPG and JPEG images are allowed.";

        qrError.style.display =
            "block";

        qrFile.value = "";

        return;
    }


    /* FILE SIZE */

    if(file.size > 5 * 1024 * 1024){

        qrError.innerText =
            "QR image must be less than 5 MB.";

        qrError.style.display =
            "block";

        qrFile.value = "";

        return;
    }


    qrError.style.display =
        "none";


    const reader =
        new FileReader();


    reader.onload =
        function(e){

            /* PREVIEW */

            qrPreview.src =
                e.target.result;

            qrPreview.style.display =
                "block";


            qrUploadContent.style.display =
                "none";


            /* BASE64 */

            qrImageData.value =
                e.target.result;


            /* ORIGINAL NAME */

            qrImageName.value =
                file.name;

        };


    reader.readAsDataURL(file);

}


/* =====================================================
   QR BROWSE
   ===================================================== */

qrFile.addEventListener(
    "change",
    function(){

        if(this.files &&
           this.files.length > 0){

            processQRFile(
                this.files[0]
            );

        }

    }
);


/* =====================================================
   QR DRAG OVER
   ===================================================== */

qrDropArea.addEventListener(
    "dragover",
    function(e){

        e.preventDefault();

        qrDropArea.classList.add(
            "drag"
        );

    }
);


/* =====================================================
   QR DRAG LEAVE
   ===================================================== */

qrDropArea.addEventListener(
    "dragleave",
    function(){

        qrDropArea.classList.remove(
            "drag"
        );

    }
);


/* =====================================================
   QR DROP
   ===================================================== */

qrDropArea.addEventListener(
    "drop",
    function(e){

        e.preventDefault();

        qrDropArea.classList.remove(
            "drag"
        );


        const files =
            e.dataTransfer.files;


        if(files.length > 0){

            processQRFile(
                files[0]
            );

        }

    }
);


/* =====================================================
   INITIAL PAYMENT STATE
   ===================================================== */

togglePaymentFields();

</script>


</body>

</html>