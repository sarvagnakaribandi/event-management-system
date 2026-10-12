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

String filter = request.getParameter("filter");
if (filter == null || filter.trim().isEmpty()) {
    filter = "pending";
}

String msg = request.getParameter("msg");

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = DBConnection.getConnection();

    StringBuilder sql = new StringBuilder();
    sql.append("SELECT u.full_name, u.email, op.* ");
    sql.append("FROM organizer_profiles op ");
    sql.append("JOIN users u ON op.organizer_id = u.id ");

    if ("pending".equalsIgnoreCase(filter)) {
        sql.append("WHERE op.verification_status = 'Pending' ");
    } else if ("verified".equalsIgnoreCase(filter)) {
        sql.append("WHERE op.verification_status = 'Verified' ");
    } else if ("rejected".equalsIgnoreCase(filter)) {
        sql.append("WHERE op.verification_status = 'Rejected' ");
    }

    sql.append("ORDER BY (CASE WHEN op.verification_status = 'Pending' THEN 0 ELSE 1 END), op.updated_at DESC");

    ps = conn.prepareStatement(sql.toString());
    rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Organizer Verifications | EventSphere Admin</title>
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
        .alert-info { background:rgba(56,189,248,0.15); border:1px solid #38bdf8; color:#38bdf8; }

        /* Tabs */
        .tabs-nav {
            display:flex;
            gap:15px;
            border-bottom:1px solid #1e293b;
            margin-bottom:30px;
        }
        .tab-btn {
            padding:12px 22px;
            text-decoration:none;
            color:#94a3b8;
            font-size:14px;
            font-weight:600;
            border-bottom:3px solid transparent;
            transition:0.25s;
        }
        .tab-btn:hover { color:#fff; }
        .tab-btn.active { color:#ffd369; border-bottom-color:#ffd369; }

        /* Table Box */
        .table-box {
            background:#0f172a;
            border:1px solid #1e293b;
            border-radius:18px;
            overflow-x:auto;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
        }
        table {
            width:100%;
            min-width:1100px;
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

        .badge {
            display:inline-block;
            padding:4px 12px;
            border-radius:20px;
            font-size:11px;
            font-weight:700;
        }
        .badge-verified { background:rgba(34,197,94,0.15); color:#4ade80; border:1px solid #22c55e; }
        .badge-pending { background:rgba(234,179,8,0.15); color:#facc15; border:1px solid #ca8a04; }
        .badge-rejected { background:rgba(239,68,68,0.15); color:#f87171; border:1px solid #ef4444; }
        .badge-unsubmitted { background:#1e293b; color:#94a3b8; border:1px solid #334155; }

        /* Actions */
        .action-btns {
            display:flex;
            gap:8px;
            align-items:center;
            flex-wrap:wrap;
        }
        .btn-action {
            padding:7px 14px;
            border-radius:8px;
            font-size:12px;
            font-weight:600;
            text-decoration:none;
            cursor:pointer;
            transition:0.2s;
            border:none;
        }
        .btn-approve {
            background:#16a34a;
            color:white;
        }
        .btn-approve:hover { background:#22c55e; }

        .btn-reject {
            background:#dc2626;
            color:white;
        }
        .btn-reject:hover { background:#ef4444; }

        .btn-doc {
            background:#1e293b;
            color:#38bdf8;
            border:1px solid #0284c7;
        }
        .btn-doc:hover { background:rgba(56,189,248,0.15); }

        .empty-row {
            text-align:center;
            padding:50px 20px;
            color:#94a3b8;
        }

        @media(max-width:768px){
            .navbar { padding:0 20px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:12px; }
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
        <a href="adminVerifications.jsp" class="active">Verifications</a>
        <a href="adminUsers.jsp">Manage Users</a>
        <a href="adminEvents.jsp">Manage Events</a>
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <div class="page-header">
        <h1 class="page-title">Organizer Verification Management</h1>
        <p class="page-subtitle">Inspect business licenses, university authorization letters, and verify event organizers.</p>
    </div>

    <% if ("approved".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-success">
            <span>✅ Organizer verified successfully! The Verified Organizer badge is now active on all their events and proposals.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } else if ("rejected".equalsIgnoreCase(msg)) { %>
        <div class="alert alert-info">
            <span>ℹ️ Verification status updated to Rejected with feedback sent to the organizer.</span>
            <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
        </div>
    <% } %>

    <!-- Filter Tabs -->
    <div class="tabs-nav">
        <a href="adminVerifications.jsp?filter=pending" class="tab-btn <%= "pending".equalsIgnoreCase(filter) ? "active" : "" %>">
            ⏳ Pending Review
        </a>
        <a href="adminVerifications.jsp?filter=verified" class="tab-btn <%= "verified".equalsIgnoreCase(filter) ? "active" : "" %>">
            ✅ Verified Organizers
        </a>
        <a href="adminVerifications.jsp?filter=rejected" class="tab-btn <%= "rejected".equalsIgnoreCase(filter) ? "active" : "" %>">
            ❌ Rejected
        </a>
        <a href="adminVerifications.jsp?filter=all" class="tab-btn <%= "all".equalsIgnoreCase(filter) ? "active" : "" %>">
            🌐 All Organizers
        </a>
    </div>

    <!-- Table -->
    <div class="table-box">
        <table>
            <thead>
                <tr>
                    <th>Organizer & Business</th>
                    <th>Contact Information</th>
                    <th>Experience</th>
                    <th>Proof Document</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <%
            boolean hasRows = false;
            while (rs.next()) {
                hasRows = true;
                int orgId = rs.getInt("organizer_id");
                String fullName = rs.getString("full_name");
                String email = rs.getString("email");
                String bName = rs.getString("business_name");
                String phone = rs.getString("contact_phone");
                int exp = rs.getInt("experience_years");
                String vStatus = rs.getString("verification_status");
                String idDoc = rs.getString("id_document");
                String qrImg = rs.getString("qr_image");
                String reason = rs.getString("rejection_reason");

                String badgeClass = "badge-unsubmitted";
                if ("Verified".equalsIgnoreCase(vStatus)) badgeClass = "badge-verified";
                else if ("Pending".equalsIgnoreCase(vStatus) || "Under Review".equalsIgnoreCase(vStatus)) badgeClass = "badge-pending";
                else if ("Rejected".equalsIgnoreCase(vStatus)) badgeClass = "badge-rejected";
            %>
                <tr>
                    <td>
                        <strong style="font-size:14px; color:#fff;"><%= SecurityUtil.escapeHtml(bName != null && !bName.isEmpty() ? bName : fullName) %></strong>
                        <div style="color:#94a3b8; font-size:12px; margin-top:2px;">Contact: <%= SecurityUtil.escapeHtml(fullName) %></div>
                    </td>
                    <td>
                        <div><%= SecurityUtil.escapeHtml(email) %></div>
                        <small style="color:#94a3b8;"><%= SecurityUtil.escapeHtml(phone != null && !phone.isEmpty() ? phone : "Phone not provided") %></small>
                    </td>
                    <td><%= exp %> Year<%= exp != 1 ? "s" : "" %></td>
                    <td>
                        <div style="display:flex; gap:6px; align-items:center;">
                            <% if (idDoc != null && !idDoc.isEmpty()) { %>
                                <a href="images/<%= SecurityUtil.escapeHtml(idDoc) %>" target="_blank" class="btn-action btn-doc" title="Open verification document">
                                    📄 ID Proof
                                </a>
                            <% } else { %>
                                <span style="color:#64748b; font-size:12px;">No ID Doc</span>
                            <% } %>

                            <% if (qrImg != null && !qrImg.isEmpty()) { %>
                                <a href="images/<%= SecurityUtil.escapeHtml(qrImg) %>" target="_blank" class="btn-action btn-doc" title="View payment QR code">
                                    QR Code
                                </a>
                            <% } %>
                        </div>
                    </td>
                    <td>
                        <span class="badge <%= badgeClass %>"><%= SecurityUtil.escapeHtml(vStatus) %></span>
                        <% if (reason != null && !reason.isEmpty()) { %>
                            <small style="display:block; color:#f87171; font-size:11px; margin-top:4px;">Reason: <%= SecurityUtil.escapeHtml(reason) %></small>
                        <% } %>
                    </td>
                    <td>
                        <div class="action-btns">
                            <% if (!"Verified".equalsIgnoreCase(vStatus)) { %>
                                <a href="adminProcessVerification.jsp?organizer_id=<%= orgId %>&action=approve" 
                                   class="btn-action btn-approve"
                                   onclick="return confirm('Approve verification for <%= SecurityUtil.escapeHtml(bName != null && !bName.isEmpty() ? bName : fullName) %>?');">
                                    ✓ Approve
                                </a>
                            <% } %>

                            <% if (!"Rejected".equalsIgnoreCase(vStatus)) { %>
                                <button type="button" class="btn-action btn-reject" onclick="rejectPrompt(<%= orgId %>, '<%= SecurityUtil.escapeHtml(fullName) %>')">
                                    ✕ Reject
                                </button>
                            <% } %>
                        </div>
                    </td>
                </tr>
            <%
            }
            if (!hasRows) {
            %>
                <tr>
                    <td colspan="6" class="empty-row">
                        No organizers found in this filter category.
                    </td>
                </tr>
            <%
            }
            %>
            </tbody>
        </table>
    </div>
</div>

<script>
function rejectPrompt(orgId, name) {
    const reason = prompt("Enter rejection reason / feedback for " + name + ":", "Document image is blurry or expired.");
    if (reason !== null && reason.trim() !== "") {
        window.location.href = "adminProcessVerification.jsp?organizer_id=" + orgId + "&action=reject&reason=" + encodeURIComponent(reason.trim());
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
