package com.example.backend.controller;

import com.example.backend.models.Event;
import com.example.backend.models.User;
import com.example.backend.service.EventService;
import com.example.backend.service.UserService;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class EventController {

    private final EventService eventService;
    private final UserService userService;
    private final FirebaseAuth firebaseAuth;

    public EventController(EventService eventService, UserService userService, FirebaseAuth firebaseAuth) {
        this.eventService = eventService;
        this.userService = userService;
        this.firebaseAuth = firebaseAuth;
    }

    @GetMapping("/events/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("Event Controller is active");
    }

    @PostMapping("/institutions/{institutionId}/events")
    public ResponseEntity<?> createEvent(
            @PathVariable String institutionId,
            @RequestBody Event event,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");

            event.setCreatedBy(userId);
            event.setInstitutionId(institutionId);
            
            Event created = eventService.createEvent(institutionId, event);
            return ResponseEntity.status(201).body(created);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/events/audience")
    public ResponseEntity<?> getEventsForAudience(
            @PathVariable String institutionId,
            @RequestParam(required = false) String userRole,
            @RequestParam(required = false) String departmentId,
            @RequestParam(required = false) String programme,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            
            String effectiveDept = departmentId;
            String effectiveProg = programme;
            
            if (userId != null && (effectiveDept == null || effectiveDept.isEmpty())) {
                User user = userService.getUserById(institutionId, userId);
                if (user != null) {
                    effectiveDept = user.getDepartmentId();
                    effectiveProg = user.getProgramme();
                }
            }

            List<Event> events = eventService.getEventsForAudience(institutionId, userRole, effectiveDept, effectiveProg);
            return ResponseEntity.ok(events);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/events/manage")
    public ResponseEntity<?> getAllEventsForManagement(
            @PathVariable String institutionId,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");
            
            // Note: In production, add a role check here to ensure only ADMIN/FACULTY access this
            List<Event> events = eventService.getAllEventsForManagement(institutionId);
            return ResponseEntity.ok(events);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/events/{eventId}")
    public ResponseEntity<?> getEventById(@PathVariable String institutionId, @PathVariable String eventId) {
        try {
            Event event = eventService.getEventById(institutionId, eventId);
            if (event == null) return ResponseEntity.status(404).body("Event not found");
            return ResponseEntity.ok(event);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @PostMapping("/institutions/{institutionId}/events/{eventId}/register")
    public ResponseEntity<?> registerForEvent(
            @PathVariable String institutionId,
            @PathVariable String eventId,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");

            User user = userService.getUserById(institutionId, userId);
            if (user == null) return ResponseEntity.status(404).body("User not found");

            eventService.registerForEvent(institutionId, eventId, user);
            return ResponseEntity.ok(Map.of("message", "Successfully registered for event"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(400).body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("message", "Internal server error: " + e.getMessage()));
        }
    }

    @PatchMapping("/institutions/{institutionId}/events/{eventId}/status")
    public ResponseEntity<?> updateEventStatus(
            @PathVariable String institutionId,
            @PathVariable String eventId,
            @RequestParam String status,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");

            eventService.updateEventStatus(institutionId, eventId, status, userId);
            return ResponseEntity.ok(Map.of("message", "Event status updated to " + status));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/events/{eventId}/participants")
    public ResponseEntity<?> getParticipants(
            @PathVariable String institutionId,
            @PathVariable String eventId,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");
            
            // In a real scenario, check if userId is the organizer or admin
            return ResponseEntity.ok(eventService.getRegistrationsForEvent(institutionId, eventId));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/events/my-registrations")
    public ResponseEntity<?> getMyRegistrations(
            @PathVariable String institutionId,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");
            
            return ResponseEntity.ok(eventService.getEventsForUser(institutionId, userId));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @PostMapping("/institutions/{institutionId}/events/{eventId}/attendance")
    public ResponseEntity<?> markAttendance(
            @PathVariable String institutionId,
            @PathVariable String eventId,
            @RequestBody Map<String, Object> payload,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");
            
            String studentId = (String) payload.get("studentId");
            boolean present = (Boolean) payload.get("present");
            
            eventService.markAttendance(institutionId, eventId, studentId, present);
            return ResponseEntity.ok(Map.of("message", "Attendance updated"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    private String extractUserIdFromToken(String authHeader) {
        try {
            if (authHeader == null || !authHeader.startsWith("Bearer ")) return null;
            String token = authHeader.substring(7);
            FirebaseToken decodedToken = firebaseAuth.verifyIdToken(token);
            return decodedToken.getUid();
        } catch (Exception e) {
            return null;
        }
    }
}
