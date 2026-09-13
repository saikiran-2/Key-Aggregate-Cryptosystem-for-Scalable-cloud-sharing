import pack.AppConfig;

/**
 * Confirms config.properties (or environment variable overrides) load
 * correctly before you even start Tomcat. Run the same way as
 * TestCipherRoundtrip. Does not touch the database, Dropbox, or email -
 * it only checks that values come through correctly.
 */
public class TestConfigLoad {
    public static void main(String[] args) {
        System.out.println("db.url            = " + AppConfig.dbUrl());
        System.out.println("db.name           = " + AppConfig.dbName());
        System.out.println("db.user           = " + AppConfig.dbUser());
        System.out.println("admin.username    = " + AppConfig.adminUsername());
        System.out.println("mail.enabled      = " + AppConfig.mailEnabled());
        System.out.println("dropbox.folder    = " + AppConfig.dropboxFolder());
        boolean dropboxConfigured = !AppConfig.dropboxAppKey().isEmpty()
                && !AppConfig.dropboxAppSecret().isEmpty()
                && !AppConfig.dropboxRefreshToken().isEmpty();
        System.out.println("dropbox configured = " + dropboxConfigured
                + (dropboxConfigured ? "" : "  (uploads/downloads will fail until you set dropbox.* - see README)"));
    }
}
