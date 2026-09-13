<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pack.DbConnector"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%
    if (!"yes".equals(session.getAttribute("ISSUPER"))) {
        response.sendRedirect("adminlogin.jsp?msg=Only the main admin can approve other admins");
        return;
    }
    String q = request.getParameter("q");
    if (q == null) q = "";
%>
<!DOCTYPE html>
<html>
<head><title>Admin Approvals</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar">
  <a href="adminpage.jsp">Upload</a><a href="FileD.jsp">My Files</a><a href="UserD.jsp">Users</a>
  <a href="approveadmins.jsp">Approvals</a><a href="logout.jsp">Logout</a>
</div>
<div class="container">
  <h1 class="step">Approve or Reject Admin Accounts</h1>
  <% if (request.getParameter("msg") != null) { %><div class="msg-ok"><%= request.getParameter("msg") %></div><% } %>
  <form method="get" style="display:flex;gap:8px">
    <input type="text" name="q" placeholder="Search by name or username" value="<%= q %>" style="flex:1">
    <input type="submit" value="Search">
  </form>
  <table>
    <tr><th>Username</th><th>Name</th><th>Email</th><th>Status</th><th>Action</th></tr>
    <%
        try (Connection con = DbConnector.getConnection()) {
            PreparedStatement ps = con.prepareStatement(
                "SELECT id, username, name, email, status FROM admins WHERE username LIKE ? OR name LIKE ? ORDER BY status, id DESC");
            ps.setString(1, "%" + q + "%");
            ps.setString(2, "%" + q + "%");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
    %>
    <tr>
        <td><%= rs.getString("username") %></td>
        <td><%= rs.getString("name") %></td>
        <td><%= rs.getString("email") %></td>
        <td><%= rs.getString("status") %></td>
        <td>
          <a href="approveaction.jsp?id=<%= rs.getInt("id") %>&action=approve">Approve</a> |
          <a href="approveaction.jsp?id=<%= rs.getInt("id") %>&action=reject">Reject</a>
        </td>
    </tr>
    <% } } catch (Exception e) { %>
      <tr><td colspan="5">Error: <%= e.getMessage() %></td></tr>
    <% } %>
  </table>
</div>
</body>
</html>
