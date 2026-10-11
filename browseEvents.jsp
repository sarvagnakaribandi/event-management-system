<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String search = request.getParameter("search");
String category = request.getParameter("category");
StringBuilder redirectUrl = new StringBuilder("index.jsp#events");
if(category != null && !category.trim().isEmpty()){
    redirectUrl = new StringBuilder("index.jsp?category=" + java.net.URLEncoder.encode(category.trim(), "UTF-8") + "#events");
} else if(search != null && !search.trim().isEmpty()){
    redirectUrl = new StringBuilder("index.jsp?search=" + java.net.URLEncoder.encode(search.trim(), "UTF-8") + "#events");
}
response.sendRedirect(redirectUrl.toString());
%>