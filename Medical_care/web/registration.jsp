<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pack.DbConnector"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%
    String name = request.getParameter("name");
    String uname = request.getParameter("username");
    String pass = request.getParameter("password");
    String cpass = request.getParameter("cpassword");
    String mail = request.getParameter("mail");
    String ph = request.getParameter("mobile");

    if (name == null || uname == null || pass == null || mail == null || ph == null
            || name.trim().isEmpty() || uname.trim().isEmpty() || pass.trim().isEmpty()) {
        response.sendRedirect("regpage.jsp?msg=All fields are required");
        return;
    }
    if (!pass.equals(cpass)) {
        response.sendRedirect("regpage.jsp?msg=Passwords do not match");
        return;
    }

    try (Connection con = DbConnector.getConnection()) {
        PreparedStatement ps = con.prepareStatement(
            "INSERT INTO users (username, name, password, email, phone, status) VALUES (?, ?, ?, ?, ?, 'active')");
        ps.setString(1, uname);
        ps.setString(2, name);
        ps.setString(3, pass);
        ps.setString(4, mail);
        ps.setString(5, ph);
        int i = ps.executeUpdate();
        if (i != 0) {
            response.sendRedirect("userlogin.jsp?msg=Registered successfully, please log in");
        } else {
            response.sendRedirect("regpage.jsp?msg=Registration failed");
        }
    } catch (Exception e) {
        response.sendRedirect("regpage.jsp?msg=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>
