package com.example.backend.controller;

import com.example.backend.service.AiPlacementService;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/ai/placement")
public class AiPlacementController {

    private final AiPlacementService aiPlacementService;

    public AiPlacementController(AiPlacementService aiPlacementService) {
        this.aiPlacementService = aiPlacementService;
    }

    private String getCurrentUserUid() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            return "anonymousUser"; 
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof FirebaseToken) {
            return ((FirebaseToken) principal).getUid();
        }
        return principal.toString();
    }

    @PostMapping("/resume-score/{driveId}")
    public Map<String, String> scoreResume(@RequestParam String institutionId, @PathVariable String driveId, @RequestParam("file") MultipartFile file) {
        String studentId = getCurrentUserUid();
        String report = aiPlacementService.scoreResume(institutionId, studentId, driveId, file);
        return Map.of("report", report);
    }

    @GetMapping("/readiness")
    public Map<String, String> getReadinessReport(@RequestParam String institutionId) throws ExecutionException, InterruptedException {
        String studentId = getCurrentUserUid();
        String report = aiPlacementService.analyzeReadiness(institutionId, studentId);
        return Map.of("report", report);
    }

    @GetMapping("/skill-gap/{driveId}")
    public Map<String, String> getSkillGap(@RequestParam String institutionId, @PathVariable String driveId) throws ExecutionException, InterruptedException {
        String studentId = getCurrentUserUid();
        String report = aiPlacementService.analyzeSkillGap(institutionId, studentId, driveId);
        return Map.of("report", report);
    }

    @GetMapping("/profile-score/{driveId}")
    public Map<String, String> getProfileScore(@RequestParam String institutionId, @PathVariable String driveId) throws ExecutionException, InterruptedException {
        String studentId = getCurrentUserUid();
        String report = aiPlacementService.scoreProfileMatch(institutionId, studentId, driveId);
        return Map.of("report", report);
    }
}
