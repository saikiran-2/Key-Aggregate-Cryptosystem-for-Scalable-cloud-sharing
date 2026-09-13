package pack;

import java.util.Properties;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

/**
 * Optional email notification. Disabled by default (config.properties:
 * mail.enabled=false) because the original project's Gmail credentials
 * were hardcoded and are long dead. When disabled, callers should just
 * show the key on-screen instead (see share_result.jsp).
 */
public class mail {

    public static void mailsend(String toEmail, String fileNames, String aggKey) throws MessagingException {

        if (!AppConfig.mailEnabled()) {
            System.out.println("Mail disabled (config.properties). Skipping email to " + toEmail);
            return;
        }

        final String host = AppConfig.mailHost();
        final String user = AppConfig.mailUsername();
        final String pass = AppConfig.mailPassword();

        Properties props = new Properties();
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", host);
        props.put("mail.smtp.port", AppConfig.mailPort());
        props.put("mail.smtp.auth", "true");

        Session session = Session.getInstance(props, new javax.mail.Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(user, pass);
            }
        });

        Message message = new MimeMessage(session);
        message.setFrom(new InternetAddress(user));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
        message.setSubject("You've been granted access to files");
        message.setText("Files shared with you: " + fileNames
                + "\nAggregate Key: " + aggKey
                + "\n\nLog in, enter this one key, and you'll see all the files listed above to download.");
        Transport.send(message);
    }
}
