<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("ADMIN") == null) {
        response.sendRedirect("adminlogin.jsp?msg=Please log in first");
        return;
    }
    String me = (String) session.getAttribute("ADMIN");
%>
<!DOCTYPE html>
<html>
<head><title>Admin - Upload</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar">
  <a href="adminpage.jsp">Upload</a>
  <a href="FileD.jsp">My Files</a>
  <a href="UserD.jsp">Users</a>
  <% if ("yes".equals(session.getAttribute("ISSUPER"))) { %><a href="approveadmins.jsp">Approvals</a><% } %>
  <a href="logout.jsp">Logout</a>
</div>
<div class="container">
  <h1 class="step">Step 3: Upload &amp; Encrypt a File</h1>
  <p style="color:#888;font-size:13px">Logged in as <b><%= me %></b><%= "yes".equals(session.getAttribute("ISSUPER")) ? " (main admin)" : "" %></p>
  <% if (request.getParameter("msg") != null) { %><div class="msg-ok"><%= request.getParameter("msg") %></div><% } %>
  <% if (request.getParameter("err") != null) { %><div class="msg-err"><%= request.getParameter("err") %></div><% } %>
  <form action="UploadServlet" method="post" enctype="multipart/form-data">
    <label>Public Key (8+ characters - this is the encryption key)</label>
    <input type="text" name="publickey" minlength="8" required>
    <label>File to Upload</label>
    <input type="file" name="file" required>
    <input type="submit" value="Encrypt & Upload">
  </form>
</div>
</body>
</html>
