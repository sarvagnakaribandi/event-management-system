<%@ page import="java.sql.*"%>

<%
Connection conn=null;
PreparedStatement ps=null;
ResultSet rs=null;

Class.forName("com.mysql.cj.jdbc.Driver");

conn=DriverManager.getConnection(
"jdbc:mysql://localhost:3306/eventsphere",
"root",
"");

String sql="SELECT * FROM events";

ps=conn.prepareStatement(sql);

rs=ps.executeQuery();
%>

<!DOCTYPE html>

<html>

<head>

<title>Manage Events</title>

<link rel="stylesheet" href="css/manageEvents.css">

</head>

<body>

<h1>Manage Events</h1>

<table>

<tr>

<th>Image</th>

<th>Event</th>

<th>Date</th>

<th>Venue</th>

<th>Edit</th>

<th>Delete</th>

</tr>

<%
while(rs.next()){
%>

<tr>

<td>

<img src="images/<%=rs.getString("banner_image")%>" width="120">

</td>

<td>

<%=rs.getString("event_name")%>

</td>

<td>

<%=rs.getDate("event_date")%>

</td>

<td>

<%=rs.getString("venue")%>

</td>

<td>

<a href="editEvent.jsp?id=<%=rs.getInt("event_id")%>">

Edit

</a>

</td>

<td>

<a href="deleteEvent.jsp?id=<%=rs.getInt("event_id")%>">

Delete

</a>

</td>

</tr>

<%
}
%>

</table>

</body>

</html>