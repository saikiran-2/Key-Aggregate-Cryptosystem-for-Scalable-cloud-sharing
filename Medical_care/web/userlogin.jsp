<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head><title>User Login</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar"><a href="index.jsp">Home</a><a href="adminlogin.jsp">Admin</a><a href="regpage.jsp">Register</a></div>
<div class="container">
  <h1 class="step">Step 2: User Login</h1>
  <% if (request.getParameter("msg") != null) { %>
    <div class="msg-ok"><%= request.getParameter("msg") %></div>
  <% } %>
  <form action="loginaction.jsp" method="post">
    <label>Username</label><input type="text" name="user" required>
    <label>Password</label><input type="password" name="pass" required>
    <input type="submit" value="Login">
  </form>
</div>
</body>
</html>
