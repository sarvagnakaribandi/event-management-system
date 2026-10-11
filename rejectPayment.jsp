<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*" %>

<%
if(session.getAttribute("userId") == null){

    response.sendRedirect("login.jsp");
    return;
}


String role =
    (String) session.getAttribute("role");


if(role == null ||
   !"Organizer".equalsIgnoreCase(role)){

    response.sendRedirect("login.jsp");
    return;
}


int organizerId =
    Integer.parseInt(
        session.getAttribute("userId").toString()
    );


String registrationParam =
    request.getParameter("id");

String eventParam =
    request.getParameter("event_id");


if(registrationParam == null ||
   eventParam == null){

    response.sendRedirect(
        request.getContextPath()
        + "/manageEvents.jsp"
    );

    return;
}


int registrationId;

int eventId;


try{

    registrationId =
        Integer.parseInt(
            registrationParam
        );

    eventId =
        Integer.parseInt(
            eventParam
        );

}
catch(NumberFormatException e){

    response.sendRedirect(
        request.getContextPath()
        + "/manageEvents.jsp"
    );

    return;
}


Connection conn = null;
PreparedStatement ps = null;


try{

    Class.forName(
        "com.mysql.cj.jdbc.Driver"
    );


    conn =
        DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/eventsphere",
            "root",
            ""
        );


    String sql =

        "UPDATE registrations r " +

        "INNER JOIN events e " +
        "ON r.event_id = e.event_id " +

        "SET r.payment_status = 'Rejected' " +

        "WHERE r.registration_id = ? " +

        "AND r.event_id = ? " +

        "AND e.organizer_id = ?";


    ps =
        conn.prepareStatement(sql);


    ps.setInt(
        1,
        registrationId
    );


    ps.setInt(
        2,
        eventId
    );


    ps.setInt(
        3,
        organizerId
    );


    int result =
        ps.executeUpdate();


    if(result > 0){

        response.sendRedirect(
    request.getContextPath()
    + "/viewParticipants.jsp?id="
    + eventId
);
        return;
    }


%>

<h2>
    Unable to reject payment.
</h2>

<a href="<%=request.getContextPath()%>/viewParticipants.jsp?id=<%=eventId%>">

    Back to Participants

</a>

<%

}
catch(Exception e){

%>

<h2 style="color:red;">
    Error rejecting payment
</h2>

<p>
    <%=e.getMessage()%>
</p>

<a href="<%=request.getContextPath()%>/viewParticipants.jsp?id=<%=eventId%>">

    Back to Participants

</a>

<%

}
finally{

    try{

        if(ps != null)
            ps.close();

    }
    catch(Exception e){}


    try{

        if(conn != null)
            conn.close();

    }
    catch(Exception e){}

}

%>