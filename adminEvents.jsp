<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   ADMIN LOGIN & ROLE GUARD
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) session.getAttribute("role");
if (role == null || !"Admin".equalsIgnoreCase(role)) {
    response.sendRedirect("login.jsp");
    return;
}

String search = request.getParameter("search");
String categoryFilter = request.getParameter("category");
String msg = request.getParameter("msg");

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = DBConnection.getConnection();

    StringBuilder sql = new StringBuilder();
    sql.append("SELECT e.*, u.full_name AS organizer_name, u.email AS organizer_email, ");
    sql.append("(SELECT COUNT(*) FROM registrations r WHERE r.event_id = e.event_id) AS reg_count ");
    sql.append("FROM events e ");
    sql.append("JOIN users u ON e.organizer_id = u.id ");
    sql.append("WHERE 1=1 ");

    if (categoryFilter != null && !categoryFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(categoryFilter)) {
        sql.append("AND e.category = ? ");
    }
    if (search != null && !search.trim().isEmpty()) {
        sql.append("AND (e.event_name LIKE ? OR e.venue LIKE ? OR u.full_name LIKE ?) ");
    }

    sql.append("ORDER BY e.event_date DESC");

    ps = conn.prepareStatement(sql.toString());
    int pIdx = 1;

    if (categoryFilter != null && !categoryFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(categoryFilter)) {
        ps.setString(pIdx++, categoryFilter.trim());
    }
    if (search != null && !search.trim().isEmpty()) {
        String s = "%" + search.trim() + "%";
        ps.setString(pIdx++, s);
        ps.setString(pIdx++, s);
        ps.setString(pIdx++, s);
    }

    rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Events | EventSphere Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin:0; padding:0; box-sizing:border-box; font-family:'Poppins', sans-serif; }
        body { background:#070d18; color:white; min-height:100vh; }

        .navbar {
            height:75px;
            display:flex;
            justify-content:space-between;
            align-items:center;
            padding:0 50px;
            background:#0f172a;
            border-bottom:1px solid #1e293b;
        }
        .logo {
            font-size:24px;
            font-weight:700;
            background:linear-gradient(90deg, #ff4fa3, #ffd369);
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
            display:flex;
            align-items:center;
            gap:10px;
        }
        .logo-tag {
            font-size:11px;
            background:#311b92;
            color:#b388ff;
            border:1px solid #7c4dff;
            padding:2px 8px;
            border-radius:12px;
            letter-spacing:1px;
        }

        .nav-links { display:flex; gap:25px; align-items:center; }
        .nav-links a { color:#cbd5e8; text-decoration:none; font-size:14px; font-weight:500; transition:0.3s; }
        .nav-links a:hover { color:#ffd369; }
        .nav-links a.active { color:#ffd369; font-weight:700; }

        .container { width:92%; max-width:1300px; margin:40px auto 80px; }

        .page-header { margin-bottom:25px; }
        .page-title { font-size:32px; font-weight:800; color:#fff; }
        .page-subtitle { color:#94a3b8; font-size:15px; margin-top:4px; }

        /* Search Bar */
        .search-bar {
            display:flex;
            gap:15px;
            background:#0f172a;
            padding:18px 24px;
            border:1px solid #1e293b;
            border-radius:16px;
            margin-bottom:25px;
        }
        .search-bar input {
            flex:1;
            background:#070d18;
            border:1px solid #2d3e58;
            border-radius:10px;
            padding:10px 16px;
            color:white;
            outline:none;
        }
        .search-bar button {
            background:#38bdf8;
            color:#000;
            border:none;
            padding:10px 20px;
            border-radius:10px;
            font-weight:600;
            cursor:pointer;
        }

        .table-box {
            background:#0f172a;
            border:1px solid #1e293b;
            border-radius:18px;
            overflow-x:auto;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
        }
        table {
            width:100%;
            min-width:1050px;
            border-collapse:collapse;
        }
        th {
            background:#1e293b;
            color:#cbd5e1;
            padding:14px 18px;
            text-align:left;
            font-size:12px;
            font-weight:600;
            text-transform:uppercase;
            letter-spacing:0.5px;
        }
        td {
            padding:16px 18px;
            border-top:1px solid #1e293b;
            font-size:13px;
            color:#e2e8f0;
            vertical-align:middle;
        }
        tr:hover td { background:#141f33; }

        .btn-view {
            padding:6px 14px;
            background:#1e293b;
            color:#38bdf8;
            border:1px solid #0284c7;
            border-radius:8px;
            text-decoration:none;
            font-size:12px;
            font-weight:600;
            display:inline-block;
        }
        .btn-del {
            padding:6px 14px;
            background:transparent;
            color:#f87171;
            border:1px solid #dc2626;
            border-radius:8px;
            text-decoration:none;
            font-size:12px;
            font-weight:600;
            display:inline-block;
            margin-left:6px;
        }
        .btn-del:hover { background:rgba(239,68,68,0.15); }

        @media(max-width:768px){
            .navbar { padding:0 20px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:12px; }
            .search-bar { flex-direction:column; }
        }
    </style>
</head>
<body>

<div class="navbar">
    <div class="logo">
        EventSphere
        <span class="logo-tag">ADMIN</span>
    </div>
    <div class="nav-links">
        <a href="adminDashboard.jsp">Overview</a>
        <a href="adminVerifications.jsp">Verifications</a>
        <a href="adminUsers.jsp">Manage Users</a>
        <a href="adminEvents.jsp" class="active">Manage Events</a>
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <div class="page-header">
        <h1 class="page-title">Platform-Wide Event Moderation</h1>
        <p class="page-subtitle">Inspect, moderate, and manage events published by all organizers across the platform.</p>
    </div>

    <!-- Search Bar -->
    <form action="adminEvents.jsp" method="get" class="search-bar">
        <input type="text" name="search" placeholder="Search by event title, venue, or organizer name..." value="<%= SecurityUtil.escapeHtml(search != null ? search : "") %>">
        <button type="submit">Filter Events</button>
    </form>

    <div class="table-box">
        <table>
            <thead>
                <tr>
                    <th>Event Details</th>
                    <th>Category</th>
                    <th>Organizer</th>
                    <th>Schedule & Venue</th>
                    <th>Price</th>
                    <th>Registrations</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <%
            boolean hasEvents = false;
            while (rs.next()) {
                hasEvents = true;
                int eId = rs.getInt("event_id");
                String eName = rs.getString("event_name");
                String cat = rs.getString("category");
                String orgName = rs.getString("organizer_name");
                Date eDate = rs.getDate("event_date");
                String venue = rs.getString("venue");
                String pType = rs.getString("payment_type");
                double fee = rs.getDouble("event_fee");
                int regCount = rs.getInt("reg_count");
                int maxCap = rs.getInt("max_capacity");
                int availSeats = rs.getInt("available_seats");
            %>
                <tr>
                    <td>
                        <strong style="color:#fff; font-size:14px;"><%= SecurityUtil.escapeHtml(eName) %></strong>
                        <div style="font-family:monospace; color:#94a3b8; font-size:11px;">#EVENT-<%= eId %></div>
                    </td>
                    <td><span style="background:#251b47; color:#c084fc; padding:4px 10px; border-radius:12px; font-size:11px; font-weight:600;"><%= SecurityUtil.escapeHtml(cat) %></span></td>
                    <td>
                        <strong><%= SecurityUtil.escapeHtml(orgName) %></strong>
                    </td>
                    <td>
                        <div>📅 <%= eDate != null ? eDate.toString() : "TBA" %></div>
                        <small style="color:#94a3b8;">📍 <%= SecurityUtil.escapeHtml(venue != null ? venue : "TBA") %></small>
                    </td>
                    <td>
                        <strong style="color:<%= "Paid".equalsIgnoreCase(pType) ? "#4ade80" : "#38bdf8" %>;">
                            <%= "Paid".equalsIgnoreCase(pType) ? ("₹" + String.format("%.2f", fee)) : "Free" %>
                        </strong>
                    </td>
                    <td>
                        <strong><%= regCount %></strong>
                        <small style="color:#94a3b8;">/ <%= maxCap %> (<%= availSeats %> left)</small>
                    </td>
                    <td>
                        <a href="eventDetails.jsp?id=<%= eId %>" target="_blank" class="btn-view">👁 Preview</a>
                        <a href="adminDeleteEvent.jsp?id=<%= eId %>" 
                           class="btn-del"
                           onclick="return confirm('Permanently delete event <%= SecurityUtil.escapeHtml(eName) %> and its registrations?');">
                            🗑️ Delete
                        </a>
                    </td>
                </tr>
            <%
            }
            if (!hasEvents) {
            %>
                <tr>
                    <td colspan="7" style="text-align:center; padding:45px; color:#94a3b8;">
                        No events found matching your query.
                    </td>
                </tr>
            <%
            }
            %>
            </tbody>
        </table>
    </div>
</div>

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
