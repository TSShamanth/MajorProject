package com.example.backend.controller;

import com.example.backend.models.Exam;
import com.example.backend.models.User;
import com.example.backend.service.ExamService;
import com.example.backend.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api")
public class ExamController {

    private final ExamService examService;
    private final UserService userService; // Inject UserService

    public ExamController(ExamService examService, UserService userService) {
        this.examService = examService;
        this.userService = userService; // Initialize UserService
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

    @GetMapping("/institutions/{institutionId}/exams/{examId}")
    public ResponseEntity<Exam> getExamById(@PathVariable String institutionId, @PathVariable String examId) {
        try {
            Exam exam = examService.getExamById(institutionId, examId);
            if (exam != null) {
                return ResponseEntity.ok(exam);
            } else {
                return ResponseEntity.status(404).build();
            }
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/institutions/{institutionId}/exams/{examId}/eligible-students")
    public ResponseEntity<List<User>> getEligibleStudentsForExam(
            @PathVariable String institutionId,
            @PathVariable String examId) {
        try {
            Exam exam = examService.getExamById(institutionId, examId);
            if (exam == null) {
                return ResponseEntity.status(404).build();
            }
            List<User> students = userService.getStudentsByDepartmentAndSemester(
                    institutionId, exam.getDepartmentId(), exam.getSemester());
            return ResponseEntity.ok(students);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }
}
