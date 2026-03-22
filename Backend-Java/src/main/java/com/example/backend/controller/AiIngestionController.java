package com.example.backend.controller;

import com.example.backend.service.AiIngestionService;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/ai/ingestion")
public class AiIngestionController {

    private final AiIngestionService aiIngestionService;

    public AiIngestionController(AiIngestionService aiIngestionService) {
        this.aiIngestionService = aiIngestionService;
    }

    @PostMapping("/pdf")
    public ResponseEntity<Map<String, String>> uploadPdf(@RequestParam("file") MultipartFile file) {
        String contentType = file.getContentType();
        boolean isPdf = contentType != null && 
                       (contentType.equalsIgnoreCase("application/pdf") || 
                        file.getOriginalFilename().toLowerCase().endsWith(".pdf"));

        if (file.isEmpty() || !isPdf) {
            return ResponseEntity.badRequest().body(Map.of("error", "Please upload a valid PDF file."));
        }

        try {
            ByteArrayResource resource = new ByteArrayResource(file.getBytes());
            aiIngestionService.ingestPdf(resource);
            return ResponseEntity.ok(Map.of("message", "PDF successfully ingested and indexed for AI!"));
        } catch (IOException e) {
            return ResponseEntity.status(500).body(Map.of("error", "Failed to process the PDF: " + e.getMessage()));
        }
    }

    @PostMapping("/sync-storage")
    public ResponseEntity<Map<String, String>> syncFromStorage(@RequestBody Map<String, String> request) {
        String bucketName = request.get("bucket");
        String path = request.get("path");

        if (bucketName == null || path == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Missing 'bucket' or 'path' in request body."));
        }

        try {
            aiIngestionService.ingestFromStorage(bucketName, path);
            return ResponseEntity.ok(Map.of("message", "File from storage successfully synced to AI knowledge base!"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Failed to sync from storage: " + e.getMessage()));
        }
    }
}
