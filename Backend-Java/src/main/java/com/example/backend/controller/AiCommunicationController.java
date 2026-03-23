package com.example.backend.controller;

import com.example.backend.service.AiCommunicationService;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/ai/communication")
public class AiCommunicationController {

    private final AiCommunicationService aiCommunicationService;

    public AiCommunicationController(AiCommunicationService aiCommunicationService) {
        this.aiCommunicationService = aiCommunicationService;
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

    @GetMapping("/summarize/{announcementId}")
    public Map<String, String> getSummary(@RequestParam String institutionId, @PathVariable String announcementId) throws ExecutionException, InterruptedException {
        String summary = aiCommunicationService.summarizeAnnouncement(institutionId, announcementId);
        return Map.of("summary", summary);
    }

    @GetMapping("/recommend-events")
    public Map<String, String> getEventRecommendations(@RequestParam String institutionId) throws ExecutionException, InterruptedException {
        String studentId = getCurrentUserUid();
        String recommendations = aiCommunicationService.recommendEvents(institutionId, studentId);
        return Map.of("recommendations", recommendations);
    }

    @GetMapping("/recommend-event/{eventId}")
    public Map<String, String> getEventRecommendation(@RequestParam String institutionId, @PathVariable String eventId) throws ExecutionException, InterruptedException {
        String studentId = getCurrentUserUid();
        String recommendation = aiCommunicationService.getEventRecommendation(institutionId, studentId, eventId);
        return Map.of("recommendation", recommendation);
    }
}
