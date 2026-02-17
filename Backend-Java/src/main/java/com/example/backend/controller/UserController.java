package com.example.backend.controller;

import com.example.backend.models.User;
import com.example.backend.service.UserService;
import com.google.firebase.auth.FirebaseToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/users")
public class UserController {

    private final UserService userService;
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<?> getMe(@PathVariable String institutionId, Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body("User not authenticated.");
        }
        
        FirebaseToken firebaseToken = (FirebaseToken) authentication.getPrincipal();
        String userId = firebaseToken.getUid();
        logger.info("UserController: /me endpoint called for user UID: {}", userId);
        
        try {
            User user = userService.getUserById(institutionId, userId);
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.status(404).body("User not found in Firestore.");
            }
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            logger.error("Error fetching user details for UID: {}", userId, e);
            return ResponseEntity.status(500).body("Error fetching user details: " + e.getMessage());
        }
    }
}
