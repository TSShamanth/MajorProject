package com.example.backend.controller;

import com.example.backend.dto.CreateUserRequest;
import com.example.backend.models.AttendanceLog;
import com.example.backend.models.User;
import com.example.backend.service.ClockService;
import com.example.backend.service.UserService;
import com.google.firebase.auth.UserRecord;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
// import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final UserService userService;
    private final ClockService clockService;
    private static final Logger logger = LoggerFactory.getLogger(AdminController.class);

    public AdminController(UserService userService, ClockService clockService) {
        this.userService = userService;
        this.clockService = clockService;
    }

    @PostMapping("/institutions/{institutionId}/users")
    public ResponseEntity<?> createUser(
            @AuthenticationPrincipal String requesterUid,
            @RequestBody CreateUserRequest createUserRequest, 
            @PathVariable String institutionId) {
        try {
            logger.info("AdminController: createUser called by UID: {} for institution: {}", requesterUid, institutionId);
            User requestingUser = userService.getUserById(institutionId, requesterUid);
            if (requestingUser == null || !"admin".equalsIgnoreCase(requestingUser.getRole())) {
                logger.warn("AdminController: Requester UID {} not found or not an admin in Firestore for institution {}", requesterUid, institutionId);
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied: Admin user not found or insufficient privileges.");
            }

            // Ensure the institutionId in the request body matches the path variable
            if (!institutionId.equals(createUserRequest.getInstitutionId())) {
                return ResponseEntity.badRequest().body("Institution ID in path and body do not match.");
            }
            UserRecord userRecord = userService.createUser(createUserRequest);
            return ResponseEntity.ok("Successfully created user: " + userRecord.getUid());
        } catch (Exception e) {
            logger.error("Error creating user", e);
            return ResponseEntity.status(500).body("Error creating user: " + e.getMessage());
        }
    }

    @GetMapping("/users")
    public ResponseEntity<?> getUsers(
            @AuthenticationPrincipal String uid,
            @RequestParam String institutionId,
            @RequestParam(required = false) String role) {
        try {
            logger.info("AdminController: getUsers called by UID: {} for institution: {}", uid, institutionId);
            if (uid == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication token missing or invalid.");
            }
            User requestingUser = userService.getUserById(institutionId, uid);
            if (requestingUser == null) {
                logger.warn("AdminController: Requester UID {} not found in Firestore for institution {}", uid, institutionId);
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied: User record not found for this institution.");
            }
            
            // Relaxed check: Allow any authenticated user belonging to the institution to list users
            List<User> users = userService.getUsers(institutionId, role);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            logger.error("Error in getUsers", e);
            return ResponseEntity.status(500).body("Internal server error: " + e.getMessage());
        }
    }

    @GetMapping("/users/{targetUid}")
    public ResponseEntity<?> getUserById(
            @AuthenticationPrincipal String requesterUid,
            @PathVariable String targetUid,
            @RequestParam String institutionId) {
        try {
            logger.info("AdminController: getUserById called by requester UID: {} for target UID: {} in institution: {}", requesterUid, targetUid, institutionId);
            User requestingUser = userService.getUserById(institutionId, requesterUid);
            if (requestingUser == null) {
                logger.warn("AdminController: Requester UID {} not found in Firestore for institution {}", requesterUid, institutionId);
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied: User record not found for this institution.");
            }

            // Relaxed check: Allow users to see details of others in the same institution
            User user = userService.getUserById(institutionId, targetUid);
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found.");
            }
        } catch (Exception e) {
            logger.error("Error in getUserById", e);
            return ResponseEntity.status(500).body("Internal server error: " + e.getMessage());
        }
    }

    @PutMapping("/users/{targetUid}")
    public ResponseEntity<?> updateUser(
            @AuthenticationPrincipal String requesterUid,
            @PathVariable String targetUid,
            @RequestParam String institutionId,
            @RequestBody User updates) {
        try {
            logger.info("AdminController: updateUser called by requester UID: {} for target UID: {} in institution: {}", requesterUid, targetUid, institutionId);
            User requestingUser = userService.getUserById(institutionId, requesterUid);
            if (requestingUser == null || !"admin".equalsIgnoreCase(requestingUser.getRole())) {
                logger.warn("AdminController: Unauthorized access attempt by UID: {}", requesterUid);
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied: Admin user not found or insufficient privileges.");
            }

            userService.updateUser(institutionId, targetUid, updates);
            return ResponseEntity.ok("User updated successfully.");
        } catch (Exception e) {
            logger.error("Error in updateUser", e);
            return ResponseEntity.status(500).body("Internal server error: " + e.getMessage());
        }
    }

    @GetMapping("/users/{facultyId}/attendance-history")
    public ResponseEntity<?> getAttendanceHistoryForFaculty(
            @AuthenticationPrincipal String requesterUid,
            @PathVariable String facultyId,
            @RequestParam String institutionId) {
        try {
            logger.info("AdminController: getAttendanceHistoryForFaculty called by requester UID: {} for faculty UID: {} in institution: {}", requesterUid, facultyId, institutionId);
            User requestingUser = userService.getUserById(institutionId, requesterUid);
            if (requestingUser == null || !"admin".equalsIgnoreCase(requestingUser.getRole())) {
                logger.warn("AdminController: Unauthorized access attempt by UID: {}", requesterUid);
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied: Admin user not found or insufficient privileges.");
            }

            List<AttendanceLog> history = clockService.getAttendanceHistory(institutionId, facultyId);
            return ResponseEntity.ok(history);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            logger.error("Error in getAttendanceHistoryForFaculty", e);
            return ResponseEntity.status(500).body("Internal server error.");
        }
    }
}
