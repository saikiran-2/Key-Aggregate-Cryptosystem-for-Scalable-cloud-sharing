package cloud;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pack.DbConnector;

/**
 * Verifies the logged-in user's aggregate key actually covers the requested
 * file, fetches the ciphertext from Dropbox, decrypts it, and streams it
 * back as a normal browser download.
 */
@WebServlet("/DownloadServlet")
public class DownloadServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        String username = session == null ? null : (String) session.getAttribute("UNAME");
        if (username == null) {
            response.sendRedirect("userlogin.jsp?msg=Please log in first");
            return;
        }

        String fileIdParam = request.getParameter("fileId");
        String aggkey = request.getParameter("aggkey");
        if (fileIdParam == null || aggkey == null) {
            response.sendRedirect("userpage.jsp?err=Missing file or key");
            return;
        }
        int fileId;
        try {
            fileId = Integer.parseInt(fileIdParam);
        } catch (NumberFormatException e) {
            response.sendRedirect("userpage.jsp?err=Invalid file reference");
            return;
        }
        aggkey = aggkey.trim();

        String storagePath = null, publicKey = null, originalName = null;
        try (Connection con = DbConnector.getConnection()) {
            String sql = "SELECT f.storage_path, f.public_key, f.original_name FROM share_batches b "
                    + "JOIN share_batch_files sbf ON sbf.batch_id = b.id "
                    + "JOIN uploaded_files f ON f.id = sbf.file_id "
                    + "WHERE b.username = ? AND b.agg_key = ? AND f.id = ?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, username);
            ps.setString(2, aggkey);
            ps.setInt(3, fileId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                storagePath = rs.getString("storage_path");
                publicKey = rs.getString("public_key");
                originalName = rs.getString("original_name");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (storagePath == null) {
            response.sendRedirect("userpage.jsp?err=This key does not grant access to that file");
            return;
        }

        byte[] encryptedBytes;
        try {
            encryptedBytes = DropboxClient.download(storagePath);
        } catch (IOException e) {
            e.printStackTrace();
            response.sendRedirect("userpage.jsp?err=" + java.net.URLEncoder.encode("Dropbox download failed: " + e.getMessage(), "UTF-8"));
            return;
        }

        response.setContentType("application/octet-stream");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + originalName + "\"");

        try (ByteArrayInputStream bais = new ByteArrayInputStream(encryptedBytes);
             OutputStream os = response.getOutputStream()) {
            CipherExample1.decrypt(publicKey, bais, os);
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }
}
