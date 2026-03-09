package com.example.backend.controller;

import com.example.backend.models.Marks;
import com.example.backend.service.MarksService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/institutions/{institutionId}/marks")
public class MarksController {

    private final MarksService marksService;

    public MarksController(MarksService marksService) {
        this.marksService = marksService;
    }

    @PostMapping
    public ResponseEntity<Marks> saveMarks(@PathVariable String institutionId, @RequestBody Marks marks) {
        try {
            marks.setInstitutionId(institutionId);
            Marks savedMarks = marksService.saveMarks(institutionId, marks);
            return ResponseEntity.ok(savedMarks);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/student/{studentId}")
    public ResponseEntity<List<Marks>> getMarksByStudent(@PathVariable String institutionId, @PathVariable String studentId) {
        try {
            List<Marks> marks = marksService.getMarksByStudent(institutionId, studentId);
            return ResponseEntity.ok(marks);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/student/{studentId}/summary")
    public ResponseEntity<Map<String, Object>> getAcademicSummary(@PathVariable String institutionId, @PathVariable String studentId) {
        try {
            Map<String, Object> summary = marksService.getAcademicSummary(institutionId, studentId);
            return ResponseEntity.ok(summary);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }
}
