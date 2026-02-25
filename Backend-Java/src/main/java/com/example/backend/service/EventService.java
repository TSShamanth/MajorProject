package com.example.backend.service;

import com.example.backend.models.Event;
import com.example.backend.models.EventRegistration;
import com.example.backend.models.User;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class EventService {

    private final Firestore firestore;

    public EventService(Firestore firestore) {
        this.firestore = firestore;
    }

    public Event createEvent(String institutionId, Event event) throws ExecutionException, InterruptedException {
        String eventId = UUID.randomUUID().toString();
        event.setId(eventId);
        event.setInstitutionId(institutionId);
        event.setCreatedAt(System.currentTimeMillis());
        event.setUpdatedAt(System.currentTimeMillis());
        event.setCurrentParticipants(0);
        
        if (event.getStatus() == null || event.getStatus().isEmpty()) {
            event.setStatus("PENDING_APPROVAL");
        }

        firestore.collection("Institutions").document(institutionId)
                .collection("events").document(eventId).set(event).get();
        return event;
    }

    public Event getEventById(String institutionId, String eventId) throws ExecutionException, InterruptedException {
        DocumentSnapshot doc = firestore.collection("Institutions").document(institutionId)
                .collection("events").document(eventId).get().get();
        return doc.exists() ? doc.toObject(Event.class) : null;
    }

    public List<Event> getEventsForAudience(String institutionId, String userRole, String departmentId, String programme) 
            throws ExecutionException, InterruptedException {
        
        // Fetch all events for the institution and filter in-memory to avoid index errors
        QuerySnapshot querySnapshot = firestore.collection("Institutions").document(institutionId)
                .collection("events")
                .get().get();

        return querySnapshot.getDocuments().stream()
                .map(doc -> doc.toObject(Event.class))
                .filter(Objects::nonNull)
                .filter(event -> "PUBLISHED".equalsIgnoreCase(event.getStatus()) || "APPROVED".equalsIgnoreCase(event.getStatus()))
                .filter(event -> isUserInTargetAudience(event, userRole, departmentId, programme))
                .sorted((e1, e2) -> {
                    if (e1.getStartDateTime() == null || e2.getStartDateTime() == null) return 0;
                    return e1.getStartDateTime().compareTo(e2.getStartDateTime());
                })
                .collect(Collectors.toList());
    }

    public List<Event> getAllEventsForManagement(String institutionId) throws ExecutionException, InterruptedException {
        QuerySnapshot querySnapshot = firestore.collection("Institutions").document(institutionId)
                .collection("events")
                .get().get();

        return querySnapshot.getDocuments().stream()
                .map(doc -> doc.toObject(Event.class))
                .filter(Objects::nonNull)
                .sorted((e1, e2) -> {
                    long t1 = e1.getCreatedAt() != null ? e1.getCreatedAt() : 0;
                    long t2 = e2.getCreatedAt() != null ? e2.getCreatedAt() : 0;
                    return Long.compare(t2, t1); // Newest first
                })
                .collect(Collectors.toList());
    }

    private boolean isUserInTargetAudience(Event event, String role, String deptId, String programme) {
        List<String> audience = event.getTargetAudience();
        if (audience == null || audience.isEmpty() || audience.contains("ALL")) return true;
        
        boolean roleMatch = audience.stream().anyMatch(a -> a.equalsIgnoreCase(role));
        if (!roleMatch) return false;

        List<String> depts = event.getTargetDepartments();
        if (depts == null || depts.isEmpty() || depts.contains("ALL")) return true;
        
        return depts.stream().anyMatch(d -> d.equalsIgnoreCase(deptId) || d.equalsIgnoreCase(programme));
    }

    /**
     * ATOMIC REGISTRATION: Uses a transaction to safely increment participants and check capacity.
     */
    public void registerForEvent(String institutionId, String eventId, User user) throws Exception {
        DocumentReference eventRef = firestore.collection("Institutions").document(institutionId)
                .collection("events").document(eventId);
        DocumentReference regRef = firestore.collection("Institutions").document(institutionId)
                .collection("event_registrations").document(eventId + "_" + user.getUid());

        firestore.runTransaction(transaction -> {
            DocumentSnapshot eventDoc = transaction.get(eventRef).get();
            if (!eventDoc.exists()) throw new RuntimeException("Event not found");

            Event event = eventDoc.toObject(Event.class);
            
            // 1. Check Capacity
            if (event.getCapacityLimit() > 0 && event.getCurrentParticipants() >= event.getCapacityLimit()) {
                throw new RuntimeException("Event is full");
            }

            // 2. Check Deadline
            if (System.currentTimeMillis() > event.getRegistrationDeadline()) {
                throw new RuntimeException("Registration deadline has passed");
            }

            // 3. Check Duplicate Registration
            DocumentSnapshot regDoc = transaction.get(regRef).get();
            if (regDoc.exists()) throw new RuntimeException("User already registered");

            // 4. Create Registration Record
            EventRegistration reg = new EventRegistration();
            reg.setId(eventId + "_" + user.getUid());
            reg.setEventId(eventId);
            reg.setUserId(user.getUid());
            reg.setInstitutionId(institutionId);
            reg.setUserName(user.getName());
            reg.setUserEmail(user.getEmail());
            reg.setUserRole(user.getRole());
            reg.setDepartmentId(user.getDepartmentId());
            reg.setRegisteredAt(System.currentTimeMillis());
            reg.setStatus("REGISTERED");

            transaction.set(regRef, reg);

            // 5. Atomic Increment
            transaction.update(eventRef, "currentParticipants", FieldValue.increment(1));

            return null;
        }).get();
    }

    public void updateEventStatus(String institutionId, String eventId, String status, String adminId) throws ExecutionException, InterruptedException {
        Map<String, Object> updates = new HashMap<>();
        updates.put("status", status);
        updates.put("updatedAt", System.currentTimeMillis());
        
        if ("APPROVED".equals(status) || "PUBLISHED".equals(status)) {
            updates.put("approvedBy", adminId);
            updates.put("approvedAt", System.currentTimeMillis());
        }

        firestore.collection("Institutions").document(institutionId)
                .collection("events").document(eventId).update(updates).get();
    }

    public List<EventRegistration> getRegistrationsForEvent(String institutionId, String eventId) throws ExecutionException, InterruptedException {
        QuerySnapshot querySnapshot = firestore.collection("Institutions").document(institutionId)
                .collection("event_registrations")
                .whereEqualTo("eventId", eventId)
                .get().get();
        
        return querySnapshot.toObjects(EventRegistration.class);
    }

    public List<Event> getEventsForUser(String institutionId, String userId) throws ExecutionException, InterruptedException {
        // 1. Get all registration records for this user
        QuerySnapshot regSnapshot = firestore.collection("Institutions").document(institutionId)
                .collection("event_registrations")
                .whereEqualTo("userId", userId)
                .get().get();

        if (regSnapshot.isEmpty()) return new ArrayList<>();

        List<String> eventIds = regSnapshot.getDocuments().stream()
                .map(doc -> doc.getString("eventId"))
                .collect(Collectors.toList());

        // 2. Fetch the actual Event objects (Firestore 'IN' query is limited to 10, so we might need batching for production, but strict loop for now is safer)
        List<Event> events = new ArrayList<>();
        for (String eid : eventIds) {
            Event e = getEventById(institutionId, eid);
            if (e != null) events.add(e);
        }
        return events;
    }

    public void markAttendance(String institutionId, String eventId, String userId, boolean present) throws ExecutionException, InterruptedException {
        String regId = eventId + "_" + userId;
        String status = present ? "ATTENDED" : "REGISTERED"; // Revert to REGISTERED if unchecked, or ABSENT if needed
        
        firestore.collection("Institutions").document(institutionId)
                .collection("event_registrations").document(regId)
                .update("status", status).get();
    }
}
