<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   CERTIFICATE GENERATOR (PHASE 9)
   ===================================================== */
String regIdParam = request.getParameter("id");
String certIdParam = request.getParameter("cert_id");

if ((regIdParam == null || regIdParam.trim().isEmpty()) && (certIdParam == null || certIdParam.trim().isEmpty())) {
    response.sendRedirect("myRegistrations.jsp");
    return;
}

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = DBConnection.getConnection();
    String sql =
        "SELECT r.*, e.event_name, e.category, e.event_date, e.venue, " +
        "u.full_name AS organizer_name, op.business_name, op.verification_status " +
        "FROM registrations r " +
        "JOIN events e ON r.event_id = e.event_id " +
        "LEFT JOIN users u ON e.organizer_id = u.id " +
        "LEFT JOIN organizer_profiles op ON e.organizer_id = op.organizer_id " +
        "WHERE " + (certIdParam != null && !certIdParam.trim().isEmpty() ? "r.certificate_id = ?" : "r.registration_id = ?");

    ps = conn.prepareStatement(sql);
    if (certIdParam != null && !certIdParam.trim().isEmpty()) {
        ps.setString(1, certIdParam.trim());
    } else {
        ps.setInt(1, Integer.parseInt(regIdParam.trim()));
    }
    rs = ps.executeQuery();

    if (!rs.next()) {
        response.sendRedirect("myRegistrations.jsp?error=certificate_not_found");
        return;
    }

    String checkInStatus = rs.getString("check_in_status");
    if (!"Checked In".equalsIgnoreCase(checkInStatus)) {
        // Cannot issue certificate if attendee did not check in at the event gate!
        out.println("<script>alert('Attendance not verified! Certificates are unlocked once your admission is scanned at the event gate.'); history.back();</script>");
        return;
    }

    String attendeeName = rs.getString("full_name");
    String eventName = rs.getString("event_name");
    String category = rs.getString("category");
    Date eventDate = rs.getDate("event_date");
    String venue = rs.getString("venue");
    String certificateId = rs.getString("certificate_id");
    Timestamp checkedInAt = rs.getTimestamp("checked_in_at");
    String organizerBusiness = rs.getString("business_name") != null && !rs.getString("business_name").trim().isEmpty()
        ? rs.getString("business_name") : rs.getString("organizer_name");

    String verifyUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + request.getContextPath() + "/verifyCertificate.jsp?cert_id=" + certificateId;
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verified Certificate: <%= SecurityUtil.escapeHtml(attendeeName) %> | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700;800;900&family=Poppins:wght@300;400;500;600;700&family=Great+Vibes&family=Space+Mono:wght@700&display=swap" rel="stylesheet">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #060913;
            color: #1e293b;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 40px 20px;
            font-family: 'Poppins', sans-serif;
        }

        .actions-bar {
            width: 100%;
            max-width: 950px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
        }

        .btn-action {
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.15);
            color: #cbd5e1;
            padding: 9px 20px;
            border-radius: 10px;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .btn-action:hover { background: rgba(255, 255, 255, 0.16); color: white; }

        .btn-download {
            background: linear-gradient(135deg, #d97706, #b45309);
            color: white;
            border: none;
            box-shadow: 0 4px 15px rgba(217, 119, 6, 0.4);
        }
        .btn-download:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(217, 119, 6, 0.6); }

        /* Certificate Canvas */
        .cert-container {
            width: 100%;
            max-width: 950px;
            background: #ffffff;
            border-radius: 12px;
            padding: 35px;
            position: relative;
            box-shadow: 0 25px 60px rgba(0, 0, 0, 0.8), 0 0 40px rgba(217, 119, 6, 0.2);
            color: #1e293b;
        }

        /* Ornate Gold Borders */
        .cert-inner-border {
            border: 3px double #d97706;
            padding: 40px 45px;
            position: relative;
            background: radial-gradient(circle at center, #ffffff 60%, #fffbeb 100%);
        }

        .cert-corner {
            position: absolute;
            width: 35px;
            height: 35px;
            border: 3px solid #b45309;
        }
        .corner-tl { top: 8px; left: 8px; border-right: none; border-bottom: none; }
        .corner-tr { top: 8px; right: 8px; border-left: none; border-bottom: none; }
        .corner-bl { bottom: 8px; left: 8px; border-right: none; border-top: none; }
        .corner-br { bottom: 8px; right: 8px; border-left: none; border-top: none; }

        /* Certificate Content */
        .cert-header {
            text-align: center;
            margin-bottom: 25px;
        }

        .cert-logo {
            font-size: 14px;
            font-weight: 800;
            letter-spacing: 4px;
            text-transform: uppercase;
            color: #b45309;
            margin-bottom: 8px;
        }

        .cert-title {
            font-family: 'Cinzel', serif;
            font-size: 34px;
            font-weight: 800;
            color: #1e293b;
            letter-spacing: 2px;
            text-transform: uppercase;
            line-height: 1.2;
        }

        .cert-subtitle {
            font-size: 13px;
            letter-spacing: 3px;
            text-transform: uppercase;
            color: #64748b;
            margin-top: 6px;
            font-weight: 600;
        }

        .cert-body {
            text-align: center;
            margin: 30px 0;
        }

        .cert-presented {
            font-size: 14px;
            color: #64748b;
            font-style: italic;
            margin-bottom: 12px;
        }

        .recipient-name {
            font-family: 'Cinzel', serif;
            font-size: 36px;
            font-weight: 900;
            color: #b45309;
            border-bottom: 2px solid #fde68a;
            display: inline-block;
            padding: 0 40px 10px;
            margin-bottom: 20px;
            letter-spacing: 1px;
        }

        .cert-statement {
            font-size: 15px;
            line-height: 1.7;
            color: #334155;
            max-width: 680px;
            margin: 0 auto;
        }

        .cert-event-name {
            font-weight: 800;
            color: #0f172a;
        }

        /* Footer & Signatures */
        .cert-footer {
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            margin-top: 45px;
            padding-top: 25px;
            border-top: 1px dashed #e2e8f0;
        }

        .signature-box {
            text-align: center;
            width: 220px;
        }

        .signature-font {
            font-family: 'Great Vibes', cursive;
            font-size: 36px;
            color: #1e293b;
            line-height: 1;
            margin-bottom: 5px;
        }

        .sign-line {
            border-top: 1.5px solid #64748b;
            margin-top: 6px;
            padding-top: 6px;
            font-size: 12px;
            color: #475569;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .seal-box {
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        .official-seal {
            width: 85px;
            height: 85px;
            border-radius: 50%;
            border: 3px double #d97706;
            background: radial-gradient(circle, #fef3c7, #fde68a);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 15px rgba(217, 119, 6, 0.25);
            text-align: center;
        }
        .seal-text { font-size: 8px; font-weight: 900; letter-spacing: 1px; color: #92400e; text-transform: uppercase; }
        .seal-icon { font-size: 20px; }

        .cert-qr-box {
            display: flex;
            align-items: center;
            gap: 12px;
            text-align: left;
        }

        .cert-id-info {
            font-size: 11px;
            color: #64748b;
            line-height: 1.4;
        }

        .cert-id-badge {
            font-family: 'Space Mono', monospace;
            font-size: 11px;
            font-weight: 700;
            color: #b45309;
        }

        /* Print CSS for Landscape Letter */
        @media print {
            body { background: white !important; padding: 0 !important; }
            .actions-bar { display: none !important; }
            .cert-container {
                box-shadow: none !important;
                border-radius: 0 !important;
                max-width: 100% !important;
                width: 100% !important;
                padding: 10px !important;
            }
            @page { size: landscape; margin: 0.5cm; }
        }
    </style>
</head>
<body>

<div class="actions-bar">
    <a href="viewTicket.jsp?id=<%= rs.getInt("registration_id") %>" class="btn-action">← Back to Ticket</a>
    <button type="button" class="btn-action btn-download" onclick="window.print()">
        🖨️ Download Certificate (PDF)
    </button>
</div>

<div class="cert-container">
    <div class="cert-inner-border">
        <div class="cert-corner corner-tl"></div>
        <div class="cert-corner corner-tr"></div>
        <div class="cert-corner corner-bl"></div>
        <div class="cert-corner corner-br"></div>

        <div class="cert-header">
            <div class="cert-logo">EVENTSPHERE VERIFIED CREDENTIAL</div>
            <h1 class="cert-title">Certificate of Participation</h1>
            <div class="cert-subtitle">Official College & Platform Recognition</div>
        </div>

        <div class="cert-body">
            <div class="cert-presented">This certificate is proudly awarded to</div>
            <div class="recipient-name"><%= SecurityUtil.escapeHtml(attendeeName) %></div>
            <p class="cert-statement">
                for active participation and successful completion of the <%= SecurityUtil.escapeHtml(category) %> event
                <br>
                <span class="cert-event-name">"<%= SecurityUtil.escapeHtml(eventName) %>"</span>
                <br>
                held on <strong><%= eventDate != null ? new java.text.SimpleDateFormat("MMMM dd, yyyy").format(eventDate) : "TBA" %></strong>
                at <%= SecurityUtil.escapeHtml(venue) %>, organized by <strong><%= SecurityUtil.escapeHtml(organizerBusiness) %></strong>.
            </p>
        </div>

        <div class="cert-footer">
            <!-- Left: Organizer Signature -->
            <div class="signature-box">
                <div class="signature-font"><%= SecurityUtil.escapeHtml(organizerBusiness) %></div>
                <div class="sign-line">Event Host & Organizer</div>
            </div>

            <!-- Center: Verified Gold Seal -->
            <div class="seal-box">
                <div class="official-seal">
                    <span class="seal-text">OFFICIAL</span>
                    <span class="seal-icon">🏆</span>
                    <span class="seal-text">VERIFIED</span>
                </div>
            </div>

            <!-- Right: QR Code & Verification ID -->
            <div class="cert-qr-box">
                <div id="certQrcode" style="width:70px; height:70px;"></div>
                <div class="cert-id-info">
                    <div><strong>Certificate ID:</strong></div>
                    <div class="cert-id-badge"><%= certificateId %></div>
                    <div style="margin-top:3px;"><a href="<%= verifyUrl %>" target="_blank" style="color:#d97706; text-decoration:none; font-weight:600;">Scan to Verify Online ↗</a></div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    // Generate QR Code linking to online verification
    const verifyUrl = "<%= verifyUrl %>";
    if (typeof QRCode !== 'undefined') {
        new QRCode(document.getElementById("certQrcode"), {
            text: verifyUrl,
            width: 70,
            height: 70,
            colorDark: "#1e293b",
            colorLight: "#ffffff",
            correctLevel: QRCode.CorrectLevel.M
        });
    }
</script>

</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:red;'>Certificate Error</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
} finally {
    DBConnection.close(rs, ps, conn);
}
%>
