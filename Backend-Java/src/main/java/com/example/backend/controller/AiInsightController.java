package com.example.backend.controller;

import com.example.backend.service.AiInsightService;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/ai/insights")
public class AiInsightController {

    private final AiInsightService aiInsightService;

    public AiInsightController(AiInsightService aiInsightService) {
        this.aiInsightService = aiInsightService;
    }

    private String getCurrentUserUid() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) return null;
        Object principal = authentication.getPrincipal();
        if (principal instanceof FirebaseToken) {
            return ((FirebaseToken) principal).getUid();
        }
        return principal.toString();
    }

    /**
     * Endpoint for students to get their own insights.
     */
    @GetMapping("/my")
    public Map<String, String> getMyInsights(@RequestParam String institutionId) throws ExecutionException, InterruptedException {
        String studentId = getCurrentUserUid();
        String insights = aiInsightService.generateInsights(institutionId, studentId);
        return Map.of("insights", insights);
    }

    /**
     * Endpoint for faculty to get insights for a specific mentee.
     */
    @GetMapping("/mentee/{studentId}")
    public Map<String, String> getMenteeInsights(@RequestParam String institutionId, @PathVariable String studentId) throws ExecutionException, InterruptedException {
        // In a real app, we'd check if this faculty is actually the mentor here,
        // but for now, we'll rely on method security or simple role check if needed.
        String insights = aiInsightService.generateInsights(institutionId, studentId);
        return Map.of("insights", insights);
    }
}
