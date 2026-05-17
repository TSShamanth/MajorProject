package com.example.backend.controller;

import com.example.backend.models.StudentFee;
import com.example.backend.models.User;
import com.example.backend.service.FeeService;
import com.example.backend.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize; // Import for PreAuthorize
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/{institutionId}/api/faculty")
public class FacultyController {

    private final UserService userService;
    private final FeeService feeService;

    public FacultyController(UserService userService, FeeService feeService) {
        this.userService = userService;
        this.feeService = feeService;
    }

    @GetMapping("/my-students-fees")
    @PreAuthorize("hasRole('FACULTY')") // Added method-level security
    public ResponseEntity<List<StudentFee>> getMyStudentsFeeStatus(@PathVariable String institutionId) {
        try {
            // Get the currently authenticated user's details
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String facultyUid = authentication.getName();
            User faculty = userService.getUserById(institutionId, facultyUid);

            if (faculty == null || !"faculty".equals(faculty.getRole())) {
                // This check is redundant due to @PreAuthorize but kept for clarity
                return ResponseEntity.status(403).build(); // Forbidden
            }

            // Find students by mentor name
            List<User> students = userService.getStudentsByMentor(institutionId, faculty.getDisplayName());
            if (students.isEmpty()) {
                return ResponseEntity.ok(List.of());
            }

            // Get a list of student IDs
            List<String> studentIds = students.stream().map(User::getUid).collect(Collectors.toList());

            // Fetch fee records for those students
            List<StudentFee> studentFees = feeService.getFeesForStudentList(institutionId, studentIds);

            return ResponseEntity.ok(studentFees);

        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
