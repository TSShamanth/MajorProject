package com.example.backend.controller;

import com.example.backend.models.Exam;
import com.example.backend.service.ExamService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api")
public class ExamController {

    private final ExamService examService;

    public ExamController(ExamService examService) {
        this.examService = examService;
    }

    @PostMapping("/institutions/{institutionId}/exams")
    public ResponseEntity<Exam> createExam(@RequestBody Exam exam, @PathVariable String institutionId) {
        try {
            Exam createdExam = examService.createExam(exam, institutionId);
            return ResponseEntity.ok(createdExam);
        } catch (ExecutionException | InterruptedException e) {
            // Log the error and return a 500 status code
            // In a real application, you'd want to use a more robust logging solution
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/institutions/{institutionId}/exams")
    public ResponseEntity<List<Exam>> getExams(@PathVariable String institutionId) {
        try {
            List<Exam> exams = examService.getExams(institutionId);
            return ResponseEntity.ok(exams);
        } catch (ExecutionException | InterruptedException e) {
            // Log the error and return a 500 status code
            // In a real application, you'd want to use a more robust logging solution
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }
}
