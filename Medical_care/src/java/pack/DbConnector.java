package pack;

import java.sql.Connection;
import java.sql.DriverManager;

public class DbConnector {

    public static Connection getConnection() {
        Connection conn = null;
        try {
           Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(
                    AppConfig.dbUrl() + AppConfig.dbName(),
                    AppConfig.dbUser(),
                    AppConfig.dbPassword());
        } catch (Exception e) {
            e.printStackTrace();
        }
        return conn;
    }
}
