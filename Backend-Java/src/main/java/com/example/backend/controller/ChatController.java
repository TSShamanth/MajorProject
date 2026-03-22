package com.example.backend.controller;

import com.example.backend.service.AiChatService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final AiChatService aiChatService;

    public ChatController(AiChatService aiChatService) {
        this.aiChatService = aiChatService;
    }

    @GetMapping("/test")
    public Map<String, String> testChat(@RequestParam(value = "message", defaultValue = "Hello, tell me a joke about computer science.") String message) {
        String response = aiChatService.generateResponse(message);
        return Map.of("response", response);
    }
}
