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
    String me = (String) session.getAttribute("ADMIN");
    String fq = request.getParameter("fq");  // file name search
    String uq = request.getParameter("uq");  // recipient username search
    if (fq == null) fq = "";
    if (uq == null) uq = "";
%>
<!DOCTYPE html>
<html>
<head><title>My Files</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar">
  <a href="adminpage.jsp">Upload</a><a href="FileD.jsp">My Files</a><a href="UserD.jsp">Users</a>
  <% if ("yes".equals(session.getAttribute("ISSUPER"))) { %><a href="approveadmins.jsp">Approvals</a><% } %>
  <a href="logout.jsp">Logout</a>
</div>
<div class="container">
  <h1 class="step">Step 4: Grant Access to Your Files</h1>
  <p style="color:#888;font-size:13px">Logged in as <b><%= me %></b> - you only see and share files you uploaded.</p>
  <% if (request.getParameter("msg") != null) { %><div class="msg-ok"><%= request.getParameter("msg") %></div><% } %>
  <% if (request.getParameter("err") != null) { %><div class="msg-err"><%= request.getParameter("err") %></div><% } %>

  <!-- Both searches are separate top-level GET forms, kept OUTSIDE the -->
  <!-- share form below - nesting <form> inside <form> is invalid HTML -->
  <!-- and silently breaks form submission in every browser. -->
  <form method="get" style="display:flex;gap:8px;margin-top:8px">
    <input type="hidden" name="uq" value="<%= uq %>">
    <input type="text" name="fq" placeholder="Search your files by name" value="<%= fq %>" style="flex:1">
    <input type="submit" value="Search Files">
  </form>

  <form method="get" style="display:flex;gap:8px;margin:8px 0">
    <input type="hidden" name="fq" value="<%= fq %>">
    <input type="text" name="uq" placeholder="Search registered users" value="<%= uq %>" style="flex:1">
    <input type="submit" value="Search Users">
  </form>

  <form action="ShareServlet" method="post">
  <table>
    <tr><th></th><th>File Name</th><th>Uploaded</th><th>Size (bytes)</th></tr>
    <%
        try (Connection con = DbConnector.getConnection()) {
            PreparedStatement ps = con.prepareStatement(
                "SELECT id, original_name, upload_time, file_size FROM uploaded_files "
              + "WHERE owner_admin = ? AND original_name LIKE ? ORDER BY upload_time DESC");
            ps.setString(1, me);
            ps.setString(2, "%" + fq + "%");
            ResultSet rs = ps.executeQuery();
            boolean any = false;
            while (rs.next()) {
                any = true;
    %>
    <tr>
        <td><input type="checkbox" name="fileIds" value="<%= rs.getInt("id") %>"></td>
        <td><%= rs.getString("original_name") %></td>
        <td><%= rs.getString("upload_time") %></td>
        <td><%= rs.getString("file_size") %></td>
    </tr>
    <% } if (!any) { %>
      <tr><td colspan="4" style="color:#888">No files match. Upload one first.</td></tr>
    <% } } catch (Exception e) { %>
      <tr><td colspan="4">Error loading files: <%= e.getMessage() %></td></tr>
    <% } %>
  </table>

  <h1 class="step" style="margin-top:24px">Step 5: Choose the Recipient</h1>

  <label>Share with</label>
  <select name="username" required>
    <%
        try (Connection con = DbConnector.getConnection()) {
            PreparedStatement ps = con.prepareStatement("SELECT username, name FROM users WHERE username LIKE ? OR name LIKE ?");
            ps.setString(1, "%" + uq + "%");
            ps.setString(2, "%" + uq + "%");
            ResultSet rs = ps.executeQuery();
            boolean anyUser = false;
            while (rs.next()) {
                anyUser = true;
    %>
        <option value="<%= rs.getString("username") %>"><%= rs.getString("username") %> - <%= rs.getString("name") %></option>
    <% } if (!anyUser) { %>
        <option disabled>No matching users - register one first</option>
    <% } } catch (Exception e) { %>
        <option disabled>Error loading users</option>
    <% } %>
  </select>

  <label>Add to existing key (optional - leave blank to issue a brand new key)</label>
  <input type="text" name="existingKey" placeholder="e.g. K7QLM2XPQ9">

  <input type="submit" value="Grant Access">
  </form>
</div>
</body>
</html>
