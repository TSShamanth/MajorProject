package com.example.backend.controller;

import com.example.backend.dto.NewUserRequest;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.UserRecord;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    @PostMapping
    public ResponseEntity<?> createUser(@RequestBody NewUserRequest newUserRequest) {
        try {
            // Step 1: Create user in Firebase Authentication
            UserRecord.CreateRequest request = new UserRecord.CreateRequest()
                .setEmail(newUserRequest.getEmail())
                .setPassword(newUserRequest.getPassword())
                .setEmailVerified(false) // Or true, depending on your flow
                .setDisabled(false);

            UserRecord userRecord = FirebaseAuth.getInstance().createUser(request);
            String uid = userRecord.getUid();
            System.out.println("Successfully created new user: " + uid);

            // Step 2: Create user document in Firestore
            Firestore db = FirestoreClient.getFirestore();
           Map<String, Object> userData = new HashMap<>();
            userData.put("email", newUserRequest.getEmail());
            userData.put("role", newUserRequest.getRole());
            // You can add more fields here if needed, like displayName
            
            db.collection("users").document(uid).set(userData).get(); // .get() waits for completion
            System.out.println("Successfully stored user data in Firestore for UID: " + uid);

            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("uid", uid));

        } catch (FirebaseAuthException e) {
            // Handle specific auth errors, e.g., email already exists
            System.err.println("Error creating new user: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            // Handle other errors (e.g., Firestore connection)
            System.err.println("An unexpected error occurred: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("message", "An unexpected error occurred."));
        }
    }
}
