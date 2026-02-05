package com.example.backend.service;

import com.example.backend.dto.CreateUserRequest;
import com.example.backend.models.User; // Import the new User POJO
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
        user.put("enrolledCourseCodes", new ArrayList<String>()); // Initialize as empty list
        user.put("assignedCourseCodes", new ArrayList<String>()); // Initialize as empty list
        db.collection("Institutions").document(createUserRequest.getInstitutionId()).collection("users").document(uid).set(user).get();

        return userRecord;
    }

    public List<User> getUsers(String institutionId, String role) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        CollectionReference usersCollection = db.collection("Institutions").document(institutionId).collection("users");
        Query query = usersCollection;

        if (role != null && !role.isEmpty()) {
            query = query.whereEqualTo("role", role);
        }

        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

        List<User> users = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            User userData = document.toObject(User.class); // Convert to User POJO
            userData.setUid(document.getId()); // Set UID from document ID
            users.add(userData);
        }
        return users;
    }

    public User getUserById(String institutionId, String uid) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userDocRef = db.collection("Institutions").document(institutionId).collection("users").document(uid);
        ApiFuture<DocumentSnapshot> documentSnapshot = userDocRef.get();
        DocumentSnapshot document = documentSnapshot.get();

        if (document.exists()) {
            User userData = document.toObject(User.class); // Convert to User POJO
            userData.setUid(document.getId()); // Set UID from document ID
            return userData;
        } else {
            return null; // User not found
        }
    }

    public void updateUser(String institutionId, String uid, User user) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userDocRef = db.collection("Institutions").document(institutionId).collection("users").document(uid);
        user.setUid(uid); // Ensure the UID is set in the object before saving
        userDocRef.set(user).get(); // Overwrite the entire document
    }

    public void updateAssignedCourses(String institutionId, String facultyId, List<String> courseCodes) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userDocRef = db.collection("Institutions").document(institutionId).collection("users").document(facultyId);
        userDocRef.update("assignedCourseCodes", courseCodes).get();
    }

    public void updateEnrolledCourses(String institutionId, String studentId, List<String> courseCodes) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userDocRef = db.collection("Institutions").document(institutionId).collection("users").document(studentId);
        userDocRef.update("enrolledCourseCodes", courseCodes).get();
    }
}
