package com.example.backend.controller;

import com.example.backend.service.AiSmartManagementService;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/ai/management")
public class AiSmartManagementController {

    private final AiSmartManagementService aiSmartManagementService;

    public AiSmartManagementController(AiSmartManagementService aiSmartManagementService) {
        this.aiSmartManagementService = aiSmartManagementService;
    }

    @GetMapping("/leave-insight")
    public Map<String, String> getLeaveInsight(
            @RequestParam String institutionId,
            @RequestParam String studentUid,
            @RequestParam String startDate,
            @RequestParam String endDate) throws ExecutionException, InterruptedException {
        String insight = aiSmartManagementService.getLeaveApprovalInsight(institutionId, studentUid, startDate, endDate);
        return Map.of("insight", insight);
    }

    @GetMapping("/substitution-suggestions")
    public Map<String, String> getSubstitutions(
            @RequestParam String institutionId,
            @RequestParam String facultyUid,
            @RequestParam String date,
            @RequestParam String timeSlotId) throws ExecutionException, InterruptedException {
        String suggestions = aiSmartManagementService.getSubstitutionSuggestions(institutionId, facultyUid, date, timeSlotId);
        return Map.of("suggestions", suggestions);
    }
}
