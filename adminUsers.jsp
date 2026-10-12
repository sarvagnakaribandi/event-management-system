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

int currentAdminId = Integer.parseInt(session.getAttribute("userId").toString());
String roleFilter = request.getParameter("role");
String search = request.getParameter("search");
String msg = request.getParameter("msg");

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = DBConnection.getConnection();

    StringBuilder sql = new StringBuilder();
    sql.append("SELECT id, full_name, email, role, created_at FROM users WHERE 1=1 ");

    if (roleFilter != null && !roleFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(roleFilter)) {
        sql.append("AND role = ? ");
    }
    if (search != null && !search.trim().isEmpty()) {
        sql.append("AND (full_name LIKE ? OR email LIKE ?) ");
    }

    sql.append("ORDER BY id DESC");

    ps = conn.prepareStatement(sql.toString());
    int paramIdx = 1;

    if (roleFilter != null && !roleFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(roleFilter)) {
        ps.setString(paramIdx++, roleFilter.trim());
    }
    if (search != null && !search.trim().isEmpty()) {
        String s = "%" + search.trim() + "%";
        ps.setString(paramIdx++, s);
        ps.setString(paramIdx++, s);
    }

    rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Users | EventSphere Admin</title>
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

        /* Filter Controls */
        .filter-bar {
            display:flex;
            justify-content:space-between;
            align-items:center;
            flex-wrap:wrap;
            gap:15px;
            background:#0f172a;
            padding:18px 24px;
            border:1px solid #1e293b;
            border-radius:16px;
            margin-bottom:25px;
        }
        .search-box {
            display:flex;
            gap:10px;
            flex:1;
            max-width:500px;
        }
        .search-box input {
            flex:1;
            background:#070d18;
            border:1px solid #2d3e58;
            border-radius:10px;
            padding:10px 16px;
            color:white;
            outline:none;
        }
        .search-box button {
            background:#38bdf8;
            color:#000;
            border:none;
            padding:10px 20px;
            border-radius:10px;
            font-weight:600;
            cursor:pointer;
        }

        .role-filters { display:flex; gap:10px; }
        .role-btn {
            padding:8px 16px;
            background:#16233b;
            color:#cbd5e1;
            text-decoration:none;
            border-radius:8px;
            font-size:13px;
            font-weight:500;
            transition:0.2s;
        }
        .role-btn.active { background:#ffd369; color:#000; font-weight:700; }

        .table-box {
            background:#0f172a;
            border:1px solid #1e293b;
            border-radius:18px;
            overflow-x:auto;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
        }
        table {
            width:100%;
            min-width:900px;
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
            padding:14px 18px;
            border-top:1px solid #1e293b;
            font-size:13px;
            color:#e2e8f0;
            vertical-align:middle;
        }
        tr:hover td { background:#141f33; }

        .role-badge {
            display:inline-block;
            padding:4px 12px;
            border-radius:15px;
            font-size:11px;
            font-weight:700;
        }
        .role-admin { background:#311b92; color:#b388ff; border:1px solid #7c4dff; }
        .role-organizer { background:#1e293b; color:#38bdf8; border:1px solid #0284c7; }
        .role-user { background:#142d1f; color:#4ade80; border:1px solid #16a34a; }

        .btn-del-user {
            background:transparent;
            color:#f87171;
            border:1px solid #dc2626;
            padding:6px 14px;
            border-radius:8px;
            font-size:12px;
            cursor:pointer;
            transition:0.2s;
        }
        .btn-del-user:hover { background:rgba(239,68,68,0.15); }

        @media(max-width:768px){
            .navbar { padding:0 20px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:12px; }
            .filter-bar { flex-direction:column; align-items:stretch; }
            .search-box { max-width:100%; }
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
        <a href="adminUsers.jsp" class="active">Manage Users</a>
        <a href="adminEvents.jsp">Manage Events</a>
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <div class="page-header">
        <h1 class="page-title">User Account Directory & Moderation</h1>
        <p class="page-subtitle">View and moderate all registered platform accounts (Customers, Organizers, and Admins).</p>
    </div>

    <!-- Filter Bar -->
    <div class="filter-bar">
        <form action="adminUsers.jsp" method="get" class="search-box">
            <input type="text" name="search" placeholder="Search by name or email..." value="<%= SecurityUtil.escapeHtml(search != null ? search : "") %>">
            <% if (roleFilter != null && !roleFilter.isEmpty()) { %>
                <input type="hidden" name="role" value="<%= SecurityUtil.escapeHtml(roleFilter) %>">
            <% } %>
            <button type="submit">Search</button>
        </form>

        <div class="role-filters">
            <a href="adminUsers.jsp" class="role-btn <%= (roleFilter == null || roleFilter.isEmpty() || "ALL".equalsIgnoreCase(roleFilter)) ? "active" : "" %>">All Accounts</a>
            <a href="adminUsers.jsp?role=User" class="role-btn <%= "User".equalsIgnoreCase(roleFilter) ? "active" : "" %>">Users</a>
            <a href="adminUsers.jsp?role=Organizer" class="role-btn <%= "Organizer".equalsIgnoreCase(roleFilter) ? "active" : "" %>">Organizers</a>
            <a href="adminUsers.jsp?role=Admin" class="role-btn <%= "Admin".equalsIgnoreCase(roleFilter) ? "active" : "" %>">Admins</a>
        </div>
    </div>

    <!-- Table -->
    <div class="table-box">
        <table>
            <thead>
                <tr>
                    <th>User ID</th>
                    <th>Full Name</th>
                    <th>Email Address</th>
                    <th>Platform Role</th>
                    <th>Joined On</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <%
            boolean hasUsers = false;
            while (rs.next()) {
                hasUsers = true;
                int uId = rs.getInt("id");
                String uName = rs.getString("full_name");
                String uEmail = rs.getString("email");
                String uRole = rs.getString("role");
                Timestamp createdAt = rs.getTimestamp("created_at");

                String rClass = "role-user";
                if ("Admin".equalsIgnoreCase(uRole)) rClass = "role-admin";
                else if ("Organizer".equalsIgnoreCase(uRole)) rClass = "role-organizer";
            %>
                <tr>
                    <td style="font-family:monospace; color:#94a3b8;">#<%= uId %></td>
                    <td><strong><%= SecurityUtil.escapeHtml(uName) %></strong></td>
                    <td><%= SecurityUtil.escapeHtml(uEmail) %></td>
                    <td><span class="role-badge <%= rClass %>"><%= uRole %></span></td>
                    <td><%= createdAt != null ? createdAt.toString().substring(0, 16) : "N/A" %></td>
                    <td>
                        <% if (uId != currentAdminId) { %>
                            <a href="adminDeleteUser.jsp?id=<%= uId %>" 
                               class="btn-del-user"
                               onclick="return confirm('Delete user account <%= SecurityUtil.escapeHtml(uName) %>? This action is permanent.');">
                                🗑️ Delete Account
                            </a>
                        <% } else { %>
                            <span style="color:#64748b; font-size:12px;">Active Session</span>
                        <% } %>
                    </td>
                </tr>
            <%
            }
            if (!hasUsers) {
            %>
                <tr>
                    <td colspan="6" style="text-align:center; padding:45px; color:#94a3b8;">
                        No user accounts found matching your query.
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
