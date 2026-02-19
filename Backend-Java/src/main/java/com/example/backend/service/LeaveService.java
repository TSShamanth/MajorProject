package com.example.backend.service;

import com.google.cloud.Timestamp;
import com.example.backend.dto.LeaveApplicationDto;
import com.example.backend.models.LeaveApplication;
import com.example.backend.models.User;
import com.example.backend.models.Notification;
import com.example.backend.service.NotificationService;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.HashMap;
import java.util.Map;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.io.IOException;

@Service
public class LeaveService {

    private final Firestore firestore;
    private final UserService userService;
    private final NotificationService notificationService;
    private static final Logger logger = LoggerFactory.getLogger(LeaveService.class);

    public LeaveService(Firestore firestore, UserService userService, NotificationService notificationService) {
        this.firestore = firestore;
        this.userService = userService;
        this.notificationService = notificationService;
    }

    private CollectionReference getLeaveApplicationsCollection(String institutionId) {
        return firestore.collection("Institutions")
                .document(institutionId)
                .collection("leaveApplications");
    }

    public LeaveApplication applyLeave(String institutionId,
                                          String userId,
                                          LeaveApplicationDto requestDto,
                                          org.springframework.web.multipart.MultipartFile file)
            throws ExecutionException, InterruptedException {

        String leaveId = UUID.randomUUID().toString();
        String documentUrl = "";

        logger.info("ApplyLeave: Creating leave application with professorId: {}", requestDto.getProfessorId());

        // Handle file upload if provided
        if (file != null && !file.isEmpty()) {
            try {
                String fileName = file.getOriginalFilename();
                // Create directory structure: uploads/institutionId/leaves/leaveId/
                String dirPath = String.format("uploads/%s/leaves/%s", institutionId, leaveId);
                Files.createDirectories(Paths.get(dirPath));
                
                // Save file to disk
                String filePath = String.format("%s/%s", dirPath, fileName);
                Files.write(Paths.get(filePath), file.getBytes());
                
                // Create a download URL reference
                documentUrl = String.format("/RVU/api/leaves/%s/download/%s", leaveId, fileName);
                logger.info("File saved successfully: {} at path: {}", fileName, filePath);
            } catch (IOException e) {
                logger.error("Error saving file: {}", e.getMessage(), e);
                // Continue without file if there's an error
            } catch (Exception e) {
                logger.error("Error processing file upload: {}", e.getMessage(), e);
                // Continue without file if there's an error
            }
        }

        User professor = null;
        String professorName = "Unknown Professor";
        String studentName = "Unknown Student";
        
        try {
            // Fetch professor details
            professor = userService.getUserById(institutionId, requestDto.getProfessorId());
            if (professor != null) {
                professorName = professor.getDisplayName();
                logger.info("Professor found: {} with name: {}", requestDto.getProfessorId(), professorName);
            } else {
                logger.warn("Professor not found for ID: {}", requestDto.getProfessorId());
                // Try to fetch professor name from Users collection directly as fallback
                professorName = getProfessorNameDirectly(institutionId, requestDto.getProfessorId());
                logger.info("Fallback professor name: {}", professorName);
            }
        } catch (Exception e) {
            logger.error("Error looking up professor: {}", e.getMessage(), e);
            professorName = "Unknown Professor";
        }

        // Fetch student details
        try {
            User student = userService.getUserById(institutionId, userId);
            if (student != null) {
                studentName = student.getDisplayName();
                logger.info("Student found: {} with name: {}", userId, studentName);
            } else {
                logger.warn("Student not found for ID: {}", userId);
                studentName = "Unknown Student";
            }
        } catch (Exception e) {
            logger.error("Error looking up student: {}", e.getMessage(), e);
            studentName = "Unknown Student";
        }

        Timestamp currentTimestamp = Timestamp.now();

        LeaveApplication leaveApplication = new LeaveApplication(
                leaveId,
                userId,
                studentName,
                institutionId,
                requestDto.getLeaveType(),
                requestDto.getStartDate(),
                requestDto.getEndDate(),
                requestDto.getReason(),
                requestDto.getProfessorId(),
                professorName,
                "Pending",
                "",
                currentTimestamp,
                currentTimestamp
        );
        
        if (documentUrl != null && !documentUrl.isEmpty()) {
            leaveApplication.setDocumentUrl(documentUrl);
        }

        getLeaveApplicationsCollection(institutionId)
                .document(leaveId)
                .set(leaveApplication)
                .get();

        logger.info("Leave application created successfully with ID: {} for professor: {}", leaveId, professorName);
        // notify professor
        try {
            Notification notif = new Notification();
            notif.setTitle("New Leave Application");
            notif.setMessage(studentName + " has applied for leave.");
            // when tapped, professor should see leave list
            notif.setRoute("/faculty/leave-approval");
            notificationService.createNotification(institutionId, requestDto.getProfessorId(), notif);
        } catch (Exception e) {
            logger.error("Failed to send notification to professor {}: {}", requestDto.getProfessorId(), e.getMessage());
        }

        return leaveApplication;
    }

