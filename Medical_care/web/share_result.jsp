<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pack.AppConfig"%>
<%@page import="java.util.List"%>
<%
    if (session.getAttribute("ADMIN") == null) {
        response.sendRedirect("adminlogin.jsp?msg=Please log in first");
        return;
    }
    String recipient = (String) request.getAttribute("recipient");
    String aggKey = (String) request.getAttribute("aggKey");
    List<String> fileNames = (List<String>) request.getAttribute("fileNames");
%>
<!DOCTYPE html>
<html>
<head><title>Share Result</title><link rel="stylesheet" href="css/simple.css"></head>
<body>
<div class="topbar">
  <a href="adminpage.jsp">Upload</a><a href="FileD.jsp">My Files</a><a href="UserD.jsp">Users</a>
  <% if ("yes".equals(session.getAttribute("ISSUPER"))) { %><a href="approveadmins.jsp">Approvals</a><% } %>
  <a href="logout.jsp">Logout</a>
</div>
<div class="container">
  <h1 class="step">Step 6: One Key, <%= fileNames.size() %> File<%= fileNames.size() == 1 ? "" : "s" %></h1>
  <div class="msg-ok">
    <%= recipient %> can now access <%= fileNames.size() %> file(s) with this single aggregate key.
    <%= AppConfig.mailEnabled() ? "An email was sent to them." : "Email is off - share this key with them directly:" %>
  </div>
  <div class="key-box">
    Aggregate Key: <b><%= aggKey %></b><br><br>
    Files included:
    <ul>
      <% for (String fn : fileNames) { %><li><%= fn %></li><% } %>
    </ul>
  </div>
  <p style="font-size:13px;color:#888">To grant this same user MORE files later without giving them a new key,
     go back to My Files, check more files, and paste this same key into "Add to existing key".</p>
  <p><a href="FileD.jsp">&larr; Back to My Files</a></p>
</div>
</body>
</html>
