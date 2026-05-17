package com.example.backend.controller;

import com.example.backend.models.Submission;
import com.example.backend.service.SubmissionService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/institutions/{institutionId}/submissions")
public class SubmissionController {

    private final SubmissionService submissionService;

    public SubmissionController(SubmissionService submissionService) {
        this.submissionService = submissionService;
    }

    @PostMapping
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<Submission> submitAssignment(
            @PathVariable String institutionId,
            @AuthenticationPrincipal String studentId,
            @RequestBody Submission submission) {
        try {
            submission.setStudentId(studentId);
            Submission created = submissionService.submitAssignment(institutionId, submission);
            return ResponseEntity.ok(created);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/assessment/{assessmentId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY')")
    public ResponseEntity<List<Submission>> getSubmissionsByAssessment(
            @PathVariable String institutionId,
            @PathVariable String assessmentId) {
        try {
            List<Submission> submissions = submissionService.getSubmissionsByAssessment(institutionId, assessmentId);
            return ResponseEntity.ok(submissions);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/assessment/{assessmentId}/me")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<Submission> getMySubmission(
            @PathVariable String institutionId,
            @PathVariable String assessmentId,
            @AuthenticationPrincipal String studentId) {
        try {
            Submission submission = submissionService.getStudentSubmission(institutionId, assessmentId, studentId);
            return ResponseEntity.ok(submission);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PostMapping("/{submissionId}/grade")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY')")
    public ResponseEntity<Submission> gradeSubmission(
            @PathVariable String institutionId,
            @PathVariable String submissionId,
            @RequestBody Map<String, Object> gradingData) {
        try {
            double marks = Double.parseDouble(gradingData.get("marks").toString());
            String feedback = (String) gradingData.get("feedback");
            Submission graded = submissionService.gradeSubmission(institutionId, submissionId, marks, feedback);
            return ResponseEntity.ok(graded);
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }
}
