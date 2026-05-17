package com.example.backend.controller;

import com.example.backend.models.Assessment;
import com.example.backend.service.AssessmentService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/institutions/{institutionId}/assessments")
public class AssessmentController {

    private final AssessmentService assessmentService;

    public AssessmentController(AssessmentService assessmentService) {
        this.assessmentService = assessmentService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY')")
    public ResponseEntity<Assessment> createAssessment(
            @PathVariable String institutionId,
            @AuthenticationPrincipal String uid,
            @RequestBody Assessment assessment) {
        try {
            assessment.setCreatedBy(uid);
            Assessment created = assessmentService.createAssessment(institutionId, assessment);
            return ResponseEntity.ok(created);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/course/{courseCode}")
    public ResponseEntity<List<Assessment>> getAssessmentsByCourse(
            @PathVariable String institutionId,
            @PathVariable String courseCode) {
        try {
            List<Assessment> assessments = assessmentService.getAssessmentsByCourse(institutionId, courseCode);
            return ResponseEntity.ok(assessments);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/{assessmentId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY')")
    public ResponseEntity<Void> deleteAssessment(
            @PathVariable String institutionId,
            @PathVariable String assessmentId) {
        try {
            assessmentService.deleteAssessment(institutionId, assessmentId);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
