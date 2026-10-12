<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.util.UUID" %>
<%@ page import="database.DBConnection" %>
<%@ page import="database.SecurityUtil" %>

<%
/* =====================================================
   ORGANIZER LOGIN CHECK
   ===================================================== */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) session.getAttribute("role");
if (role == null || !"Organizer".equalsIgnoreCase(role)) {
    response.sendRedirect("login.jsp");
    return;
}

int organizerId = Integer.parseInt(session.getAttribute("userId").toString());

String businessName = request.getParameter("business_name");
String contactPhone = request.getParameter("contact_phone");
String businessAddress = request.getParameter("business_address");
String expStr = request.getParameter("experience_years");
String organizerDesc = request.getParameter("organizer_description");
String servicesDesc = request.getParameter("services_description");

String qrData = request.getParameter("qr_data");
String qrName = request.getParameter("qr_name");
String idData = request.getParameter("id_data");
String idName = request.getParameter("id_name");

int experienceYears = 0;
if (expStr != null && !expStr.trim().isEmpty()) {
    try {
        experienceYears = Integer.parseInt(expStr.trim());
    } catch (Exception ignored) {}
}

String savedQrImage = null;
String savedIdDoc = null;
boolean newDocUploaded = false;

String uploadPath = application.getRealPath("/images");
File uploadFolder = new File(uploadPath);
if (!uploadFolder.exists()) {
    uploadFolder.mkdirs();
}

// 1. Process QR image if uploaded
if (qrData != null && !qrData.trim().isEmpty()) {
    try {
        String[] parts = qrData.split(",");
        String base64 = parts.length > 1 ? parts[1] : parts[0];
        byte[] bytes = Base64.getDecoder().decode(base64);

        String ext = ".png";
        if (qrName != null) {
            String lower = qrName.toLowerCase();
            if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) ext = ".jpg";
        }
        savedQrImage = "qr_" + UUID.randomUUID().toString() + ext;
        File qrFile = new File(uploadFolder, savedQrImage);
        try (FileOutputStream fos = new FileOutputStream(qrFile)) {
            fos.write(bytes);
        }
    } catch (Exception ignored) {}
}

// 2. Process ID Document if uploaded
if (idData != null && !idData.trim().isEmpty()) {
    try {
        String[] parts = idData.split(",");
        String base64 = parts.length > 1 ? parts[1] : parts[0];
        byte[] bytes = Base64.getDecoder().decode(base64);

        String ext = ".jpg";
        if (idName != null) {
            String lower = idName.toLowerCase();
            if (lower.endsWith(".png")) ext = ".png";
            else if (lower.endsWith(".jpeg")) ext = ".jpeg";
        }
        savedIdDoc = "doc_" + UUID.randomUUID().toString() + ext;
        File idFile = new File(uploadFolder, savedIdDoc);
        try (FileOutputStream fos = new FileOutputStream(idFile)) {
            fos.write(bytes);
        }
        newDocUploaded = true;
    } catch (Exception ignored) {}
}

Connection conn = null;
PreparedStatement ps = null;

try {
    conn = DBConnection.getConnection();

    // Build dynamic UPDATE query
    StringBuilder sql = new StringBuilder();
    sql.append("UPDATE organizer_profiles SET ");
    sql.append("business_name = ?, ");
    sql.append("contact_phone = ?, ");
    sql.append("business_address = ?, ");
    sql.append("experience_years = ?, ");
    sql.append("organizer_description = ?, ");
    sql.append("services_description = ? ");

    if (savedQrImage != null) {
        sql.append(", qr_image = ? ");
    }
    if (savedIdDoc != null) {
        sql.append(", id_document = ?, verification_status = 'Pending', rejection_reason = NULL ");
    }

    sql.append("WHERE organizer_id = ?");

    ps = conn.prepareStatement(sql.toString());
    int paramIdx = 1;
    ps.setString(paramIdx++, businessName != null ? businessName.trim() : "");
    ps.setString(paramIdx++, contactPhone != null ? contactPhone.trim() : "");
    ps.setString(paramIdx++, businessAddress != null ? businessAddress.trim() : "");
    ps.setInt(paramIdx++, experienceYears);
    ps.setString(paramIdx++, organizerDesc != null ? organizerDesc.trim() : "");
    ps.setString(paramIdx++, servicesDesc != null ? servicesDesc.trim() : "");

    if (savedQrImage != null) {
        ps.setString(paramIdx++, savedQrImage);
    }
    if (savedIdDoc != null) {
        ps.setString(paramIdx++, savedIdDoc);
    }

    ps.setInt(paramIdx++, organizerId);

    int rows = ps.executeUpdate();

    // If no row updated, insert one
    if (rows == 0) {
        String insertSql =
            "INSERT INTO organizer_profiles " +
            "(organizer_id, business_name, contact_phone, business_address, experience_years, " +
            "organizer_description, services_description, qr_image, id_document, verification_status) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement inPs = conn.prepareStatement(insertSql)) {
            inPs.setInt(1, organizerId);
            inPs.setString(2, businessName != null ? businessName.trim() : "");
            inPs.setString(3, contactPhone != null ? contactPhone.trim() : "");
            inPs.setString(4, businessAddress != null ? businessAddress.trim() : "");
            inPs.setInt(5, experienceYears);
            inPs.setString(6, organizerDesc != null ? organizerDesc.trim() : "");
            inPs.setString(7, servicesDesc != null ? servicesDesc.trim() : "");
            inPs.setString(8, savedQrImage);
            inPs.setString(9, savedIdDoc);
            inPs.setString(10, newDocUploaded ? "Pending" : "Not Submitted");
            inPs.executeUpdate();
        }
    }

    response.sendRedirect("organizerProfile.jsp?msg=updated");
    return;

} catch (Exception e) {
    out.println("<h2 style='color:red;'>Error Updating Profile</h2>");
    out.println("<p>" + SecurityUtil.escapeHtml(e.getMessage()) + "</p>");
    out.println("<a href='organizerProfile.jsp'>Back to Profile</a>");
} finally {
    DBConnection.close(ps, conn);
}
%>
