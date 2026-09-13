import cloud.CipherExample1;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;

/**
 * Simple sanity test - no JUnit needed. Right-click this file in NetBeans
 * and choose "Run File", or from the command line:
 *   javac -cp build/web/WEB-INF/classes -d /tmp/testout test/TestCipherRoundtrip.java
 *   java -cp /tmp/testout:build/web/WEB-INF/classes TestCipherRoundtrip
 *
 * Checks that encrypting then decrypting with the SAME key returns the
 * original bytes, and that decrypting with the WRONG key does NOT.
 */
public class TestCipherRoundtrip {
    public static void main(String[] args) throws Throwable {
        String original = "This is a test file's contents. 1234567890!";
        String correctKey = "mySecret1";
        String wrongKey = "otherPass2";

        // Encrypt
        ByteArrayOutputStream encrypted = new ByteArrayOutputStream();
        CipherExample1.encrypt(correctKey, new ByteArrayInputStream(original.getBytes(StandardCharsets.UTF_8)), encrypted);

        // Decrypt with the correct key - should match exactly
        ByteArrayOutputStream decrypted = new ByteArrayOutputStream();
        CipherExample1.decrypt(correctKey, new ByteArrayInputStream(encrypted.toByteArray()), decrypted);
        String result = decrypted.toString(StandardCharsets.UTF_8);

        boolean pass1 = original.equals(result);
        System.out.println((pass1 ? "PASS" : "FAIL") + ": decrypt with correct key returns original text");

        // Decrypt with the wrong key - should either throw or produce garbage, never the original
        boolean pass2;
        try {
            ByteArrayOutputStream wrongDecrypted = new ByteArrayOutputStream();
            CipherExample1.decrypt(wrongKey, new ByteArrayInputStream(encrypted.toByteArray()), wrongDecrypted);
            pass2 = !original.equals(wrongDecrypted.toString(StandardCharsets.UTF_8));
        } catch (Exception expected) {
            pass2 = true; // throwing (e.g. bad padding) is also a correct outcome
        }
        System.out.println((pass2 ? "PASS" : "FAIL") + ": decrypt with wrong key never returns original text");

        if (!pass1 || !pass2) {
            System.out.println("\nOne or more checks FAILED.");
            System.exit(1);
        } else {
            System.out.println("\nAll checks passed.");
        }
    }
}
