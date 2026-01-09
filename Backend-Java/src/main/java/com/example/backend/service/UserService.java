package com.example.backend.service;

import com.example.backend.dto.CreateUserRequest;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class UserService {

    public UserRecord createUser(CreateUserRequest createUserRequest) throws Exception {
        UserRecord.CreateRequest request = new UserRecord.CreateRequest()
                .setEmail(createUserRequest.getEmail())
                .setPassword(createUserRequest.getPassword())
                .setDisplayName(createUserRequest.getDisplayName());

        UserRecord userRecord = FirebaseAuth.getInstance().createUser(request);

        // Set custom claim for role
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", createUserRequest.getRole());
        FirebaseAuth.getInstance().setCustomUserClaims(userRecord.getUid(), claims);

        // Save user details in Firestore
        Firestore db = FirestoreClient.getFirestore();
        Map<String, Object> user = new HashMap<>();
        user.put("email", createUserRequest.getEmail());
        user.put("displayName", createUserRequest.getDisplayName());
        user.put("role", createUserRequest.getRole());
        db.collection("users").document(userRecord.getUid()).set(user).get();

        return userRecord;
    }
}
