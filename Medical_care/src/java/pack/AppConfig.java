package pack;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Loads settings from, in order of priority:
 *   1. An environment variable (e.g. DB_PASSWORD) - lets you deploy to any
 *      cloud platform (Render, Railway, an EC2/VPS, Azure App Service, etc.)
 *      without ever committing real credentials to config.properties.
 *   2. config.properties on the classpath (WEB-INF/classes/config.properties)
 *      - used for local development.
 *   3. A hardcoded fallback default.
 */
public class AppConfig {

    private static final Properties props = new Properties();

    static {
        try (InputStream in = AppConfig.class.getClassLoader()
                .getResourceAsStream("config.properties")) {
            if (in != null) {
                props.load(in);
            } else {
                System.err.println("WARNING: config.properties not found on classpath; relying on environment variables / defaults.");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static String get(String key, String defaultValue) {
        String envKey = key.toUpperCase().replace('.', '_');
        String fromEnv = System.getenv(envKey);
        if (fromEnv != null && !fromEnv.isEmpty()) {
            return fromEnv;
        }
        return props.getProperty(key, defaultValue);
    }

    // --- Database ---
    public static String dbUrl()      { return get("db.url", "jdbc:mysql://localhost:3306/"); }
    public static String dbName()     { return get("db.name", "key_agg"); }
    public static String dbUser()     { return get("db.user", "root"); }
    public static String dbPassword() { return get("db.password", "root"); }

    // --- Main admin login (the one super-admin who approves other admins) ---
    public static String adminUsername() { return get("admin.username", "admin"); }
    public static String adminPassword() { return get("admin.password", "admin"); }

    // --- Mail (optional; disabled by default since the old Gmail account/password is dead) ---
    public static boolean mailEnabled()  { return Boolean.parseBoolean(get("mail.enabled", "false")); }
    public static String mailHost()      { return get("mail.host", "smtp.gmail.com"); }
    public static String mailPort()      { return get("mail.port", "587"); }
    public static String mailUsername()  { return get("mail.username", ""); }
    public static String mailPassword()  { return get("mail.password", ""); }

    // --- Dropbox (each deployment uses its own Dropbox app/account) ---
    public static String dropboxAppKey()      { return get("dropbox.app.key", ""); }
    public static String dropboxAppSecret()   { return get("dropbox.app.secret", ""); }
    public static String dropboxRefreshToken(){ return get("dropbox.refresh.token", ""); }
    public static String dropboxFolder()      { return get("dropbox.folder", "/keyagg"); }
}
