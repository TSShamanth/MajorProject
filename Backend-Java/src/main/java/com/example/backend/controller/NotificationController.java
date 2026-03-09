package com.example.backend.controller;

import com.example.backend.models.Notification;
import com.example.backend.service.NotificationService;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;
    private final FirebaseAuth firebaseAuth;

    public NotificationController(NotificationService notificationService, FirebaseAuth firebaseAuth) {
        this.notificationService = notificationService;
        this.firebaseAuth = firebaseAuth;
    }

    @GetMapping("/me")
    public ResponseEntity<?> getMyNotifications(
            @PathVariable String institutionId,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) {
                return ResponseEntity.status(401).body("Unauthorized");
            }
            List<Notification> notifications = notificationService.getNotifications(institutionId, userId);
            return ResponseEntity.ok(notifications);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error fetching notifications: " + e.getMessage());
        }
    }

    @PutMapping("/me/{notificationId}/read")
    public ResponseEntity<?> markAsRead(
            @PathVariable String institutionId,
            @PathVariable String notificationId,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) {
                return ResponseEntity.status(401).body("Unauthorized");
            }
            notificationService.markAsRead(institutionId, userId, notificationId);
            return ResponseEntity.ok().body("Marked as read");
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error updating notification: " + e.getMessage());
        }
    }

    private String extractUserIdFromToken(String authHeader) {
        try {
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return null;
            }

            String token = authHeader.substring(7);
            FirebaseToken decodedToken = firebaseAuth.verifyIdToken(token);
            return decodedToken.getUid();
        } catch (Exception e) {
            return null;
        }
    }
}
