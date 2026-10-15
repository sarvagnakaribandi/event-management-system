<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   ORGANIZER PERFORMANCE & REVENUE ANALYTICS (PHASE 10)
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String sessionRole = session.getAttribute("role") != null ? session.getAttribute("role").toString() : "";
boolean isAdmin = "Admin".equalsIgnoreCase(sessionRole);
boolean isOrganizer = "Organizer".equalsIgnoreCase(sessionRole);

if (!isAdmin && !isOrganizer) {
    response.sendRedirect("login.jsp");
    return;
}

int organizerId = Integer.parseInt(session.getAttribute("userId").toString());
String userName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Organizer";

Connection conn = null;
PreparedStatement psKpi = null;
PreparedStatement psEvents = null;
PreparedStatement psReviews = null;
ResultSet rsKpi = null;
ResultSet rsEvents = null;
ResultSet rsReviews = null;

double totalRevenue = 0.0;
int totalBookings = 0;
int totalCheckedIn = 0;
double avgRating = 0.0;
int totalReviews = 0;
String businessName = null;
String verifStatus = null;

try {
    conn = DBConnection.getConnection();

    // Organizer profile
    PreparedStatement psProf = conn.prepareStatement("SELECT business_name, verification_status FROM organizer_profiles WHERE organizer_id = ?");
    psProf.setInt(1, organizerId);
    ResultSet rsProf = psProf.executeQuery();
    if (rsProf.next()) {
        businessName = rsProf.getString("business_name");
        verifStatus = rsProf.getString("verification_status");
    }
    rsProf.close();
    psProf.close();

    // 1. KPI Aggregations
    String kpiSql =
        "SELECT " +
        "COALESCE(SUM(CASE WHEN r.payment_status = 'Approved' THEN e.event_fee ELSE 0 END), 0) AS total_rev, " +
        "COUNT(r.registration_id) AS total_reg, " +
        "COALESCE(SUM(CASE WHEN r.check_in_status = 'Checked In' THEN 1 ELSE 0 END), 0) AS total_checked " +
        "FROM events e " +
        "LEFT JOIN registrations r ON e.event_id = r.event_id " +
        (isAdmin ? "" : "WHERE e.organizer_id = ? ");

    psKpi = conn.prepareStatement(kpiSql);
    if (!isAdmin) {
        psKpi.setInt(1, organizerId);
    }
    rsKpi = psKpi.executeQuery();
    if (rsKpi.next()) {
        totalRevenue = rsKpi.getDouble("total_rev");
        totalBookings = rsKpi.getInt("total_reg");
        totalCheckedIn = rsKpi.getInt("total_checked");
    }

    // 2. Reviews Average
    String revKpiSql =
        "SELECT COALESCE(AVG(er.rating), 0) AS avg_stars, COUNT(er.review_id) AS rev_count " +
        "FROM event_reviews er " +
        "JOIN events e ON er.event_id = e.event_id " +
        (isAdmin ? "" : "WHERE e.organizer_id = ? ");

    PreparedStatement psRevKpi = conn.prepareStatement(revKpiSql);
    if (!isAdmin) {
        psRevKpi.setInt(1, organizerId);
    }
    ResultSet rsRevKpi = psRevKpi.executeQuery();
    if (rsRevKpi.next()) {
        avgRating = rsRevKpi.getDouble("avg_stars");
        totalReviews = rsRevKpi.getInt("rev_count");
    }
    rsRevKpi.close();
    psRevKpi.close();

    double checkInRate = totalBookings > 0 ? ((double) totalCheckedIn / totalBookings) * 100.0 : 0.0;

    // 3. Event-by-Event Analytics
    String eventsSql =
        "SELECT e.event_id, e.event_name, e.category, e.event_date, e.payment_type, e.event_fee, e.max_capacity, e.available_seats, " +
        "COUNT(r.registration_id) AS event_reg, " +
        "COALESCE(SUM(CASE WHEN r.check_in_status = 'Checked In' THEN 1 ELSE 0 END), 0) AS event_checked, " +
        "COALESCE(AVG(er.rating), 0) AS event_rating, " +
        "COUNT(DISTINCT er.review_id) AS event_reviews_count " +
        "FROM events e " +
        "LEFT JOIN registrations r ON e.event_id = r.event_id " +
        "LEFT JOIN event_reviews er ON e.event_id = er.event_id " +
        (isAdmin ? "" : "WHERE e.organizer_id = ? ") +
        "GROUP BY e.event_id " +
        "ORDER BY e.event_date DESC";

    psEvents = conn.prepareStatement(eventsSql);
    if (!isAdmin) {
        psEvents.setInt(1, organizerId);
    }
    rsEvents = psEvents.executeQuery();

    // 4. Recent Reviews Feed
    String recentRevSql =
        "SELECT er.*, u.full_name AS reviewer_name, e.event_name, r.check_in_status " +
        "FROM event_reviews er " +
        "JOIN events e ON er.event_id = e.event_id " +
        "JOIN users u ON er.user_id = u.id " +
        "LEFT JOIN registrations r ON er.registration_id = r.registration_id " +
        (isAdmin ? "" : "WHERE e.organizer_id = ? ") +
        "ORDER BY er.created_at DESC LIMIT 15";

    psReviews = conn.prepareStatement(recentRevSql);
    if (!isAdmin) {
        psReviews.setInt(1, organizerId);
    }
    rsReviews = psReviews.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Organizer Analytics & Revenue Insights | EventSphere</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Space+Mono:wght@700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="css/notifications.css">
    <link rel="stylesheet" href="css/toast.css">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #090e1c;
            color: #f1f5f9;
            font-family: 'Poppins', sans-serif;
            min-height: 100vh;
        }

        .navbar {
            height: 75px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0 40px;
            background: #10172a;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
        }

        .logo {
            font-size: 22px;
            font-weight: 700;
            background: linear-gradient(90deg, #38bdf8, #818cf8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-decoration: none;
        }

        .nav-links {
            display: flex;
            gap: 20px;
            align-items: center;
        }

        .nav-links a {
            color: #cbd5e1;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            transition: color 0.2s;
        }
        .nav-links a:hover { color: #38bdf8; }

        .container {
            width: 92%;
            max-width: 1350px;
            margin: 35px auto 70px auto;
        }

        .header-section {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 35px;
        }

        .page-title {
            font-size: 30px;
            font-weight: 800;
            color: #fff;
            letter-spacing: -0.5px;
        }

        .page-subtitle {
            color: #94a3b8;
            font-size: 14px;
            margin-top: 4px;
        }

        /* KPI Grid */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }

        .kpi-card {
            background: #111a2f;
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 16px;
            padding: 24px;
            position: relative;
            overflow: hidden;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
            transition: transform 0.2s, border-color 0.2s;
        }
        .kpi-card:hover {
            transform: translateY(-3px);
            border-color: rgba(99, 102, 241, 0.4);
        }

        .kpi-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
            margin-bottom: 16px;
        }

        .kpi-label {
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #94a3b8;
            margin-bottom: 6px;
        }

        .kpi-value {
            font-size: 28px;
            font-weight: 800;
            color: #fff;
            letter-spacing: -0.5px;
        }

        .kpi-sub {
            font-size: 12px;
            color: #64748b;
            margin-top: 6px;
        }

        /* Content Grid */
        .analytics-layout {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 30px;
        }

        .panel-box {
            background: #111a2f;
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 18px;
            padding: 30px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.25);
            margin-bottom: 30px;
        }

        .panel-title {
            font-size: 18px;
            font-weight: 700;
            color: #fff;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        /* Table */
        .table-responsive {
            overflow-x: auto;
        }

        table.analytics-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }

        table.analytics-table th {
            background: rgba(255, 255, 255, 0.02);
            color: #94a3b8;
            padding: 12px 14px;
            text-align: left;
            font-weight: 600;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            white-space: nowrap;
        }

        table.analytics-table td {
            padding: 14px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.04);
            color: #cbd5e1;
        }

        table.analytics-table tr:hover td {
            background: rgba(255, 255, 255, 0.02);
        }

        .badge-rating-mini {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: rgba(245, 158, 11, 0.15);
            color: #fbbf24;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 12px;
        }

        /* Review Feed Item */
        .feed-item {
            padding: 16px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.06);
        }
        .feed-item:last-child { border-bottom: none; }

        .feed-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 4px;
        }

        .feed-event {
            font-size: 11px;
            color: #38bdf8;
            font-weight: 600;
            text-transform: uppercase;
        }

        .feed-user {
            font-weight: 600;
            color: #fff;
            font-size: 13px;
        }

        .feed-text {
            color: #94a3b8;
            font-size: 12px;
            line-height: 1.5;
            margin-top: 4px;
        }

        @media (max-width: 1024px) {
            .analytics-layout { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

    <header class="navbar">
        <a href="organizerDashboard.jsp" class="logo">EventSphere</a>
        <div class="nav-links">
            <a href="organizerDashboard.jsp">Dashboard</a>
            <a href="manageEvents.jsp">Manage Events</a>
            <a href="organizerAnalytics.jsp" style="color:#38bdf8; font-weight:700;">Analytics</a>
            <jsp:include page="navbarNotification.jsp" />
            <a href="logout.jsp" style="color:#ff7180;">Logout</a>
        </div>
    </header>

    <main class="container">
        <div class="header-section">
            <div>
                <h1 class="page-title">Performance & Revenue Analytics</h1>
                <p class="page-subtitle">Real-time attendance rates, ticket sales, gate check-in statistics, and attendee reviews.</p>
            </div>
            <div style="display:flex; gap:10px;">
                <a href="manageEvents.jsp" style="padding:10px 18px; border-radius:10px; background:#1e293b; color:#cbd5e1; text-decoration:none; font-weight:600; font-size:13px; border:1px solid #334155;">
                    📅 Manage Events
                </a>
                <a href="organizerDashboard.jsp" style="padding:10px 18px; border-radius:10px; background:#6366f1; color:#fff; text-decoration:none; font-weight:600; font-size:13px;">
                    ← Back to Dashboard
                </a>
            </div>
        </div>

        <!-- 4 Core KPIs -->
        <div class="kpi-grid">
            <div class="kpi-card">
                <div class="kpi-icon" style="background: rgba(16, 185, 129, 0.15); color: #34d399;">₹</div>
                <div class="kpi-label">Confirmed Revenue</div>
                <div class="kpi-value" style="color: #34d399;">₹<%= String.format("%.2f", totalRevenue) %></div>
                <div class="kpi-sub">From approved paid registrations</div>
            </div>

            <div class="kpi-card">
                <div class="kpi-icon" style="background: rgba(56, 189, 248, 0.15); color: #38bdf8;">🎟️</div>
                <div class="kpi-label">Total Bookings</div>
                <div class="kpi-value"><%= totalBookings %></div>
                <div class="kpi-sub">Total event participant reservations</div>
            </div>

            <div class="kpi-card">
                <div class="kpi-icon" style="background: rgba(139, 92, 246, 0.15); color: #c084fc;">📲</div>
                <div class="kpi-label">Gate Check-In Rate</div>
                <div class="kpi-value"><%= String.format("%.1f", checkInRate) %>%</div>
                <div class="kpi-sub"><%= totalCheckedIn %> of <%= totalBookings %> attendees admitted</div>
            </div>

            <div class="kpi-card">
                <div class="kpi-icon" style="background: rgba(245, 158, 11, 0.15); color: #fbbf24;">⭐</div>
                <div class="kpi-label">Attendee Rating</div>
                <div class="kpi-value" style="color: #fbbf24;"><%= totalReviews > 0 ? String.format("%.1f", avgRating) : "N/A" %></div>
                <div class="kpi-sub">Based on <%= totalReviews %> verified attendee reviews</div>
            </div>
        </div>

        <!-- Layout Grid -->
        <div class="analytics-layout">
            <!-- Left: Event Breakdown Table -->
            <div class="panel-box">
                <div class="panel-title">
                    <span>📊 Event Performance Breakdown</span>
                </div>

                <div class="table-responsive">
                    <table class="analytics-table">
                        <thead>
                            <tr>
                                <th>Event Name</th>
                                <th>Date</th>
                                <th>Bookings</th>
                                <th>Check-In %</th>
                                <th>Rating</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                            boolean hasEvents = false;
                            while (rsEvents.next()) {
                                hasEvents = true;
                                int eId = rsEvents.getInt("event_id");
                                String eName = rsEvents.getString("event_name");
                                Date eDate = rsEvents.getDate("event_date");
                                int eBooked = rsEvents.getInt("event_reg");
                                int eChecked = rsEvents.getInt("event_checked");
                                double eRating = rsEvents.getDouble("event_rating");
                                int eRevCount = rsEvents.getInt("event_reviews_count");
                                double eCheckRate = eBooked > 0 ? ((double) eChecked / eBooked) * 100.0 : 0.0;
                            %>
                            <tr>
                                <td>
                                    <strong><%= SecurityUtil.escapeHtml(eName) %></strong>
                                    <div style="font-size:11px; color:#64748b;"><%= SecurityUtil.escapeHtml(rsEvents.getString("category")) %></div>
                                </td>
                                <td><%= eDate != null ? eDate.toString() : "TBD" %></td>
                                <td><strong><%= eBooked %></strong></td>
                                <td>
                                    <span style="color: <%= eCheckRate >= 70 ? "#34d399" : (eCheckRate >= 40 ? "#fbbf24" : "#94a3b8") %>; font-weight:700;">
                                        <%= String.format("%.0f", eCheckRate) %>%
                                    </span>
                                    <div style="font-size:11px; color:#64748b;"><%= eChecked %> / <%= eBooked %></div>
                                </td>
                                <td>
                                    <% if (eRevCount > 0) { %>
                                        <span class="badge-rating-mini">★ <%= String.format("%.1f", eRating) %></span>
                                    <% } else { %>
                                        <span style="color:#64748b; font-size:11px;">No reviews</span>
                                    <% } %>
                                </td>
                                <td>
                                    <a href="gateScanner.jsp?id=<%= eId %>" style="color:#0ea5e9; text-decoration:none; font-weight:600; font-size:12px; margin-right:10px;">📲 Gate</a>
                                    <a href="viewParticipants.jsp?id=<%= eId %>" style="color:#818cf8; text-decoration:none; font-weight:600; font-size:12px;">👥 Roster</a>
                                </td>
                            </tr>
                            <% } %>
                            <% if (!hasEvents) { %>
                            <tr>
                                <td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No events published yet.</td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Right: Recent Reviews Feed -->
            <div class="panel-box">
                <div class="panel-title">
                    <span>⭐ Recent Attendee Reviews</span>
                </div>

                <div class="feed-list">
                    <%
                    boolean hasReviews = false;
                    while (rsReviews.next()) {
                        hasReviews = true;
                        String rUser = rsReviews.getString("reviewer_name");
                        String rEvent = rsReviews.getString("event_name");
                        int rScore = rsReviews.getInt("rating");
                        String rTitle = rsReviews.getString("review_title");
                        String rText = rsReviews.getString("review_text");
                        Timestamp rTime = rsReviews.getTimestamp("created_at");
                    %>
                    <div class="feed-item">
                        <div class="feed-event"><%= SecurityUtil.escapeHtml(rEvent) %></div>
                        <div class="feed-top">
                            <span class="feed-user"><%= SecurityUtil.escapeHtml(rUser) %></span>
                            <span style="color:#fbbf24; font-size:12px;">
                                <% for (int s = 1; s <= rScore; s++) { out.print("★"); } %>
                            </span>
                        </div>
                        <div style="font-weight:600; font-size:12px; color:#fff;"><%= SecurityUtil.escapeHtml(rTitle) %></div>
                        <p class="feed-text"><%= SecurityUtil.escapeHtml(rText) %></p>
                        <div style="font-size:10px; color:#64748b; margin-top:4px;">
                            <%= rTime != null ? new java.text.SimpleDateFormat("MMM dd, yyyy").format(rTime) : "" %>
                        </div>
                    </div>
                    <% } %>
                    <% if (!hasReviews) { %>
                    <div style="text-align:center; padding:40px 10px; color:#64748b; font-size:13px;">
                        No attendee reviews received yet.
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
    </main>

    <script src="js/toast.js"></script>
    <script src="js/notifications.js"></script>
</body>
</html>
<%
} catch (Exception e) {
    e.printStackTrace();
    out.println("<h3 style='color:red;'>Analytics Error: " + SecurityUtil.escapeHtml(e.getMessage()) + "</h3>");
} finally {
    if (rsReviews != null) try { rsReviews.close(); } catch (Exception ignored) {}
    if (psReviews != null) try { psReviews.close(); } catch (Exception ignored) {}
    if (rsEvents != null) try { rsEvents.close(); } catch (Exception ignored) {}
    if (psEvents != null) try { psEvents.close(); } catch (Exception ignored) {}
    if (rsKpi != null) try { rsKpi.close(); } catch (Exception ignored) {}
    if (psKpi != null) try { psKpi.close(); } catch (Exception ignored) {}
    if (conn != null) try { conn.close(); } catch (Exception ignored) {}
}
%>
