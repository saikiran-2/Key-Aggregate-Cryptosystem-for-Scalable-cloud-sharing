<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head><title>Admin Registration</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar"><a href="index.jsp">Home</a><a href="adminlogin.jsp">Admin Login</a></div>
<div class="container">
  <h1 class="step">Register as an Admin</h1>
  <p style="color:#888;font-size:13px">Your account needs approval from the main admin before you can log in and upload files.</p>
  <% if (request.getParameter("msg") != null) { %><div class="msg-err"><%= request.getParameter("msg") %></div><% } %>
  <form action="adminregistration.jsp" method="post">
    <label>Full Name</label><input type="text" name="name" required>
    <label>Username</label><input type="text" name="username" required>
    <label>Password</label><input type="password" name="password" required>
    <label>Confirm Password</label><input type="password" name="cpassword" required>
    <label>Email</label><input type="email" name="mail" required>
    <input type="submit" value="Register">
  </form>
</div>
</body>
</html>
