<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>
<%@ page import="database.NotificationDAO" %>

<%
/* =====================================================
   LOGIN CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

int userId = Integer.parseInt(session.getAttribute("userId").toString());

/* =====================================================
   GET FORM DATA
   ===================================================== */
String eventTypeValue = request.getParameter("event_type_id");
String eventTitle = request.getParameter("event_title");
String eventDate = request.getParameter("event_date");
String eventTime = request.getParameter("event_time");
String location = request.getParameter("location");
String guestCountValue = request.getParameter("guest_count");
String budgetValue = request.getParameter("budget");
String requirements = request.getParameter("requirements");
String additionalNotes = request.getParameter("additional_notes");

/* =====================================================
   VALIDATION
   ===================================================== */
if (eventTypeValue == null || eventTitle == null || eventDate == null ||
    location == null || guestCountValue == null ||
    eventTitle.trim().isEmpty() || location.trim().isEmpty()) {
    response.sendRedirect("requestEvent.jsp?error=missing_fields");
    return;
}

int eventTypeId;
int guestCount;
double budget = 0.0;

try {
    eventTypeId = Integer.parseInt(eventTypeValue.trim());
    guestCount = Integer.parseInt(guestCountValue.trim());
    if (guestCount <= 0) guestCount = 1;

    if (budgetValue != null && !budgetValue.trim().isEmpty()) {
        budget = Double.parseDouble(budgetValue.trim());
        if (budget < 0) budget = 0.0;
    }
} catch (Exception e) {
    response.sendRedirect("requestEvent.jsp?error=invalid_numbers");
    return;
}

Connection conn = null;
PreparedStatement ps = null;

try {
    conn = DBConnection.getConnection();

    String sql =
        "INSERT INTO event_requests " +
        "(user_id, event_type_id, event_title, event_date, event_time, location, " +
        "guest_count, budget, requirements, additional_notes, status) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending')";

    ps = conn.prepareStatement(sql);
    ps.setInt(1, userId);
    ps.setInt(2, eventTypeId);
    ps.setString(3, eventTitle.trim());
    ps.setDate(4, java.sql.Date.valueOf(eventDate.trim()));

    if (eventTime == null || eventTime.trim().isEmpty()) {
        ps.setNull(5, Types.TIME);
    } else {
        String t = eventTime.trim();
        if (t.length() == 5) t = t + ":00";
        ps.setTime(5, java.sql.Time.valueOf(t));
    }

    ps.setString(6, location.trim());
    ps.setInt(7, guestCount);
    ps.setDouble(8, budget);
    ps.setString(9, requirements != null ? requirements.trim() : "");
    ps.setString(10, additionalNotes != null ? additionalNotes.trim() : "");

    int result = ps.executeUpdate();

    if (result > 0) {
        // Notifications (Phase 7)
        try {
            NotificationDAO.createNotification(conn, userId, "🎪 Custom Event Request Posted", 
                "Your request for '" + eventTitle + "' was posted successfully. Organizers will review and submit quotations.", 
                "proposal", "myRequests.jsp");

            Statement orgSt = conn.createStatement();
            ResultSet orgRs = orgSt.executeQuery("SELECT id FROM users WHERE role='Organizer'");
            while (orgRs.next()) {
                int orgId = orgRs.getInt("id");
                NotificationDAO.createNotification(conn, orgId, "🎪 New Custom Event Request", 
                    "A customer posted a custom request for '" + eventTitle + "' (Budget: ₹" + budget + "). Review and submit a quotation!", 
                    "proposal", "incomingRequests.jsp");
            }
            orgRs.close();
            orgSt.close();
        } catch (Exception ignored) {}

        response.sendRedirect("myRequests.jsp?msg=created");
        return;
    } else {
        response.sendRedirect("requestEvent.jsp?error=failed");
        return;
    }

} catch (Exception e) {
    out.println("<h2 style='color:red;'>Error Submitting Request</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
    out.println("<a href='requestEvent.jsp'>Back to Request Form</a>");
} finally {
    DBConnection.close(ps, conn);
}
%>