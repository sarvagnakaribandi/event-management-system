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
String reqIdParam = request.getParameter("request_id");

if (reqIdParam == null || reqIdParam.trim().isEmpty()) {
    response.sendRedirect("incomingRequests.jsp");
    return;
}

int requestId;
try {
    requestId = Integer.parseInt(reqIdParam.trim());
} catch (Exception e) {
    response.sendRedirect("incomingRequests.jsp");
    return;
}

Connection conn = null;
PreparedStatement checkPs = null;
PreparedStatement reqPs = null;
ResultSet checkRs = null;
ResultSet reqRs = null;

try {
    conn = DBConnection.getConnection();

    // Check if organizer already submitted a proposal
    checkPs = conn.prepareStatement("SELECT proposal_id FROM proposals WHERE request_id = ? AND organizer_id = ?");
    checkPs.setInt(1, requestId);
    checkPs.setInt(2, organizerId);
    checkRs = checkPs.executeQuery();

    if (checkRs.next()) {
        response.sendRedirect("incomingRequests.jsp?tab=sent");
        return;
    }

    // Query request details
    String sql =
        "SELECT r.*, t.event_type_name, u.full_name AS customer_name " +
        "FROM event_requests r " +
        "JOIN event_types t ON r.event_type_id = t.event_type_id " +
        "JOIN users u ON r.user_id = u.id " +
        "WHERE r.request_id = ? AND r.status IN ('Pending', 'Proposal Received')";

    reqPs = conn.prepareStatement(sql);
    reqPs.setInt(1, requestId);
    reqRs = reqPs.executeQuery();

    if (!reqRs.next()) {
        response.sendRedirect("incomingRequests.jsp");
        return;
    }

    String title = reqRs.getString("event_title");
    String typeName = reqRs.getString("event_type_name");
    String custName = reqRs.getString("customer_name");
    Date date = reqRs.getDate("event_date");
    Time time = reqRs.getTime("event_time");
    String loc = reqRs.getString("location");
    int guests = reqRs.getInt("guest_count");
    double budget = reqRs.getDouble("budget");
    String reqs = reqRs.getString("requirements");
    String notes = reqRs.getString("additional_notes");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Proposal | EventSphere</title>
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

        .container { width:92%; max-width:1150px; margin:35px auto 80px; }

        .back-link {
            display:inline-flex;
            align-items:center;
            gap:6px;
            color:#00eaff;
            text-decoration:none;
            font-size:14px;
            margin-bottom:20px;
            font-weight:500;
        }
        .back-link:hover { color:#67e8f9; transform:translateX(-3px); }

        .page-title { font-size:30px; font-weight:700; color:#fff; margin-bottom:5px; }
        .page-subtitle { color:#94a3b8; font-size:15px; margin-bottom:25px; }

        /* Request Summary Box */
        .req-summary {
            background:#111a2d;
            border:1px solid #26354d;
            border-radius:18px;
            padding:24px;
            margin-bottom:30px;
        }
        .summary-header {
            display:flex;
            justify-content:space-between;
            align-items:flex-start;
            flex-wrap:wrap;
            gap:12px;
            margin-bottom:15px;
        }
        .summary-title { font-size:20px; font-weight:600; color:#fff; }
        .badge { background:#251b47; color:#c084fc; border:1px solid #6b21a8; padding:4px 12px; border-radius:20px; font-size:12px; font-weight:600; }

        .summary-grid {
            display:grid;
            grid-template-columns:repeat(auto-fit, minmax(180px, 1fr));
            gap:14px;
            background:#16233b;
            padding:16px;
            border-radius:12px;
            margin-bottom:15px;
        }
        .summary-item { font-size:12px; color:#94a3b8; }
        .summary-item strong { display:block; color:#f1f5f9; font-size:14px; margin-top:2px; }

        /* Form Card */
        .form-card {
            background:#111a2d;
            border:1px solid #26354d;
            border-radius:20px;
            padding:32px;
            box-shadow:0 15px 35px rgba(0,0,0,0.3);
        }
        .section-header { font-size:18px; font-weight:600; color:#ffd369; margin-bottom:18px; display:flex; align-items:center; gap:8px; }

        .form-grid {
            display:grid;
            grid-template-columns:1fr 1fr;
            gap:20px;
            margin-bottom:22px;
        }
        .form-group { display:flex; flex-direction:column; gap:8px; }
        .form-group.full { grid-column:1 / -1; }

        label { font-size:13px; font-weight:500; color:#cbd5e1; }
        label span { color:#ff4fa3; }

        input, textarea, select {
            background:#0b1220;
            border:1px solid #2d3e58;
            border-radius:10px;
            padding:12px 16px;
            color:white;
            font-size:14px;
            outline:none;
            transition:0.25s;
        }
        input:focus, textarea:focus, select:focus {
            border-color:#7c3aed;
            box-shadow:0 0 12px rgba(124, 58, 237, 0.3);
        }
        textarea { resize:vertical; min-height:90px; }

        /* Itemized Table */
        .items-table {
            width:100%;
            border-collapse:collapse;
            margin-bottom:20px;
            background:#0c1424;
            border-radius:12px;
            overflow:hidden;
            border:1px solid #26354d;
        }
        .items-table th {
            background:#16233b;
            color:#cbd5e1;
            padding:12px 15px;
            font-size:12px;
            text-align:left;
            font-weight:600;
            text-transform:uppercase;
        }
        .items-table td {
            padding:10px 15px;
            border-top:1px solid #1f2c44;
            vertical-align:middle;
        }
        .items-table input {
            padding:8px 12px;
            font-size:13px;
            width:100%;
        }

        .btn-add-item {
            background:#1e293b;
            color:#38bdf8;
            border:1px solid #0284c7;
            padding:8px 18px;
            border-radius:8px;
            font-size:13px;
            font-weight:600;
            cursor:pointer;
            display:inline-flex;
            align-items:center;
            gap:6px;
            transition:0.2s;
            margin-bottom:25px;
        }
        .btn-add-item:hover { background:rgba(56, 189, 248, 0.15); }

        .btn-del-item {
            background:transparent;
            color:#f87171;
            border:none;
            cursor:pointer;
            font-size:18px;
            padding:4px 8px;
            border-radius:6px;
        }
        .btn-del-item:hover { background:rgba(239, 68, 68, 0.2); }

        /* Summary Box */
        .total-box {
            background:#16233b;
            border:1px solid #2d3e58;
            border-radius:14px;
            padding:20px;
            display:flex;
            justify-content:space-between;
            align-items:center;
            flex-wrap:wrap;
            gap:15px;
            margin-bottom:30px;
        }
        .total-item span { display:block; color:#94a3b8; font-size:12px; }
        .total-item strong { font-size:22px; color:#4ade80; font-weight:700; }

        .submit-btn {
            width:100%;
            padding:15px;
            background:linear-gradient(135deg, #10b981, #059669);
            color:white;
            border:none;
            border-radius:12px;
            font-size:16px;
            font-weight:700;
            cursor:pointer;
            transition:0.3s;
            box-shadow:0 8px 25px rgba(16, 185, 129, 0.35);
        }
        .submit-btn:hover { opacity:0.95; transform:translateY(-2px); box-shadow:0 12px 30px rgba(16, 185, 129, 0.5); }

        @media(max-width:768px){
            .form-grid { grid-template-columns:1fr; }
            .navbar { padding:0 20px; flex-direction:column; height:auto; padding-top:15px; padding-bottom:15px; gap:12px; }
        }
    </style>
</head>
<body>

<div class="navbar">
    <div class="logo">EventSphere</div>
    <div class="nav-links">
        <a href="organizerDashboard.jsp">Dashboard</a>
        <a href="manageEvents.jsp">Manage Events</a>
        <a href="incomingRequests.jsp" class="active">Custom Requests</a>
        <a href="logout.jsp" style="color:#ff7180;">Logout</a>
    </div>
</div>

<div class="container">
    <a href="incomingRequests.jsp" class="back-link">← Back to Requests Marketplace</a>

    <h1 class="page-title">Draft Custom Proposal & Quotation</h1>
    <p class="page-subtitle">Submit a transparent, itemized quotation to win this client's event booking.</p>

    <!-- Request Summary Card -->
    <div class="req-summary">
        <div class="summary-header">
            <div>
                <span class="badge"><%= SecurityUtil.escapeHtml(typeName) %></span>
                <span class="summary-title" style="margin-left:8px;"><%= SecurityUtil.escapeHtml(title) %></span>
            </div>
            <div style="color:#94a3b8; font-size:13px;">Client: <strong><%= SecurityUtil.escapeHtml(custName) %></strong></div>
        </div>

        <div class="summary-grid">
            <div class="summary-item">Target Date: <strong>📅 <%= date != null ? date.toString() : "TBA" %></strong></div>
            <div class="summary-item">Location: <strong>📍 <%= SecurityUtil.escapeHtml(loc) %></strong></div>
            <div class="summary-item">Guests: <strong>👥 <%= guests %> Persons</strong></div>
            <div class="summary-item">Client Budget: <strong style="color:#4ade80;"><%= budget > 0 ? ("₹" + String.format("%.2f", budget)) : "Flexible" %></strong></div>
        </div>

        <% if (reqs != null && !reqs.trim().isEmpty()) { %>
            <div style="font-size:13px; color:#cbd5e1; margin-top:8px;">
                <strong>Requirements:</strong> <%= SecurityUtil.escapeHtml(reqs) %>
            </div>
        <% } %>
    </div>

    <!-- Proposal Creation Form -->
    <div class="form-card">
        <form action="submitProposal.jsp" method="post" id="proposalForm">
            <input type="hidden" name="request_id" value="<%= requestId %>">

            <div class="section-header">📑 Proposal Overview</div>
            <div class="form-grid">
                <div class="form-group full">
                    <label>Proposal Title <span>*</span></label>
                    <input type="text" name="proposal_title" placeholder="e.g., Premium All-Inclusive Birthday Celebration Package" required maxlength="200">
                </div>

                <div class="form-group">
                    <label>Quotation Valid Until <span>*</span></label>
                    <input type="date" name="valid_until" id="valid_until" required>
                </div>

                <div class="form-group">
                    <label>Advance Deposit Required (₹) <span>*</span></label>
                    <input type="number" step="0.01" name="advance_amount" id="advance_amount" placeholder="0.00" value="0.00" required min="0" oninput="updateTotals()">
                </div>

                <div class="form-group full">
                    <label>Executive Summary / Pitch</label>
                    <textarea name="description" placeholder="Brief introduction of your company, expertise, and why you are the best fit for this event..."></textarea>
                </div>

                <div class="form-group full">
                    <label>Detailed Execution Plan & Inclusions <span>*</span></label>
                    <textarea name="event_plan" placeholder="Outline the timeline, decoration theme, catering menu, sound/lighting specifications, deliverables..." style="min-height:130px;" required></textarea>
                </div>
            </div>

            <div class="section-header">🧾 Itemized Cost Breakdown</div>
            <p style="color:#94a3b8; font-size:13px; margin-bottom:15px;">List individual line items, deliverables, or services with their unit costs.</p>

            <table class="items-table" id="itemsTable">
                <thead>
                    <tr>
                        <th style="width:30%;">Item / Service Name</th>
                        <th style="width:35%;">Description / Specifications</th>
                        <th style="width:12%;">Qty</th>
                        <th style="width:18%;">Unit Price (₹)</th>
                        <th style="width:5%;"></th>
                    </tr>
                </thead>
                <tbody id="itemsBody">
                    <tr>
                        <td><input type="text" name="item_name" placeholder="e.g. Balloon Decor & Theme Backdrop" required></td>
                        <td><input type="text" name="item_desc" placeholder="Specifications..."></td>
                        <td><input type="number" name="item_qty" value="1" min="1" oninput="updateTotals()" required></td>
                        <td><input type="number" step="0.01" name="item_price" placeholder="0.00" min="0" oninput="updateTotals()" required></td>
                        <td></td>
                    </tr>
                </tbody>
            </table>

            <button type="button" class="btn-add-item" onclick="addItemRow()">+ Add Another Line Item</button>

            <!-- Total Calculation Display -->
            <div class="total-box">
                <div class="total-item">
                    <span>Total Quotation Amount</span>
                    <strong id="displayTotal">₹0.00</strong>
                    <input type="hidden" name="total_amount" id="total_amount" value="0.00">
                </div>
                <div class="total-item">
                    <span>Advance Required</span>
                    <strong id="displayAdvance" style="color:#38bdf8;">₹0.00</strong>
                </div>
                <div class="total-item">
                    <span>Remaining Balance on Event Day</span>
                    <strong id="displayRemaining" style="color:#facc15;">₹0.00</strong>
                </div>
            </div>

            <button type="submit" class="submit-btn">🚀 Submit Proposal Quotation to Client</button>
        </form>
    </div>
</div>

<script>
// Set default valid_until date to 7 days from today
const today = new Date();
today.setDate(today.getDate() + 7);
document.getElementById('valid_until').value = today.toISOString().split('T')[0];

function addItemRow() {
    const tbody = document.getElementById('itemsBody');
    const tr = document.createElement('tr');
    tr.innerHTML = `
        <td><input type="text" name="item_name" placeholder="Item / service name" required></td>
        <td><input type="text" name="item_desc" placeholder="Specifications..."></td>
        <td><input type="number" name="item_qty" value="1" min="1" oninput="updateTotals()" required></td>
        <td><input type="number" step="0.01" name="item_price" placeholder="0.00" min="0" oninput="updateTotals()" required></td>
        <td><button type="button" class="btn-del-item" onclick="removeItemRow(this)" title="Remove item">✕</button></td>
    `;
    tbody.appendChild(tr);
    updateTotals();
}

function removeItemRow(btn) {
    const tbody = document.getElementById('itemsBody');
    if (tbody.children.length > 1) {
        btn.closest('tr').remove();
        updateTotals();
    } else {
        alert("At least one line item is required.");
    }
}

function updateTotals() {
    let total = 0;
    const qtys = document.getElementsByName('item_qty');
    const prices = document.getElementsByName('item_price');

    for (let i = 0; i < qtys.length; i++) {
        const q = parseFloat(qtys[i].value) || 0;
        const p = parseFloat(prices[i].value) || 0;
        total += (q * p);
    }

    const advance = parseFloat(document.getElementById('advance_amount').value) || 0;
    const remaining = Math.max(0, total - advance);

    document.getElementById('total_amount').value = total.toFixed(2);
    document.getElementById('displayTotal').innerText = '₹' + total.toFixed(2);
    document.getElementById('displayAdvance').innerText = '₹' + advance.toFixed(2);
    document.getElementById('displayRemaining').innerText = '₹' + remaining.toFixed(2);
}

document.getElementById('proposalForm').addEventListener('submit', function(e) {
    updateTotals();
    const total = parseFloat(document.getElementById('total_amount').value) || 0;
    if (total <= 0) {
        e.preventDefault();
        alert('Please enter valid quantities and prices for your line items so total is greater than 0.');
    }
});
</script>

</body>
</html>
<%
} catch (Exception e) {
    out.println("<h2 style='color:#f87171;padding:30px;'>Error</h2>");
    out.println("<p style='padding:0 30px;color:#cbd5e1;'>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
} finally {
    DBConnection.close(checkRs, reqRs, checkPs, reqPs, conn);
}
%>
