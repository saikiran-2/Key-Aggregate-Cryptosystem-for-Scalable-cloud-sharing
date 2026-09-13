package cloud;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import pack.AppConfig;
import pack.DbConnector;

/**
 * Browser file upload -> encrypt with the admin's public key -> store the
 * ciphertext in the deployment's own Dropbox account. Replaces the original
 * cloud.Upload, which used an AWT FileDialog (only works with a GUI on the
 * server itself) and the dead Dropbox API v1.
 */
@WebServlet("/UploadServlet")
@MultipartConfig(maxFileSize = 50 * 1024 * 1024) // 50MB cap - Dropbox's simple upload call supports up to 150MB
public class UploadServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        javax.servlet.http.HttpSession session = request.getSession(false);
        String ownerAdmin = session == null ? null : (String) session.getAttribute("ADMIN");
        if (ownerAdmin == null) {
            response.sendRedirect("adminlogin.jsp?msg=Please log in first");
            return;
        }

        String publickey = request.getParameter("publickey");
        Part filePart = request.getPart("file");

        if (publickey == null || publickey.trim().length() < 8 || filePart == null) {
            response.sendRedirect("adminpage.jsp?err=Public key must be 8+ characters and a file is required");
            return;
        }
        publickey = publickey.trim();
        String originalName = extractFileName(filePart);

        ByteArrayOutputStream encrypted = new ByteArrayOutputStream();
        try (InputStream in = filePart.getInputStream()) {
            CipherExample1.encrypt(publickey, in, encrypted);
        } catch (Throwable t) {
            t.printStackTrace();
            response.sendRedirect("adminpage.jsp?err=Encryption failed: " + t.getMessage());
            return;
        }

        String dropboxPath = AppConfig.dropboxFolder() + "/" + java.util.UUID.randomUUID() + ".enc";
        try {
            DropboxClient.upload(dropboxPath, encrypted.toByteArray());
        } catch (IOException e) {
            e.printStackTrace();
            response.sendRedirect("adminpage.jsp?err=" + java.net.URLEncoder.encode("Dropbox upload failed: " + e.getMessage(), "UTF-8"));
            return;
        }

        try (Connection con = DbConnector.getConnection()) {
            String sql = "INSERT INTO uploaded_files (original_name, storage_path, file_size, upload_time, public_key, owner_admin) "
                    + "VALUES (?, ?, ?, NOW(), ?, ?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, originalName);
            ps.setString(2, dropboxPath);
            ps.setLong(3, encrypted.size());
            ps.setString(4, publickey);
            ps.setString(5, ownerAdmin);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("adminpage.jsp?err=Database error saving file record");
            return;
        }

        response.sendRedirect("adminpage.jsp?msg=Uploaded, encrypted, and stored in Dropbox successfully");
    }

    private String extractFileName(Part part) {
        String header = part.getHeader("content-disposition");
        for (String token : header.split(";")) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return "file";
    }
}
