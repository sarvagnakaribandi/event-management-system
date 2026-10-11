<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
String email = request.getParameter("email");
String password = request.getParameter("password");

if(email == null || email.trim().isEmpty() || password == null || password.trim().isEmpty()){
    out.println("<script>alert('Please provide both email and password.'); history.back();</script>");
    return;
}

email = email.trim();

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = DBConnection.getConnection();
    if(conn == null){
        out.println("<script>alert('Database connection error. Please try again.'); history.back();</script>");
        return;
    }

    String sql = "SELECT * FROM users WHERE email=?";
    ps = conn.prepareStatement(sql);
    ps.setString(1, email);

    rs = ps.executeQuery();

    if(rs.next()){
        String storedPassword = rs.getString("password");

        if(SecurityUtil.verifyPassword(password, storedPassword)){
            String role = rs.getString("role");
            int userId = rs.getInt("id");
            String fullName = rs.getString("full_name");

            session.setAttribute("userId", userId);
            session.setAttribute("userName", fullName);
            session.setAttribute("email", email);
            session.setAttribute("role", role);

            // If stored password was legacy plaintext, automatically upgrade it to hashed
            if(storedPassword.equals(password) && !storedPassword.equals(SecurityUtil.hashPassword(password))){
                try {
                    PreparedStatement upgradePs = conn.prepareStatement("UPDATE users SET password=? WHERE id=?");
                    upgradePs.setString(1, SecurityUtil.hashPassword(password));
                    upgradePs.setInt(2, userId);
                    upgradePs.executeUpdate();
                    upgradePs.close();
                } catch(Exception ignored){}
            }

            if("Admin".equalsIgnoreCase(role)){
                response.sendRedirect("adminDashboard.jsp");
            } else if("Organizer".equalsIgnoreCase(role)){
                response.sendRedirect("organizerDashboard.jsp");
            } else {
                response.sendRedirect("userDashboard.jsp");
            }
            return;
        }
    }

    out.println("<script>alert('Invalid Email or Password.'); history.back();</script>");

} catch(Exception e) {
    out.println("<h3 style='color:red;'>Login Error: " + SecurityUtil.escapeHtml(e.getMessage()) + "</h3>");
} finally {
    DBConnection.close(conn, ps, rs);
}
%>