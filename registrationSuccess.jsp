<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   LOGIN CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(session.getAttribute("userId").toString());

String eventIdParam = request.getParameter("id");
String regIdParam = request.getParameter("reg_id");

int regId = 0;
if (regIdParam != null && !regIdParam.trim().isEmpty()) {
    try {
        regId = Integer.parseInt(regIdParam.trim());
    } catch (Exception ignored) {}
}

int eventId = 0;
if (eventIdParam != null && !eventIdParam.trim().isEmpty()) {
    try {
        eventId = Integer.parseInt(eventIdParam.trim());
    } catch (Exception ignored) {}
}

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

String eventName = "Event";
String fullName = (String) session.getAttribute("userName");
Date eventDate = null;
Time eventTime = null;
String venue = null;
String paymentType = "Free";
double eventFee = 0.0;
String paymentStatus = "Approved";
String paymentMethod = "Free";
String transactionId = null;
Timestamp regDate = null;
boolean foundDetails = false;

try {
    conn = DBConnection.getConnection();

    if (regId > 0) {
        ps = conn.prepareStatement(
            "SELECT r.registration_id, r.full_name, r.payment_status, r.payment_method, r.transaction_id, r.registration_date, " +
            "e.event_id, e.event_name, e.event_date, e.event_time, e.venue, e.payment_type, e.event_fee " +
            "FROM registrations r " +
            "INNER JOIN events e ON r.event_id = e.event_id " +
            "WHERE r.registration_id = ? AND r.user_id = ?"
        );
        ps.setInt(1, regId);
        ps.setInt(2, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            foundDetails = true;
            eventId = rs.getInt("event_id");
            eventName = rs.getString("event_name");
            fullName = rs.getString("full_name");
            paymentStatus = rs.getString("payment_status");
            paymentMethod = rs.getString("payment_method");
            transactionId = rs.getString("transaction_id");
            regDate = rs.getTimestamp("registration_date");
            eventDate = rs.getDate("event_date");
            eventTime = rs.getTime("event_time");
            venue = rs.getString("venue");
            paymentType = rs.getString("payment_type");
            eventFee = rs.getDouble("event_fee");
        }
    } else if (eventId > 0) {
        ps = conn.prepareStatement("SELECT event_name, event_date, event_time, venue, payment_type, event_fee FROM events WHERE event_id = ?");
        ps.setInt(1, eventId);
        rs = ps.executeQuery();
        if (rs.next()) {
            eventName = rs.getString("event_name");
            eventDate = rs.getDate("event_date");
            eventTime = rs.getTime("event_time");
            venue = rs.getString("venue");
            paymentType = rs.getString("payment_type");
            eventFee = rs.getDouble("event_fee");
        }
    }
} catch (Exception ignored) {
} finally {
    DBConnection.close(rs, ps, conn);
}

