import cloud.DropboxClient;
import pack.AppConfig;
import java.util.List;

/**
 * Diagnostic tool - asks Dropbox's API directly what's in your configured
 * folder, bypassing the Dropbox website entirely (which can lag/cache, or
 * be showing a different account than the one your refresh token belongs to).
 *
 * Run the same way as the other test files - fill in real dropbox.app.key /
 * dropbox.app.secret / dropbox.refresh.token in config.properties first.
 */
public class TestDropboxListFiles {
    public static void main(String[] args) throws Exception {
        String folder = AppConfig.dropboxFolder();
        System.out.println("Checking Dropbox folder: " + folder);
        System.out.println("(This is relative to your app's own sandbox if you used 'App folder' access -");
        System.out.println(" i.e. it corresponds to Apps/<your app name>" + folder + " on dropbox.com)\n");
        try {
            List<String> files = DropboxClient.listFolder(folder);
            if (files.isEmpty()) {
                System.out.println("Folder exists but is EMPTY according to Dropbox's API.");
                System.out.println("-> Your uploads are NOT reaching this account/folder at all.");
                System.out.println("-> Double check dropbox.refresh.token belongs to the SAME Dropbox");
                System.out.println("   account you're viewing in the browser.");
            } else {
                System.out.println("Files Dropbox's API actually sees in this folder:");
                for (String f : files) System.out.println("  - " + f);
                System.out.println("\nIf these ARE your uploads: it's just a Dropbox website caching/refresh");
                System.out.println("issue - hard-refresh the Dropbox web page (Ctrl+Shift+R) or check the");
                System.out.println("desktop/mobile app instead.");
            }
        } catch (Exception e) {
            System.out.println("Could not reach Dropbox: " + e.getMessage());
            System.out.println("-> This usually means dropbox.app.key/secret/refresh.token in");
            System.out.println("   config.properties are wrong, blank, or belong to a different app.");
        }
    }
}
