package com.example.backend.controller;

import com.example.backend.dto.ClockRequest;
import com.example.backend.models.User;
import com.example.backend.service.ClockService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/attendance")
public class ClockController {

    private final ClockService clockService;

    public ClockController(ClockService clockService) {
        this.clockService = clockService;
    }

    @PostMapping("/clock-in")
    public ResponseEntity<?> clockIn(@PathVariable String institutionId, @RequestBody ClockRequest clockRequest, Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body("User not authenticated.");
        }
        try {
            String facultyId = (String) authentication.getPrincipal();
            User updatedUser = clockService.clockIn(institutionId, facultyId, clockRequest);
            return ResponseEntity.ok(updatedUser);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error during clock-in: " + e.getMessage());
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/clock-out")
    public ResponseEntity<?> clockOut(@PathVariable String institutionId, @RequestBody ClockRequest clockRequest, Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body("User not authenticated.");
        }
        try {
            String facultyId = (String) authentication.getPrincipal();
            User updatedUser = clockService.clockOut(institutionId, facultyId, clockRequest);
            return ResponseEntity.ok(updatedUser);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error during clock-out: " + e.getMessage());
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/history")
    public ResponseEntity<?> getAttendanceHistory(@PathVariable String institutionId, Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body("User not authenticated.");
        }
        try {
            String facultyId = (String) authentication.getPrincipal();
            java.util.List<com.example.backend.models.AttendanceLog> history = clockService.getAttendanceHistory(institutionId, facultyId);
            return ResponseEntity.ok(history);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error fetching attendance history: " + e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
