package com.example.backend.service;

import com.example.backend.dto.CreateUserRequest;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

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
        db.collection("Institutions").document(createUserRequest.getInstitutionId()).collection("users").document(uid).set(user).get();

        return userRecord;
    }

    public List<Map<String, Object>> getUsers(String institutionId, String role) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        CollectionReference usersCollection = db.collection("Institutions").document(institutionId).collection("users");
        Query query = usersCollection;

        if (role != null && !role.isEmpty()) {
            query = query.whereEqualTo("role", role);
        }

        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

        List<Map<String, Object>> users = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            Map<String, Object> userData = document.getData();
            userData.put("uid", document.getId()); // Add UID to the map
            users.add(userData);
        }
        return users;
    }

    public Map<String, Object> getUserById(String institutionId, String uid) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userDocRef = db.collection("Institutions").document(institutionId).collection("users").document(uid);
        ApiFuture<DocumentSnapshot> documentSnapshot = userDocRef.get();
        DocumentSnapshot document = documentSnapshot.get();

        if (document.exists()) {
            Map<String, Object> userData = document.getData();
            userData.put("uid", document.getId()); // Add UID to the map
            return userData;
        } else {
            return null; // User not found
        }
    }

    public void updateUser(String institutionId, String uid, Map<String, Object> updates) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userDocRef = db.collection("Institutions").document(institutionId).collection("users").document(uid);
        userDocRef.update(updates).get();
    }
}
