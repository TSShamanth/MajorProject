package com.example.backend.controller;

import com.example.backend.models.Company;
import com.example.backend.models.PlacementDrive;
import com.example.backend.models.PlacementApplication;
import com.example.backend.models.InterviewSlot;
import com.example.backend.service.PlacementService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/institutions/{institutionId}/placement")
public class PlacementController {

    private final PlacementService placementService;

    public PlacementController(PlacementService placementService) {
        this.placementService = placementService;
    }

    // --- Interviews ---

    @GetMapping("/interviews")
    public ResponseEntity<List<InterviewSlot>> getInterviews(@PathVariable String institutionId) {
        try {
            return ResponseEntity.ok(placementService.getInterviewSlots(institutionId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PostMapping("/interviews")
    public ResponseEntity<InterviewSlot> createInterview(@PathVariable String institutionId, @RequestBody InterviewSlot slot) {
        try {
            return ResponseEntity.ok(placementService.createInterviewSlot(institutionId, slot));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    // --- Companies ---

    @GetMapping("/companies")
    public ResponseEntity<List<Company>> getCompanies(@PathVariable String institutionId) {
        try {
            return ResponseEntity.ok(placementService.getCompanies(institutionId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PostMapping("/companies")
    public ResponseEntity<Company> createCompany(@PathVariable String institutionId, @RequestBody Company company) {
        try {
            return ResponseEntity.ok(placementService.createCompany(institutionId, company));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    // --- Placement Drives ---

    @GetMapping("/drives")
    public ResponseEntity<List<PlacementDrive>> getDrives(@PathVariable String institutionId) {
        try {
            return ResponseEntity.ok(placementService.getDrives(institutionId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PostMapping("/drives")
    public ResponseEntity<PlacementDrive> createDrive(@PathVariable String institutionId, @RequestBody PlacementDrive drive) {
        try {
            return ResponseEntity.ok(placementService.createDrive(institutionId, drive));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    // --- Applications ---

    @GetMapping("/applications")
    public ResponseEntity<List<PlacementApplication>> getApplications(
            @PathVariable String institutionId, 
            @RequestParam(required = false) String driveId) {
        try {
            return ResponseEntity.ok(placementService.getApplications(institutionId, driveId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PatchMapping("/applications/{applicationId}")
    public ResponseEntity<PlacementApplication> updateApplication(
            @PathVariable String institutionId, 
            @PathVariable String applicationId, 
            @RequestBody Map<String, Object> updates) {
        try {
            return ResponseEntity.ok(placementService.updateApplication(institutionId, applicationId, updates));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    // --- Stats ---

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats(@PathVariable String institutionId) {
        try {
            return ResponseEntity.ok(placementService.getPlacementStats(institutionId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
