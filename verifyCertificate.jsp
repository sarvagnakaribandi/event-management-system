<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   PUBLIC CERTIFICATE VERIFIER (PHASE 9)
   Public endpoint to verify Certificate of Participation
   ===================================================== */
String certIdParam = request.getParameter("cert_id");
boolean searched = (certIdParam != null && !certIdParam.trim().isEmpty());

boolean isVerified = false;
String attendeeName = null;
String attendeeEmail = null;
String eventName = null;
String category = null;
Date eventDate = null;
String venue = null;
Timestamp checkedInAt = null;
String organizerName = null;
String organizerBusiness = null;
boolean organizerVerified = false;
String certificateId = null;

if (searched) {
    certIdParam = certIdParam.trim().toUpperCase();
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
            "WHERE r.certificate_id = ? AND r.check_in_status = 'Checked In'";

        ps = conn.prepareStatement(sql);
        ps.setString(1, certIdParam);
        rs = ps.executeQuery();

        if (rs.next()) {
            isVerified = true;
            attendeeName = rs.getString("full_name");
            String rawEmail = rs.getString("email");
            if (rawEmail != null && rawEmail.contains("@")) {
                String[] parts = rawEmail.split("@", 2);
                attendeeEmail = (parts[0].length() > 2 ? parts[0].substring(0, 2) + "***" : parts[0].substring(0, 1) + "***") + "@" + parts[1];
            } else {
                attendeeEmail = "Confidential";
            }
            eventName = rs.getString("event_name");
            category = rs.getString("category");
            eventDate = rs.getDate("event_date");
            venue = rs.getString("venue");
            checkedInAt = rs.getTimestamp("checked_in_at");
            certificateId = rs.getString("certificate_id");
            organizerName = rs.getString("organizer_name");
            organizerBusiness = rs.getString("business_name");
            organizerVerified = "Verified".equalsIgnoreCase(rs.getString("verification_status"));
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
        if (ps != null) try { ps.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Certificate Verification Portal | EventSphere Trust Engine</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Space+Mono:wght@700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #080c1a;
            color: #f1f5f9;
            font-family: 'Poppins', sans-serif;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            overflow-x: hidden;
            position: relative;
        }

        .bg-glow-1 {
            position: absolute;
            top: -150px;
            left: 50%;
            transform: translateX(-50%);
            width: 700px;
            height: 400px;
            background: radial-gradient(ellipse at center, rgba(16, 185, 129, 0.15) 0%, rgba(99, 102, 241, 0.08) 50%, transparent 80%);
            filter: blur(80px);
            pointer-events: none;
            z-index: 0;
        }

        .bg-glow-2 {
            position: absolute;
            bottom: 0;
            right: 10%;
            width: 500px;
            height: 350px;
            background: radial-gradient(ellipse at center, rgba(245, 158, 11, 0.08) 0%, transparent 70%);
            filter: blur(70px);
            pointer-events: none;
            z-index: 0;
        }

        /* Top Nav */
        .header {
            position: relative;
            z-index: 10;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 24px 40px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.06);
            backdrop-filter: blur(12px);
            background: rgba(8, 12, 26, 0.7);
        }

        .brand-logo {
            display: flex;
            align-items: center;
            gap: 12px;
            text-decoration: none;
            color: #fff;
            font-size: 20px;
            font-weight: 700;
            letter-spacing: -0.5px;
        }

        .brand-logo svg {
            width: 32px;
            height: 32px;
        }

        .nav-links a {
            color: #94a3b8;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            transition: color 0.2s;
            margin-left: 20px;
        }
        .nav-links a:hover {
            color: #38bdf8;
        }

        /* Container */
        .main-container {
            position: relative;
            z-index: 2;
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 60px 20px 80px 20px;
            max-width: 900px;
            margin: 0 auto;
            width: 100%;
        }

        .portal-header {
            text-align: center;
            margin-bottom: 40px;
        }

        .badge-trust {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(16, 185, 129, 0.12);
            border: 1px solid rgba(16, 185, 129, 0.35);
            color: #34d399;
            padding: 6px 16px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 1px;
            text-transform: uppercase;
            margin-bottom: 16px;
        }

        .badge-trust svg {
            width: 15px;
            height: 15px;
        }

        .portal-title {
            font-size: 36px;
            font-weight: 800;
            color: #fff;
            letter-spacing: -1px;
            margin-bottom: 10px;
            line-height: 1.2;
        }

        .portal-desc {
            color: #94a3b8;
            font-size: 15px;
            max-width: 600px;
            margin: 0 auto;
            line-height: 1.6;
        }

        /* Search Bar */
        .search-box-card {
            width: 100%;
            background: rgba(15, 23, 42, 0.85);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 16px;
            padding: 10px;
            backdrop-filter: blur(20px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
            margin-bottom: 40px;
        }

        .search-form {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .search-input-wrapper {
            position: relative;
            flex: 1;
            display: flex;
            align-items: center;
        }

        .search-icon {
            position: absolute;
            left: 18px;
            color: #64748b;
            width: 20px;
            height: 20px;
            pointer-events: none;
        }

        .search-input {
            width: 100%;
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 10px;
            padding: 15px 15px 15px 50px;
            color: #fff;
            font-family: 'Space Mono', monospace;
            font-size: 15px;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            outline: none;
            transition: all 0.2s;
        }

        .search-input:focus {
            border-color: #6366f1;
            background: rgba(99, 102, 241, 0.05);
            box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.15);
        }

        .btn-verify {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: #fff;
            font-weight: 600;
            font-size: 14px;
            padding: 15px 32px;
            border-radius: 10px;
            border: none;
            cursor: pointer;
            transition: all 0.2s;
            box-shadow: 0 8px 20px rgba(16, 185, 129, 0.3);
            white-space: nowrap;
        }

        .btn-verify:hover {
            transform: translateY(-2px);
            box-shadow: 0 12px 25px rgba(16, 185, 129, 0.4);
        }

        /* Result Cards */
        .result-container {
            width: 100%;
            animation: fadeIn 0.4s ease-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(12px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .verified-card {
            background: linear-gradient(145deg, rgba(16, 185, 129, 0.05) 0%, rgba(15, 23, 42, 0.95) 100%);
            border: 1px solid rgba(16, 185, 129, 0.4);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 25px 60px rgba(0, 0, 0, 0.5), 0 0 40px rgba(16, 185, 129, 0.15);
            position: relative;
            overflow: hidden;
        }

        .verified-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: linear-gradient(90deg, #10b981, #38bdf8, #6366f1);
        }

        .status-banner {
            display: flex;
            align-items: center;
            gap: 16px;
            padding-bottom: 28px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            margin-bottom: 30px;
        }

        .status-icon-wrap {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            background: rgba(16, 185, 129, 0.15);
            border: 2px solid #10b981;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #34d399;
            box-shadow: 0 0 25px rgba(16, 185, 129, 0.35);
        }

        .status-icon-wrap svg {
            width: 32px;
            height: 32px;
        }

        .status-title {
            font-size: 22px;
            font-weight: 700;
            color: #34d399;
            letter-spacing: -0.5px;
        }

        .status-sub {
            font-size: 13px;
            color: #94a3b8;
            margin-top: 2px;
        }

        .data-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 24px;
            margin-bottom: 35px;
        }

        .data-item {
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 255, 255, 0.05);
            border-radius: 12px;
            padding: 16px 20px;
        }

        .data-label {
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #64748b;
            margin-bottom: 6px;
        }

        .data-value {
            font-size: 16px;
            font-weight: 600;
            color: #fff;
            word-break: break-word;
        }

        .data-value.highlight {
            color: #38bdf8;
            font-family: 'Space Mono', monospace;
            font-size: 15px;
        }

        .verified-badge-mini {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: rgba(16, 185, 129, 0.15);
            color: #34d399;
            font-size: 11px;
            padding: 2px 8px;
            border-radius: 4px;
            margin-left: 8px;
            vertical-align: middle;
        }

        .verified-actions {
            display: flex;
            justify-content: flex-end;
            gap: 15px;
            border-top: 1px solid rgba(255, 255, 255, 0.08);
            padding-top: 25px;
        }

        .btn-view-cert {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
            color: #fff;
            text-decoration: none;
            padding: 12px 24px;
            border-radius: 10px;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.2s;
            box-shadow: 0 4px 15px rgba(99, 102, 241, 0.35);
        }

        .btn-view-cert:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(99, 102, 241, 0.5);
        }

        /* Not Found Card */
        .notfound-card {
            background: linear-gradient(145deg, rgba(239, 68, 68, 0.05) 0%, rgba(15, 23, 42, 0.95) 100%);
            border: 1px solid rgba(239, 68, 68, 0.35);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 25px 60px rgba(0, 0, 0, 0.5);
            text-align: center;
        }

        .notfound-icon {
            width: 70px;
            height: 70px;
            border-radius: 50%;
            background: rgba(239, 68, 68, 0.15);
            border: 2px solid #ef4444;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #f87171;
            margin: 0 auto 20px auto;
        }

        .notfound-icon svg {
            width: 36px;
            height: 36px;
        }

        .notfound-title {
            font-size: 22px;
            font-weight: 700;
            color: #f87171;
            margin-bottom: 10px;
        }

        .notfound-text {
            color: #94a3b8;
            font-size: 14px;
            max-width: 500px;
            margin: 0 auto 25px auto;
            line-height: 1.6;
        }

        /* Empty state info */
        .info-cards-row {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            width: 100%;
            margin-top: 10px;
        }

        .info-card {
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 255, 255, 0.06);
            border-radius: 14px;
            padding: 24px 20px;
            text-align: center;
        }

        .info-card-icon {
            width: 44px;
            height: 44px;
            border-radius: 12px;
            background: rgba(99, 102, 241, 0.12);
            color: #818cf8;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 16px auto;
        }

        .info-card h4 {
            font-size: 15px;
            font-weight: 600;
            color: #fff;
            margin-bottom: 8px;
        }

        .info-card p {
            font-size: 13px;
            color: #64748b;
            line-height: 1.5;
        }

        .footer {
            text-align: center;
            padding: 30px;
            font-size: 13px;
            color: #475569;
            border-top: 1px solid rgba(255, 255, 255, 0.04);
        }

        @media (max-width: 768px) {
            .header { padding: 18px 20px; }
            .data-grid { grid-template-columns: 1fr; }
            .info-cards-row { grid-template-columns: 1fr; }
            .search-form { flex-direction: column; }
            .btn-verify { width: 100%; }
        }
    </style>
