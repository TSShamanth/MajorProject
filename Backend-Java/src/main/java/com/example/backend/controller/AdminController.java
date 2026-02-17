package com.example.backend.controller;

import com.example.backend.dto.CreateUserRequest;
import com.example.backend.models.AttendanceLog;
import com.example.backend.models.User;
import com.example.backend.service.ClockService;
import com.example.backend.service.UserService;
import com.google.firebase.auth.UserRecord;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<?> createUser(@RequestBody CreateUserRequest createUserRequest, @PathVariable String institutionId) {
        try {
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
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<List<User>> getUsers(
            @RequestParam String institutionId,
            @RequestParam(required = false) String role) {
        try {
            List<User> users = userService.getUsers(institutionId, role);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/users/{uid}")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<User> getUserById(
            @PathVariable String uid,
            @RequestParam String institutionId) {
        try {
            User user = userService.getUserById(institutionId, uid);
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.status(404).build();
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/users/{uid}")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<?> updateUser(
            @PathVariable String uid,
            @RequestParam String institutionId,
            @RequestBody User updates) {
        try {
            userService.updateUser(institutionId, uid, updates);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/users/{facultyId}/attendance-history")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<List<AttendanceLog>> getAttendanceHistoryForFaculty(
            @PathVariable String facultyId,
            @RequestParam String institutionId) {
        try {
            List<AttendanceLog> history = clockService.getAttendanceHistory(institutionId, facultyId);
            return ResponseEntity.ok(history);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).build();
        }
    }
}
