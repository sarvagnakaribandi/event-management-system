<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
String fullName = request.getParameter("full_name");
String email = request.getParameter("email");
String password = request.getParameter("password");
String confirmPassword = request.getParameter("confirm_password");
String role = request.getParameter("role");

if(fullName == null || fullName.trim().isEmpty() ||
   email == null || email.trim().isEmpty() ||
   password == null || password.trim().isEmpty()){
    out.println("<script>alert('Please fill in all required fields.'); history.back();</script>");
    return;
}

fullName = fullName.trim();
email = email.trim().toLowerCase();

if(!password.equals(confirmPassword)){
    out.println("<script>alert('Passwords do not match!'); history.back();</script>");
    return;
}

if(password.length() < 6){
    out.println("<script>alert('Password must be at least 6 characters long.'); history.back();</script>");
    return;
}

// Security: Prevent administrative role tampering during public registration
if(!"Organizer".equalsIgnoreCase(role)){
    role = "User";
} else {
    role = "Organizer";
}

Connection conn = null;
PreparedStatement checkPs = null;
PreparedStatement ps = null;
ResultSet rs = null;

try{
    conn = DBConnection.getConnection();
    if(conn == null){
        out.println("<script>alert('Database connection error. Please try again.'); history.back();</script>");
        return;
    }

    // Check duplicate email
    checkPs = conn.prepareStatement("SELECT id FROM users WHERE email=?");
    checkPs.setString(1, email);
    rs = checkPs.executeQuery();
    if(rs.next()){
        out.println("<script>alert('An account with this email already exists. Please log in.'); window.location='login.jsp';</script>");
        return;
    }

    String hashedPassword = SecurityUtil.hashPassword(password);

    String sql = "INSERT INTO users(full_name, email, password, role) VALUES(?,?,?,?)";
    ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
    ps.setString(1, fullName);
    ps.setString(2, email);
    ps.setString(3, hashedPassword);
    ps.setString(4, role);

    int result = ps.executeUpdate();

    if(result > 0){
        ResultSet generatedKeys = ps.getGeneratedKeys();
        if(generatedKeys.next() && "Organizer".equalsIgnoreCase(role)){
            int newOrganizerId = generatedKeys.getInt(1);
            try {
                PreparedStatement profilePs = conn.prepareStatement(
                    "INSERT IGNORE INTO organizer_profiles(organizer_id) VALUES(?)"
                );
                profilePs.setInt(1, newOrganizerId);
                profilePs.executeUpdate();
                profilePs.close();
            } catch(Exception ignored){}
        }

        out.println("<script>alert('Account created successfully! Please log in.'); window.location='login.jsp';</script>");
    }else{
        out.println("<script>alert('Registration failed. Please try again.'); history.back();</script>");
    }

}catch(Exception e){
    out.println("<h3 style='color:red;'>Registration Error: " + SecurityUtil.escapeHtml(e.getMessage()) + "</h3>");
}finally{
    DBConnection.close(rs);
    DBConnection.close(checkPs);
    DBConnection.close(ps);
    DBConnection.close(conn);
}
%>