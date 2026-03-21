package com.example.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/debug")
public class DebugController {

    @GetMapping("/whoami")
    public ResponseEntity<?> whoAmI(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(401).body("Not authenticated");
        }

        Map<String, Object> debugInfo = new HashMap<>();
        debugInfo.put("uid", authentication.getPrincipal());
        debugInfo.put("authorities", authentication.getAuthorities());
        
        return ResponseEntity.ok(debugInfo);
    }
}
