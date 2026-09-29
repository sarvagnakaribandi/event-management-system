<%@ page import="java.sql.*" %>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>Browse Events</title>

<link rel="stylesheet" href="css/browseEvents.css">

</head>

<body>

<header class="navbar">

<h2>Available Events</h2>

<a href="userDashboard.jsp">Dashboard</a>

</header>

<div class="container">

<%

Connection conn = null;
Statement st = null;
ResultSet rs = null;

try{

Class.forName("com.mysql.cj.jdbc.Driver");

conn = DriverManager.getConnection(
"jdbc:mysql://localhost:3306/eventsphere",
"root",
""
);

st = conn.createStatement();

rs = st.executeQuery("SELECT * FROM events");

while(rs.next()){

%>

<div class="card">

<h2><%= rs.getString("event_name") %></h2>

<p><strong>Date:</strong> <%= rs.getString("event_date") %></p>

<p><strong>Time:</strong> <%= rs.getString("event_time") %></p>

<p><strong>Venue:</strong> <%= rs.getString("venue") %></p>

<p><%= rs.getString("description") %></p>

<a href="registerEvent.jsp?id=<%=rs.getInt("event_id")%>">

<button>Register</button>

</a>

</div>

<%

}

}catch(Exception e){

out.println(e);

}

%>

</div>

</body>
</html>