package com.example.backend.controller;

import com.example.backend.dto.CreateUserRequest;
import com.example.backend.service.UserService;
import com.google.firebase.auth.UserRecord;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final UserService userService;

    @Autowired
    public AdminController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/users")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<?> createUser(@RequestBody CreateUserRequest createUserRequest) {
        try {
            UserRecord userRecord = userService.createUser(createUserRequest);
            return ResponseEntity.ok("Successfully created user: " + userRecord.getUid());
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error creating user: " + e.getMessage());
        }
    }

    @GetMapping("/users")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<?> getUsers(
            @RequestParam String institutionId,
            @RequestParam(required = false) String role) {
        try {
            List<Map<String, Object>> users = userService.getUsers(institutionId, role);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error fetching users: " + e.getMessage());
        }
    }

    @GetMapping("/users/{uid}")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<?> getUserById(
            @PathVariable String uid,
            @RequestParam String institutionId) {
        try {
            Map<String, Object> user = userService.getUserById(institutionId, uid);
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.status(404).body("User not found with ID: " + uid);
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error fetching user: " + e.getMessage());
        }
    }

    @PutMapping("/users/{uid}")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<?> updateUser(
            @PathVariable String uid,
            @RequestParam String institutionId,
            @RequestBody Map<String, Object> updates) {
        try {
            userService.updateUser(institutionId, uid, updates);
            return ResponseEntity.ok("User updated successfully: " + uid);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error updating user: " + e.getMessage());
        }
    }
}