</head>
<body>
    <div class="bg-glow-1"></div>
    <div class="bg-glow-2"></div>

    <header class="header">
        <a href="index.jsp" class="brand-logo">
            <svg viewBox="0 0 24 24" fill="none" stroke="url(#logo-grad)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <defs>
                    <linearGradient id="logo-grad" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stop-color="#38bdf8"/>
                        <stop offset="100%" stop-color="#818cf8"/>
                    </linearGradient>
                </defs>
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
            </svg>
            <span>Event<span style="color: #38bdf8;">Sphere</span></span>
        </a>
        <div class="nav-links">
            <a href="events.jsp">Browse Events</a>
            <a href="myRegistrations.jsp">My Tickets</a>
            <a href="index.jsp">Home</a>
        </div>
    </header>

    <main class="main-container">
        <div class="portal-header">
            <div class="badge-trust">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                    <polyline points="9 12 11 14 15 10"></polyline>
                </svg>
                EventSphere Trust & Safety Engine
            </div>
            <h1 class="portal-title">Official Certificate Verification</h1>
            <p class="portal-desc">Instantly verify the cryptographic authenticity of EventSphere Certificates of Participation and confirm gate-scanned attendance.</p>
        </div>

        <!-- Search Bar -->
        <div class="search-box-card">
            <form action="verifyCertificate.jsp" method="GET" class="search-form">
                <div class="search-input-wrapper">
                    <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="11" cy="11" r="8"></circle>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                    </svg>
                    <input type="text" name="cert_id" class="search-input" placeholder="Enter Certificate ID (e.g. CERT-0004-BEEDAF)" value="<%= certIdParam != null ? SecurityUtil.escapeHtml(certIdParam) : "" %>" required autocomplete="off">
                </div>
                <button type="submit" class="btn-verify">Verify Record</button>
            </form>
        </div>

        <!-- Search Results -->
        <% if (searched) { %>
            <div class="result-container">
                <% if (isVerified) { %>
                    <div class="verified-card">
                        <div class="status-banner">
                            <div class="status-icon-wrap">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                            </div>
                            <div>
                                <div class="status-title">Authentic & Verified Certificate</div>
                                <div class="status-sub">This certificate was generated by the EventSphere Trust Engine following verified gate check-in.</div>
                            </div>
                        </div>

                        <div class="data-grid">
                            <div class="data-item">
                                <div class="data-label">Certificate ID</div>
                                <div class="data-value highlight"><%= certificateId %></div>
                            </div>

                            <div class="data-item">
                                <div class="data-label">Honored Recipient</div>
                                <div class="data-value"><%= SecurityUtil.escapeHtml(attendeeName) %></div>
                            </div>

                            <div class="data-item">
                                <div class="data-label">Event Name & Category</div>
                                <div class="data-value"><%= SecurityUtil.escapeHtml(eventName) %> <span style="color: #94a3b8; font-weight: 400; font-size: 13px;">(<%= SecurityUtil.escapeHtml(category) %>)</span></div>
                            </div>

                            <div class="data-item">
                                <div class="data-label">Event Date & Venue</div>
                                <div class="data-value"><%= eventDate != null ? eventDate.toString() : "TBD" %> • <%= SecurityUtil.escapeHtml(venue) %></div>
                            </div>

                            <div class="data-item">
                                <div class="data-label">Verified Gate Check-In</div>
                                <div class="data-value" style="color: #34d399;">
                                    ✓ Attended (<%= checkedInAt != null ? checkedInAt.toString() : "Verified" %>)
                                </div>
                            </div>

                            <div class="data-item">
                                <div class="data-label">Issuing Organizer</div>
                                <div class="data-value">
                                    <%= SecurityUtil.escapeHtml(organizerBusiness != null && !organizerBusiness.trim().isEmpty() ? organizerBusiness : organizerName) %>
                                    <% if (organizerVerified) { %>
                                        <span class="verified-badge-mini">✓ Verified Host</span>
                                    <% } %>
                                </div>
                            </div>
                        </div>

                        <div class="verified-actions">
                            <a href="certificate.jsp?cert_id=<%= certificateId %>" target="_blank" class="btn-view-cert">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                    <polyline points="14 2 14 8 20 8"></polyline>
                                    <line x1="16" y1="13" x2="8" y2="13"></line>
                                    <line x1="16" y1="17" x2="8" y2="17"></line>
                                    <polyline points="10 9 9 9 8 9"></polyline>
                                </svg>
                                View Official Certificate
                            </a>
                        </div>
                    </div>
                <% } else { %>
                    <div class="notfound-card">
                        <div class="notfound-icon">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"></circle>
                                <line x1="15" y1="9" x2="9" y2="15"></line>
                                <line x1="9" y1="9" x2="15" y2="15"></line>
                            </svg>
                        </div>
                        <h2 class="notfound-title">Certificate Not Verified</h2>
                        <p class="notfound-text">
                            No verified attendance certificate found for code: <strong style="color: #fff;"><%= SecurityUtil.escapeHtml(certIdParam) %></strong>.
                            Certificates are strictly issued only after the attendee physically checks in through the live gate scanner.
                        </p>
                        <a href="verifyCertificate.jsp" style="color: #818cf8; text-decoration: none; font-size: 14px; font-weight: 500;">← Clear & Search Again</a>
                    </div>
                <% } %>
            </div>
        <% } else { %>
            <div class="info-cards-row">
                <div class="info-card">
                    <div class="info-card-icon">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                            <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                        </svg>
                    </div>
                    <h4>Tamper-Proof ID</h4>
                    <p>Every certificate is cryptographically bound to its unique booking and gate check-in event.</p>
                </div>

                <div class="info-card">
                    <div class="info-card-icon">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                            <polyline points="22 4 12 14.01 9 11.01"></polyline>
                        </svg>
                    </div>
                    <h4>Gate Checked-In Only</h4>
                    <p>Certificates unlock only after attendance is physically scanned at the venue gate.</p>
                </div>

                <div class="info-card">
                    <div class="info-card-icon">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"></circle>
                            <line x1="2" y1="12" x2="22" y2="12"></line>
                            <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
                        </svg>
                    </div>
                    <h4>Public Verification</h4>
                    <p>Employers and institutions can verify recipient credentials globally in real-time.</p>
                </div>
            </div>
        <% } %>
    </main>

    <footer class="footer">
        &copy; 2026 EventSphere Platform Inc. All verification records are cryptographically indexed.
    </footer>
</body>
</html>