    public LeaveApplication applyLeave(String institutionId,
                                          String userId,
                                          LeaveApplicationDto requestDto)
            throws ExecutionException, InterruptedException {
        return applyLeave(institutionId, userId, requestDto, null);
    }
    @SuppressWarnings("unchecked")
    public List<LeaveApplication> getLeaveHistory(String institutionId,
                                                     String userId)
            throws ExecutionException, InterruptedException {

        Query query = getLeaveApplicationsCollection(institutionId)
                .whereEqualTo("userId", userId)
                .orderBy("createdAt", Query.Direction.DESCENDING);

        List<LeaveApplication> result = new ArrayList<>();

        for (DocumentSnapshot doc : query.get().get().getDocuments()) {
            if (doc.exists()) {
                String id = doc.getId();
                String retrievedUserId = doc.getString("userId") != null ? doc.getString("userId") : "";
                String institutionIdFromDoc = doc.getString("institutionId") != null ? doc.getString("institutionId") : "";
                String leaveType = doc.getString("leaveType") != null ? doc.getString("leaveType") : "";
                String startDate = doc.getString("startDate") != null ? doc.getString("startDate") : "";
                String endDate = doc.getString("endDate") != null ? doc.getString("endDate") : "";
                String reason = doc.getString("reason") != null ? doc.getString("reason") : "";
                String professorId = doc.getString("professorId") != null ? doc.getString("professorId") : "";
                String professorName = doc.getString("professorName") != null ? doc.getString("professorName") : "";
                String studentName = doc.getString("studentName") != null ? doc.getString("studentName") : "Unknown Student";
                String status = doc.getString("status") != null ? doc.getString("status") : "";
                String rejectionReason = doc.getString("rejectionReason") != null ? doc.getString("rejectionReason") : "";
                String documentUrl = doc.getString("documentUrl") != null ? doc.getString("documentUrl") : "";

                Timestamp createdAt = Timestamp.now(); // Default to current timestamp
                Object createdAtObj = doc.get("createdAt");
                if (createdAtObj instanceof Timestamp) {
                    createdAt = (Timestamp) createdAtObj;
                } else if (createdAtObj instanceof Map) {
                    Map<String, Long> map = (Map<String, Long>) createdAtObj;
                    if (map.containsKey("_seconds") && map.containsKey("_nanoseconds")) {
                        createdAt = Timestamp.ofTimeSecondsAndNanos(map.get("_seconds"), map.get("_nanoseconds").intValue());
                    }
                }

                Timestamp updatedAt = Timestamp.now(); // Default to current timestamp
                Object updatedAtObj = doc.get("updatedAt");
                if (updatedAtObj instanceof Timestamp) {
                    updatedAt = (Timestamp) updatedAtObj;
                } else if (updatedAtObj instanceof Map) {
                    Map<String, Long> map = (Map<String, Long>) updatedAtObj;
                    if (map.containsKey("_seconds") && map.containsKey("_nanoseconds")) {
                        updatedAt = Timestamp.ofTimeSecondsAndNanos(map.get("_seconds"), map.get("_nanoseconds").intValue());
                    }
                }

                LeaveApplication leave = new LeaveApplication(
                    id, retrievedUserId, studentName, institutionIdFromDoc, leaveType, startDate, endDate, reason,
                    professorId, professorName, status, rejectionReason, createdAt, updatedAt
                );
                leave.setDocumentUrl(documentUrl);
                result.add(leave);
            }
        }

        return result;
    }

