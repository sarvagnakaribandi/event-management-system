<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   EXPORT PARTICIPANTS & GATE ROSTER (PHASE 9)
   Supports CSV download & Printable Security Roster
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) session.getAttribute("role");
boolean isAdmin = "Admin".equalsIgnoreCase(role);
boolean isOrganizer = "Organizer".equalsIgnoreCase(role);

if (!isAdmin && !isOrganizer) {
    response.sendRedirect("login.jsp");
    return;
}

int currentUserId = Integer.parseInt(session.getAttribute("userId").toString());

String eventIdParam = request.getParameter("id");
if (eventIdParam == null || eventIdParam.trim().isEmpty()) {
    response.sendRedirect("organizerDashboard.jsp");
    return;
}

int eventId = 0;
try {
    eventId = Integer.parseInt(eventIdParam.trim());
} catch (Exception e) {
    response.sendRedirect("organizerDashboard.jsp");
    return;
}

String format = request.getParameter("format");
if (format == null || format.trim().isEmpty()) {
    format = "csv";
}

Connection conn = null;
PreparedStatement eventPs = null;
PreparedStatement regPs = null;
ResultSet eventRs = null;
ResultSet regRs = null;

try {
    conn = DBConnection.getConnection();

    // Verify ownership (unless admin)
    String eventSql = "SELECT * FROM events WHERE event_id = ?";
    if (!isAdmin) {
        eventSql += " AND organizer_id = ?";
    }

    eventPs = conn.prepareStatement(eventSql);
    eventPs.setInt(1, eventId);
    if (!isAdmin) {
        eventPs.setInt(2, currentUserId);
    }
    eventRs = eventPs.executeQuery();

    if (!eventRs.next()) {
        response.sendRedirect("organizerDashboard.jsp?error=unauthorized");
        return;
    }

    String eventName = eventRs.getString("event_name");
    Date eventDate = eventRs.getDate("event_date");
    Time eventTime = eventRs.getTime("event_time");
    String venue = eventRs.getString("venue");
    String category = eventRs.getString("category");

    // Fetch all registrations
    String regSql =
        "SELECT registration_id, full_name, email, phone, gender, " +
        "team_name, registration_date, payment_status, payment_method, " +
        "ticket_token, check_in_status, checked_in_at, certificate_id " +
        "FROM registrations " +
        "WHERE event_id = ? " +
        "ORDER BY registration_id ASC";

    regPs = conn.prepareStatement(regSql);
    regPs.setInt(1, eventId);
    regRs = regPs.executeQuery();

    /* =====================================================
       FORMAT 1: CSV DOWNLOAD
       ===================================================== */
    if ("csv".equalsIgnoreCase(format)) {
        String safeName = eventName.replaceAll("[^a-zA-Z0-9_-]", "_");
        response.setContentType("text/csv; charset=UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=\"attendees_" + safeName + "_" + eventId + ".csv\"");

        // UTF-8 BOM for Microsoft Excel compatibility
        out.write('\uFEFF');

        // CSV Header
        out.println("\"Reg ID\",\"Full Name\",\"Email\",\"Phone\",\"Gender\",\"Team Name\",\"Reg Date\",\"Payment Status\",\"Payment Method\",\"Ticket Token\",\"Check-In Status\",\"Checked-In Time\",\"Certificate ID\"");

        while (regRs.next()) {
            StringBuilder line = new StringBuilder();
            line.append("\"").append(regRs.getInt("registration_id")).append("\",");
            line.append("\"").append(regRs.getString("full_name") != null ? regRs.getString("full_name").replace("\"", "\"\"") : "").append("\",");
            line.append("\"").append(regRs.getString("email") != null ? regRs.getString("email").replace("\"", "\"\"") : "").append("\",");
            line.append("\"").append(regRs.getString("phone") != null ? regRs.getString("phone").replace("\"", "\"\"") : "").append("\",");
            line.append("\"").append(regRs.getString("gender") != null ? regRs.getString("gender").replace("\"", "\"\"") : "").append("\",");
            line.append("\"").append(regRs.getString("team_name") != null ? regRs.getString("team_name").replace("\"", "\"\"") : "").append("\",");
            line.append("\"").append(regRs.getTimestamp("registration_date") != null ? regRs.getTimestamp("registration_date").toString() : "").append("\",");
            line.append("\"").append(regRs.getString("payment_status") != null ? regRs.getString("payment_status") : "").append("\",");
            line.append("\"").append(regRs.getString("payment_method") != null ? regRs.getString("payment_method") : "").append("\",");
            line.append("\"").append(regRs.getString("ticket_token") != null ? regRs.getString("ticket_token") : "").append("\",");
            line.append("\"").append(regRs.getString("check_in_status") != null ? regRs.getString("check_in_status") : "Not Checked In").append("\",");
            line.append("\"").append(regRs.getTimestamp("checked_in_at") != null ? regRs.getTimestamp("checked_in_at").toString() : "").append("\",");
            line.append("\"").append(regRs.getString("certificate_id") != null ? regRs.getString("certificate_id") : "").append("\"");
            out.println(line.toString());
        }
        return;
    }

    /* =====================================================
       FORMAT 2: PRINTABLE ATTENDANCE ROSTER SHEET
       ===================================================== */
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gate Attendance Sheet - <%= SecurityUtil.escapeHtml(eventName) %> | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&family=Space+Mono:wght@700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #f8fafc;
            color: #0f172a;
            font-family: 'Poppins', sans-serif;
            padding: 30px;
        }

        .no-print {
            max-width: 1100px;
            margin: 0 auto 25px auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: #1e293b;
            color: #fff;
            padding: 15px 24px;
            border-radius: 12px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }

        .btn-group {
            display: flex;
            gap: 12px;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 20px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            border: none;
            transition: all 0.2s;
        }

        .btn-primary { background: #6366f1; color: #fff; }
        .btn-primary:hover { background: #4f46e5; }
        .btn-csv { background: #10b981; color: #fff; }
        .btn-csv:hover { background: #059669; }
        .btn-back { background: rgba(255,255,255,0.1); color: #cbd5e1; }
        .btn-back:hover { background: rgba(255,255,255,0.2); }

        .sheet-container {
            max-width: 1100px;
            margin: 0 auto;
            background: #fff;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.06);
            border: 1px solid #e2e8f0;
        }

        .sheet-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            border-bottom: 2px solid #0f172a;
            padding-bottom: 20px;
            margin-bottom: 25px;
        }

        .sheet-title {
            font-size: 24px;
            font-weight: 800;
            color: #0f172a;
            text-transform: uppercase;
            letter-spacing: -0.5px;
        }

        .sheet-subtitle {
            font-size: 14px;
            color: #64748b;
            margin-top: 4px;
        }

        .meta-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            background: #f1f5f9;
            padding: 16px;
            border-radius: 8px;
            margin-bottom: 25px;
        }

        .meta-item {
            font-size: 12px;
        }

        .meta-label {
            font-weight: 600;
            color: #64748b;
            text-transform: uppercase;
            font-size: 10px;
            letter-spacing: 0.5px;
        }

        .meta-val {
            font-weight: 700;
            color: #0f172a;
            margin-top: 2px;
            font-size: 13px;
        }

        table.roster-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
        }

        table.roster-table th {
            background: #0f172a;
            color: #fff;
            padding: 10px 12px;
            text-align: left;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            font-size: 11px;
        }

        table.roster-table td {
            padding: 10px 12px;
            border-bottom: 1px solid #e2e8f0;
            color: #1e293b;
        }

        table.roster-table tr:nth-child(even) {
            background: #f8fafc;
        }

        .token-tag {
            font-family: 'Space Mono', monospace;
            font-weight: 700;
            font-size: 11px;
            background: #e2e8f0;
            padding: 3px 6px;
            border-radius: 4px;
            color: #334155;
        }

        .status-badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 999px;
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
        }

        .status-badge.in {
            background: #dcfce7;
            color: #15803d;
        }

        .status-badge.out {
            background: #fee2e2;
            color: #b91c1c;
        }

        .sig-box {
            width: 140px;
            border-bottom: 1px dashed #94a3b8;
            height: 20px;
        }

        @media print {
            body { padding: 0; background: #fff; }
            .no-print { display: none !important; }
            .sheet-container { box-shadow: none; border: none; padding: 0; }
            @page { margin: 15mm; size: landscape; }
        }
    </style>
</head>
<body>

    <div class="no-print">
        <div>
            <div style="font-weight: 700; font-size: 16px;">Gate Attendance Roster</div>
            <div style="font-size: 12px; color: #94a3b8;">Use this sheet for physical security checkpoints and offline backup</div>
        </div>
        <div class="btn-group">
            <a href="viewParticipants.jsp?id=<%= eventId %>" class="btn btn-back">← Back to Event</a>
            <a href="exportParticipants.jsp?id=<%= eventId %>&format=csv" class="btn btn-csv">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="7 10 12 15 17 10"></polyline>
                    <line x1="12" y1="15" x2="12" y2="3"></line>
                </svg>
                Download CSV
            </a>
            <button onclick="window.print()" class="btn btn-primary">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="6 9 6 2 18 2 18 9"></polyline>
                    <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                    <rect x="6" y="14" width="12" height="8"></rect>
                </svg>
                Print Roster
            </button>
        </div>
    </div>

    <div class="sheet-container">
        <div class="sheet-header">
            <div>
                <div class="sheet-title"><%= SecurityUtil.escapeHtml(eventName) %></div>
                <div class="sheet-subtitle">Official Venue Gate Attendance Sheet & Participant Verification Roster</div>
            </div>
            <div style="text-align: right;">
                <div style="font-size: 12px; font-weight: 700; color: #64748b;">EVENTSPHERE GATE ROSTER</div>
                <div style="font-size: 11px; color: #94a3b8;">Generated: <%= new java.util.Date() %></div>
            </div>
        </div>

        <div class="meta-grid">
            <div class="meta-item">
                <div class="meta-label">Date & Time</div>
                <div class="meta-val"><%= eventDate != null ? eventDate.toString() : "TBD" %> at <%= eventTime != null ? eventTime.toString() : "TBD" %></div>
            </div>
            <div class="meta-item">
                <div class="meta-label">Venue Location</div>
                <div class="meta-val"><%= SecurityUtil.escapeHtml(venue) %></div>
            </div>
            <div class="meta-item">
                <div class="meta-label">Category</div>
                <div class="meta-val"><%= SecurityUtil.escapeHtml(category) %></div>
            </div>
            <div class="meta-item">
                <div class="meta-label">Event ID</div>
                <div class="meta-val">#EVT-<%= eventId %></div>
            </div>
        </div>

        <table class="roster-table">
            <thead>
                <tr>
                    <th style="width: 40px;">#</th>
                    <th>Attendee Name</th>
                    <th>Email & Contact</th>
                    <th>Ticket Token</th>
                    <th>Payment</th>
                    <th>Gate Status</th>
                    <th>Checked-In Time</th>
                    <th style="width: 140px;">Gate Signature</th>
                </tr>
            </thead>
            <tbody>
                <%
                int count = 0;
                while (regRs.next()) {
                    count++;
                    String status = regRs.getString("check_in_status");
                    boolean checkedIn = "Checked In".equalsIgnoreCase(status);
                    Timestamp inTime = regRs.getTimestamp("checked_in_at");
                %>
                <tr>
                    <td><%= count %></td>
                    <td><strong><%= SecurityUtil.escapeHtml(regRs.getString("full_name")) %></strong></td>
                    <td>
                        <%= SecurityUtil.escapeHtml(regRs.getString("email")) %><br>
                        <span style="color:#64748b;"><%= SecurityUtil.escapeHtml(regRs.getString("phone")) %></span>
                    </td>
                    <td><span class="token-tag"><%= regRs.getString("ticket_token") != null ? regRs.getString("ticket_token") : "N/A" %></span></td>
                    <td><%= SecurityUtil.escapeHtml(regRs.getString("payment_status")) %></td>
                    <td>
                        <span class="status-badge <%= checkedIn ? "in" : "out" %>">
                            <%= checkedIn ? "Checked In" : "Not In" %>
                        </span>
                    </td>
                    <td><%= inTime != null ? inTime.toString().substring(11, 19) : "-" %></td>
                    <td><div class="sig-box"></div></td>
                </tr>
                <% } %>
                <% if (count == 0) { %>
                <tr>
                    <td colspan="8" style="text-align: center; padding: 30px; color: #94a3b8;">No registered attendees found for this event.</td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>

</body>
</html>
<%
} catch (Exception e) {
    e.printStackTrace();
    out.println("<script>alert('Error generating export: " + e.getMessage() + "'); history.back();</script>");
} finally {
    if (regRs != null) try { regRs.close(); } catch (Exception ignored) {}
    if (eventRs != null) try { eventRs.close(); } catch (Exception ignored) {}
    if (regPs != null) try { regPs.close(); } catch (Exception ignored) {}
    if (eventPs != null) try { eventPs.close(); } catch (Exception ignored) {}
    if (conn != null) try { conn.close(); } catch (Exception ignored) {}
}
%>
