package com.example.backend.service;

import com.example.backend.models.TimetableEntry;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class TimetableService {

    private final Firestore firestore;

    public TimetableService(Firestore firestore) {
        this.firestore = firestore;
    }

    public TimetableEntry assignTimetable(TimetableEntry entry) throws ExecutionException, InterruptedException {
        validateConflict(entry);
        String id = UUID.randomUUID().toString();
        entry.setId(id);
        ApiFuture<WriteResult> future = firestore.collection("Institutions")
                .document(entry.getInstitutionId())
                .collection("timetable")
                .document(id)
                .set(entry);
        future.get();
        return entry;
    }

    private void validateConflict(TimetableEntry entry) throws ExecutionException, InterruptedException {
        CollectionReference timetableRef = firestore.collection("Institutions")
                .document(entry.getInstitutionId())
                .collection("timetable");

        // Rule 1: Faculty cannot have 2 classes at same time
        ApiFuture<QuerySnapshot> facultyConflict = timetableRef
                .whereEqualTo("facultyUid", entry.getFacultyUid())
                .whereEqualTo("day", entry.getDay())
                .whereEqualTo("timeSlotId", entry.getTimeSlotId())
                .get();
        
        for (DocumentSnapshot doc : facultyConflict.get().getDocuments()) {
            if (entry.getId() == null || !doc.getId().equals(entry.getId())) {
                throw new RuntimeException("Faculty is already assigned to another class at this time.");
            }
        }

        // Rule 2: Room cannot be double booked
        ApiFuture<QuerySnapshot> roomConflict = timetableRef
                .whereEqualTo("roomId", entry.getRoomId())
                .whereEqualTo("day", entry.getDay())
                .whereEqualTo("timeSlotId", entry.getTimeSlotId())
                .get();
        
        for (DocumentSnapshot doc : roomConflict.get().getDocuments()) {
            if (entry.getId() == null || !doc.getId().equals(entry.getId())) {
                throw new RuntimeException("Room is already booked for another class at this time.");
            }
        }

        // Rule 3: Same class cannot have 2 subjects same slot
        ApiFuture<QuerySnapshot> classConflict = timetableRef
                .whereEqualTo("departmentId", entry.getDepartmentId())
                .whereEqualTo("program", entry.getProgram())
                .whereEqualTo("semester", entry.getSemester())
                .whereEqualTo("sectionId", entry.getSectionId())
                .whereEqualTo("day", entry.getDay())
                .whereEqualTo("timeSlotId", entry.getTimeSlotId())
                .get();
        
        for (DocumentSnapshot doc : classConflict.get().getDocuments()) {
            if (entry.getId() == null || !doc.getId().equals(entry.getId())) {
                throw new RuntimeException("This class already has a subject assigned for this slot.");
            }
        }
    }

    public List<TimetableEntry> getTimetableForClass(String institutionId, String departmentId, String program, String semester, String sectionId) throws ExecutionException, InterruptedException {
        List<TimetableEntry> entries = new ArrayList<>();
        Query query = firestore.collection("Institutions")
                .document(institutionId)
                .collection("timetable")
                .whereEqualTo("sectionId", sectionId);
        
        ApiFuture<QuerySnapshot> future = query.get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            entries.add(document.toObject(TimetableEntry.class));
        }
        return entries;
    }

    public List<TimetableEntry> getTimetableForFaculty(String institutionId, String facultyUid) throws ExecutionException, InterruptedException {
        List<TimetableEntry> entries = new ArrayList<>();
        Query query = firestore.collection("Institutions")
                .document(institutionId)
                .collection("timetable")
                .whereEqualTo("facultyUid", facultyUid);
        
        ApiFuture<QuerySnapshot> future = query.get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            entries.add(document.toObject(TimetableEntry.class));
        }
        return entries;
    }

    public void updateTimetable(TimetableEntry entry) throws ExecutionException, InterruptedException {
        validateConflict(entry);
        ApiFuture<WriteResult> future = firestore.collection("Institutions")
                .document(entry.getInstitutionId())
                .collection("timetable")
                .document(entry.getId())
                .set(entry);
        future.get();
    }

    public void deleteTimetable(String institutionId, String id) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore.collection("Institutions")
                .document(institutionId)
                .collection("timetable")
                .document(id)
                .delete();
        future.get();
    }
}
