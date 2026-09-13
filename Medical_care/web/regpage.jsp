<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head><title>Register</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar"><a href="index.jsp">Home</a><a href="adminlogin.jsp">Admin</a><a href="userlogin.jsp">User Login</a></div>
<div class="container">
  <h1 class="step">Step 1: Register a New User</h1>
  <% if (request.getParameter("msg") != null) { %>
    <div class="msg-err"><%= request.getParameter("msg") %></div>
  <% } %>
  <form action="registration.jsp" method="post">
    <label>Full Name</label><input type="text" name="name" required>
    <label>Username</label><input type="text" name="username" required>
    <label>Password</label><input type="password" name="password" required>
    <label>Confirm Password</label><input type="password" name="cpassword" required>
    <label>Email</label><input type="email" name="mail" required>
    <label>Mobile Number</label><input type="text" name="mobile" required>
    <input type="submit" value="Register">
  </form>
</div>
</body>
</html>
