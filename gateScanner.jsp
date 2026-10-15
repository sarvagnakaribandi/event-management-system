<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   ORGANIZER / ADMIN LOGIN CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String sessionRole = session.getAttribute("role") != null ? session.getAttribute("role").toString() : "";
int sessionUserId = Integer.parseInt(session.getAttribute("userId").toString());

if (!"Organizer".equalsIgnoreCase(sessionRole) && !"Admin".equalsIgnoreCase(sessionRole)) {
    response.sendRedirect("userDashboard.jsp");
    return;
}

String selectedEventParam = request.getParameter("event_id");
if (selectedEventParam == null || selectedEventParam.trim().isEmpty()) {
    selectedEventParam = request.getParameter("id");
}

int selectedEventId = 0;
if (selectedEventParam != null && !selectedEventParam.trim().isEmpty()) {
    try { selectedEventId = Integer.parseInt(selectedEventParam.trim()); } catch (Exception ignored) {}
}

Connection conn = null;
PreparedStatement psEvents = null;
ResultSet rsEvents = null;
PreparedStatement psStats = null;
ResultSet rsStats = null;
PreparedStatement psRecent = null;
ResultSet rsRecent = null;

java.util.List<java.util.Map<String, Object>> eventList = new java.util.ArrayList<>();
int totalRegistered = 0;
int totalCheckedIn = 0;
String selectedEventTitle = "Select Event";

