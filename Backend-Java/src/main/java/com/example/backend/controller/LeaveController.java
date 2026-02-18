package com.example.backend.controller;

import com.example.backend.dto.LeaveApplicationDto;
import com.example.backend.models.LeaveApplication;
import com.example.backend.service.LeaveService;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.MediaType;
import org.springframework.http.HttpHeaders;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/leaves")
public class LeaveController {

    private final LeaveService leaveService;
    private static final Logger logger = LoggerFactory.getLogger(LeaveController.class);

    public LeaveController(LeaveService leaveService) {
        this.leaveService = leaveService;
    }

    @PostMapping("/apply")
    public ResponseEntity<?> applyLeave(
            @PathVariable String institutionId,
            @RequestHeader(name = "Authorization") String idToken,
            @RequestParam(value = "leaveType", required = true) String leaveType,
            @RequestParam(value = "startDate", required = true) String startDate,
            @RequestParam(value = "endDate", required = true) String endDate,
            @RequestParam(value = "reason", required = true) String reason,
            @RequestParam(value = "professorId", required = true) String professorId,
            @RequestParam(value = "file", required = false) MultipartFile file) {
        String userId;
        try {
            userId = FirebaseAuth.getInstance().verifyIdToken(idToken.substring(7)).getUid();
        } catch (FirebaseAuthException e) {
            logger.error("Auth error: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid or expired token");
        }

        logger.info("LeaveController: /apply endpoint called for user UID: {} in institution: {}", userId, institutionId);
        logger.info("Request params - leaveType: {}, startDate: {}, endDate: {}, reason: {}, professorId: {}, hasFile: {}", 
            leaveType, startDate, endDate, reason, professorId, file != null);

        try {
            // Create DTO from multipart request parameters
            LeaveApplicationDto leaveApplicationDto = new LeaveApplicationDto();
            leaveApplicationDto.setLeaveType(leaveType);
            leaveApplicationDto.setStartDate(startDate);
            leaveApplicationDto.setEndDate(endDate);
            leaveApplicationDto.setReason(reason);
            leaveApplicationDto.setProfessorId(professorId);
            
            logger.info("Created LeaveApplicationDto successfully");
            
            // Call service with file
            LeaveApplication newLeaveApplication = leaveService.applyLeave(
                    institutionId, userId, leaveApplicationDto, file);
            
            logger.info("Leave application created successfully with ID: {}", newLeaveApplication.getId());
            return ResponseEntity.ok(newLeaveApplication);
        } catch (ExecutionException | InterruptedException e) {
            logger.error("ExecutionException/InterruptedException applying for leave for user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.status(500).body("Error applying for leave: " + e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected exception applying for leave for user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.status(500).body("Unexpected error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
        }
    }

    @GetMapping("/history/me")
    public ResponseEntity<?> getLeaveHistory(
            @PathVariable String institutionId,
            @RequestHeader(name = "Authorization") String idToken) {
        String userId;
        try {
            userId = FirebaseAuth.getInstance().verifyIdToken(idToken.substring(7)).getUid();
        } catch (FirebaseAuthException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid or expired token");
        }

        logger.info("LeaveController: /history/me endpoint called for user UID: {} in institution: {}", userId, institutionId);

        try {
            List<LeaveApplication> leaveHistory = leaveService.getLeaveHistory(institutionId, userId);
            return ResponseEntity.ok(leaveHistory);
        } catch (ExecutionException | InterruptedException e) {
            logger.error("Error fetching leave history for user {}: {}", userId, e.getMessage());
            return ResponseEntity.status(500).body("Error fetching leave history: " + e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error fetching leave history for user {}: {}", userId, e.getMessage());
            return ResponseEntity.status(500).body("Unexpected error fetching leave history: " + e.getMessage());
        }
    }

    @GetMapping("/types")
    public ResponseEntity<?> getLeaveTypes(@PathVariable String institutionId) {
        logger.info("LeaveController: /types endpoint called for institution: {}", institutionId);
        try {
            List<String> leaveTypes = leaveService.getLeaveTypes();
            return ResponseEntity.ok(leaveTypes);
        } catch (Exception e) {
            logger.error("Error fetching leave types for institution {}: {}", institutionId, e.getMessage());
            return ResponseEntity.status(500).body("Error fetching leave types: " + e.getMessage());
        }
    }

    @GetMapping("/professors")
    public ResponseEntity<?> getProfessors(
            @PathVariable String institutionId,
            @RequestHeader(name = "Authorization") String idToken) {
        try {
            FirebaseAuth.getInstance().verifyIdToken(idToken.substring(7)).getUid(); // Verify token
        } catch (FirebaseAuthException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid or expired token");
        }

        logger.info("LeaveController: /professors endpoint called for institution: {}", institutionId);
        try {
            List<com.example.backend.dto.ProfessorDto> professors = leaveService.getProfessors(institutionId);
            return ResponseEntity.ok(professors);
        } catch (ExecutionException | InterruptedException e) {
            logger.error("Error fetching professors for institution {}: {}", institutionId, e.getMessage());
            return ResponseEntity.status(500).body("Error fetching professors: " + e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error fetching professors for institution {}: {}", institutionId, e.getMessage());
            return ResponseEntity.status(500).body("Unexpected error fetching professors: " + e.getMessage());
        }
    }

    @GetMapping("/faculty/me/pending")
    public ResponseEntity<?> getPendingLeaveApplicationsForFaculty(
            @PathVariable String institutionId,
            @RequestHeader(name = "Authorization") String idToken) {
        String facultyId;
        try {
            facultyId = FirebaseAuth.getInstance().verifyIdToken(idToken.substring(7)).getUid();
        } catch (FirebaseAuthException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid or expired token");
        }

        logger.info("LeaveController: /faculty/me/pending endpoint called for faculty UID: {} in institution: {}", facultyId, institutionId);

        try {
            List<LeaveApplication> pendingLeaves = leaveService.getPendingLeaveApplicationsForFaculty(institutionId, facultyId);
            return ResponseEntity.ok(pendingLeaves);
        } catch (ExecutionException | InterruptedException e) {
            logger.error("Error fetching pending leave applications for faculty {}: {}", facultyId, e.getMessage());
            return ResponseEntity.status(500).body("Error fetching pending leave applications: " + e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error fetching pending leave applications for faculty {}: {}", facultyId, e.getMessage());
            return ResponseEntity.status(500).body("Unexpected error fetching pending leave applications: " + e.getMessage());
        }
    }

    @PostMapping("/{leaveId}/approve")
    public ResponseEntity<?> approveLeaveApplication(
            @PathVariable String institutionId,
            @PathVariable String leaveId,
            @RequestHeader(name = "Authorization") String idToken) {
        String facultyId;
        try {
            facultyId = FirebaseAuth.getInstance().verifyIdToken(idToken.substring(7)).getUid();
        } catch (FirebaseAuthException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid or expired token");
        }

        logger.info("LeaveController: /{}/approve endpoint called for faculty UID: {} to approve leave ID: {} in institution: {}", leaveId, facultyId, leaveId, institutionId);

        try {
            leaveService.approveLeaveApplication(institutionId, leaveId, facultyId);
            return ResponseEntity.ok("Leave application approved successfully.");
        } catch (IllegalArgumentException e) {
            logger.warn("Authorization or data error approving leave ID {}: {}", leaveId, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (ExecutionException | InterruptedException e) {
            logger.error("Error approving leave ID {} for faculty {}: {}", leaveId, facultyId, e.getMessage());
            return ResponseEntity.status(500).body("Error approving leave application: " + e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error approving leave ID {} for faculty {}: {}", leaveId, facultyId, e.getMessage());
            return ResponseEntity.status(500).body("Unexpected error approving leave application: " + e.getMessage());
        }
    }

    @PostMapping("/{leaveId}/reject")
    public ResponseEntity<?> rejectLeaveApplication(
            @PathVariable String institutionId,
            @PathVariable String leaveId,
            @RequestHeader(name = "Authorization") String idToken,
            @RequestBody(required = false) Map<String, String> requestBody) { // reason is optional
        String facultyId;
        try {
            facultyId = FirebaseAuth.getInstance().verifyIdToken(idToken.substring(7)).getUid();
        } catch (FirebaseAuthException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid or expired token");
        }

        String rejectionReason = requestBody != null ? requestBody.getOrDefault("reason", "") : "";

        logger.info("LeaveController: /{}/reject endpoint called for faculty UID: {} to reject leave ID: {} in institution: {} with reason: {}", leaveId, facultyId, leaveId, institutionId, rejectionReason);

        try {
            leaveService.rejectLeaveApplication(institutionId, leaveId, facultyId, rejectionReason);
            return ResponseEntity.ok("Leave application rejected successfully.");
        } catch (IllegalArgumentException e) {
            logger.warn("Authorization or data error rejecting leave ID {}: {}", leaveId, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (ExecutionException | InterruptedException e) {
            logger.error("Error rejecting leave ID {} for faculty {}: {}", leaveId, facultyId, e.getMessage());
            return ResponseEntity.status(500).body("Error rejecting leave application: " + e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error rejecting leave ID {} for faculty {}: {}", leaveId, facultyId, e.getMessage());
            return ResponseEntity.status(500).body("Unexpected error rejecting leave application: " + e.getMessage());
        }
    }

    @GetMapping("/faculty/me/history")
    public ResponseEntity<?> getFacultyLeaveHistory(
            @PathVariable String institutionId,
            @RequestHeader(name = "Authorization") String idToken) {
        String facultyId;
        try {
            facultyId = FirebaseAuth.getInstance().verifyIdToken(idToken.substring(7)).getUid();
        } catch (FirebaseAuthException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid or expired token");
        }

        logger.info("LeaveController: /faculty/me/history endpoint called for faculty UID: {} in institution: {}", facultyId, institutionId);

        try {
            List<LeaveApplication> leaveHistory = leaveService.getFacultyLeaveHistory(institutionId, facultyId);
            return ResponseEntity.ok(leaveHistory);
        } catch (ExecutionException | InterruptedException e) {
            logger.error("Error fetching faculty leave history for faculty {}: {}", facultyId, e.getMessage());
            return ResponseEntity.status(500).body("Error fetching faculty leave history: " + e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error fetching faculty leave history for faculty {}: {}", facultyId, e.getMessage());
            return ResponseEntity.status(500).body("Unexpected error fetching faculty leave history: " + e.getMessage());
        }
    }

    @GetMapping("/{leaveId}/download/{fileName}")
    public ResponseEntity<?> downloadLeaveDocument(
            @PathVariable String leaveId,
            @PathVariable String fileName) {
        logger.info("Download request for leaveId: {}, fileName: {}", leaveId, fileName);
        
        try {
            byte[] fileContent = leaveService.downloadLeaveDocument(leaveId, fileName);
            
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                    .body(fileContent);
        } catch (Exception e) {
            logger.error("Error downloading document for leaveId {}: {}", leaveId, e.getMessage(), e);
            return ResponseEntity.status(404).body("Document not found: " + e.getMessage());
        }
    }

    // private String getContentType(String fileName) {
    //     if (fileName.endsWith(".pdf")) {
    //         return "application/pdf";
    //     } else if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")) {
    //         return "image/jpeg";
    //     } else if (fileName.endsWith(".png")) {
    //         return "image/png";
    //     } else if (fileName.endsWith(".doc")) {
    //         return "application/msword";
    //     } else if (fileName.endsWith(".docx")) {
    //         return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    //     } else {
    //         return "application/octet-stream";
    //     }
    // }
}
