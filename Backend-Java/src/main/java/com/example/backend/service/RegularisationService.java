package com.example.backend.service;

import com.example.backend.dto.RegularisationRequestDTO;
import com.example.backend.models.AttendanceLog;
import com.example.backend.models.RegularisationRequest;
import com.example.backend.models.User;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Service;

import java.text.ParseException;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class RegularisationService {

    private final Firestore firestore;

    public RegularisationService(Firestore firestore) {
        this.firestore = firestore;
    }

    public User getUserById(String institutionId, String uid) throws ExecutionException, InterruptedException {
        DocumentReference userDocRef = firestore.collection("Institutions").document(institutionId).collection("users").document(uid);
        ApiFuture<DocumentSnapshot> documentSnapshot = userDocRef.get();
        DocumentSnapshot document = documentSnapshot.get();

        if (document.exists()) {
            User userData = document.toObject(User.class);
            if (userData != null) {
                userData.setUid(document.getId());
            }
            return userData;
        } else {
            return null;
        }
    }

    public RegularisationRequest createRegularisationRequest(String institutionId, String facultyId, RegularisationRequestDTO requestDTO) throws ExecutionException, InterruptedException {
        String requestId = UUID.randomUUID().toString();
        RegularisationRequest request = new RegularisationRequest();
        request.setId(requestId);
        request.setInstitutionId(institutionId);
        request.setFacultyId(facultyId);
        request.setRequestDate(new Date());
        request.setTargetDate(requestDTO.getTargetDate());
        request.setTargetTime(requestDTO.getTargetTime()); // For missed entry
        request.setType(requestDTO.getType()); // For missed entry
        request.setNewClockInTime(requestDTO.getNewClockInTime()); // For modifying existing log
        request.setNewClockOutTime(requestDTO.getNewClockOutTime()); // For modifying existing log
        request.setReason(requestDTO.getReason());
        request.setStatus("Pending");
        request.setAttendanceLogId(requestDTO.getAttendanceLogId());

        firestore.collection("Institutions").document(institutionId)
                .collection("regularisation_requests").document(requestId).set(request).get();

        return request;
    }

    public List<RegularisationRequest> getRegularisationRequestsForFaculty(String institutionId, String facultyId) throws ExecutionException, InterruptedException {
        List<RegularisationRequest> requests = new ArrayList<>();
        List<QueryDocumentSnapshot> documents = firestore.collection("Institutions").document(institutionId)
                .collection("regularisation_requests")
                .whereEqualTo("facultyId", facultyId)
                .orderBy("requestDate", Query.Direction.DESCENDING)
                .get().get().getDocuments();

        for (QueryDocumentSnapshot document : documents) {
            requests.add(document.toObject(RegularisationRequest.class));
        }
        return requests;
    }

    public List<RegularisationRequest> getPendingRegularisationRequests(String institutionId) throws ExecutionException, InterruptedException {
        List<RegularisationRequest> requests = new ArrayList<>();
        List<QueryDocumentSnapshot> documents = firestore.collection("Institutions").document(institutionId)
                .collection("regularisation_requests")
                .whereEqualTo("status", "Pending")
                .orderBy("requestDate", Query.Direction.ASCENDING)
                .get().get().getDocuments();

        for (QueryDocumentSnapshot document : documents) {
            requests.add(document.toObject(RegularisationRequest.class));
        }
        return requests;
    }

    public RegularisationRequest approveRegularisationRequest(String institutionId, String requestId, String adminId) throws ExecutionException, InterruptedException, ParseException {
        DocumentReference requestRef = firestore.collection("Institutions").document(institutionId)
                .collection("regularisation_requests").document(requestId);
        RegularisationRequest request = requestRef.get().get().toObject(RegularisationRequest.class);

        if (request == null) {
            throw new IllegalArgumentException("Regularisation request not found.");
        }
        if (!"Pending".equals(request.getStatus())) {
            throw new IllegalStateException("Request is not in pending state.");
        }

        request.setStatus("Approved");
        request.setApprovedBy(adminId);
        request.setApprovedOn(new Date());

        if (request.getAttendanceLogId() != null) { // Modifying an existing log
            DocumentReference logRef = firestore.collection("Institutions").document(institutionId)
                    .collection("attendance_logs").document(request.getAttendanceLogId());
            
            // Update clock-in time if provided
            if (request.getNewClockInTime() != null) {
                Date newClockInTime = combineDateAndTime(request.getTargetDate(), request.getNewClockInTime());
                logRef.update("clockInTime", newClockInTime).get();
            }

            // Update clock-out time if provided
            if (request.getNewClockOutTime() != null) {
                Date newClockOutTime = combineDateAndTime(request.getTargetDate(), request.getNewClockOutTime());
                logRef.update("clockOutTime", newClockOutTime).get();
            }
            logRef.update("regularisationStatus", "Regularised").get(); // Mark as regularised

            // Recalculate duration
            AttendanceLog updatedLog = logRef.get().get().toObject(AttendanceLog.class);
            if (updatedLog != null && updatedLog.getClockInTime() != null && updatedLog.getClockOutTime() != null) {
                long diffInMillis = Math.abs(updatedLog.getClockOutTime().getTime() - updatedLog.getClockInTime().getTime());
                long durationInMinutes = java.util.concurrent.TimeUnit.MINUTES.convert(diffInMillis, java.util.concurrent.TimeUnit.MILLISECONDS);
                logRef.update("duration", durationInMinutes).get();
            }

        } else { // Request for a missed entry
            if (request.getType() == null || request.getTargetTime() == null) {
                throw new IllegalArgumentException("Type and target time are required for missed entries.");
            }
            if ("Clock-in".equalsIgnoreCase(request.getType())) {
                String logId = UUID.randomUUID().toString();
                AttendanceLog log = new AttendanceLog();
                log.setId(logId);
                log.setFacultyId(request.getFacultyId());
                log.setInstitutionId(institutionId);
                log.setClockInTime(combineDateAndTime(request.getTargetDate(), request.getTargetTime()));
                log.setLocationStatus("On-Campus (Regularised)"); // Default status for regularised entry
                log.setRegularisationStatus("Regularised");
                firestore.collection("Institutions").document(institutionId)
                        .collection("attendance_logs").document(logId).set(log).get();
            } else if ("Clock-out".equalsIgnoreCase(request.getType())) {
                // Find the latest log without a clock-out time for that day.
                List<QueryDocumentSnapshot> logs = firestore.collection("Institutions").document(institutionId)
                        .collection("attendance_logs")
                        .whereEqualTo("facultyId", request.getFacultyId())
                        .whereEqualTo("clockOutTime", null)
                        .orderBy("clockInTime", Query.Direction.DESCENDING)
                        .limit(1)
                        .get().get().getDocuments();

                if (!logs.isEmpty()) {
                    DocumentReference logRef = logs.get(0).getReference();
                    Date newClockOutTime = combineDateAndTime(request.getTargetDate(), request.getTargetTime());
                    logRef.update("clockOutTime", newClockOutTime, "regularisationStatus", "Regularised").get();

                    // Recalculate duration
                    AttendanceLog updatedLog = logRef.get().get().toObject(AttendanceLog.class);
                    if (updatedLog != null && updatedLog.getClockInTime() != null && updatedLog.getClockOutTime() != null) {
                        long diffInMillis = Math.abs(updatedLog.getClockOutTime().getTime() - updatedLog.getClockInTime().getTime());
                        long durationInMinutes = java.util.concurrent.TimeUnit.MINUTES.convert(diffInMillis, java.util.concurrent.TimeUnit.MILLISECONDS);
                        logRef.update("duration", durationInMinutes).get();
                    }
                } else {
                    throw new IllegalStateException("No matching clock-in record found to regularise a clock-out.");
                }
            }
        }

        requestRef.set(request).get();
        return request;
    }

    public RegularisationRequest denyRegularisationRequest(String institutionId, String requestId, String adminId) throws ExecutionException, InterruptedException {
        DocumentReference requestRef = firestore.collection("Institutions").document(institutionId)
                .collection("regularisation_requests").document(requestId);
        RegularisationRequest request = requestRef.get().get().toObject(RegularisationRequest.class);

        if (request == null) {
            throw new IllegalArgumentException("Regularisation request not found.");
        }
        if (!"Pending".equals(request.getStatus())) {
            throw new IllegalStateException("Request is not in pending state.");
        }

        request.setStatus("Denied");
        request.setApprovedBy(adminId);
        request.setApprovedOn(new Date());

        requestRef.set(request).get();
        return request;
    }

    private Date combineDateAndTime(Date date, String time) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTime(date);
        String[] timeParts = time.split(":");
        calendar.set(Calendar.HOUR_OF_DAY, Integer.parseInt(timeParts[0]));
        calendar.set(Calendar.MINUTE, Integer.parseInt(timeParts[1]));
        return calendar.getTime();
    }
}
