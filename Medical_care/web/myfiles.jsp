<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pack.DbConnector"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%
    if (session.getAttribute("UNAME") == null) {
        response.sendRedirect("userlogin.jsp?msg=Please log in first");
        return;
    }
    String me = (String) session.getAttribute("UNAME");
    String aggkey = request.getParameter("aggkey");
    if (aggkey == null || aggkey.trim().isEmpty()) {
        response.sendRedirect("userpage.jsp?err=Enter an aggregate key");
        return;
    }
    aggkey = aggkey.trim();
%>
<!DOCTYPE html>
<html>
<head><title>My Shared Files</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar"><a href="userpage.jsp">My Files</a><a href="logout.jsp">Logout</a></div>
<div class="container">
  <h1 class="step">Files Available Under This Key</h1>
  <table>
    <tr><th>File Name</th><th>Uploaded</th><th>Size (bytes)</th><th>Action</th></tr>
    <%
        boolean any = false;
        try (Connection con = DbConnector.getConnection()) {
            PreparedStatement ps = con.prepareStatement(
                "SELECT f.id, f.original_name, f.upload_time, f.file_size FROM share_batches b "
              + "JOIN share_batch_files sbf ON sbf.batch_id = b.id "
              + "JOIN uploaded_files f ON f.id = sbf.file_id "
              + "WHERE b.username = ? AND b.agg_key = ?");
            ps.setString(1, me);
            ps.setString(2, aggkey);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                any = true;
    %>
    <tr>
        <td><%= rs.getString("original_name") %></td>
        <td><%= rs.getString("upload_time") %></td>
        <td><%= rs.getString("file_size") %></td>
        <td><a href="DownloadServlet?fileId=<%= rs.getInt("id") %>&aggkey=<%= java.net.URLEncoder.encode(aggkey, "UTF-8") %>">Download</a></td>
    </tr>
    <% } if (!any) { %>
      <tr><td colspan="4">No files found for that key - check it's correct.</td></tr>
    <% } } catch (Exception e) { %>
      <tr><td colspan="4">Error: <%= e.getMessage() %></td></tr>
    <% } %>
  </table>
</div>
</body>
</html>