    public List<String> getLeaveTypes() {
        return Arrays.asList(
                "Sick Leave",
                "Casual Leave",
                "Medical Appointment",
                "Family Emergency",
                "Other"
        );
    }

    public List<com.example.backend.dto.ProfessorDto> getProfessors(String institutionId)
            throws ExecutionException, InterruptedException {
        return userService.getProfessorsWithIds(institutionId);
    }

    @SuppressWarnings("unchecked")
    public List<LeaveApplication> getPendingLeaveApplicationsForFaculty(String institutionId, String facultyId)
            throws ExecutionException, InterruptedException {

        Query query = getLeaveApplicationsCollection(institutionId)
                .whereEqualTo("professorId", facultyId)
                .whereEqualTo("status", "Pending")
                .orderBy("createdAt", Query.Direction.DESCENDING);

        List<LeaveApplication> result = new ArrayList<>();

        for (DocumentSnapshot doc : query.get().get().getDocuments()) {
            if (doc.exists()) {
                // Manually map fields, similar to getLeaveHistory
                String id = doc.getId();
                String retrievedUserId = doc.getString("userId") != null ? doc.getString("userId") : "";
                String institutionIdFromDoc = doc.getString("institutionId") != null ? doc.getString("institutionId") : "";
                String leaveType = doc.getString("leaveType") != null ? doc.getString("leaveType") : "";
                String startDate = doc.getString("startDate") != null ? doc.getString("startDate") : "";
                String endDate = doc.getString("endDate") != null ? doc.getString("endDate") : "";
                String reason = doc.getString("reason") != null ? doc.getString("reason") : "";
                String professorId = doc.getString("professorId") != null ? doc.getString("professorId") : "";
                String professorName = doc.getString("professorName") != null ? doc.getString("professorName") : "";
                String studentName = doc.getString("studentName") != null ? doc.getString("studentName") : "Unknown Student";
                String status = doc.getString("status") != null ? doc.getString("status") : "";
                String rejectionReason = doc.getString("rejectionReason") != null ? doc.getString("rejectionReason") : "";
                String documentUrl = doc.getString("documentUrl") != null ? doc.getString("documentUrl") : "";

                Timestamp createdAt = Timestamp.now(); // Default to current timestamp
                Object createdAtObj = doc.get("createdAt");
                if (createdAtObj instanceof Timestamp) {
                    createdAt = (Timestamp) createdAtObj;
                } else if (createdAtObj instanceof Map) {
                    Map<String, Long> map = (Map<String, Long>) createdAtObj;
                    if (map.containsKey("_seconds") && map.containsKey("_nanoseconds")) {
                        createdAt = Timestamp.ofTimeSecondsAndNanos(map.get("_seconds"), map.get("_nanoseconds").intValue());
                    }
                }

                Timestamp updatedAt = Timestamp.now(); // Default to current timestamp
                Object updatedAtObj = doc.get("updatedAt");
                if (updatedAtObj instanceof Timestamp) {
                    updatedAt = (Timestamp) updatedAtObj;
                } else if (updatedAtObj instanceof Map) {
                    Map<String, Long> map = (Map<String, Long>) updatedAtObj;
                    if (map.containsKey("_seconds") && map.containsKey("_nanoseconds")) {
                        updatedAt = Timestamp.ofTimeSecondsAndNanos(map.get("_seconds"), map.get("_nanoseconds").intValue());
                    }
                }

                LeaveApplication leave = new LeaveApplication(
                    id, retrievedUserId, studentName, institutionIdFromDoc, leaveType, startDate, endDate, reason,
                    professorId, professorName, status, rejectionReason, createdAt, updatedAt
                );
                leave.setDocumentUrl(documentUrl);
                result.add(leave);
            }
        }
        return result;
    }

