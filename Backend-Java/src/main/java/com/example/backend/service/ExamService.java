package com.example.backend.service;

import com.example.backend.models.Exam;
import com.example.backend.models.ExamScheduleEntry; // Import ExamScheduleEntry
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.WriteResult;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.DocumentSnapshot;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map; // Import Map
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class ExamService {

    private final Firestore firestore;

    public ExamService(Firestore firestore) {
        this.firestore = firestore;
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
        // Fetch the existing exam
        Exam exam = getExamById(institutionId, examId);
        if (exam == null) {
            throw new IllegalArgumentException("Exam not found with ID: " + examId);
        }

        // Set the frozen candidate list
        exam.setFrozenCandidateList(studentUids);

        // Update the exam in Firestore
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("exams").document(examId).set(exam);
        future.get();
    }

    public void updateExamSchedule(String institutionId, String examId, Map<String, ExamScheduleEntry> newSchedule) throws ExecutionException, InterruptedException {
        // Fetch the existing exam
        Exam exam = getExamById(institutionId, examId);
        if (exam == null) {
            throw new IllegalArgumentException("Exam not found with ID: " + examId);
        }

        // Set the new schedule
        exam.setSchedule(newSchedule);

        // Update the exam in Firestore
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("exams").document(examId).set(exam);
        future.get();
    }
}
