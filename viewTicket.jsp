<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   AUTHENTICATION CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

int sessionUserId = Integer.parseInt(session.getAttribute("userId").toString());
String sessionRole = session.getAttribute("role") != null ? session.getAttribute("role").toString() : "User";

String regIdParam = request.getParameter("id");
String tokenParam = request.getParameter("token");

if ((regIdParam == null || regIdParam.trim().isEmpty()) && (tokenParam == null || tokenParam.trim().isEmpty())) {
    response.sendRedirect("myRegistrations.jsp");
    return;
}

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = DBConnection.getConnection();
    String sql =
        "SELECT r.*, e.event_name, e.category, e.event_date, e.event_time, e.venue, e.event_fee, e.payment_type, " +
        "e.organizer_id, u.full_name AS organizer_name, op.business_name, op.contact_phone " +
        "FROM registrations r " +
        "JOIN events e ON r.event_id = e.event_id " +
        "LEFT JOIN users u ON e.organizer_id = u.id " +
        "LEFT JOIN organizer_profiles op ON e.organizer_id = op.organizer_id " +
        "WHERE " + (tokenParam != null && !tokenParam.trim().isEmpty() ? "r.ticket_token = ?" : "r.registration_id = ?");

    ps = conn.prepareStatement(sql);
    if (tokenParam != null && !tokenParam.trim().isEmpty()) {
        ps.setString(1, tokenParam.trim());
    } else {
        ps.setInt(1, Integer.parseInt(regIdParam.trim()));
    }
    rs = ps.executeQuery();

    if (!rs.next()) {
        response.sendRedirect("myRegistrations.jsp?error=ticket_not_found");
        return;
    }

    int regUserId = rs.getInt("user_id");
    int eventOrganizerId = rs.getInt("organizer_id");

    // Guard: Only the attendee, the host organizer, or an Admin may view this ticket
    if (sessionUserId != regUserId && sessionUserId != eventOrganizerId && !"Admin".equalsIgnoreCase(sessionRole)) {
        response.sendRedirect("myRegistrations.jsp?error=unauthorized");
        return;
    }

    int regId = rs.getInt("registration_id");
    String attendeeName = rs.getString("full_name");
    String attendeeEmail = rs.getString("email");
    String attendeePhone = rs.getString("phone");
    String teamName = rs.getString("team_name");
    int teamMembers = rs.getInt("team_members");
    String paymentStatus = rs.getString("payment_status");
    String paymentMethod = rs.getString("payment_method");
    String transactionId = rs.getString("transaction_id");
    String ticketToken = rs.getString("ticket_token");
    String checkInStatus = rs.getString("check_in_status");
    Timestamp checkedInAt = rs.getTimestamp("checked_in_at");
    String certificateId = rs.getString("certificate_id");

    String eventName = rs.getString("event_name");
    String category = rs.getString("category");
    Date eventDate = rs.getDate("event_date");
    Time eventTime = rs.getTime("event_time");
    String venue = rs.getString("venue");
    double eventFee = rs.getDouble("event_fee");
    String paymentType = rs.getString("payment_type");
    String organizerBusiness = rs.getString("business_name") != null && !rs.getString("business_name").trim().isEmpty() 
        ? rs.getString("business_name") : rs.getString("organizer_name");

    boolean isApproved = "Approved".equalsIgnoreCase(paymentStatus) || "Not Required".equalsIgnoreCase(paymentStatus);
    boolean isCheckedIn = "Checked In".equalsIgnoreCase(checkInStatus);
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Ticket Pass: <%= SecurityUtil.escapeHtml(eventName) %> | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Space+Mono:wght@700&display=swap" rel="stylesheet">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Poppins', sans-serif; }
        body {
            background: radial-gradient(circle at top, #140b2b 0%, #080314 60%, #030108 100%);
            color: #f8fafc;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 40px 20px;
        }

        .actions-top {
            width: 100%;
            max-width: 820px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            flex-wrap: wrap;
            gap: 15px;
        }

        .btn-back {
            color: #cbd5e1;
            text-decoration: none;
            font-size: 14px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(255,255,255,0.06);
            border: 1px solid rgba(255,255,255,0.12);
            padding: 8px 16px;
            border-radius: 10px;
            transition: all 0.2s;
        }
        .btn-back:hover { background: rgba(255,255,255,0.12); color: white; }

        .btn-print {
            background: linear-gradient(135deg, #ec4899, #8b5cf6);
            color: white;
            border: none;
            padding: 9px 20px;
            border-radius: 10px;
            font-size: 13.5px;
            font-weight: 600;
            cursor: pointer;
            box-shadow: 0 4px 15px rgba(236, 72, 153, 0.3);
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .btn-print:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(236, 72, 153, 0.45); }

        /* Boarding Pass Ticket */
        .ticket-wrapper {
            width: 100%;
            max-width: 820px;
            background: #0f1526;
            border-radius: 24px;
            box-shadow: 0 25px 60px rgba(0, 0, 0, 0.7), 0 0 35px rgba(139, 92, 246, 0.2);
            border: 1px solid rgba(255, 255, 255, 0.12);
            display: flex;
            overflow: hidden;
            position: relative;
        }

        /* Left Main Section */
        .ticket-main {
            flex: 1;
            padding: 35px 40px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .ticket-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 25px;
            border-bottom: 1px dashed rgba(255, 255, 255, 0.12);
            padding-bottom: 20px;
        }

        .brand-box h3 {
            font-size: 20px;
            font-weight: 800;
            background: linear-gradient(135deg, #ff4fa3, #8b5cf6, #38bdf8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            letter-spacing: 0.5px;
        }

        .brand-box span {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            color: #94a3b8;
            font-weight: 600;
        }

        .category-tag {
            background: rgba(139, 92, 246, 0.15);
            border: 1px solid rgba(139, 92, 246, 0.4);
            color: #c084fc;
            padding: 4px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }

        .event-hero-title {
            font-size: 26px;
            font-weight: 800;
            color: #ffffff;
            line-height: 1.3;
            margin-bottom: 25px;
        }

        .ticket-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
            margin-bottom: 25px;
        }

        .ticket-field {
            display: flex;
            flex-direction: column;
        }

        .field-label {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #64748b;
            font-weight: 600;
            margin-bottom: 4px;
        }

        .field-value {
            font-size: 15px;
            font-weight: 600;
            color: #f1f5f9;
        }

        .field-highlight {
            color: #38bdf8;
            font-family: 'Space Mono', monospace;
        }

        /* Status Banner */
        .status-banner {
            padding: 10px 16px;
            border-radius: 10px;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: 0.5px;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            text-transform: uppercase;
        }
        .banner-valid { background: rgba(16, 185, 129, 0.15); border: 1px solid #10b981; color: #34d399; }
        .banner-checked { background: rgba(56, 189, 248, 0.15); border: 1px solid #38bdf8; color: #38bdf8; }
        .banner-pending { background: rgba(239, 68, 68, 0.15); border: 1px solid #ef4444; color: #f87171; }

        /* Perforated Divider */
        .ticket-divider {
            width: 30px;
            position: relative;
            background: transparent;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            align-items: center;
        }

        .notch-top {
            width: 32px;
            height: 32px;
            background: #080314;
            border-radius: 50%;
            margin-top: -16px;
            border: 1px solid rgba(255,255,255,0.12);
        }

        .dashed-line {
            flex: 1;
            border-right: 2px dashed rgba(255, 255, 255, 0.18);
            width: 1px;
            margin: 5px 0;
        }

        .notch-bottom {
            width: 32px;
            height: 32px;
            background: #080314;
            border-radius: 50%;
            margin-bottom: -16px;
            border: 1px solid rgba(255,255,255,0.12);
        }

        /* Right Stub Section */
        .ticket-stub {
            width: 260px;
            background: rgba(255, 255, 255, 0.02);
            padding: 35px 25px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            text-align: center;
        }

        .qr-card {
            background: #ffffff;
            padding: 12px;
            border-radius: 14px;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.4);
            margin-bottom: 16px;
        }

        .qr-card canvas, .qr-card img {
            display: block;
            margin: 0 auto;
        }

        .token-text {
            font-family: 'Space Mono', monospace;
            font-size: 15px;
            font-weight: 700;
            color: #ffd369;
            letter-spacing: 1px;
            margin-bottom: 4px;
        }

        .stub-desc {
            font-size: 11px;
            color: #94a3b8;
            line-height: 1.4;
            max-width: 200px;
        }

        .cert-btn {
            margin-top: 15px;
            background: linear-gradient(135deg, #10b981, #059669);
            color: white;
            text-decoration: none;
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: 0.2s;
        }
        .cert-btn:hover { opacity: 0.95; transform: scale(1.03); }

        /* Print Media Styles */
        @media print {
            body { background: white !important; color: black !important; padding: 0 !important; }
            .actions-top { display: none !important; }
            .ticket-wrapper {
                box-shadow: none !important;
                border: 2px solid #000 !important;
                background: #fff !important;
                color: #000 !important;
                page-break-inside: avoid;
            }
            .ticket-main, .ticket-stub { color: #000 !important; }
            .field-label { color: #555 !important; }
            .field-value, .event-hero-title { color: #000 !important; }
            .brand-box h3 { color: #000 !important; -webkit-text-fill-color: initial !important; }
            .status-banner { border: 1px solid #000 !important; color: #000 !important; background: #eee !important; }
            .notch-top, .notch-bottom { display: none; }
            .dashed-line { border-right: 2px dashed #000 !important; }
        }

        @media (max-width: 768px) {
            .ticket-wrapper { flex-direction: column; }
            .ticket-divider { display: none; }
            .ticket-stub { width: 100%; border-top: 2px dashed rgba(255,255,255,0.15); padding: 30px 20px; }
            .ticket-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<div class="actions-top">
    <a href="myRegistrations.jsp" class="btn-back">← Back to My Registrations</a>
    <div style="display:flex; gap:10px;">
        <% if (isCheckedIn) { %>
            <a href="certificate.jsp?id=<%= regId %>" class="btn-print" style="background: linear-gradient(135deg, #10b981, #059669);">
                🎓 View Certificate
            </a>
        <% } %>
        <button type="button" class="btn-print" onclick="window.print()">
            🖨️ Print Ticket / PDF
        </button>
    </div>
</div>

<div class="ticket-wrapper">
    <!-- Main Ticket Body -->
    <div class="ticket-main">
        <div>
            <div class="ticket-header">
                <div class="brand-box">
                    <h3>EventSphere</h3>
                    <span>Official Entry Pass</span>
                </div>
                <div class="category-tag"><%= SecurityUtil.escapeHtml(category) %></div>
            </div>

            <div class="event-hero-title">
                <%= SecurityUtil.escapeHtml(eventName) %>
            </div>

            <div class="ticket-grid">
                <div class="ticket-field">
                    <span class="field-label">Attendee Name</span>
                    <span class="field-value"><%= SecurityUtil.escapeHtml(attendeeName) %></span>
                </div>

                <div class="ticket-field">
                    <span class="field-label">Date & Time</span>
                    <span class="field-value">
                        <%= eventDate != null ? new java.text.SimpleDateFormat("EEE, MMM dd, yyyy").format(eventDate) : "TBA" %>
                        <%= eventTime != null ? " • " + new java.text.SimpleDateFormat("hh:mm a").format(eventTime) : "" %>
                    </span>
                </div>

                <div class="ticket-field">
                    <span class="field-label">Venue Location</span>
                    <span class="field-value"><%= SecurityUtil.escapeHtml(venue) %></span>
                </div>

                <div class="ticket-field">
                    <span class="field-label">Host Organizer</span>
                    <span class="field-value"><%= SecurityUtil.escapeHtml(organizerBusiness) %></span>
                </div>

                <% if (teamName != null && !teamName.trim().isEmpty()) { %>
                    <div class="ticket-field">
                        <span class="field-label">Team Registration</span>
                        <span class="field-value"><%= SecurityUtil.escapeHtml(teamName) %> (<%= teamMembers %> members)</span>
                    </div>
                <% } %>

                <div class="ticket-field">
                    <span class="field-label">Transaction Reference</span>
                    <span class="field-value field-highlight"><%= SecurityUtil.escapeHtml(transactionId != null ? transactionId : "FREE") %></span>
                </div>
            </div>
        </div>

        <div>
            <% if (!isApproved) { %>
                <div class="status-banner banner-pending">
                    ⚠️ Payment Pending Organizer Verification • Not Yet Admissible
                </div>
            <% } else if (isCheckedIn) { %>
                <div class="status-banner banner-checked">
                    ✓ Admitted at Gate • Checked In <%= checkedInAt != null ? new java.text.SimpleDateFormat("hh:mm a").format(checkedInAt) : "" %>
                </div>
            <% } else { %>
                <div class="status-banner banner-valid">
                    ✓ Valid Pass • Present QR to Gate Security for Entry
                </div>
            <% } %>
        </div>
    </div>

    <!-- Perforated Divider -->
    <div class="ticket-divider">
        <div class="notch-top"></div>
        <div class="dashed-line"></div>
        <div class="notch-bottom"></div>
    </div>

    <!-- Right Gate Stub with QR Code -->
    <div class="ticket-stub">
        <div class="qr-card">
            <div id="qrcode"></div>
        </div>
        <div class="token-text"><%= ticketToken %></div>
        <div class="stub-desc">Scan at event entrance checkpoint to confirm admission.</div>

        <% if (isCheckedIn) { %>
            <a href="certificate.jsp?id=<%= regId %>" class="cert-btn">
                🎓 Verified Certificate →
            </a>
        <% } %>
    </div>
</div>

<script>
    // Generate QR Code containing the ticket verification token
    const token = "<%= ticketToken %>";
    if (typeof QRCode !== 'undefined') {
        new QRCode(document.getElementById("qrcode"), {
            text: token,
            width: 140,
            height: 140,
            colorDark: "#0b0f19",
            colorLight: "#ffffff",
            correctLevel: QRCode.CorrectLevel.H
        });
    } else {
        // Fallback placeholder if CDN offline
        document.getElementById("qrcode").innerHTML = 
            '<div style="width:140px;height:140px;background:#eee;color:#333;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:bold;text-align:center;padding:5px;">' +
            token + '</div>';
    }
</script>

</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:#f87171;'>Error Rendering Ticket</h2>");
    out.println("<p style='color:#cbd5e1;'>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
} finally {
    DBConnection.close(rs, ps, conn);
}
%>
