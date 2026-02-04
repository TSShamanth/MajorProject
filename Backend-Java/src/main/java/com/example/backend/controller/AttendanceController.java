package com.example.backend.controller;

import com.example.backend.models.Attendance;
import com.example.backend.models.Course;
import com.example.backend.service.AttendanceService;
import com.example.backend.service.CourseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/institutions/{institutionId}")
public class AttendanceController {

    private final AttendanceService attendanceService;
    private final CourseService courseService; // To get faculty's assigned courses and students in a course

    @Autowired
    public AttendanceController(AttendanceService attendanceService, CourseService courseService) {
        this.attendanceService = attendanceService;
        this.courseService = courseService;
    }

    /**
     * Endpoint for faculty to mark attendance for a course.
     * POST /institutions/{institutionId}/departments/{departmentId}/courses/{courseCode}/attendance
     * Request Body: List of Attendance objects
     */
    @PostMapping("/departments/{departmentId}/courses/{courseCode}/attendance")
    public ResponseEntity<List<Attendance>> markAttendance(
            @PathVariable String institutionId,
            @PathVariable String departmentId,
            @PathVariable String courseCode,
            @RequestBody List<Attendance> attendanceRecords) {
        try {
            List<Attendance> savedRecords = attendanceService.markAttendance(
                    institutionId, departmentId, courseCode, attendanceRecords);
            return ResponseEntity.ok(savedRecords);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Endpoint to get all attendance records for a specific course.
     * GET /institutions/{institutionId}/departments/{departmentId}/courses/{courseCode}/attendance
     */
    @GetMapping("/departments/{departmentId}/courses/{courseCode}/attendance")
    public ResponseEntity<List<Attendance>> getAttendanceForCourse(
            @PathVariable String institutionId,
            @PathVariable String departmentId,
            @PathVariable String courseCode) {
        try {
            List<Attendance> attendanceList = attendanceService.getAttendanceForCourse(
                    institutionId, departmentId, courseCode);
            return ResponseEntity.ok(attendanceList);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Endpoint to get attendance records for a specific student across all courses.
     * GET /institutions/{institutionId}/students/{studentUid}/attendance
     */
    @GetMapping("/students/{studentUid}/attendance")
    public ResponseEntity<List<Attendance>> getAttendanceForStudent(
            @PathVariable String institutionId,
            @PathVariable String studentUid) {
        try {
            List<Attendance> attendanceList = attendanceService.getAttendanceForStudent(
                    institutionId, studentUid);
            return ResponseEntity.ok(attendanceList);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Endpoint to get attendance records for a specific course and date.
     * GET /institutions/{institutionId}/departments/{departmentId}/courses/{courseCode}/attendance?date={date}
     */
    @GetMapping(value = "/departments/{departmentId}/courses/{courseCode}/attendance", params = "date")
    public ResponseEntity<List<Attendance>> getAttendanceForDate(
            @PathVariable String institutionId,
            @PathVariable String departmentId,
            @PathVariable String courseCode,
            @RequestParam String date) {
        try {
            List<Attendance> attendanceList = attendanceService.getAttendanceForDate(
                    institutionId, departmentId, courseCode, date);
            return ResponseEntity.ok(attendanceList);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // Additional endpoints for mark attendance screen to get data
    /**
     * Endpoint to get courses assigned to a faculty for the mark attendance screen.
     * GET /institutions/{institutionId}/faculty/{facultyUid}/courses
     */
    @GetMapping("/faculty/{facultyUid}/courses")
    public ResponseEntity<List<Course>> getFacultyAssignedCourses(
            @PathVariable String institutionId,
            @PathVariable String facultyUid) {
        try {
            List<Course> courses = courseService.getFacultyCourses(institutionId, facultyUid);
            return ResponseEntity.ok(courses);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Endpoint to get students enrolled in a specific course for the mark attendance screen.
     * GET /institutions/{institutionId}/departments/{departmentId}/courses/{courseCode}/students
     */
    @GetMapping("/departments/{departmentId}/courses/{courseCode}/students")
    public ResponseEntity<?> getStudentsEnrolledInCourse(
            @PathVariable String institutionId,
            @PathVariable String departmentId,
            @PathVariable String courseCode) {
        try {
            var students = courseService.getStudentsForCourse(institutionId, departmentId, courseCode);
            return ResponseEntity.ok(students);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Endpoint to get subject-wise attendance for a specific student.
     * GET /institutions/{institutionId}/students/{studentUid}/subject-wise-attendance
     */
    @GetMapping("/students/{studentUid}/subject-wise-attendance")
    public ResponseEntity<List<com.example.backend.dto.SubjectWiseAttendance>> getSubjectWiseAttendance(
            @PathVariable String institutionId,
            @PathVariable String studentUid) {
        try {
            List<com.example.backend.dto.SubjectWiseAttendance> attendanceList = attendanceService.getSubjectWiseAttendance(
                    institutionId, studentUid);
            return ResponseEntity.ok(attendanceList);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