boolean isPending = "Pending".equalsIgnoreCase(paymentStatus);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registration Confirmation | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin:0; padding:0; box-sizing:border-box; font-family:'Poppins', sans-serif; }
        body {
            margin:0;
            background:#08101f;
            color:white;
            min-height:100vh;
            display:flex;
            flex-direction:column;
            align-items:center;
            justify-content:center;
            padding:30px 15px;
        }

        .success-box {
            width:100%;
            max-width:620px;
            background:#111a2d;
            border:1px solid #283750;
            border-radius:24px;
            padding:45px 35px;
            text-align:center;
            box-shadow:0 25px 50px rgba(0,0,0,0.5);
            position:relative;
        }

        .icon-wrapper {
            width:84px;
            height:84px;
            margin:0 auto 20px;
            border-radius:50%;
            display:flex;
            align-items:center;
            justify-content:center;
            font-size:42px;
            background:<%= isPending ? "rgba(234, 179, 8, 0.15)" : "rgba(34, 197, 94, 0.15)" %>;
            border:2px solid <%= isPending ? "#facc15" : "#22c55e" %>;
        }

        h1 {
            color:<%= isPending ? "#facc15" : "#4ade80" %>;
            font-size:28px;
            font-weight:700;
            margin-bottom:8px;
        }

        .subtext {
            color:#94a3b8;
            font-size:15px;
            margin-bottom:28px;
            line-height:1.6;
        }

        /* Receipt Card */
        .receipt-card {
            background:#16233b;
            border:1px solid #283852;
            border-radius:16px;
            padding:22px;
            text-align:left;
            margin-bottom:28px;
        }

        .receipt-header {
            display:flex;
            justify-content:space-between;
            align-items:center;
            border-bottom:1px solid #283852;
            padding-bottom:14px;
            margin-bottom:14px;
        }

        .event-title {
            font-size:18px;
            font-weight:600;
            color:#fff;
        }

        .receipt-grid {
            display:grid;
            grid-template-columns:1fr 1fr;
            gap:14px;
            font-size:13px;
        }

        .receipt-item span {
            display:block;
            color:#94a3b8;
            font-size:12px;
            margin-bottom:2px;
        }
        .receipt-item strong {
            color:#f1f5f9;
            font-weight:500;
        }

        .status-pill {
            display:inline-block;
            padding:4px 12px;
            border-radius:15px;
            font-size:12px;
            font-weight:600;
            background:<%= isPending ? "rgba(234, 179, 8, 0.2)" : "rgba(34, 197, 94, 0.2)" %>;
            color:<%= isPending ? "#fde047" : "#4ade80" %>;
            border:1px solid <%= isPending ? "#ca8a04" : "#16a34a" %>;
        }

        .notice-box {
            background:rgba(124, 58, 237, 0.1);
            border:1px solid rgba(124, 58, 237, 0.3);
            border-radius:12px;
            padding:14px 18px;
            font-size:13px;
            color:#c4b5fd;
            text-align:left;
            margin-bottom:28px;
            line-height:1.5;
        }

        .buttons {
            display:flex;
            gap:12px;
            justify-content:center;
            flex-wrap:wrap;
        }

        .btn {
            text-decoration:none;
            padding:12px 24px;
            border-radius:12px;
            font-weight:600;
            font-size:14px;
            transition:0.25s;
            display:inline-flex;
            align-items:center;
            gap:6px;
            cursor:pointer;
        }

        .btn-primary {
            background:linear-gradient(135deg, #7c3aed, #9333ea);
            color:white;
            border:none;
        }
        .btn-primary:hover {
            opacity:0.9;
            transform:translateY(-2px);
            box-shadow:0 8px 20px rgba(124, 58, 237, 0.4);
        }

        .btn-secondary {
            background:#1b2842;
            color:#38bdf8;
            border:1px solid #38bdf8;
        }
        .btn-secondary:hover {
            background:rgba(56, 189, 248, 0.15);
            transform:translateY(-2px);
        }

        .btn-print {
            background:transparent;
            color:#cbd5e1;
            border:1px solid #475569;
        }
        .btn-print:hover {
            background:#1e293b;
        }

        @media print {
            body { background:white; color:black; }
            .success-box { box-shadow:none; border:1px solid #ccc; background:white; color:black; }
            .receipt-card { background:#f8fafc; border:1px solid #e2e8f0; color:black; }
            .receipt-header, .receipt-item strong, .event-title { color:black !important; }
            .buttons, .back-link { display:none; }
        }
    </style>
</head>
<body>

<div class="success-box">
    <div class="icon-wrapper">
        <%= isPending ? "⏳" : "🎉" %>
    </div>

    <h1><%= isPending ? "Registration Submitted!" : "Booking Confirmed!" %></h1>
    <p class="subtext">
        <%= isPending 
            ? "Your registration has been received and is pending organizer verification." 
            : "Your seat is officially reserved. See you at the event!" %>
    </p>

    <div class="receipt-card">
        <div class="receipt-header">
            <div>
                <div class="event-title"><%= SecurityUtil.escapeHtml(eventName) %></div>
                <small style="color:#94a3b8;"><%= eventDate != null ? eventDate.toString() : "Date TBA" %> &bull; <%= venue != null ? SecurityUtil.escapeHtml(venue) : "Venue TBA" %></small>
            </div>
            <div>
                <span class="status-pill"><%= isPending ? "🟡 Pending Verification" : ("Free".equalsIgnoreCase(paymentMethod) ? "🎉 Registered (Free)" : "✅ Confirmed") %></span>
            </div>
        </div>

        <div class="receipt-grid">
            <div class="receipt-item">
                <span>Participant</span>
                <strong><%= SecurityUtil.escapeHtml(fullName != null ? fullName : "Customer") %></strong>
            </div>
            <% if (regId > 0) { %>
            <div class="receipt-item">
                <span>Booking ID</span>
                <strong>#REG-<%= regId %></strong>
            </div>
            <% } %>
            <div class="receipt-item">
                <span>Payment Method</span>
                <strong><%= SecurityUtil.escapeHtml(paymentMethod != null ? paymentMethod : ("Paid".equalsIgnoreCase(paymentType) ? "UPI" : "Free")) %></strong>
            </div>
            <div class="receipt-item">
                <span>Amount Paid</span>
                <strong><%= "Paid".equalsIgnoreCase(paymentType) && eventFee > 0 ? ("₹" + String.format("%.2f", eventFee)) : "₹0.00 (Free)" %></strong>
            </div>
            <% if (transactionId != null && !transactionId.trim().isEmpty()) { %>
            <div class="receipt-item" style="grid-column:1 / -1;">
                <span>Transaction Reference</span>
                <strong style="font-family:monospace; color:#38bdf8;"><%= SecurityUtil.escapeHtml(transactionId) %></strong>
            </div>
            <% } %>
        </div>
    </div>

    <div class="notice-box">
        <% if (isPending) { %>
            📌 <strong>Important:</strong> Since you paid via UPI QR Transfer, the organizer will cross-verify your transaction reference against their bank statement. You can monitor verification status at any time in <strong>My Registrations</strong>.
        <% } else { %>
            💡 <strong>Next Steps:</strong> You can download or print this receipt for your records. Check the event venue and schedule on the event page.
        <% } %>
    </div>

    <div class="buttons">
        <a href="myRegistrations.jsp" class="btn btn-primary">📋 View My Registrations</a>
        <a href="userDashboard.jsp" class="btn btn-secondary">🏠 Back to Dashboard</a>
        <button onclick="window.print()" class="btn btn-print">🖨️ Print Receipt</button>
    </div>
</div>

</body>
</html>