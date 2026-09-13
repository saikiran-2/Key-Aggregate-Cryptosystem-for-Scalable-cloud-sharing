<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pack.DbConnector"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%
    if (session.getAttribute("ADMIN") == null) {
        response.sendRedirect("adminlogin.jsp?msg=Please log in first");
        return;
    }
    String q = request.getParameter("q");
    if (q == null) q = "";
%>
<!DOCTYPE html>
<html>
<head><title>Registered Users</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar">
  <a href="adminpage.jsp">Upload</a><a href="FileD.jsp">My Files</a><a href="UserD.jsp">Users</a>
  <% if ("yes".equals(session.getAttribute("ISSUPER"))) { %><a href="approveadmins.jsp">Approvals</a><% } %>
  <a href="logout.jsp">Logout</a>
</div>
<div class="container">
  <h1 class="step">Registered Users</h1>
  <form method="get" style="display:flex;gap:8px">
    <input type="text" name="q" placeholder="Search by name or username" value="<%= q %>" style="flex:1">
    <input type="submit" value="Search">
  </form>
  <table>
    <tr><th>Username</th><th>Name</th><th>Email</th><th>Phone</th></tr>
    <%
        try (Connection con = DbConnector.getConnection()) {
            PreparedStatement ps = con.prepareStatement("SELECT username, name, email, phone FROM users WHERE username LIKE ? OR name LIKE ?");
            ps.setString(1, "%" + q + "%");
            ps.setString(2, "%" + q + "%");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
    %>
    <tr>
        <td><%= rs.getString("username") %></td>
        <td><%= rs.getString("name") %></td>
        <td><%= rs.getString("email") %></td>
        <td><%= rs.getString("phone") %></td>
    </tr>
    <% } } catch (Exception e) { %>
      <tr><td colspan="4">Error loading users: <%= e.getMessage() %></td></tr>
    <% } %>
  </table>
</div>
</body>
</html>
