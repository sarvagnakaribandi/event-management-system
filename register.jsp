<%@ page import="java.sql.*" %>

<%

String fullName = request.getParameter("full_name");
String email = request.getParameter("email");
String password = request.getParameter("password");
String confirmPassword = request.getParameter("confirm_password");
String role = request.getParameter("role");

if(!password.equals(confirmPassword)){
    out.println("<script>");
    out.println("alert('Passwords do not match!');");
    out.println("history.back();");
    out.println("</script>");
    return;
}

Connection conn = null;
PreparedStatement ps = null;

try{

    Class.forName("com.mysql.cj.jdbc.Driver");

    conn = DriverManager.getConnection(
        "jdbc:mysql://localhost:3306/eventsphere",
        "root",
        ""
    );

    String sql = "INSERT INTO users(full_name,email,password,role) VALUES(?,?,?,?)";

    ps = conn.prepareStatement(sql);

    ps.setString(1, fullName);
    ps.setString(2, email);
    ps.setString(3, password);
    ps.setString(4, role);

    int result = ps.executeUpdate();

    if(result>0){

        response.sendRedirect("login.jsp");

    }else{

        out.println("Registration Failed");

    }

}catch(Exception e){

    out.println(e);

}

finally{

    if(ps!=null) ps.close();

    if(conn!=null) conn.close();

}

%>