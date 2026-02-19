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

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final UserService userService;
    private final ClockService clockService;

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
            User requestingUser = userService.getUserById(institutionId, requesterUid);
            if (requestingUser == null || !"admin".equals(requestingUser.getRole())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }

            // Ensure the institutionId in the request body matches the path variable
            if (!institutionId.equals(createUserRequest.getInstitutionId())) {
                return ResponseEntity.badRequest().body("Institution ID in path and body do not match.");
            }
            UserRecord userRecord = userService.createUser(createUserRequest);
            return ResponseEntity.ok("Successfully created user: " + userRecord.getUid());
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error creating user: " + e.getMessage());
        }
    }

    @GetMapping("/users")
    public ResponseEntity<List<User>> getUsers(
            @AuthenticationPrincipal String uid,
            @RequestParam String institutionId,
            @RequestParam(required = false) String role) {
        try {
            User requestingUser = userService.getUserById(institutionId, uid);
            if (requestingUser == null || !"admin".equals(requestingUser.getRole())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
            List<User> users = userService.getUsers(institutionId, role);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/users/{targetUid}")
    public ResponseEntity<User> getUserById(
            @AuthenticationPrincipal String requesterUid,
            @PathVariable String targetUid,
            @RequestParam String institutionId) {
        try {
            User requestingUser = userService.getUserById(institutionId, requesterUid);
            if (requestingUser == null || !"admin".equals(requestingUser.getRole())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }

            User user = userService.getUserById(institutionId, targetUid);
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.status(404).build();
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/users/{targetUid}")
    public ResponseEntity<?> updateUser(
            @AuthenticationPrincipal String requesterUid,
            @PathVariable String targetUid,
            @RequestParam String institutionId,
            @RequestBody User updates) {
        try {
            User requestingUser = userService.getUserById(institutionId, requesterUid);
            if (requestingUser == null || !"admin".equals(requestingUser.getRole())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }

            userService.updateUser(institutionId, targetUid, updates);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/users/{facultyId}/attendance-history")
    public ResponseEntity<List<AttendanceLog>> getAttendanceHistoryForFaculty(
            @AuthenticationPrincipal String requesterUid,
            @PathVariable String facultyId,
            @RequestParam String institutionId) {
        try {
            User requestingUser = userService.getUserById(institutionId, requesterUid);
            if (requestingUser == null || !"admin".equals(requestingUser.getRole())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }

            List<AttendanceLog> history = clockService.getAttendanceHistory(institutionId, facultyId);
            return ResponseEntity.ok(history);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).build();
        }
    }
}