try {
    conn = DBConnection.getConnection();

    // Query events available for this organizer
    String eventSql = "Admin".equalsIgnoreCase(sessionRole) 
        ? "SELECT event_id, event_name, event_date FROM events ORDER BY event_date DESC"
        : "SELECT event_id, event_name, event_date FROM events WHERE organizer_id = ? ORDER BY event_date DESC";

    psEvents = conn.prepareStatement(eventSql);
    if (!"Admin".equalsIgnoreCase(sessionRole)) {
        psEvents.setInt(1, sessionUserId);
    }
    rsEvents = psEvents.executeQuery();

    while (rsEvents.next()) {
        java.util.Map<String, Object> ev = new java.util.HashMap<>();
        ev.put("id", rsEvents.getInt("event_id"));
        ev.put("name", rsEvents.getString("event_name"));
        eventList.add(ev);
    }

    if (selectedEventId == 0 && !eventList.isEmpty()) {
        selectedEventId = (Integer) eventList.get(0).get("id");
        selectedEventTitle = (String) eventList.get(0).get("name");
    } else {
        for (java.util.Map<String, Object> ev : eventList) {
            if (((Integer) ev.get("id")) == selectedEventId) {
                selectedEventTitle = (String) ev.get("name");
                break;
            }
        }
    }

    if (selectedEventId > 0) {
        // Query event stats
        String statsSql =
            "SELECT COUNT(*) AS total_reg, " +
            "SUM(CASE WHEN check_in_status = 'Checked In' THEN 1 ELSE 0 END) AS checked_in " +
            "FROM registrations WHERE event_id = ?";
        psStats = conn.prepareStatement(statsSql);
        psStats.setInt(1, selectedEventId);
        rsStats = psStats.executeQuery();
        if (rsStats.next()) {
            totalRegistered = rsStats.getInt("total_reg");
            totalCheckedIn = rsStats.getInt("checked_in");
        }

        // Query event title if needed
        PreparedStatement tPs = conn.prepareStatement("SELECT event_name FROM events WHERE event_id = ?");
        tPs.setInt(1, selectedEventId);
        ResultSet tRs = tPs.executeQuery();
        if (tRs.next()) selectedEventTitle = tRs.getString("event_name");
        tRs.close();
        tPs.close();

        // Query recent check-ins
        String recentSql =
            "SELECT full_name, email, ticket_token, checked_in_at, registration_id " +
            "FROM registrations " +
            "WHERE event_id = ? AND check_in_status = 'Checked In' " +
            "ORDER BY checked_in_at DESC LIMIT 15";
        psRecent = conn.prepareStatement(recentSql);
        psRecent.setInt(1, selectedEventId);
        rsRecent = psRecent.executeQuery();
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gate Check-In Scanner | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Space+Mono:wght@700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="css/toast.css">
    <link rel="stylesheet" href="css/notifications.css">
    <!-- jsQR Library for Camera QR scanning -->
    <script src="https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.js"></script>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Poppins', sans-serif; }
        body {
            background: #060913;
            color: #f1f5f9;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* Top Navbar */
        .navbar {
            background: rgba(15, 23, 42, 0.85);
            backdrop-filter: blur(14px);
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            padding: 16px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .logo h2 {
            font-size: 22px;
            font-weight: 800;
            background: linear-gradient(135deg, #ff4fa3, #8b5cf6, #38bdf8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .nav-right { display: flex; align-items: center; gap: 15px; }
        .btn-dash {
            color: #cbd5e1;
            text-decoration: none;
            font-size: 13.5px;
            font-weight: 600;
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid rgba(255, 255, 255, 0.12);
            padding: 8px 16px;
            border-radius: 10px;
            transition: all 0.2s;
        }
        .btn-dash:hover { background: rgba(255, 255, 255, 0.12); color: white; }

        .container {
            width: 92%;
            max-width: 1200px;
            margin: 30px auto 60px;
            flex: 1;
        }

        .header-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 30px;
        }

        .header-title h1 {
            font-size: 28px;
            font-weight: 800;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .header-title p { color: #94a3b8; font-size: 14px; margin-top: 4px; }

        /* Event Selector */
        .event-select-box select {
            background: #0f172a;
            color: #f8fafc;
            border: 1px solid #334155;
            padding: 10px 18px;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 600;
            outline: none;
            cursor: pointer;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
        }

        /* Stats HUD */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 18px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: #0f172a;
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 18px;
            padding: 22px;
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .stat-icon {
            width: 50px;
            height: 50px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
        }

        .stat-val { font-size: 26px; font-weight: 800; color: #ffffff; }
        .stat-lbl { font-size: 12px; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.5px; }

        /* Scanner Main Layout */
        .scanner-grid {
            display: grid;
            grid-template-columns: 1.1fr 0.9fr;
            gap: 30px;
            margin-bottom: 35px;
        }

        .card-box {
            background: #0f172a;
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 20px;
            padding: 26px;
        }

        .card-header {
            font-size: 16px;
            font-weight: 700;
            color: #f8fafc;
            margin-bottom: 18px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* Video Viewfinder */
        .video-wrapper {
            position: relative;
            width: 100%;
            height: 280px;
            background: #020617;
            border-radius: 14px;
            overflow: hidden;
            border: 2px solid #1e293b;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        #cameraVideo {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        #cameraCanvas { display: none; }

        .laser-scanner {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: linear-gradient(90deg, transparent, #ec4899, #8b5cf6, transparent);
            box-shadow: 0 0 15px #ec4899;
            animation: scanLaser 2s infinite ease-in-out;
            pointer-events: none;
        }

        @keyframes scanLaser {
            0% { top: 5%; }
            50% { top: 95%; }
            100% { top: 5%; }
        }

        .camera-overlay-text {
            position: absolute;
            bottom: 12px;
            background: rgba(0, 0, 0, 0.65);
            padding: 4px 14px;
            border-radius: 20px;
            font-size: 11.5px;
            color: #cbd5e1;
        }

        /* Manual Input Box */
        .manual-box {
            margin-top: 20px;
            display: flex;
            gap: 12px;
        }

        .manual-input {
            flex: 1;
            background: #090e1a;
            border: 1px solid #334155;
            padding: 12px 18px;
            border-radius: 12px;
            color: white;
            font-size: 15px;
            font-family: 'Space Mono', monospace;
            outline: none;
            transition: border-color 0.2s;
        }
        .manual-input:focus { border-color: #8b5cf6; box-shadow: 0 0 15px rgba(139, 92, 246, 0.3); }

        .btn-checkin {
            background: linear-gradient(135deg, #10b981, #059669);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 12px;
            font-weight: 700;
            font-size: 14px;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-checkin:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(16, 185, 129, 0.4); }

        /* Real-Time Result Display Box */
        .result-box {
            min-height: 220px;
            border-radius: 16px;
            padding: 24px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
            background: #090e1a;
            border: 2px dashed #1e293b;
            transition: all 0.3s;
        }

        .result-box.state-ready { border-color: #334155; color: #94a3b8; }
        .result-box.state-success {
            background: rgba(16, 185, 129, 0.12);
            border: 2px solid #10b981;
            box-shadow: 0 0 30px rgba(16, 185, 129, 0.25);
        }
        .result-box.state-error {
            background: rgba(239, 68, 68, 0.12);
            border: 2px solid #ef4444;
            box-shadow: 0 0 30px rgba(239, 68, 68, 0.25);
        }
        .result-box.state-warning {
            background: rgba(234, 179, 8, 0.12);
            border: 2px solid #eab308;
            box-shadow: 0 0 30px rgba(234, 179, 8, 0.25);
        }

        .res-icon { font-size: 46px; margin-bottom: 12px; }
        .res-title { font-size: 20px; font-weight: 800; color: #ffffff; margin-bottom: 6px; }
        .res-desc { font-size: 14px; color: #cbd5e1; max-width: 360px; line-height: 1.5; }
        .res-token { font-family: 'Space Mono', monospace; font-size: 13px; color: #ffd369; margin-top: 10px; }

        /* Recent Activity Table */
        .table-wrapper {
            overflow-x: auto;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13.5px;
        }
        th {
            background: #090e1a;
            color: #94a3b8;
            font-weight: 600;
            text-align: left;
            padding: 12px 18px;
            border-bottom: 1px solid #1e293b;
        }
        td {
            padding: 14px 18px;
            border-bottom: 1px solid rgba(255,255,255,0.05);
            color: #cbd5e1;
        }
        tr:hover td { background: rgba(255, 255, 255, 0.02); }

        .link-ticket { color: #38bdf8; text-decoration: none; font-weight: 600; }
        .link-ticket:hover { text-decoration: underline; }

        @media (max-width: 900px) {
            .scanner-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<header class="navbar">
    <div class="logo">
        <h2>EventSphere</h2>
    </div>
    <div class="nav-right">
        <a href="viewParticipants.jsp?id=<%= selectedEventId %>" class="btn-dash">📋 View All Attendees</a>
        <a href="<%= "Admin".equalsIgnoreCase(sessionRole) ? "adminDashboard.jsp" : "organizerDashboard.jsp" %>" class="btn-dash">← Back to Dashboard</a>
    </div>
</header>

<main class="container">
    <div class="header-bar">
        <div class="header-title">
            <h1>📲 Live Gate Check-In Scanner</h1>
            <p>Scan digital QR ticket passes or enter ticket tokens to authorize entrance in real-time.</p>
        </div>

        <div class="event-select-box">
            <form method="GET" action="gateScanner.jsp">
                <select name="event_id" onchange="this.form.submit()">
                    <%
                    for (java.util.Map<String, Object> ev : eventList) {
                        int eId = (Integer) ev.get("id");
                        String eName = (String) ev.get("name");
                    %>
                        <option value="<%= eId %>" <%= eId == selectedEventId ? "selected" : "" %>>
                            <%= SecurityUtil.escapeHtml(eName) %>
                        </option>
                    <% } %>
                </select>
            </form>
        </div>
    </div>

    <!-- Stats HUD -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon" style="background: rgba(139, 92, 246, 0.15); color: #c084fc;">🎟️</div>
            <div>
                <div class="stat-val" id="statTotal"><%= totalRegistered %></div>
                <div class="stat-lbl">Total Registered</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: rgba(16, 185, 129, 0.15); color: #34d399;">✓</div>
            <div>
                <div class="stat-val" id="statChecked" style="color: #4ade80;"><%= totalCheckedIn %></div>
                <div class="stat-lbl">Checked In at Gate</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: rgba(234, 179, 8, 0.15); color: #facc15;">⏳</div>
            <div>
                <div class="stat-val" id="statPending"><%= Math.max(0, totalRegistered - totalCheckedIn) %></div>
                <div class="stat-lbl">Awaiting Arrival</div>
            </div>
        </div>
    </div>

    <!-- Scanner & Result Grid -->
    <div class="scanner-grid">
        <!-- Left: Camera & Manual Entry -->
        <div class="card-box">
            <div class="card-header">
                <span>📷 QR Code Camera Scanner</span>
            </div>

            <div class="video-wrapper">
                <video id="cameraVideo" playsinline></video>
                <canvas id="cameraCanvas"></canvas>
                <div class="laser-scanner" id="laserScanner"></div>
                <div class="camera-overlay-text" id="cameraStatus">Camera Active • Align ticket QR inside viewfinder</div>
            </div>

            <div class="manual-box">
                <input type="text" id="manualTokenInput" class="manual-input" placeholder="Or enter Ticket Token (e.g. TKT-0007...)" autocomplete="off">
                <button type="button" class="btn-checkin" onclick="processManualEntry()">Check In</button>
            </div>
        </div>

        <!-- Right: Verification Result -->
        <div class="card-box">
            <div class="card-header">
                <span>⚡ Gate Verification Status</span>
            </div>

            <div class="result-box state-ready" id="resultCard">
                <div class="res-icon" id="resIcon">🎫</div>
                <div class="res-title" id="resTitle">Ready to Scan</div>
                <div class="res-desc" id="resDesc">Scan a ticket QR code with camera or type a ticket token to verify entry authorization.</div>
                <div class="res-token" id="resToken"></div>
            </div>
        </div>
    </div>

    <!-- Recent Check-In Stream -->
    <div class="card-box">
        <div class="card-header" style="justify-content: space-between;">
            <span>🕒 Recent Check-Ins (<%= selectedEventTitle %>)</span>
            <span style="font-size: 12px; color: #64748b; font-weight: normal;">Live admission log</span>
        </div>

        <div class="table-wrapper">
            <table>
                <thead>
                    <tr>
                        <th>Attendee Name</th>
                        <th>Email</th>
                        <th>Ticket Token</th>
                        <th>Checked-In Time</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody id="recentCheckinsBody">
                    <%
                    boolean hasRecent = false;
                    if (rsRecent != null) {
                        while (rsRecent.next()) {
                            hasRecent = true;
                            int regId = rsRecent.getInt("registration_id");
                            String aName = rsRecent.getString("full_name");
                            String aEmail = rsRecent.getString("email");
                            String tToken = rsRecent.getString("ticket_token");
                            Timestamp cTime = rsRecent.getTimestamp("checked_in_at");
                    %>
                        <tr>
                            <td style="font-weight:600; color:white;"><%= SecurityUtil.escapeHtml(aName) %></td>
                            <td><%= SecurityUtil.escapeHtml(aEmail) %></td>
                            <td><span style="font-family:'Space Mono'; color:#ffd369;"><%= tToken %></span></td>
                            <td><%= cTime != null ? new java.text.SimpleDateFormat("hh:mm a, MMM dd").format(cTime) : "Just now" %></td>
                            <td><a href="viewTicket.jsp?id=<%= regId %>" target="_blank" class="link-ticket">View Ticket ↗</a></td>
                        </tr>
                    <%
                        }
                    }
                    if (!hasRecent) {
                    %>
                        <tr id="noScansRow"><td colspan="5" style="text-align:center; padding:30px; color:#64748b;">No attendees have checked in to this event yet.</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

<script src="js/toast.js"></script>
<script>
const eventId = <%= selectedEventId %>;
const resultCard = document.getElementById('resultCard');
const resIcon = document.getElementById('resIcon');
const resTitle = document.getElementById('resTitle');
const resDesc = document.getElementById('resDesc');
const resToken = document.getElementById('resToken');
const manualInput = document.getElementById('manualTokenInput');

let scanningActive = true;
let lastScannedToken = "";
let cooldownTimer = null;

// Audio Chimes using HTML5 Web Audio API (no external mp3 needed)
function playBeep(success) {
    try {
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain);
        gain.connect(audioCtx.destination);

        if (success) {
            osc.frequency.setValueAtTime(587.33, audioCtx.currentTime); // D5
            osc.frequency.setValueAtTime(880.00, audioCtx.currentTime + 0.1); // A5
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.35);
            osc.start();
            osc.stop(audioCtx.currentTime + 0.35);
        } else {
            osc.frequency.setValueAtTime(220, audioCtx.currentTime); // A3
            osc.frequency.setValueAtTime(160, audioCtx.currentTime + 0.15);
            gain.gain.setValueAtTime(0.4, audioCtx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.4);
            osc.start();
            osc.stop(audioCtx.currentTime + 0.4);
        }
    } catch (e) {}
}

// Process check-in API call
function submitCheckIn(token) {
    if (!token || token.trim() === '') return;
    token = token.trim();

    fetch('checkInProcess.jsp?token=' + encodeURIComponent(token) + '&event_id=' + eventId)
        .then(res => res.json())
        .then(data => {
            handleResult(data, token);
        })
        .catch(err => {
            showToast('error', 'Network error verifying ticket', 'Scanner Error');
        });
}

function handleResult(data, token) {
    resultCard.className = 'result-box';
    resToken.innerText = 'Token: ' + token;

    if (data.status === 'SUCCESS') {
        playBeep(true);
        resultCard.classList.add('state-success');
        resIcon.innerText = '✅';
        resTitle.innerText = 'Access Granted!';
        resDesc.innerHTML = '<strong>' + data.attendeeName + '</strong> has been admitted.<br>Check-in confirmed at ' + data.checkedInAt;

        // Update stats
        const checkedEl = document.getElementById('statChecked');
        const pendingEl = document.getElementById('statPending');
        if (checkedEl && pendingEl) {
            let cur = parseInt(checkedEl.innerText) || 0;
            checkedEl.innerText = cur + 1;
            let pend = parseInt(pendingEl.innerText) || 1;
            pendingEl.innerText = Math.max(0, pend - 1);
        }

        // Prepend to activity table
        const tbody = document.getElementById('recentCheckinsBody');
        const emptyRow = document.getElementById('noScansRow');
        if (emptyRow) emptyRow.remove();

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td style="font-weight:600; color:#4ade80;">` + data.attendeeName + `</td>
            <td>` + data.email + `</td>
            <td><span style="font-family:'Space Mono'; color:#ffd369;">` + token + `</span></td>
            <td>` + data.checkedInAt + `</td>
            <td><a href="viewTicket.jsp?id=` + data.regId + `" target="_blank" class="link-ticket">View Ticket ↗</a></td>
        `;
        tbody.insertBefore(tr, tbody.firstChild);

    } else if (data.status === 'ALREADY_CHECKED_IN') {
        playBeep(false);
        resultCard.classList.add('state-warning');
        resIcon.innerText = '⚠️';
        resTitle.innerText = 'Already Checked In';
        resDesc.innerHTML = data.message;
    } else {
        playBeep(false);
        resultCard.classList.add('state-error');
        resIcon.innerText = '❌';
        resTitle.innerText = 'Access Denied';
        resDesc.innerHTML = data.message;
    }

    // Set cooldown so camera doesn't scan the same code 10 times in 1 second
    clearTimeout(cooldownTimer);
    cooldownTimer = setTimeout(() => {
        lastScannedToken = "";
    }, 4000);
}

function processManualEntry() {
    const val = manualInput.value;
    if (val && val.trim() !== '') {
        submitCheckIn(val);
        manualInput.value = '';
        manualInput.focus();
    }
}

manualInput.addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        processManualEntry();
    }
});

// Camera Scanner Setup using WebRTC & jsQR
const video = document.getElementById('cameraVideo');
const canvas = document.getElementById('cameraCanvas');
const ctx = canvas.getContext('2d');
const cameraStatus = document.getElementById('cameraStatus');

if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } })
        .then(function(stream) {
            video.srcObject = stream;
            video.setAttribute("playsinline", true);
            video.play();
            requestAnimationFrame(tickScanner);
        })
        .catch(function(err) {
            cameraStatus.innerText = "Camera not available. Use manual token input.";
            document.getElementById('laserScanner').style.display = 'none';
        });
} else {
    cameraStatus.innerText = "Camera not supported on this browser. Use manual input.";
    document.getElementById('laserScanner').style.display = 'none';
}

function tickScanner() {
    if (video.readyState === video.HAVE_ENOUGH_DATA) {
        canvas.height = video.videoHeight;
        canvas.width = video.videoWidth;
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        
        if (typeof jsQR !== 'undefined') {
            const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
            const code = jsQR(imageData.data, imageData.width, imageData.height, {
                inversionAttempts: "dontInvert"
            });

            if (code && code.data && code.data.trim() !== "") {
                const detected = code.data.trim();
                if (detected !== lastScannedToken) {
                    lastScannedToken = detected;
                    submitCheckIn(detected);
                }
            }
        }
    }
    requestAnimationFrame(tickScanner);
}
</script>

</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:red;'>Scanner Error</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
} finally {
    DBConnection.close(rsRecent, rsStats, rsEvents, psRecent, psStats, psEvents, conn);
}
%>
