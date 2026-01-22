package com.example.backend.config;

// import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
// import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
// import org.springframework.core.io.ClassPathResource;

import javax.annotation.PostConstruct;
// import java.io.IOException;
// import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initialize() {
        try {
            /*
            When running on Google Cloud (like Cloud Run), the SDK can discover credentials automatically.
            This is known as Application Default Credentials (ADC).
            We will initialize without explicit credentials.
            For local testing, you would need to set the GOOGLE_APPLICATION_CREDENTIALS environment variable
            to point to your service account JSON file.
            */
            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp();
                System.out.println("Firebase app initialized successfully using Application Default Credentials.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Error initializing Firebase app: " + e.getMessage());
        }
    }
}
