<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("UNAME") == null) {
        response.sendRedirect("userlogin.jsp?msg=Please log in first");
        return;
    }
    String me = (String) session.getAttribute("UNAME");
%>
<!DOCTYPE html>
<html>
<head><title>My Shared Files</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar"><a href="userpage.jsp">My Files</a><a href="logout.jsp">Logout</a></div>
<div class="container">
  <h1 class="step">Step 7: Enter an Aggregate Key</h1>
  <p>Logged in as: <b><%= me %></b></p>
  <p style="color:#888;font-size:13px">One key unlocks every file it was issued for - you don't need a separate key per file.</p>
  <% if (request.getParameter("err") != null) { %><div class="msg-err"><%= request.getParameter("err") %></div><% } %>
  <form action="myfiles.jsp" method="get">
    <label>Aggregate Key</label>
    <input type="text" name="aggkey" required>
    <input type="submit" value="View My Files">
  </form>
</div>
</body>
</html>
