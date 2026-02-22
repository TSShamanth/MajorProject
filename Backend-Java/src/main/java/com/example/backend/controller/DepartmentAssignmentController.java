package com.example.backend.controller;

import com.example.backend.service.CourseService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/departments/{departmentId}")
public class DepartmentAssignmentController {

    private final CourseService courseService;

    public DepartmentAssignmentController(CourseService courseService) {
        this.courseService = courseService;
    }

    @PutMapping("/faculty/{facultyId}/courses")
    public ResponseEntity<Void> updateFacultyCourses(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String facultyId, @RequestBody List<String> courseCodes) {
        try {
            courseService.updateFacultyCourses(institutionId, departmentId, facultyId, courseCodes);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/student/{studentId}/courses")
    public ResponseEntity<Void> updateStudentCourses(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String studentId, @RequestBody List<String> courseCodes) {
        try {
            courseService.updateStudentCourses(institutionId, departmentId, studentId, courseCodes);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
    @DeleteMapping("/faculty/{facultyId}")
    public ResponseEntity<Void> unassignFaculty(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String facultyId) {
        try {
            courseService.unassignFaculty(institutionId, departmentId, facultyId);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/student/{studentId}")
    public ResponseEntity<Void> unassignStudent(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String studentId) {
        try {
            courseService.unassignStudent(institutionId, departmentId, studentId);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
