<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head><title>Key-Aggregate Cryptosystem</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar">
  <a href="index.jsp">Home</a>
  <a href="adminlogin.jsp">Admin</a>
  <a href="userlogin.jsp">User Login</a>
  <a href="regpage.jsp">Register</a>
</div>
<div class="container">
  <h1 class="step">Key-Aggregate Cryptosystem for Scalable Data Sharing in Cloud Storage</h1>
  <p>This is a simulation of a key-aggregate encryption scheme for sharing files:</p>
  <ol>
    <li><b>Register</b> as a user.</li>
    <li><b>Admin</b> uploads a file, encrypting it with a chosen public key.</li>
    <li><b>Admin</b> shares the file with a registered user, generating an aggregate key.</li>
    <li><b>User</b> enters the file name, public key, and aggregate key to decrypt and download the file.</li>
  </ol>
</div>
</body>
</html>
