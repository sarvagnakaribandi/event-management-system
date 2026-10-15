<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>
<%@ page import="database.NotificationDAO" %>

<%
/* =====================================================
   SUBMIT / EDIT EVENT REVIEW (PHASE 10)
   Verified attendee ratings & feedback submission handler
   ===================================================== */
boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"))
    || (request.getParameter("format") != null && "json".equalsIgnoreCase(request.getParameter("format")));

if (!isAjax) {
    response.setContentType("text/html; charset=UTF-8");
}

if (session.getAttribute("userId") == null) {
    if (isAjax) {
        out.print("{\"success\": false, \"message\": \"Please log in to submit a review.\"}");
    } else {
        response.sendRedirect("login.jsp");
    }
    return;
}

int sessionUserId = Integer.parseInt(session.getAttribute("userId").toString());
String userName = session.getAttribute("userName") != null ? session.getAttribute("userName").toString() : "Attendee";

String eventIdParam = request.getParameter("event_id");
String ratingParam = request.getParameter("rating");
String reviewTitle = request.getParameter("review_title");
String reviewText = request.getParameter("review_text");
String returnUrl = request.getParameter("return_url");

if (eventIdParam == null || eventIdParam.trim().isEmpty() ||
    ratingParam == null || ratingParam.trim().isEmpty() ||
    reviewText == null || reviewText.trim().isEmpty()) {
    if (isAjax) {
        out.print("{\"success\": false, \"message\": \"Please provide a rating and review comments.\"}");
    } else {
        response.sendRedirect("eventDetails.jsp?id=" + eventIdParam + "&error=missing_fields");
    }
    return;
}

int eventId;
int rating;
try {
    eventId = Integer.parseInt(eventIdParam.trim());
    rating = Integer.parseInt(ratingParam.trim());
    if (rating < 1 || rating > 5) {
        throw new IllegalArgumentException("Rating must be between 1 and 5");
    }
} catch (Exception e) {
    if (isAjax) {
        out.print("{\"success\": false, \"message\": \"Invalid event ID or rating range (1-5).\"}");
    } else {
        response.sendRedirect("eventDetails.jsp?id=" + eventIdParam + "&error=invalid_rating");
    }
    return;
}

if (reviewTitle == null || reviewTitle.trim().isEmpty()) {
    reviewTitle = rating >= 4 ? "Great Experience!" : (rating == 3 ? "Average Experience" : "Needs Improvement");
}
reviewTitle = reviewTitle.trim();
reviewText = reviewText.trim();

Connection conn = null;
PreparedStatement psCheck = null;
PreparedStatement psUpsert = null;
PreparedStatement psEvent = null;
ResultSet rsCheck = null;
ResultSet rsEvent = null;

try {
    conn = DBConnection.getConnection();

    // Verification Guard: Only registered attendees with confirmed/free status can submit reviews
    String checkSql =
        "SELECT registration_id, check_in_status FROM registrations " +
        "WHERE user_id = ? AND event_id = ? AND payment_status IN ('Approved', 'Not Required') " +
        "ORDER BY registration_id DESC LIMIT 1";

    psCheck = conn.prepareStatement(checkSql);
    psCheck.setInt(1, sessionUserId);
    psCheck.setInt(2, eventId);
    rsCheck = psCheck.executeQuery();

    if (!rsCheck.next()) {
        if (isAjax) {
            out.print("{\"success\": false, \"message\": \"Only verified registered attendees can submit reviews for this event.\"}");
        } else {
            response.sendRedirect("eventDetails.jsp?id=" + eventId + "&error=not_registered_attendee");
        }
        return;
    }

    int registrationId = rsCheck.getInt("registration_id");

    // Upsert review (allows attendees to edit their review)
    String upsertSql =
        "INSERT INTO event_reviews (event_id, user_id, registration_id, rating, review_title, review_text) " +
        "VALUES (?, ?, ?, ?, ?, ?) " +
        "ON DUPLICATE KEY UPDATE " +
        "rating = VALUES(rating), " +
        "review_title = VALUES(review_title), " +
        "review_text = VALUES(review_text), " +
        "registration_id = VALUES(registration_id), " +
        "updated_at = CURRENT_TIMESTAMP";

    psUpsert = conn.prepareStatement(upsertSql);
    psUpsert.setInt(1, eventId);
    psUpsert.setInt(2, sessionUserId);
    psUpsert.setInt(3, registrationId);
    psUpsert.setInt(4, rating);
    psUpsert.setString(5, reviewTitle);
    psUpsert.setString(6, reviewText);
    int affected = psUpsert.executeUpdate();

    // Fetch organizer info to dispatch notification
    String eventSql = "SELECT organizer_id, event_name FROM events WHERE event_id = ?";
    psEvent = conn.prepareStatement(eventSql);
    psEvent.setInt(1, eventId);
    rsEvent = psEvent.executeQuery();

    if (rsEvent.next()) {
        int organizerId = rsEvent.getInt("organizer_id");
        String eventName = rsEvent.getString("event_name");
        try {
            NotificationDAO.createNotification(
                conn,
                organizerId,
                "⭐ New Attendee Review (" + rating + "★)",
                userName + " left a " + rating + "-star review for '" + eventName + "': \"" + (reviewTitle.length() > 30 ? reviewTitle.substring(0, 30) + "..." : reviewTitle) + "\"",
                "event",
                "eventDetails.jsp?id=" + eventId + "#reviews"
            );
        } catch (Exception ignored) {}
    }

    if (isAjax) {
        out.print("{\"success\": true, \"message\": \"Your verified review has been posted successfully!\", \"rating\": " + rating + "}");
    } else {
        String target = (returnUrl != null && !returnUrl.trim().isEmpty()) ? returnUrl : ("eventDetails.jsp?id=" + eventId);
        if (target.contains("?")) {
            target += "&msg=review_success#reviews";
        } else {
            target += "?msg=review_success#reviews";
        }
        response.sendRedirect(target);
    }

} catch (Exception e) {
    e.printStackTrace();
    if (isAjax) {
        out.print("{\"success\": false, \"message\": \"Failed to save review: " + SecurityUtil.escapeHtml(e.getMessage()) + "\"}");
    } else {
        response.sendRedirect("eventDetails.jsp?id=" + eventId + "&error=" + SecurityUtil.escapeHtml(e.getMessage()));
    }
} finally {
    if (rsEvent != null) try { rsEvent.close(); } catch (Exception ignored) {}
    if (psEvent != null) try { psEvent.close(); } catch (Exception ignored) {}
    if (rsCheck != null) try { rsCheck.close(); } catch (Exception ignored) {}
    if (psCheck != null) try { psCheck.close(); } catch (Exception ignored) {}
    if (psUpsert != null) try { psUpsert.close(); } catch (Exception ignored) {}
    if (conn != null) try { conn.close(); } catch (Exception ignored) {}
}
%>
