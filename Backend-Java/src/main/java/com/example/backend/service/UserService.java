package com.example.backend.service;

import com.example.backend.dto.CreateUserRequest;
import com.example.backend.models.User;
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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class UserService {

    private final FirebaseAuth firebaseAuth;
    private final Firestore firestore;
    private static final Logger logger = LoggerFactory.getLogger(UserService.class);


    public UserService(FirebaseAuth firebaseAuth, Firestore firestore) {
        this.firebaseAuth = firebaseAuth;
        this.firestore = firestore;
    }

    public UserRecord createUser(CreateUserRequest createUserRequest) throws Exception {
        UserRecord.CreateRequest request = new UserRecord.CreateRequest()
                .setEmail(createUserRequest.getEmail())
                .setPassword(createUserRequest.getPassword())
                .setDisplayName(createUserRequest.getDisplayName());

        UserRecord userRecord = firebaseAuth.createUser(request);

        String uid = userRecord.getUid();
        if (uid == null) {
            throw new Exception("Failed to create user: UID is null");
        }

        // Set custom claim for role
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", createUserRequest.getRole());
        firebaseAuth.setCustomUserClaims(uid, claims);

        // Save user details in Firestore
        Map<String, Object> user = new HashMap<>();
        user.put("email", createUserRequest.getEmail());
        user.put("displayName", createUserRequest.getDisplayName());
        user.put("role", createUserRequest.getRole());
        user.put("name", createUserRequest.getName());
        user.put("usn", createUserRequest.getUsn());
        user.put("phone", createUserRequest.getPhone());
        user.put("sem", createUserRequest.getSem());
        user.put("departmentId", createUserRequest.getDepartmentId()); // Save departmentId
        user.put("sectionId", createUserRequest.getSectionId()); // Save sectionId
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
        firestore.collection("Institutions").document(createUserRequest.getInstitutionId()).collection("users").document(uid).set(user).get();

        return userRecord;
    }

    public List<User> getUsers(String institutionId, String role) throws ExecutionException, InterruptedException {
        CollectionReference usersCollection = firestore.collection("Institutions").document(institutionId).collection("users");
        Query query = usersCollection;

        if (role != null && !role.isEmpty()) {
            query = query.whereEqualTo("role", role);
        }

        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

        List<User> users = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            User userData = document.toObject(User.class);
            userData.setUid(document.getId());
            users.add(userData);
        }
        return users;
    }

    public List<User> getStudentsByMentor(String institutionId, String mentorName) throws ExecutionException, InterruptedException {
        CollectionReference usersCollection = firestore.collection("Institutions").document(institutionId).collection("users");
        Query query = usersCollection.whereEqualTo("role", "student").whereEqualTo("mentorName", mentorName);
        
        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<User> students = new ArrayList<>();
        for (QueryDocumentSnapshot document : querySnapshot.get().getDocuments()) {
            User student = document.toObject(User.class);
            student.setUid(document.getId());
            students.add(student);
        }
        return students;
    }

    public List<User> getStudentsByDepartmentAndSemester(String institutionId, String departmentId, String semester) throws ExecutionException, InterruptedException {
        CollectionReference usersCollection = firestore.collection("Institutions").document(institutionId).collection("users");
        Query query = usersCollection
                .whereEqualTo("role", "student")
                .whereEqualTo("departmentId", departmentId) // Assuming User model has departmentId
                .whereEqualTo("sem", semester) // Assuming User model has sem for semester
                .whereEqualTo("isDetained", false); // Filter out detained students

        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

        List<User> students = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            User studentData = document.toObject(User.class);
            studentData.setUid(document.getId());
            students.add(studentData);
        }
        return students;
    }

    public List<String> getProfessorNames(String institutionId) throws ExecutionException, InterruptedException {
        CollectionReference usersCollection = firestore.collection("Institutions").document(institutionId).collection("users");
        Query query = usersCollection.whereEqualTo("role", "faculty");

        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

        List<String> professorNames = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            String displayName = document.getString("displayName");
            if (displayName != null && !displayName.isEmpty()) {
                professorNames.add(displayName);
            }
        }
        return professorNames;
    }

    public List<com.example.backend.dto.ProfessorDto> getProfessorsWithIds(String institutionId) throws ExecutionException, InterruptedException {
        logger.info("UserService: Fetching professors with IDs for institution: {}", institutionId);
        CollectionReference usersCollection = firestore.collection("Institutions").document(institutionId).collection("users");
        Query query = usersCollection.whereEqualTo("role", "faculty");

        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

        List<com.example.backend.dto.ProfessorDto> professors = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            String displayName = document.getString("displayName");
            String uid = document.getId();
            if (displayName != null && !displayName.isEmpty()) {
                professors.add(new com.example.backend.dto.ProfessorDto(uid, displayName));
                logger.info("Added professor: {} (UID: {})", displayName, uid);
            }
        }
        return professors;
    }

    public User getUserById(String institutionId, String uid) throws ExecutionException, InterruptedException {
        logger.info("UserService: Searching for user with institutionId='{}' and uid='{}'", institutionId, uid);
        DocumentReference userDocRef = firestore.collection("Institutions").document(institutionId).collection("users").document(uid);
        ApiFuture<DocumentSnapshot> documentSnapshot = userDocRef.get();
        DocumentSnapshot document = documentSnapshot.get();

        if (document.exists()) {
            logger.info("UserService: Found user document for uid='{}'", uid);
            User userData = document.toObject(User.class);
            userData.setUid(document.getId());
            return userData;
        } else {
            logger.warn("UserService: User document NOT FOUND for uid='{}' in institution='{}'", uid, institutionId);
            return null;
        }
    }

    public void updateUser(String institutionId, String uid, User user) throws ExecutionException, InterruptedException {
        DocumentReference userDocRef = firestore.collection("Institutions").document(institutionId).collection("users").document(uid);
        user.setUid(uid);
        userDocRef.set(user).get();
    }

    public void updateAssignedCourses(String institutionId, String facultyId, List<String> courseCodes) throws ExecutionException, InterruptedException {
        DocumentReference userDocRef = firestore.collection("Institutions").document(institutionId).collection("users").document(facultyId);
        userDocRef.update("assignedCourseCodes", courseCodes).get();
    }

    public void updateEnrolledCourses(String institutionId, String studentId, List<String> courseCodes) throws ExecutionException, InterruptedException {
        DocumentReference userDocRef = firestore.collection("Institutions").document(institutionId).collection("users").document(studentId);
        userDocRef.update("enrolledCourseCodes", courseCodes).get();
    }

    public void updateUserDetainedStatus(String institutionId, String studentUid, boolean isDetained) throws ExecutionException, InterruptedException {
        DocumentReference userDocRef = firestore.collection("Institutions").document(institutionId).collection("users").document(studentUid);
        // Directly update the 'isDetained' field
        userDocRef.update("isDetained", isDetained).get();
    }
}
