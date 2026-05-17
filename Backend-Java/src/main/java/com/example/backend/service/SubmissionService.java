package com.example.backend.service;

import com.example.backend.models.Submission;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class SubmissionService {

    private final Firestore firestore;

    public SubmissionService(Firestore firestore) {
        this.firestore = firestore;
    }

    public Submission submitAssignment(String institutionId, Submission submission) throws ExecutionException, InterruptedException {
        DocumentReference docRef = firestore.collection("Institutions")
                .document(institutionId)
                .collection("submissions")
                .document();
        
        submission.setId(docRef.getId());
        submission.setSubmittedAt(System.currentTimeMillis());
        submission.setStatus("Submitted");
        
        docRef.set(submission).get();
        return submission;
    }

    public List<Submission> getSubmissionsByAssessment(String institutionId, String assessmentId) throws ExecutionException, InterruptedException {
        QuerySnapshot querySnapshot = firestore.collection("Institutions")
                .document(institutionId)
                .collection("submissions")
                .whereEqualTo("assessmentId", assessmentId)
                .get().get();
        
        List<Submission> submissions = new ArrayList<>();
        for (DocumentSnapshot doc : querySnapshot.getDocuments()) {
            submissions.add(doc.toObject(Submission.class));
        }
        return submissions;
    }

    public Submission getStudentSubmission(String institutionId, String assessmentId, String studentId) throws ExecutionException, InterruptedException {
        QuerySnapshot querySnapshot = firestore.collection("Institutions")
                .document(institutionId)
                .collection("submissions")
                .whereEqualTo("assessmentId", assessmentId)
                .whereEqualTo("studentId", studentId)
                .limit(1)
                .get().get();
        
        if (querySnapshot.isEmpty()) return null;
        return querySnapshot.getDocuments().get(0).toObject(Submission.class);
    }

    public Submission gradeSubmission(String institutionId, String submissionId, double marks, String feedback) throws ExecutionException, InterruptedException {
        DocumentReference docRef = firestore.collection("Institutions")
                .document(institutionId)
                .collection("submissions")
                .document(submissionId);
        
        docRef.update("marksObtained", marks, "feedback", feedback, "status", "Graded").get();
        return docRef.get().get().toObject(Submission.class);
    }
}
