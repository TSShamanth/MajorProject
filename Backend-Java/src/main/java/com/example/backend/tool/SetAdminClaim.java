package com.example.backend.tool;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * A one-time utility to set a custom claim on a Firebase user.
 *
 * HOW TO USE:
 * 1.  Update the `USER_UID` variable below with the UID of the user you want to make an admin.
 * 2.  Make sure your `firebase-service-account.json` file is in the root directory of your Backend-Java project,
 *     or provide the correct path to it in the `FileInputStream`.
 * 3.  Run this main() method from your IDE.
 * 4.  After running, the user MUST log out and log back in to get the new claim in their token.
 */
public class SetAdminClaim {


    private static final String USER_UID = "hcEkFWFecdYUYAjxjpTyUXqpo8n2";

    public static void main(String[] args) {
        if (USER_UID == null || USER_UID.isEmpty()) {
            System.err.println("❌ ERROR: Please edit the USER_UID variable in SetAdminClaim.java before running.");
            return;
        }

        try {
            // Initialize Firebase Admin SDK
            initializeFirebase();

            // Set the custom claim
            Map<String, Object> claims = new HashMap<>();
            claims.put("role", "admin");

            FirebaseAuth.getInstance().setCustomUserClaims(USER_UID, claims);

            // Verify the claim was set
            UserRecord user = FirebaseAuth.getInstance().getUser(USER_UID);
            System.out.println("✅ Successfully set custom claims for user: " + user.getDisplayName() + " (" + user.getUid() + ")");
            System.out.println("New role: " + user.getCustomClaims().get("role"));
            System.out.println("\n\nIMPORTANT: The user must now SIGN OUT and SIGN BACK IN to your application.");

        } catch (IOException e) {
            System.err.println("❌ ERROR: Could not find 'firebase-service-account.json'.");
            System.err.println("Please make sure the service account file is in the root of the Backend-Java project or update the path.");
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("❌ An unexpected error occurred:");
            e.printStackTrace();
        }
    }

    private static void initializeFirebase() throws IOException {
        // Only initialize if no other apps are running
        if (FirebaseApp.getApps().isEmpty()) {
            // IMPORTANT: Make sure this path is correct.
            // This assumes the file is in the root of the `Backend-Java` directory.
            FileInputStream serviceAccount = new FileInputStream("firebase-service-account.json");

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            FirebaseApp.initializeApp(options);
            System.out.println("Firebase Admin SDK initialized.");
        }
    }
}
