package com.example.backend.service;

import com.example.backend.models.WorkingDay;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class WorkingDayService {

    private final Firestore firestore;

    public WorkingDayService(Firestore firestore) {
        this.firestore = firestore;
    }

    public WorkingDay createWorkingDay(WorkingDay workingDay) throws ExecutionException, InterruptedException {
        String id = UUID.randomUUID().toString();
        workingDay.setId(id);
        ApiFuture<WriteResult> future = firestore.collection("Institutions")
                .document(workingDay.getInstitutionId())
                .collection("workingDays")
                .document(id)
                .set(workingDay);
        future.get();
        return workingDay;
    }

    public List<WorkingDay> getWorkingDays(String institutionId) throws ExecutionException, InterruptedException {
        List<WorkingDay> workingDays = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions")
                .document(institutionId)
                .collection("workingDays")
                .get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            workingDays.add(document.toObject(WorkingDay.class));
        }
        return workingDays;
    }

    public void updateWorkingDay(WorkingDay workingDay) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore.collection("Institutions")
                .document(workingDay.getInstitutionId())
                .collection("workingDays")
                .document(workingDay.getId())
                .set(workingDay);
        future.get();
    }
}
