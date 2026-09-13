<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pack.AppConfig"%>
<%@page import="pack.DbConnector"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%
    String user = request.getParameter("user");
    String pass = request.getParameter("pass");

    // The one main admin - configured, not stored in the database.
    if (AppConfig.adminUsername().equals(user) && AppConfig.adminPassword().equals(pass)) {
        session.setAttribute("ADMIN", user);
        session.setAttribute("ISSUPER", "yes");
        response.sendRedirect("adminpage.jsp");
        return;
    }

    // Any other admin - must exist and be approved.
    try (Connection con = DbConnector.getConnection()) {
        PreparedStatement ps = con.prepareStatement("SELECT password, status FROM admins WHERE username = ?");
        ps.setString(1, user);
        ResultSet rs = ps.executeQuery();
        if (rs.next() && rs.getString("password").equals(pass)) {
            String status = rs.getString("status");
            if ("approved".equalsIgnoreCase(status)) {
                session.setAttribute("ADMIN", user);
                response.sendRedirect("adminpage.jsp");
            } else if ("pending".equalsIgnoreCase(status)) {
                response.sendRedirect("adminlogin.jsp?msg=Your account is awaiting approval from the main admin");
            } else {
                response.sendRedirect("adminlogin.jsp?msg=Your registration was not approved");
            }
        } else {
            response.sendRedirect("adminlogin.jsp?msg=Invalid admin credentials");
        }
    } catch (Exception e) {
        response.sendRedirect("adminlogin.jsp?msg=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>