    public void approveLeaveApplication(String institutionId, String leaveId, String facultyId)
            throws ExecutionException, InterruptedException, IllegalArgumentException {
        DocumentReference leaveRef = getLeaveApplicationsCollection(institutionId).document(leaveId);
        DocumentSnapshot snapshot = leaveRef.get().get();

        if (!snapshot.exists()) {
            throw new IllegalArgumentException("Leave application not found.");
        }

        // Manually map fields to handle missing rejectionReason field in older documents
        String professorId = snapshot.getString("professorId");
        
        if (professorId == null) {
            throw new IllegalArgumentException("Failed to parse LeaveApplication.");
        }

        // Authorization check: Ensure the faculty approving is the assigned professor
        if (!professorId.equals(facultyId)) {
            throw new IllegalArgumentException("Faculty not authorized to approve this leave application.");
        }

        // Update only the specific fields
        Map<String, Object> updates = new HashMap<>();
        updates.put("status", "Approved");
        updates.put("updatedAt", Timestamp.now());
        leaveRef.update(updates).get();
        // notify student about approval
        try {
            String studentId = snapshot.getString("userId");
            String professorName = snapshot.getString("professorName");
            if (professorName == null) {
                professorName = getProfessorNameDirectly(institutionId, facultyId);
            }
            if (studentId != null) {
                Notification notif = new Notification();
                notif.setTitle("Leave Application Approved");
                notif.setMessage("Your leave application has been approved by " + professorName + ".");
                notif.setRoute("/student/leave/history");
                notificationService.createNotification(institutionId, studentId, notif);
            }
        } catch (Exception e) {
            logger.error("Failed to notify student about approval for leave {}: {}", leaveId, e.getMessage());
        }
    }

