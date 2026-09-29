<%@ page import="java.sql.*" %>

<%
String email = request.getParameter("email");
String password = request.getParameter("password");

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try{

    Class.forName("com.mysql.cj.jdbc.Driver");

    conn = DriverManager.getConnection(
        "jdbc:mysql://localhost:3306/eventsphere",
        "root",
        ""
    );

    String sql = "SELECT * FROM users WHERE email=? AND password=?";

    ps = conn.prepareStatement(sql);

    ps.setString(1,email);
    ps.setString(2,password);

    rs = ps.executeQuery();

    if(rs.next()){

        String role = rs.getString("role");

        session.setAttribute("userName", rs.getString("full_name"));
        session.setAttribute("userId", rs.getInt("id"));
        session.setAttribute("role", role);

        if(role.equals("Organizer")){

            response.sendRedirect("organizerDashboard.jsp");

        }else{

            response.sendRedirect("userDashboard.jsp");

        }

    }else{

        out.println("<script>");
        out.println("alert('Invalid Email or Password');");
        out.println("history.back();");
        out.println("</script>");

    }

}catch(Exception e){

    out.println(e);

}
%>