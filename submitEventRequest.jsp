<%@ page language="java" contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>

<%

if(session.getAttribute("userId") == null){

    response.sendRedirect("login.jsp");

    return;
}


int userId = Integer.parseInt(
    session.getAttribute("userId").toString()
);


/* ================= GET FORM DATA ================= */

String eventTypeValue =
    request.getParameter("event_type_id");

String eventTitle =
    request.getParameter("event_title");

String eventDate =
    request.getParameter("event_date");

String eventTime =
    request.getParameter("event_time");

String location =
    request.getParameter("location");

String guestCountValue =
    request.getParameter("guest_count");

String budgetValue =
    request.getParameter("budget");

String requirements =
    request.getParameter("requirements");

String additionalNotes =
    request.getParameter("additional_notes");


/* ================= VALIDATION ================= */

if(eventTypeValue == null ||
   eventTitle == null ||
   eventDate == null ||
   location == null ||
   guestCountValue == null){

    response.sendRedirect("requestEvent.jsp");

    return;
}


int eventTypeId =
    Integer.parseInt(eventTypeValue);

int guestCount =
    Integer.parseInt(guestCountValue);


double budget = 0;

if(budgetValue != null &&
   !budgetValue.trim().isEmpty()){

    budget =
        Double.parseDouble(budgetValue);

}


/* ================= DATABASE ================= */

Class.forName(
    "com.mysql.cj.jdbc.Driver"
);

Connection conn =
    DriverManager.getConnection(
        "jdbc:mysql://localhost:3306/eventsphere",
        "root",
        ""
);


/* ================= INSERT REQUEST ================= */

PreparedStatement ps =
    conn.prepareStatement(

        "INSERT INTO event_requests " +
        "(user_id, event_type_id, event_title, " +
        "event_date, event_time, location, " +
        "guest_count, budget, requirements, " +
        "additional_notes) " +

        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

    );


ps.setInt(1, userId);

ps.setInt(2, eventTypeId);

ps.setString(3, eventTitle);

ps.setString(4, eventDate);


if(eventTime == null ||
   eventTime.trim().isEmpty()){

    ps.setNull(5, Types.TIME);

}
else{

    ps.setString(5, eventTime);

}


ps.setString(6, location);

ps.setInt(7, guestCount);

ps.setDouble(8, budget);

ps.setString(9, requirements);

ps.setString(10, additionalNotes);


int result =
    ps.executeUpdate();


ps.close();

conn.close();


/* ================= RESULT ================= */

if(result > 0){

    response.sendRedirect(
        "userDashboard.jsp?request=success"
    );

}
else{

    response.sendRedirect(
        "requestEvent.jsp?request=failed"
    );

}

%>