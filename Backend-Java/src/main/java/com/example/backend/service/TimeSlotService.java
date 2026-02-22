package com.example.backend.service;

import com.example.backend.models.TimeSlot;
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
public class TimeSlotService {

    private final Firestore firestore;

    public TimeSlotService(Firestore firestore) {
        this.firestore = firestore;
    }

    public TimeSlot createTimeSlot(TimeSlot timeSlot) throws ExecutionException, InterruptedException {
        String id = UUID.randomUUID().toString();
        timeSlot.setId(id);
        ApiFuture<WriteResult> future = firestore.collection("Institutions")
                .document(timeSlot.getInstitutionId())
                .collection("timeSlots")
                .document(id)
                .set(timeSlot);
        future.get();
        return timeSlot;
    }

    public List<TimeSlot> getTimeSlots(String institutionId) throws ExecutionException, InterruptedException {
        List<TimeSlot> timeSlots = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions")
                .document(institutionId)
                .collection("timeSlots")
                .get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            timeSlots.add(document.toObject(TimeSlot.class));
        }
        return timeSlots;
    }

    public void deleteTimeSlot(String institutionId, String timeSlotId) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore.collection("Institutions")
                .document(institutionId)
                .collection("timeSlots")
                .document(timeSlotId)
                .delete();
        future.get();
    }
}
