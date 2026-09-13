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

    if (name == null || uname == null || pass == null || mail == null
            || name.trim().isEmpty() || uname.trim().isEmpty() || pass.trim().isEmpty()) {
        response.sendRedirect("adminregister.jsp?msg=All fields are required");
        return;
    }
    if (!pass.equals(cpass)) {
        response.sendRedirect("adminregister.jsp?msg=Passwords do not match");
        return;
    }

    try (Connection con = DbConnector.getConnection()) {
        PreparedStatement ps = con.prepareStatement(
            "INSERT INTO admins (username, password, name, email, status) VALUES (?, ?, ?, ?, 'pending')");
        ps.setString(1, uname);
        ps.setString(2, pass);
        ps.setString(3, name);
        ps.setString(4, mail);
        ps.executeUpdate();
        response.sendRedirect("adminlogin.jsp?msg=Registered! Wait for the main admin to approve your account.");
    } catch (Exception e) {
        response.sendRedirect("adminregister.jsp?msg=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>
