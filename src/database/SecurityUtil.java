package database;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

public class SecurityUtil {

    /**
     * Hashes a password using SHA-256 with standard hex encoding.
     */
    public static String hashPassword(String password) {
        if (password == null) return "";
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            throw new RuntimeException("Error hashing password", e);
        }
    }

    /**
     * Verifies password against stored credential.
     * Supports both modern SHA-256 hashes and legacy plaintext for existing user accounts.
     */
    public static boolean verifyPassword(String inputPassword, String storedCredential) {
        if (inputPassword == null || storedCredential == null) return false;
        // 1. Check against modern SHA-256 hash
        String inputHashed = hashPassword(inputPassword);
        if (inputHashed.equalsIgnoreCase(storedCredential)) {
            return true;
        }
        // 2. Backward compatibility with existing plaintext database records
        return inputPassword.equals(storedCredential);
    }

    /**
     * Sanitizes string to prevent Cross-Site Scripting (XSS).
     */
    public static String escapeHtml(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#x27;");
    }
}
