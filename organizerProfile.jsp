<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   ORGANIZER LOGIN CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) session.getAttribute("role");
if (role == null || !"Organizer".equalsIgnoreCase(role)) {
    response.sendRedirect("login.jsp");
    return;
}

int organizerId = Integer.parseInt(session.getAttribute("userId").toString());
String userName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Organizer";
String msg = request.getParameter("msg");

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

String fullName = userName;
String email = "";
String businessName = "";
String contactPhone = "";
String businessAddress = "";
int experienceYears = 0;
String organizerDesc = "";
String servicesDesc = "";
String qrImage = null;
String idDocument = null;
String verificationStatus = "Not Submitted";
String rejectionReason = null;
Timestamp verifiedAt = null;

try {
    conn = DBConnection.getConnection();

    // Query user and profile
    String sql =
        "SELECT u.full_name, u.email, p.* " +
        "FROM users u " +
        "LEFT JOIN organizer_profiles p ON u.id = p.organizer_id " +
        "WHERE u.id = ?";

    ps = conn.prepareStatement(sql);
    ps.setInt(1, organizerId);
    rs = ps.executeQuery();

    if (rs.next()) {
        fullName = rs.getString("full_name");
        email = rs.getString("email");
        businessName = rs.getString("business_name") != null ? rs.getString("business_name") : "";
        contactPhone = rs.getString("contact_phone") != null ? rs.getString("contact_phone") : "";
        businessAddress = rs.getString("business_address") != null ? rs.getString("business_address") : "";
        experienceYears = rs.getInt("experience_years");
        organizerDesc = rs.getString("organizer_description") != null ? rs.getString("organizer_description") : "";
        servicesDesc = rs.getString("services_description") != null ? rs.getString("services_description") : "";
        qrImage = rs.getString("qr_image");
        idDocument = rs.getString("id_document");
        if (rs.getString("verification_status") != null) {
            verificationStatus = rs.getString("verification_status");
        }
        rejectionReason = rs.getString("rejection_reason");
        verifiedAt = rs.getTimestamp("verified_at");

        // If profile row didn't exist yet, create one
        if (rs.getObject("profile_id") == null) {
            try (PreparedStatement initPs = conn.prepareStatement(
                    "INSERT INTO organizer_profiles (organizer_id, verification_status) VALUES (?, 'Not Submitted')")) {
                initPs.setInt(1, organizerId);
                initPs.executeUpdate();
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Organizer Profile & Verification | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin:0; padding:0; box-sizing:border-box; font-family:'Poppins', sans-serif; }
        body { background:#08101f; color:white; min-height:100vh; }

        .navbar {
            height:75px;
            display:flex;
            justify-content:space-between;
            align-items:center;
            padding:0 50px;
            background:#111a2c;
            border-bottom:1px solid #283750;
        }
        .logo {
            font-size:24px;
            font-weight:700;
            background:linear-gradient(90deg, #8f4cff, #ffd369);
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
        }
        .nav-links { display:flex; gap:25px; align-items:center; }
        .nav-links a { color:#cbd5e8; text-decoration:none; font-size:14px; font-weight:500; transition:0.3s; }
        .nav-links a:hover { color:#ffd369; }
        .nav-links a.active { color:#ffd369; font-weight:700; }

        .container { width:92%; max-width:1150px; margin:40px auto 80px; }

        .page-header { margin-bottom:25px; }
        .page-title { font-size:32px; font-weight:700; color:#fff; }
        .page-subtitle { color:#94a3b8; font-size:15px; margin-top:4px; }

        /* Alerts */
        .alert {
            padding:14px 20px;
            border-radius:12px;
            margin-bottom:25px;
            font-size:14px;
            font-weight:500;
            display:flex;
            align-items:center;
            justify-content:space-between;
        }
        .alert-success { background:rgba(34,197,94,0.15); border:1px solid #22c55e; color:#4ade80; }

        /* Verification Status Banner */
        .verif-banner {
            border-radius:18px;
            padding:25px 30px;
            margin-bottom:30px;
            display:flex;
            align-items:center;
            justify-content:space-between;
            flex-wrap:wrap;
            gap:20px;
        }
        .verif-verified { background:linear-gradient(135deg, rgba(34,197,94,0.15), rgba(16,185,129,0.25)); border:1px solid #22c55e; }
        .verif-pending { background:linear-gradient(135deg, rgba(234,179,8,0.15), rgba(202,138,4,0.25)); border:1px solid #facc15; }
        .verif-rejected { background:linear-gradient(135deg, rgba(239,68,68,0.15), rgba(220,38,38,0.25)); border:1px solid #ef4444; }
        .verif-unsubmitted { background:linear-gradient(135deg, rgba(56,189,248,0.15), rgba(124,58,237,0.2)); border:1px solid #38bdf8; }

        .verif-info h3 { font-size:20px; font-weight:700; margin-bottom:6px; }
        .verif-info p { color:#cbd5e1; font-size:14px; line-height:1.5; }

        .badge-pill {
            padding:6px 16px;
            border-radius:20px;
            font-weight:700;
            font-size:13px;
            display:inline-flex;
            align-items:center;
            gap:6px;
        }

        /* Form Card */
        .form-card {
            background:#111a2d;
            border:1px solid #26354d;
            border-radius:20px;
            padding:35px;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
        }

        .section-header {
            font-size:18px;
            font-weight:600;
            color:#ffd369;
            margin:30px 0 18px;
            padding-bottom:10px;
            border-bottom:1px solid #233550;
            display:flex;
            align-items:center;
            gap:8px;
        }
        .section-header:first-of-type { margin-top:0; }

        .form-grid {
            display:grid;
            grid-template-columns:1fr 1fr;
            gap:20px;
            margin-bottom:20px;
        }
        .form-group { display:flex; flex-direction:column; gap:8px; }
        .form-group.full { grid-column:1 / -1; }

        label { font-size:13px; font-weight:500; color:#cbd5e1; }
        label span { color:#ff4fa3; }

        input, textarea {
            background:#0b1220;
            border:1px solid #2d3e58;
            border-radius:10px;
            padding:12px 16px;
            color:white;
            font-size:14px;
            outline:none;
            transition:0.25s;
        }
        input:focus, textarea:focus {
            border-color:#7c3aed;
            box-shadow:0 0 12px rgba(124, 58, 237, 0.3);
        }
        input[readonly] { background:#16233b; color:#94a3b8; cursor:not-allowed; }
        textarea { resize:vertical; min-height:90px; }

        /* Upload preview box */
        .upload-row {
            display:grid;
            grid-template-columns:1fr 1fr;
            gap:20px;
            margin-bottom:20px;
        }
        .upload-card {
            background:#0c1424;
            border:1px dashed #2d3e58;
            border-radius:14px;
            padding:20px;
            text-align:center;
        }
        .preview-img {
            max-width:140px;
            max-height:140px;
            object-fit:cover;
            border-radius:10px;
            margin:12px auto;
            display:block;
            border:1px solid #334155;
        }

        .submit-btn {
            width:100%;
            padding:15px;
            background:linear-gradient(135deg, #7c3aed, #9333ea);
            color:white;
            border:none;
            border-radius:12px;
            font-size:16px;
            font-weight:700;
            cursor:pointer;
            transition:0.3s;
            margin-top:20px;
            box-shadow:0 8px 25px rgba(124, 58, 237, 0.35);
        }
        .submit-btn:hover { opacity:0.95; transform:translateY(-2px); box-shadow:0 12px 30px rgba(124, 58, 237, 0.5); }

        @media(max-width:768px){
            .navbar { padding:0 20px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:12px; }
            .form-grid, .upload-row { grid-template-columns:1fr; }
            .verif-banner { flex-direction:column; align-items:flex-start; }
        }
    </style>
</head>
<body>

<div class="navbar">
    <div class="logo">EventSphere</div>
    <div class="nav-links">
        <a href="organizerDashboard.jsp">Dashboard</a>
        <a href="addEvent.jsp">Add Event</a>
        <a href="manageEvents.jsp">Manage Events</a>
        <a href="incomingRequests.jsp">Custom Requests</a>
        <a href="organizerProfile.jsp" class="active">My Profile</a>
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <div class="page-header">
        <h1 class="page-title">Organizer Profile & Verification</h1>
        <p class="page-subtitle">Manage your business brand, payment settings, and platform trust verification credentials.</p>
    </div>

    <% if ("updated".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-success">
            <span>✅ Profile updated successfully! Your business information and verification documents have been saved.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } %>

    <!-- VERIFICATION STATUS BANNER -->
    <% if ("Verified".equalsIgnoreCase(verificationStatus)) { %>
        <div class="verif-banner verif-verified">
            <div class="verif-info">
                <h3 style="color:#4ade80;">✅ Verified Organizer</h3>
                <p>Congratulations! Your business credentials have been officially vetted and approved by the EventSphere Administration. The <strong>Verified Organizer</strong> badge is actively displayed on all your public events and proposals.</p>
                <% if (verifiedAt != null) { %>
                    <small style="color:#86efac; display:block; margin-top:4px;">Verified on: <%= verifiedAt.toString().substring(0, 10) %></small>
                <% } %>
            </div>
            <div>
                <span class="badge-pill" style="background:#14532d; color:#86efac; border:1px solid #22c55e;">VERIFIED BADGE ACTIVE</span>
            </div>
        </div>
    <% } else if ("Pending".equalsIgnoreCase(verificationStatus) || "Under Review".equalsIgnoreCase(verificationStatus)) { %>
        <div class="verif-banner verif-pending">
            <div class="verif-info">
                <h3 style="color:#facc15;">⏳ Verification Under Review</h3>
                <p>Your business credentials and identification proof have been submitted and are currently in queue for administrator review. Reviews typically take 24-48 business hours.</p>
            </div>
            <div>
                <span class="badge-pill" style="background:#713f12; color:#fde047; border:1px solid #eab308;">PENDING REVIEW</span>
            </div>
        </div>
    <% } else if ("Rejected".equalsIgnoreCase(verificationStatus)) { %>
        <div class="verif-banner verif-rejected">
            <div class="verif-info">
                <h3 style="color:#f87171;">⚠️ Verification Rejected</h3>
                <p>Your previous verification documents could not be verified by the admin.</p>
                <% if (rejectionReason != null && !rejectionReason.trim().isEmpty()) { %>
                    <div style="background:rgba(239,68,68,0.2); border-left:3px solid #ef4444; padding:8px 14px; margin-top:8px; border-radius:4px; font-size:13px; color:#fca5a5;">
                        <strong>Admin Feedback:</strong> <%= SecurityUtil.escapeHtml(rejectionReason) %>
                    </div>
                <% } %>
                <p style="margin-top:8px; font-size:13px;">Please upload valid, clear documents below and save your profile to resubmit for review.</p>
            </div>
            <div>
                <span class="badge-pill" style="background:#7f1d1d; color:#fca5a5; border:1px solid #ef4444;">ACTION REQUIRED</span>
            </div>
        </div>
    <% } else { %>
        <div class="verif-banner verif-unsubmitted">
            <div class="verif-info">
                <h3 style="color:#38bdf8;">🛡️ Get Verified on EventSphere</h3>
                <p>Submit your Business Registration, College Club ID, or Government ID proof below to earn the <strong>Verified Organizer Badge</strong>. Verified organizers receive 3.5x higher bookings and customer trust.</p>
            </div>
            <div>
                <span class="badge-pill" style="background:#1e293b; color:#38bdf8; border:1px solid #38bdf8;">NOT SUBMITTED</span>
            </div>
        </div>
    <% } %>

    <!-- Profile Form -->
    <div class="form-card">
        <form action="updateOrganizerProfile.jsp" method="post" id="profileForm">
            <div class="section-header">👤 Account & Business Identity</div>
            <div class="form-grid">
                <div class="form-group">
                    <label>Registered Account Name</label>
                    <input type="text" value="<%= SecurityUtil.escapeHtml(fullName) %>" readonly>
                </div>
                <div class="form-group">
                    <label>Account Email</label>
                    <input type="email" value="<%= SecurityUtil.escapeHtml(email) %>" readonly>
                </div>
                <div class="form-group">
                    <label>Business / Club Name <span>*</span></label>
                    <input type="text" name="business_name" value="<%= SecurityUtil.escapeHtml(businessName) %>" placeholder="e.g. Nexus Events & Production" required maxlength="150">
                </div>
                <div class="form-group">
                    <label>Contact Phone <span>*</span></label>
                    <input type="tel" name="contact_phone" value="<%= SecurityUtil.escapeHtml(contactPhone) %>" placeholder="e.g. +91 98765 43210" required maxlength="20">
                </div>
                <div class="form-group">
                    <label>Years of Industry Experience</label>
                    <input type="number" name="experience_years" value="<%= experienceYears %>" min="0" max="60">
                </div>
                <div class="form-group">
                    <label>Office / Campus Address</label>
                    <input type="text" name="business_address" value="<%= SecurityUtil.escapeHtml(businessAddress) %>" placeholder="City, State, Campus..." maxlength="255">
                </div>
                <div class="form-group full">
                    <label>About Us / Bio</label>
                    <textarea name="organizer_description" placeholder="Share your story, previous events conducted, team background, and achievements..."><%= SecurityUtil.escapeHtml(organizerDesc) %></textarea>
                </div>
                <div class="form-group full">
                    <label>Specialized Services Offered</label>
                    <textarea name="services_description" placeholder="e.g. Full Stage Setup, 4K Photography & Videography, Catering, DJ Nights, Sports Ground Management..."><%= SecurityUtil.escapeHtml(servicesDesc) %></textarea>
                </div>
            </div>

            <div class="section-header">📸 Payment & Verification Assets</div>
            <div class="upload-row">
                <!-- QR Image -->
                <div class="upload-card">
                    <label style="font-weight:600; display:block; margin-bottom:8px;">UPI Payment QR Code</label>
                    <p style="font-size:12px; color:#94a3b8; margin-bottom:12px;">Displayed to attendees and clients during UPI checkout.</p>
                    
                    <% if (qrImage != null && !qrImage.trim().isEmpty()) { %>
                        <img src="images/<%= SecurityUtil.escapeHtml(qrImage) %>" class="preview-img" alt="QR Code Preview" id="qrPreview">
                    <% } else { %>
                        <img src="images/image2.png" class="preview-img" alt="Default QR" id="qrPreview" style="opacity:0.4;">
                    <% } %>

                    <input type="file" id="qrFile" accept="image/png,image/jpeg,image/jpg" style="display:none;" onchange="handleFile(this, 'qrPreview', 'qrData', 'qrName')">
                    <button type="button" onclick="document.getElementById('qrFile').click()" style="background:#1e293b; color:#38bdf8; border:1px solid #0284c7; padding:8px 16px; border-radius:8px; font-size:12px; cursor:pointer; font-weight:600;">
                        📷 Upload New QR Image
                    </button>
                    <input type="hidden" name="qr_data" id="qrData">
                    <input type="hidden" name="qr_name" id="qrName">
                </div>

                <!-- ID Document -->
                <div class="upload-card">
                    <label style="font-weight:600; display:block; margin-bottom:8px;">Business License / ID Proof Document</label>
                    <p style="font-size:12px; color:#94a3b8; margin-bottom:12px;">GST Certificate, College Authorization Letter, or Govt ID proof.</p>
                    
                    <% if (idDocument != null && !idDocument.trim().isEmpty()) { %>
                        <img src="images/<%= SecurityUtil.escapeHtml(idDocument) %>" class="preview-img" alt="ID Document Preview" id="idPreview">
                        <small style="color:#4ade80; display:block; margin-bottom:8px;">✓ Document currently on file</small>
                    <% } else { %>
                        <img src="images/image2.png" class="preview-img" alt="Default ID" id="idPreview" style="opacity:0.4;">
                        <small style="color:#94a3b8; display:block; margin-bottom:8px;">No document uploaded yet</small>
                    <% } %>

                    <input type="file" id="idFile" accept="image/png,image/jpeg,image/jpg" style="display:none;" onchange="handleFile(this, 'idPreview', 'idData', 'idName')">
                    <button type="button" onclick="document.getElementById('idFile').click()" style="background:#1e293b; color:#ffd369; border:1px solid #ca8a04; padding:8px 16px; border-radius:8px; font-size:12px; cursor:pointer; font-weight:600;">
                        📄 Upload Proof Document
                    </button>
                    <input type="hidden" name="id_data" id="idData">
                    <input type="hidden" name="id_name" id="idName">
                </div>
            </div>

            <button type="submit" class="submit-btn">💾 Save Profile & Submit Verification</button>
        </form>
    </div>
</div>

<script>
function handleFile(input, previewId, dataId, nameId) {
    if (input.files && input.files[0]) {
        const file = input.files[0];
        if (file.size > 5 * 1024 * 1024) {
            alert('File must be smaller than 5 MB.');
            return;
        }

        const reader = new FileReader();
        reader.onload = function(e) {
            const preview = document.getElementById(previewId);
            preview.src = e.target.result;
            preview.style.opacity = '1';
            document.getElementById(dataId).value = e.target.result;
            document.getElementById(nameId).value = file.name;
        };
        reader.readAsDataURL(file);
    }
}
</script>

</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:#f87171;padding:30px;'>Error</h2>");
    out.println("<p style='padding:0 30px;color:#cbd5e1;'>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
} finally {
    DBConnection.close(rs, ps, conn);
}
%>
