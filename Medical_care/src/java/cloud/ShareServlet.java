package cloud;

import java.io.IOException;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pack.DbConnector;
import pack.mail;

/**
 * Grants a user access to a chosen set of files with ONE aggregate key -
 * the actual "key aggregation" feature. An admin can either issue a brand
 * new key (a new share_batches row) or add more files to a key they
 * already issued that user (reusing an existing share_batches row) -
 * either way, only files the CURRENT admin owns can be attached, so one
 * admin's files never leak into another admin's shares.
 */
@WebServlet("/ShareServlet")
public class ShareServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        String ownerAdmin = session == null ? null : (String) session.getAttribute("ADMIN");
        if (ownerAdmin == null) {
            response.sendRedirect("adminlogin.jsp?msg=Please log in first");
            return;
        }

        String recipient = request.getParameter("username");
        String existingKey = request.getParameter("existingKey");
        String[] fileIdParams = request.getParameterValues("fileIds");

        if (recipient == null || recipient.trim().isEmpty() || fileIdParams == null || fileIdParams.length == 0) {
            response.sendRedirect("FileD.jsp?err=Pick a user and at least one file");
            return;
        }
        recipient = recipient.trim();
        existingKey = existingKey == null ? "" : existingKey.trim();

        try (Connection con = DbConnector.getConnection()) {

            // Confirm the recipient is a real registered user.
            PreparedStatement uck = con.prepareStatement("SELECT 1 FROM users WHERE username = ?");
            uck.setString(1, recipient);
            if (!uck.executeQuery().next()) {
                response.sendRedirect("FileD.jsp?err=No such registered user");
                return;
            }

            int batchId;
            String aggKey;

            if (!existingKey.isEmpty()) {
                // Add to a key this SAME admin already issued to this SAME user.
                PreparedStatement bps = con.prepareStatement(
                        "SELECT id FROM share_batches WHERE username = ? AND agg_key = ? AND owner_admin = ?");
                bps.setString(1, recipient);
                bps.setString(2, existingKey);
                bps.setString(3, ownerAdmin);
                ResultSet brs = bps.executeQuery();
                if (!brs.next()) {
                    response.sendRedirect("FileD.jsp?err=" + java.net.URLEncoder.encode(
                            "That key doesn't exist for this user under your account", "UTF-8"));
                    return;
                }
                batchId = brs.getInt("id");
                aggKey = existingKey;
            } else {
                aggKey = randomKey(10);
                PreparedStatement ins = con.prepareStatement(
                        "INSERT INTO share_batches (username, agg_key, owner_admin, created_time) VALUES (?, ?, ?, NOW())",
                        java.sql.Statement.RETURN_GENERATED_KEYS);
                ins.setString(1, recipient);
                ins.setString(2, aggKey);
                ins.setString(3, ownerAdmin);
                ins.executeUpdate();
                ResultSet keys = ins.getGeneratedKeys();
                keys.next();
                batchId = keys.getInt(1);
            }

            // Attach each selected file - but only if THIS admin actually owns it.
            for (String idStr : fileIdParams) {
                int fileId;
                try { fileId = Integer.parseInt(idStr); } catch (NumberFormatException e) { continue; }

                PreparedStatement own = con.prepareStatement("SELECT 1 FROM uploaded_files WHERE id = ? AND owner_admin = ?");
                own.setInt(1, fileId);
                own.setString(2, ownerAdmin);
                if (!own.executeQuery().next()) {
                    continue; // silently skip files that aren't this admin's
                }

                PreparedStatement link = con.prepareStatement(
                        "INSERT IGNORE INTO share_batch_files (batch_id, file_id) VALUES (?, ?)");
                link.setInt(1, batchId);
                link.setInt(2, fileId);
                link.executeUpdate();
            }

            // Build the confirmation: full current file list under this key + recipient's email.
            List<String> fileNames = new ArrayList<>();
            PreparedStatement list = con.prepareStatement(
                    "SELECT f.original_name FROM share_batch_files sbf "
                            + "JOIN uploaded_files f ON sbf.file_id = f.id WHERE sbf.batch_id = ?");
            list.setInt(1, batchId);
            ResultSet lrs = list.executeQuery();
            while (lrs.next()) fileNames.add(lrs.getString("original_name"));

            String recipientEmail = null;
            PreparedStatement em = con.prepareStatement("SELECT email FROM users WHERE username = ?");
            em.setString(1, recipient);
            ResultSet ers = em.executeQuery();
            if (ers.next()) recipientEmail = ers.getString("email");

            if (recipientEmail != null) {
                try {
                    mail.mailsend(recipientEmail, String.join(", ", fileNames), aggKey);
                } catch (Exception ignore) { }
            }

            request.setAttribute("recipient", recipient);
            request.setAttribute("aggKey", aggKey);
            request.setAttribute("fileNames", fileNames);
            request.getRequestDispatcher("share_result.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("FileD.jsp?err=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
        }
    }

    private String randomKey(int length) {
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        SecureRandom rnd = new SecureRandom();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) sb.append(chars.charAt(rnd.nextInt(chars.length())));
        return sb.toString();
    }
}
