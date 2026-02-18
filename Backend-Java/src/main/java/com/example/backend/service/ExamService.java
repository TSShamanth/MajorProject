package com.example.backend.service;

import com.example.backend.models.Exam;
import com.example.backend.models.ExamScheduleEntry;
import com.example.backend.models.InvigilatorAssignment; // Import InvigilatorAssignment
import com.example.backend.models.Room;
import com.example.backend.models.SeatingEntry; // Import SeatingEntry
import com.example.backend.models.User; // Import User
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.WriteResult;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.DocumentSnapshot;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class ExamService {

    private final Firestore firestore;
    private final RoomService roomService; // Inject RoomService
    private final UserService userService; // Inject UserService

    public ExamService(Firestore firestore, RoomService roomService, UserService userService) {
        this.firestore = firestore;
        this.roomService = roomService; // Initialize RoomService
        this.userService = userService;
    }

    public Exam createExam(Exam exam, String institutionId) throws ExecutionException, InterruptedException {
        String examId = UUID.randomUUID().toString();
        exam.setId(examId);
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("exams").document(examId).set(exam);
        future.get();
        return exam;
    }

    public List<Exam> getExams(String institutionId) throws ExecutionException, InterruptedException {
        List<Exam> exams = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId).collection("exams").get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            exams.add(document.toObject(Exam.class));
        }
        return exams;
    }

    public Exam getExamById(String institutionId, String examId) throws ExecutionException, InterruptedException {
        ApiFuture<DocumentSnapshot> future = firestore.collection("Institutions").document(institutionId).collection("exams").document(examId).get();
        DocumentSnapshot document = future.get();
        if (document.exists()) {
            return document.toObject(Exam.class);
        } else {
            return null;
        }
    }

    public void freezeEligibleStudentsForExam(String institutionId, String examId, List<String> studentUids) throws ExecutionException, InterruptedException {
        Exam exam = getExamById(institutionId, examId);
        if (exam == null) {
            throw new IllegalArgumentException("Exam not found with ID: " + examId);
        }

        exam.setFrozenCandidateList(studentUids);

        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("exams").document(examId).set(exam);
        future.get();
    }

    public void updateExamSchedule(String institutionId, String examId, Map<String, ExamScheduleEntry> newSchedule) throws ExecutionException, InterruptedException {
        Exam exam = getExamById(institutionId, examId);
        if (exam == null) {
            throw new IllegalArgumentException("Exam not found with ID: " + examId);
        }

        exam.setSchedule(newSchedule);

        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("exams").document(examId).set(exam);
        future.get();
    }

    // New method for hall allocation
    public Map<String, SeatingEntry> allocateHalls(String institutionId, String examId) throws ExecutionException, InterruptedException {
        Exam exam = getExamById(institutionId, examId);
        if (exam == null) {
            throw new IllegalArgumentException("Exam not found with ID: " + examId);
        }
        if (exam.getFrozenCandidateList() == null || exam.getFrozenCandidateList().isEmpty()) {
            throw new IllegalStateException("No eligible students frozen for this exam.");
        }

        List<Room> availableRooms = roomService.getRooms(institutionId);
        if (availableRooms.isEmpty()) {
            throw new IllegalStateException("No rooms available for allocation.");
        }

        Map<String, SeatingEntry> seatingArrangement = new HashMap<>();
        List<String> students = new ArrayList<>(exam.getFrozenCandidateList());
        Collections.shuffle(students); // Randomize student order

        int studentIndex = 0;
        for (Room room : availableRooms) {
            for (int i = 1; i <= room.getCapacity(); i++) {
                if (studentIndex < students.size()) {
                    String studentId = students.get(studentIndex);
                    String seatNumber = String.valueOf(i); // Simple sequential seat numbering
                    seatingArrangement.put(studentId, new SeatingEntry(studentId, room.getId(), seatNumber));
                    studentIndex++;
                } else {
                    break; // All students allocated
                }
            }
            if (studentIndex >= students.size()) {
                break; // All students allocated
            }
        }

        if (studentIndex < students.size()) {
            throw new IllegalStateException("Not enough room capacity to allocate all students.");
        }

        exam.setSeatingArrangement(seatingArrangement);
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("exams").document(examId).set(exam);
        future.get();

        return seatingArrangement;
    }

    // Method to get seating arrangement
    public Map<String, SeatingEntry> getSeatingArrangement(String institutionId, String examId) throws ExecutionException, InterruptedException {
        Exam exam = getExamById(institutionId, examId);
        if (exam == null) {
            throw new IllegalArgumentException("Exam not found with ID: " + examId);
        }
        return exam.getSeatingArrangement();
    }

    // Invigilator Assignment Methods
    public InvigilatorAssignment assignInvigilator(String institutionId, InvigilatorAssignment assignment) throws ExecutionException, InterruptedException {
        // Validate facultyId using UserService
        User faculty = userService.getUserById(institutionId, assignment.getFacultyId());
        if (faculty == null || !("faculty".equalsIgnoreCase(faculty.getRole()))) {
            throw new IllegalArgumentException("Invalid faculty ID or user is not a faculty member.");
        }

        if (assignment.getId() == null || assignment.getId().isEmpty()) {
            assignment.setId(UUID.randomUUID().toString());
        }
        assignment.setInstitutionId(institutionId);

        firestore.collection("Institutions").document(institutionId)
                 .collection("exams").document(assignment.getExamId())
                 .collection("invigilatorAssignments").document(assignment.getId())
                 .set(assignment).get();
        return assignment;
    }

    public List<InvigilatorAssignment> getInvigilatorAssignments(String institutionId, String examId) throws ExecutionException, InterruptedException {
        List<InvigilatorAssignment> assignments = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId)
                                                 .collection("exams").document(examId)
                                                 .collection("invigilatorAssignments").get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            assignments.add(document.toObject(InvigilatorAssignment.class));
        }
        return assignments;
    }

    public List<InvigilatorAssignment> getInvigilatorAssignmentsByRoom(String institutionId, String examId, String roomId) throws ExecutionException, InterruptedException {
        List<InvigilatorAssignment> assignments = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId)
                                                 .collection("exams").document(examId)
                                                 .collection("invigilatorAssignments")
                                                 .whereEqualTo("roomId", roomId).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            assignments.add(document.toObject(InvigilatorAssignment.class));
        }
        return assignments;
    }

    public void deleteInvigilatorAssignment(String institutionId, String examId, String assignmentId) throws ExecutionException, InterruptedException {
        firestore.collection("Institutions").document(institutionId)
                 .collection("exams").document(examId)
                 .collection("invigilatorAssignments").document(assignmentId)
                 .delete().get();
    }
}
