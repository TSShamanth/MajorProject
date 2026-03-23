package com.example.backend.controller;

import com.example.backend.service.AiFeedbackService;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/ai/feedback")
public class AiFeedbackController {

    private final AiFeedbackService aiFeedbackService;

    public AiFeedbackController(AiFeedbackService aiFeedbackService) {
        this.aiFeedbackService = aiFeedbackService;
    }

    @GetMapping("/analyze/{formId}")
    public Map<String, String> analyzeResponses(@RequestParam String institutionId, @PathVariable String formId) throws ExecutionException, InterruptedException {
        String analysis = aiFeedbackService.analyzeFormResponses(institutionId, formId);
        return Map.of("analysis", analysis);
    }

    @PostMapping("/propose-form")
    public Map<String, String> proposeForm(@RequestBody Map<String, String> payload) {
        String topic = payload.get("topic");
        String proposal = aiFeedbackService.proposeFormFields(topic);
        return Map.of("proposal", proposal);
    }
}
