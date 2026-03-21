package com.example.backend.controller;

import com.example.backend.models.Course;
import com.example.backend.service.CourseService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/departments/{departmentId}/courses")
public class CourseController {

    private final CourseService courseService;

    public CourseController(CourseService courseService) {
        this.courseService = courseService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'ADMISSION_ADMIN')")
    public ResponseEntity<Course> createCourse(@PathVariable String institutionId, @PathVariable String departmentId, @RequestBody Course course) {
        try {
            course.setInstitutionId(institutionId);
            Course createdCourse = courseService.createCourse(institutionId, departmentId, course);
            return ResponseEntity.ok(createdCourse);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Course>> getCourses(@PathVariable String institutionId, @PathVariable String departmentId) {
        try {
            List<Course> courses = courseService.getCourses(institutionId, departmentId);
            return ResponseEntity.ok(courses);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/{courseCode}")
    public ResponseEntity<Course> getCourse(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String courseCode) {
        try {
            Course course = courseService.getCourse(institutionId, departmentId, courseCode);
            if (course == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(course);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/{courseCode}")
    @PreAuthorize("hasAnyRole('ADMIN', 'ADMISSION_ADMIN')")
    public ResponseEntity<Course> updateCourse(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String courseCode, @RequestBody Course course) {
        try {
            course.setCourseCode(courseCode);
            course.setInstitutionId(institutionId);
            Course updatedCourse = courseService.updateCourse(institutionId, departmentId, course);
            return ResponseEntity.ok(updatedCourse);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/{courseCode}")
    @PreAuthorize("hasAnyRole('ADMIN', 'ADMISSION_ADMIN')")
    public ResponseEntity<Void> deleteCourse(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String courseCode) {
        try {
            courseService.deleteCourse(institutionId, departmentId, courseCode);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
