package com.example.backend.service;

import com.example.backend.models.Exam;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.WriteResult;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
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
}
