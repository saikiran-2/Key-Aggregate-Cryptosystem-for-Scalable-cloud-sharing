<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pack.DbConnector"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%
    if (!"yes".equals(session.getAttribute("ISSUPER"))) {
        response.sendRedirect("adminlogin.jsp?msg=Only the main admin can approve other admins");
        return;
    }
    int id = Integer.parseInt(request.getParameter("id"));
    String action = request.getParameter("action");
    String status = "approve".equals(action) ? "approved" : "rejected";

    try (Connection con = DbConnector.getConnection()) {
        PreparedStatement ps = con.prepareStatement("UPDATE admins SET status = ? WHERE id = ?");
        ps.setString(1, status);
        ps.setInt(2, id);
        ps.executeUpdate();
        response.sendRedirect("approveadmins.jsp?msg=Updated");
    } catch (Exception e) {
        response.sendRedirect("approveadmins.jsp?msg=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>
