package com.example.backend.controller;

import com.example.backend.dto.RegularisationRequestDTO;
import com.example.backend.models.RegularisationRequest;
import com.example.backend.service.RegularisationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.text.ParseException;
import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/regularisation")
public class RegularisationController {

    private final RegularisationService regularisationService;

    public RegularisationController(RegularisationService regularisationService) {
        this.regularisationService = regularisationService;
    }

    @PostMapping("/request")
    public ResponseEntity<?> createRegularisationRequest(@RequestParam String institutionId, @RequestBody RegularisationRequestDTO requestDTO, Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body("User not authenticated.");
        }
        String facultyId = (String) authentication.getPrincipal();
        try {
            RegularisationRequest request = regularisationService.createRegularisationRequest(institutionId, facultyId, requestDTO);
            return ResponseEntity.ok(request);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error creating regularisation request: " + e.getMessage());
        }
    }

    @GetMapping("/requests/me")
    public ResponseEntity<?> getMyRegularisationRequests(@RequestParam String institutionId, Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body("User not authenticated.");
        }
        String facultyId = (String) authentication.getPrincipal();
        try {
            List<RegularisationRequest> requests = regularisationService.getRegularisationRequestsForFaculty(institutionId, facultyId);
            return ResponseEntity.ok(requests);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error fetching regularisation requests: " + e.getMessage());
        }
    }

    @GetMapping("/admin/requests")
    public ResponseEntity<?> getPendingRequests(@RequestParam String institutionId, Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body("User not authenticated.");
        }
        String uid = (String) authentication.getPrincipal();
        try {
            com.example.backend.models.User requestingUser = regularisationService.getUserById(institutionId, uid);
            if (requestingUser == null || !"admin".equalsIgnoreCase(requestingUser.getRole())) {
                return ResponseEntity.status(403).body("Access denied: Requires admin role.");
            }
            List<RegularisationRequest> requests = regularisationService.getPendingRegularisationRequests(institutionId);
            return ResponseEntity.ok(requests);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error fetching pending requests: " + e.getMessage());
        }
    }

    @PostMapping("/admin/requests/{requestId}/approve")
    public ResponseEntity<?> approveRequest(@RequestParam String institutionId, @PathVariable String requestId, Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body("User not authenticated.");
        }
        String adminId = (String) authentication.getPrincipal();
        try {
            com.example.backend.models.User requestingUser = regularisationService.getUserById(institutionId, adminId);
            if (requestingUser == null || !"admin".equalsIgnoreCase(requestingUser.getRole())) {
                return ResponseEntity.status(403).body("Access denied: Requires admin role.");
            }
            RegularisationRequest request = regularisationService.approveRegularisationRequest(institutionId, requestId, adminId);
            return ResponseEntity.ok(request);
        } catch (ExecutionException | InterruptedException | ParseException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error approving request: " + e.getMessage());
        }
    }

    @PostMapping("/admin/requests/{requestId}/deny")
    public ResponseEntity<?> denyRequest(@RequestParam String institutionId, @PathVariable String requestId, Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).body("User not authenticated.");
        }
        String adminId = (String) authentication.getPrincipal();
        try {
            com.example.backend.models.User requestingUser = regularisationService.getUserById(institutionId, adminId);
            if (requestingUser == null || !"admin".equalsIgnoreCase(requestingUser.getRole())) {
                return ResponseEntity.status(403).body("Access denied: Requires admin role.");
            }
            RegularisationRequest request = regularisationService.denyRegularisationRequest(institutionId, requestId, adminId);
            return ResponseEntity.ok(request);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error denying request: " + e.getMessage());
        }
    }
}
