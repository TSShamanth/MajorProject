package com.example.backend.controller;

import com.example.backend.models.Exam;
import com.example.backend.models.ExamScheduleEntry; // Import ExamScheduleEntry
import com.example.backend.models.InvigilatorAssignment; // Import InvigilatorAssignment
import com.example.backend.models.SeatingEntry; // Import SeatingEntry
import com.example.backend.models.User;
import com.example.backend.dto.HallTicketData; // Import HallTicketData
import com.example.backend.service.ExamService;
import com.example.backend.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
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

    @PostMapping("/institutions/{institutionId}/exams/{examId}/freeze-eligible-students")
    public ResponseEntity<Void> freezeEligibleStudentsForExam(
            @PathVariable String institutionId,
            @PathVariable String examId,
            @RequestBody List<String> studentUids) {
        try {
            examService.freezeEligibleStudentsForExam(institutionId, examId, studentUids);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/institutions/{institutionId}/users/{studentUid}/detained-status")
    public ResponseEntity<Void> updateStudentDetainedStatus(
            @PathVariable String institutionId,
            @PathVariable String studentUid,
            @RequestBody Map<String, Boolean> requestBody) {
        try {
            Boolean isDetained = requestBody.get("isDetained");
            if (isDetained == null) {
                return ResponseEntity.badRequest().build();
            }
            userService.updateUserDetainedStatus(institutionId, studentUid, isDetained);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/institutions/{institutionId}/exams/{examId}/schedule")
    public ResponseEntity<Void> updateExamSchedule(
            @PathVariable String institutionId,
            @PathVariable String examId,
            @RequestBody Map<String, ExamScheduleEntry> schedule) {
        try {
            examService.updateExamSchedule(institutionId, examId, schedule);
            return ResponseEntity.ok().build();
        } catch (IllegalArgumentException e) {
            // Exam not found
            return ResponseEntity.status(404).body(null);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @PostMapping("/institutions/{institutionId}/exams/{examId}/allocate-halls")
    public ResponseEntity<Map<String, SeatingEntry>> allocateHalls(
            @PathVariable String institutionId,
            @PathVariable String examId) {
        try {
            Map<String, SeatingEntry> seatingArrangement = examService.allocateHalls(institutionId, examId);
            return ResponseEntity.ok(seatingArrangement);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(null);
        } catch (IllegalStateException e) {
            return ResponseEntity.status(409).body(null); // Conflict, e.g., no students or rooms
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/institutions/{institutionId}/exams/{examId}/seating-arrangement")
    public ResponseEntity<Map<String, SeatingEntry>> getSeatingArrangement(
            @PathVariable String institutionId,
            @PathVariable String examId) {
        try {
            Map<String, SeatingEntry> seatingArrangement = examService.getSeatingArrangement(institutionId, examId);
            if (seatingArrangement != null && !seatingArrangement.isEmpty()) {
                return ResponseEntity.ok(seatingArrangement);
            } else {
                return ResponseEntity.status(404).body(null);
            }
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(null);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    // Invigilator Assignment Endpoints
    @PostMapping("/institutions/{institutionId}/exams/{examId}/invigilator-assignments")
    public ResponseEntity<InvigilatorAssignment> assignInvigilator(
            @PathVariable String institutionId,
            @PathVariable String examId,
            @RequestBody InvigilatorAssignment assignment) {
        try {
            assignment.setExamId(examId); // Ensure examId from path is set
            InvigilatorAssignment createdAssignment = examService.assignInvigilator(institutionId, assignment);
            return ResponseEntity.ok(createdAssignment);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/institutions/{institutionId}/exams/{examId}/invigilator-assignments")
    public ResponseEntity<List<InvigilatorAssignment>> getInvigilatorAssignments(
            @PathVariable String institutionId,
            @PathVariable String examId) {
        try {
            List<InvigilatorAssignment> assignments = examService.getInvigilatorAssignments(institutionId, examId);
            return ResponseEntity.ok(assignments);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/institutions/{institutionId}/exams/{examId}/invigilator-assignments/room/{roomId}")
    public ResponseEntity<List<InvigilatorAssignment>> getInvigilatorAssignmentsByRoom(
            @PathVariable String institutionId,
            @PathVariable String examId,
            @PathVariable String roomId) {
        try {
            List<InvigilatorAssignment> assignments = examService.getInvigilatorAssignmentsByRoom(institutionId, examId, roomId);
            return ResponseEntity.ok(assignments);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/institutions/{institutionId}/exams/{examId}/invigilator-assignments/{assignmentId}")
    public ResponseEntity<Void> deleteInvigilatorAssignment(
            @PathVariable String institutionId,
            @PathVariable String examId,
            @PathVariable String assignmentId) {
        try {
            examService.deleteInvigilatorAssignment(institutionId, examId, assignmentId);
            return ResponseEntity.noContent().build();
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    // Hall Ticket Endpoints
    @GetMapping("/institutions/{institutionId}/exams/{examId}/students/{studentId}/hall-ticket-data")
    public ResponseEntity<HallTicketData> getHallTicketData(
            @PathVariable String institutionId,
            @PathVariable String examId,
            @PathVariable String studentId) {
        try {
            HallTicketData hallTicketData = examService.getHallTicketData(institutionId, examId, studentId);
            return ResponseEntity.ok(hallTicketData);
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.status(404).body(null);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }
}
