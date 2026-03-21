package com.example.backend.service;

import com.example.backend.models.Assessment;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class AssessmentService {

    private final Firestore firestore;

    public AssessmentService(Firestore firestore) {
        this.firestore = firestore;
    }

    public Assessment createAssessment(String institutionId, Assessment assessment) throws ExecutionException, InterruptedException {
        DocumentReference docRef = firestore.collection("Institutions")
                .document(institutionId)
                .collection("assessments")
                .document();
        assessment.setId(docRef.getId());
        assessment.setInstitutionId(institutionId);
        docRef.set(assessment).get();
        return assessment;
    }

    public List<Assessment> getAssessmentsByCourse(String institutionId, String courseCode) throws ExecutionException, InterruptedException {
        QuerySnapshot querySnapshot = firestore.collection("Institutions")
                .document(institutionId)
                .collection("assessments")
                .whereEqualTo("courseCode", courseCode)
                .get().get();
        
        List<Assessment> assessments = new ArrayList<>();
        for (DocumentSnapshot doc : querySnapshot.getDocuments()) {
            assessments.add(doc.toObject(Assessment.class));
        }
        return assessments;
    }

    public void deleteAssessment(String institutionId, String assessmentId) throws ExecutionException, InterruptedException {
        firestore.collection("Institutions")
                .document(institutionId)
                .collection("assessments")
                .document(assessmentId)
                .delete().get();
    }
}
