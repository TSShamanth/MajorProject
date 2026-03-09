package com.example.backend.controller;

import com.example.backend.models.CustomForm;
import com.example.backend.models.FormResponse;
import com.example.backend.service.FormService;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api")
public class FormController {

    private final FormService formService;
    private final FirebaseAuth firebaseAuth;

    public FormController(FormService formService, FirebaseAuth firebaseAuth) {
        this.formService = formService;
        this.firebaseAuth = firebaseAuth;
    }

    @PostMapping("/institutions/{institutionId}/forms")
    public ResponseEntity<?> createForm(
            @PathVariable String institutionId,
            @RequestBody CustomForm form,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");

            form.setCreatedBy(userId);
            CustomForm created = formService.createForm(institutionId, form);
            return ResponseEntity.status(201).body(created);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/forms")
    public ResponseEntity<?> getForms(@PathVariable String institutionId) {
        try {
            return ResponseEntity.ok(formService.getForms(institutionId));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/forms/audience")
    public ResponseEntity<?> getFormsForAudience(
            @PathVariable String institutionId,
            @RequestParam String role,
            @RequestHeader("Authorization") String authHeader) {
        try {
            if (extractUserIdFromToken(authHeader) == null) return ResponseEntity.status(401).body("Unauthorized");
            return ResponseEntity.ok(formService.getFormsForAudience(institutionId, role));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/forms/{formId}")
    public ResponseEntity<?> getFormById(@PathVariable String institutionId, @PathVariable String formId) {
        try {
            CustomForm form = formService.getFormById(institutionId, formId);
            return form != null ? ResponseEntity.ok(form) : ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @PutMapping("/institutions/{institutionId}/forms/{formId}")
    public ResponseEntity<?> updateForm(
            @PathVariable String institutionId,
            @PathVariable String formId,
            @RequestBody CustomForm form,
            @RequestHeader("Authorization") String authHeader) {
        try {
            if (extractUserIdFromToken(authHeader) == null) return ResponseEntity.status(401).body("Unauthorized");
            return ResponseEntity.ok(formService.updateForm(institutionId, formId, form));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @DeleteMapping("/institutions/{institutionId}/forms/{formId}")
    public ResponseEntity<?> deleteForm(
            @PathVariable String institutionId,
            @PathVariable String formId,
            @RequestHeader("Authorization") String authHeader) {
        try {
            if (extractUserIdFromToken(authHeader) == null) return ResponseEntity.status(401).body("Unauthorized");
            formService.deleteForm(institutionId, formId);
            return ResponseEntity.ok().body("Form deleted successfully");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @PostMapping("/institutions/{institutionId}/forms/{formId}/responses")
    public ResponseEntity<?> submitResponse(
            @PathVariable String institutionId,
            @PathVariable String formId,
            @RequestBody FormResponse response,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");

            response.setUserId(userId);
            response.setFormId(formId);
            return ResponseEntity.status(201).body(formService.submitResponse(institutionId, response));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/forms/{formId}/responses")
    public ResponseEntity<?> getResponsesForForm(
            @PathVariable String institutionId,
            @PathVariable String formId,
            @RequestHeader("Authorization") String authHeader) {
        try {
            if (extractUserIdFromToken(authHeader) == null) return ResponseEntity.status(401).body("Unauthorized");
            return ResponseEntity.ok(formService.getResponsesForForm(institutionId, formId));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/forms/{formId}/responses/me")
    public ResponseEntity<?> getUserResponse(
            @PathVariable String institutionId,
            @PathVariable String formId,
            @RequestHeader("Authorization") String authHeader) {
        try {
            String userId = extractUserIdFromToken(authHeader);
            if (userId == null) return ResponseEntity.status(401).body("Unauthorized");
            FormResponse response = formService.getUserResponseForForm(institutionId, formId, userId);
            return response != null ? ResponseEntity.ok(response) : ResponseEntity.noContent().build();
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/institutions/{institutionId}/forms/{formId}/responses/count")
    public ResponseEntity<?> getResponseCount(
            @PathVariable String institutionId,
            @PathVariable String formId) {
        try {
            long count = formService.getResponseCountForForm(institutionId, formId);
            return ResponseEntity.ok(count);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }

    private String extractUserIdFromToken(String authHeader) {
        try {
            if (authHeader == null || !authHeader.startsWith("Bearer ")) return null;
            String token = authHeader.substring(7);
            FirebaseToken decodedToken = firebaseAuth.verifyIdToken(token);
            return decodedToken.getUid();
        } catch (Exception e) {
            return null;
        }
    }
}
