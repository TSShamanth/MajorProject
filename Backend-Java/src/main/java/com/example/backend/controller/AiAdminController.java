package com.example.backend.controller;

import com.example.backend.service.AiAdminService;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/ai/admin")
public class AiAdminController {

    private final AiAdminService aiAdminService;

    public AiAdminController(AiAdminService aiAdminService) {
        this.aiAdminService = aiAdminService;
    }

    @PostMapping("/analyze-error")
    public Map<String, String> analyzeError(@RequestBody Map<String, String> body) {
        String trace = body.get("trace");
        String analysis = aiAdminService.analyzeBug(trace);
        return Map.of("analysis", analysis);
    }

    @GetMapping("/security-audit")
    public Map<String, String> getSecurityAudit(@RequestParam String institutionId) throws ExecutionException, InterruptedException {
        String audit = aiAdminService.detectAccessAnomalies(institutionId);
        return Map.of("audit", audit);
    }
}
