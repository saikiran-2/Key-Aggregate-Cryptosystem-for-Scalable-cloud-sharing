package cloud;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import pack.AppConfig;

/**
 * Minimal Dropbox API v2 client. Talks straight to Dropbox's REST endpoints
 * with HttpURLConnection so no external SDK jar is required.
 *
 * Auth model (current Dropbox policy, changed in 2021 - the original
 * project's DbxWebAuthNoRedirect + long-lived token approach no longer
 * works at all):
 *   - You get ONE refresh token per app, once, via the OAuth authorize flow
 *     (see README "Dropbox setup").
 *   - This class exchanges that refresh token for a short-lived (~4hr)
 *     access token as needed, and caches it until it's close to expiring.
 */
public class DropboxClient {

    private static volatile String cachedAccessToken = null;
    private static volatile long expiresAtMillis = 0L;

    /** Returns a currently-valid access token, refreshing it if needed. */
    private static synchronized String getAccessToken() throws IOException {
        if (cachedAccessToken != null && System.currentTimeMillis() < expiresAtMillis - 60_000) {
            return cachedAccessToken;
        }
        String appKey = AppConfig.dropboxAppKey();
        String appSecret = AppConfig.dropboxAppSecret();
        String refreshToken = AppConfig.dropboxRefreshToken();
        if (appKey.isEmpty() || appSecret.isEmpty() || refreshToken.isEmpty()) {
            throw new IOException("Dropbox is not configured - fill in dropbox.app.key / dropbox.app.secret / "
                    + "dropbox.refresh.token in config.properties (see README).");
        }

        String body = "grant_type=refresh_token&refresh_token=" + refreshToken;
        HttpURLConnection conn = (HttpURLConnection) java.net.URI.create("https://api.dropbox.com/oauth2/token").toURL().openConnection();
        conn.setRequestMethod("POST");
        String basicAuth = Base64.getEncoder().encodeToString((appKey + ":" + appSecret).getBytes(StandardCharsets.UTF_8));
        conn.setRequestProperty("Authorization", "Basic " + basicAuth);
        conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
        conn.setDoOutput(true);
        conn.getOutputStream().write(body.getBytes(StandardCharsets.UTF_8));

        String responseText = readAll(conn.getResponseCode() < 400 ? conn.getInputStream() : conn.getErrorStream());
        if (conn.getResponseCode() >= 400) {
            throw new IOException("Dropbox token refresh failed (" + conn.getResponseCode() + "): " + responseText);
        }

        String accessToken = extractJsonString(responseText, "access_token");
        long expiresIn = extractJsonLong(responseText, "expires_in", 14400L);
        cachedAccessToken = accessToken;
        expiresAtMillis = System.currentTimeMillis() + expiresIn * 1000L;
        return cachedAccessToken;
    }

    /** Uploads raw bytes to the given Dropbox path (e.g. "/keyagg/abc.enc"). */
    public static void upload(String dropboxPath, byte[] data) throws IOException {
        String token = getAccessToken();
        HttpURLConnection conn = (HttpURLConnection) java.net.URI.create("https://content.dropboxapi.com/2/files/upload").toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Authorization", "Bearer " + token);
        conn.setRequestProperty("Dropbox-API-Arg",
                "{\"path\":\"" + dropboxPath + "\",\"mode\":\"add\",\"autorename\":true,\"mute\":false}");
        conn.setRequestProperty("Content-Type", "application/octet-stream");
        conn.setDoOutput(true);
        conn.getOutputStream().write(data);

        if (conn.getResponseCode() >= 400) {
            String err = readAll(conn.getErrorStream());
            throw new IOException("Dropbox upload failed (" + conn.getResponseCode() + "): " + err);
        }
    }

    /** Lists file names directly under the given Dropbox folder path (e.g. "/keyagg"). Useful for diagnostics. */
    public static java.util.List<String> listFolder(String folderPath) throws IOException {
        String token = getAccessToken();
        HttpURLConnection conn = (HttpURLConnection) java.net.URI.create("https://api.dropboxapi.com/2/files/list_folder").toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Authorization", "Bearer " + token);
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);
        conn.getOutputStream().write(("{\"path\":\"" + folderPath + "\"}").getBytes(StandardCharsets.UTF_8));

        int code = conn.getResponseCode();
        String body = readAll(code < 400 ? conn.getInputStream() : conn.getErrorStream());
        if (code >= 400) {
            throw new IOException("Dropbox list_folder failed (" + code + "): " + body);
        }
        java.util.List<String> names = new java.util.ArrayList<>();
        Matcher m = Pattern.compile("\"name\"\\s*:\\s*\"([^\"]+)\"").matcher(body);
        while (m.find()) names.add(m.group(1));
        return names;
    }

    /** Downloads raw bytes from the given Dropbox path. */
    public static byte[] download(String dropboxPath) throws IOException {
        String token = getAccessToken();
        HttpURLConnection conn = (HttpURLConnection) java.net.URI.create("https://content.dropboxapi.com/2/files/download").toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Authorization", "Bearer " + token);
        conn.setRequestProperty("Dropbox-API-Arg", "{\"path\":\"" + dropboxPath + "\"}");

        if (conn.getResponseCode() >= 400) {
            String err = readAll(conn.getErrorStream());
            throw new IOException("Dropbox download failed (" + conn.getResponseCode() + "): " + err);
        }
        try (InputStream in = conn.getInputStream()) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) != -1) {
                baos.write(buf, 0, n);
            }
            return baos.toByteArray();
        }
    }

    private static String readAll(InputStream in) throws IOException {
        if (in == null) return "";
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buf = new byte[4096];
        int n;
        while ((n = in.read(buf)) != -1) baos.write(buf, 0, n);
        return baos.toString(StandardCharsets.UTF_8);
    }

    private static String extractJsonString(String json, String key) throws IOException {
        Matcher m = Pattern.compile("\"" + key + "\"\\s*:\\s*\"([^\"]+)\"").matcher(json);
        if (m.find()) return m.group(1);
        throw new IOException("Dropbox response missing \"" + key + "\": " + json);
    }

    private static long extractJsonLong(String json, String key, long fallback) {
        Matcher m = Pattern.compile("\"" + key + "\"\\s*:\\s*(\\d+)").matcher(json);
        return m.find() ? Long.parseLong(m.group(1)) : fallback;
    }
}
