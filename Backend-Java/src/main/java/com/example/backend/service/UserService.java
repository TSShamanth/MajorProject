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

        String uid = userRecord.getUid();
        if (uid == null) {
            throw new Exception("Failed to create user: UID is null");
        }

        // Set custom claim for role
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", createUserRequest.getRole());
        FirebaseAuth.getInstance().setCustomUserClaims(uid, claims);

        // Save user details in Firestore
        Firestore db = FirestoreClient.getFirestore();
        Map<String, Object> user = new HashMap<>();
        user.put("email", createUserRequest.getEmail());
        user.put("displayName", createUserRequest.getDisplayName());
        user.put("role", createUserRequest.getRole());
        user.put("name", createUserRequest.getName());
        user.put("usn", createUserRequest.getUsn());
        user.put("phone", createUserRequest.getPhone());
        user.put("sem", createUserRequest.getSem());
        user.put("mentorName", createUserRequest.getMentorName());
        user.put("photoUrl", createUserRequest.getPhotoUrl()); // Save photo URL
        user.put("programme", createUserRequest.getProgramme());
        user.put("school", createUserRequest.getSchool());
        user.put("address", createUserRequest.getAddress());
        user.put("dob", createUserRequest.getDob());
        user.put("bloodGroup", createUserRequest.getBloodGroup());
        user.put("emergencyContact", createUserRequest.getEmergencyContact());
        user.put("validUpto", createUserRequest.getValidUpto());
        db.collection("Institutions").document("RVU").collection("users").document(uid).set(user).get();

        return userRecord;
    }
}
