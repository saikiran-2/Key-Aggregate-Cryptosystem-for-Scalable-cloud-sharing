<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pack.DbConnector"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%
    String uname = request.getParameter("user");
    String pass = request.getParameter("pass");

    try (Connection con = DbConnector.getConnection()) {
        PreparedStatement ps = con.prepareStatement("SELECT password, status FROM users WHERE username = ?");
        ps.setString(1, uname);
        ResultSet rs = ps.executeQuery();
        if (rs.next() && rs.getString("password").equals(pass) && "active".equalsIgnoreCase(rs.getString("status"))) {
            session.setAttribute("UNAME", uname);
            response.sendRedirect("userpage.jsp");
        } else {
            response.sendRedirect("userlogin.jsp?msg=Invalid username or password");
        }
    } catch (Exception e) {
        response.sendRedirect("userlogin.jsp?msg=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>