    public void rejectLeaveApplication(String institutionId, String leaveId, String facultyId, String rejectionReason)
            throws ExecutionException, InterruptedException, IllegalArgumentException {
        DocumentReference leaveRef = getLeaveApplicationsCollection(institutionId).document(leaveId);
        DocumentSnapshot snapshot = leaveRef.get().get();

        if (!snapshot.exists()) {
            throw new IllegalArgumentException("Leave application not found.");
        }

        // Manually map fields to handle missing rejectionReason field in older documents
        String professorId = snapshot.getString("professorId");
        
        if (professorId == null) {
            throw new IllegalArgumentException("Failed to parse LeaveApplication.");
        }

        // Authorization check: Ensure the faculty rejecting is the assigned professor
        if (!professorId.equals(facultyId)) {
            throw new IllegalArgumentException("Faculty not authorized to reject this leave application.");
        }

        // Update only the specific fields
        Map<String, Object> updates = new HashMap<>();
        updates.put("status", "Rejected");
        updates.put("rejectionReason", rejectionReason);
        updates.put("updatedAt", Timestamp.now());
        leaveRef.update(updates).get();
        // notify student about rejection
        try {
            String studentId = snapshot.getString("userId");
            String professorName = snapshot.getString("professorName");
            if (professorName == null) {
                professorName = getProfessorNameDirectly(institutionId, facultyId);
            }
            if (studentId != null) {
                Notification notif = new Notification();
                notif.setTitle("Leave Application Rejected");
                notif.setMessage("Your leave application was rejected by " + professorName + ". Reason: " + rejectionReason);
                notif.setRoute("/student/leave/history");
                notificationService.createNotification(institutionId, studentId, notif);
            }
        } catch (Exception e) {
            logger.error("Failed to notify student about rejection for leave {}: {}", leaveId, e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    public List<LeaveApplication> getFacultyLeaveHistory(String institutionId, String facultyId)
            throws ExecutionException, InterruptedException {

        Query query = getLeaveApplicationsCollection(institutionId)
                .whereEqualTo("professorId", facultyId)
                .whereIn("status", Arrays.asList("Approved", "Rejected")) // Query for Approved or Rejected
                .orderBy("createdAt", Query.Direction.DESCENDING);

        List<LeaveApplication> result = new ArrayList<>();

        for (DocumentSnapshot doc : query.get().get().getDocuments()) {
            if (doc.exists()) {
                // Manually map fields, similar to other methods
                String id = doc.getId();
                String retrievedUserId = doc.getString("userId") != null ? doc.getString("userId") : "";
                String institutionIdFromDoc = doc.getString("institutionId") != null ? doc.getString("institutionId") : "";
                String leaveType = doc.getString("leaveType") != null ? doc.getString("leaveType") : "";
                String startDate = doc.getString("startDate") != null ? doc.getString("startDate") : "";
                String endDate = doc.getString("endDate") != null ? doc.getString("endDate") : "";
                String reason = doc.getString("reason") != null ? doc.getString("reason") : "";
                String professorId = doc.getString("professorId") != null ? doc.getString("professorId") : "";
                String professorName = doc.getString("professorName") != null ? doc.getString("professorName") : "";
                String studentName = doc.getString("studentName") != null ? doc.getString("studentName") : "Unknown Student";
                String status = doc.getString("status") != null ? doc.getString("status") : "";
                String rejectionReason = doc.getString("rejectionReason") != null ? doc.getString("rejectionReason") : "";
                String documentUrl = doc.getString("documentUrl") != null ? doc.getString("documentUrl") : "";

                Timestamp createdAt = Timestamp.now();
                Object createdAtObj = doc.get("createdAt");
                if (createdAtObj instanceof Timestamp) {
                    createdAt = (Timestamp) createdAtObj;
                } else if (createdAtObj instanceof Map) {
                    Map<String, Long> map = (Map<String, Long>) createdAtObj;
                    if (map.containsKey("_seconds") && map.containsKey("_nanoseconds")) {
                        createdAt = Timestamp.ofTimeSecondsAndNanos(map.get("_seconds"), map.get("_nanoseconds").intValue());
                    }
                }

                Timestamp updatedAt = Timestamp.now();
                Object updatedAtObj = doc.get("updatedAt");
                if (updatedAtObj instanceof Timestamp) {
                    updatedAt = (Timestamp) updatedAtObj;
                } else if (updatedAtObj instanceof Map) {
                    Map<String, Long> map = (Map<String, Long>) updatedAtObj;
                    if (map.containsKey("_seconds") && map.containsKey("_nanoseconds")) {
                        updatedAt = Timestamp.ofTimeSecondsAndNanos(map.get("_seconds"), map.get("_nanoseconds").intValue());
                    }
                }

                LeaveApplication leave = new LeaveApplication(
                    id, retrievedUserId, studentName, institutionIdFromDoc, leaveType, startDate, endDate, reason,
                    professorId, professorName, status, rejectionReason, createdAt, updatedAt
                );
                leave.setDocumentUrl(documentUrl);
                result.add(leave);
            }
        }
        return result;
    }

    private String getProfessorNameDirectly(String institutionId, String professorId) {
        try {
            DocumentSnapshot professorDoc = firestore.collection("Institutions")
                    .document(institutionId)
                    .collection("users")
                    .document(professorId)
                    .get()
                    .get();

            if (professorDoc.exists()) {
                String displayName = professorDoc.getString("displayName");
                logger.info("Got professor name directly: {}", displayName);
                return displayName != null ? displayName : "Unknown Professor";
            }
        } catch (Exception e) {
            logger.error("Error getting professor name directly: {}", e.getMessage());
        }
        return "Unknown Professor";
    }

    public byte[] downloadLeaveDocument(String leaveId, String fileName) throws IOException {
        // String filePath = String.format("uploads/*/leaves/%s/%s", leaveId, fileName); // Removed unused variable
        // Since we don't know the institutionId, search for the file
        java.io.File uploadsDir = new java.io.File("uploads");
        
        if (uploadsDir.exists()) {
            for (java.io.File institutionDir : uploadsDir.listFiles()) {
                if (institutionDir.isDirectory()) {
                    java.io.File leavesDir = new java.io.File(institutionDir, "leaves");
                    if (leavesDir.exists()) {
                        java.io.File leaveDir = new java.io.File(leavesDir, leaveId);
                        if (leaveDir.exists()) {
                            java.io.File file = new java.io.File(leaveDir, fileName);
                            if (file.exists()) {
                                logger.info("Downloading file: {}", file.getAbsolutePath());
                                return Files.readAllBytes(file.toPath());
                            }
                        }
                    }
                }
            }
        }
        
        throw new IOException("File not found: " + fileName);
    }
}