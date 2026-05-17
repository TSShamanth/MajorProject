package com.example.backend.controller;

import com.example.backend.service.AiChatService;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final AiChatService aiChatService;

    public ChatController(AiChatService aiChatService) {
        this.aiChatService = aiChatService;
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

    @GetMapping("/test")
    public Map<String, String> testChat(@RequestParam(value = "message", defaultValue = "Hello, tell me a joke about computer science.") String message) {
        String response = aiChatService.generateResponse(message, "test-inst", "test-user");
        return Map.of("response", response);
    }

    @PostMapping("/ask")
    public ResponseEntity<ChatResponse> askChatbot(@RequestBody ChatRequest request) {
        String studentId = getCurrentUserUid();
        String institutionId = request.getInstitutionId();
        
        System.out.println("CHAT CONTROLLER: Processing message from " + studentId + " for inst: " + institutionId);
        
        String reply = aiChatService.generateResponse(request.getMessage(), institutionId, studentId);
        return ResponseEntity.ok(new ChatResponse(reply));
    }
}

