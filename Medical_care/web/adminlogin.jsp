<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head><title>Admin Login</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar"><a href="index.jsp">Home</a><a href="userlogin.jsp">User Login</a><a href="regpage.jsp">Register</a></div>
<div class="container">
  <h1 class="step">Admin Login</h1>
  <p style="color:#888;font-size:13px">For any provider who uploads and shares files - a doctor, teacher, or staff member.</p>
  <% if (request.getParameter("msg") != null) { %><div class="msg-err"><%= request.getParameter("msg") %></div><% } %>
  <form action="adminaction.jsp" method="post">
    <label>Username</label><input type="text" name="user" required>
    <label>Password</label><input type="password" name="pass" required>
    <input type="submit" value="Login">
  </form>
  <p style="margin-top:16px">New here? <a href="adminregister.jsp">Register as an admin</a> (needs main admin approval first).</p>
</div>
</body>
</html>
