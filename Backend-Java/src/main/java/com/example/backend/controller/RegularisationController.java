package com.example.backend.controller;

import com.example.backend.dto.RegularisationRequestDTO;
import com.example.backend.models.RegularisationRequest;
import com.example.backend.service.RegularisationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
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
    @PreAuthorize("hasRole('FACULTY')")
    public ResponseEntity<?> createRegularisationRequest(
            @RequestParam String institutionId, 
            @RequestBody RegularisationRequestDTO requestDTO, 
            @AuthenticationPrincipal String facultyId) {
        try {
            RegularisationRequest request = regularisationService.createRegularisationRequest(institutionId, facultyId, requestDTO);
            return ResponseEntity.ok(request);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error creating regularisation request: " + e.getMessage());
        }
    }

    @GetMapping("/requests/me")
    @PreAuthorize("hasRole('FACULTY')")
    public ResponseEntity<?> getMyRegularisationRequests(@RequestParam String institutionId, @AuthenticationPrincipal String facultyId) {
        try {
            List<RegularisationRequest> requests = regularisationService.getRegularisationRequestsForFaculty(institutionId, facultyId);
            return ResponseEntity.ok(requests);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error fetching regularisation requests: " + e.getMessage());
        }
    }

    @GetMapping("/admin/requests")
    @PreAuthorize("hasAnyRole('ADMIN', 'HR_ADMIN')")
    public ResponseEntity<?> getPendingRequests(@RequestParam String institutionId) {
        try {
            List<RegularisationRequest> requests = regularisationService.getPendingRegularisationRequests(institutionId);
            return ResponseEntity.ok(requests);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error fetching pending requests: " + e.getMessage());
        }
    }

    @PostMapping("/admin/requests/{requestId}/approve")
    @PreAuthorize("hasAnyRole('ADMIN', 'HR_ADMIN')")
    public ResponseEntity<?> approveRequest(@RequestParam String institutionId, @PathVariable String requestId, @AuthenticationPrincipal String adminId) {
        try {
            RegularisationRequest request = regularisationService.approveRegularisationRequest(institutionId, requestId, adminId);
            return ResponseEntity.ok(request);
        } catch (ExecutionException | InterruptedException | ParseException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error approving request: " + e.getMessage());
        }
    }

    @PostMapping("/admin/requests/{requestId}/deny")
    @PreAuthorize("hasAnyRole('ADMIN', 'HR_ADMIN')")
    public ResponseEntity<?> denyRequest(@RequestParam String institutionId, @PathVariable String requestId, @AuthenticationPrincipal String adminId) {
        try {
            RegularisationRequest request = regularisationService.denyRegularisationRequest(institutionId, requestId, adminId);
            return ResponseEntity.ok(request);
        } catch (ExecutionException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(500).body("Error denying request: " + e.getMessage());
        }
    }
}
