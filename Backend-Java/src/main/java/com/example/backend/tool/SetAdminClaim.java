package com.example.backend.tool;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * A one-time utility to set a custom claim on a Firebase user.
 *
 * HOW TO USE:
 * 1.  Update the `USER_UID` variable below with the UID of the user you want to make an admin.
 * 2.  Ensure you have run the local development setup steps to configure Application Default Credentials (ADC).
 *     This tool now uses ADC for authentication.
 * 3.  Run this main() method from your IDE.
 * 4.  After running, the user MUST log out and log back in to get the new claim in their token.
 */
public class SetAdminClaim {


    private static final String USER_UID = "QDfWXZNAaAhYZWcCe0bXySPI8063";

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
            System.err.println("❌ ERROR: Could not initialize Firebase. Ensure you have configured Application Default Credentials correctly.");
            System.err.println("This can happen if the GOOGLE_APPLICATION_CREDENTIALS environment variable is not set.");
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("❌ An unexpected error occurred:");
            e.printStackTrace();
        }
    }

    private static void initializeFirebase() throws IOException {
        // Only initialize if no other apps are running
        if (FirebaseApp.getApps().isEmpty()) {
            // This now uses Application Default Credentials.
            // It will automatically find credentials in your environment.
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.getApplicationDefault())
                    .setProjectId("acadexa-484807")
                    .build();

            FirebaseApp.initializeApp(options);
            System.out.println("Firebase Admin SDK initialized using Application Default Credentials.");
        }
    }
}
