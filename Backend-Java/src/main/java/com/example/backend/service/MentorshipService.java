package com.example.backend.service;

import com.example.backend.models.MenteeConcern;
import com.example.backend.models.MentorMeeting;
import com.example.backend.models.User;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class MentorshipService {

    private static final Logger logger = LoggerFactory.getLogger(MentorshipService.class);
    private final Firestore firestore;
    private final AttendanceService attendanceService;

    public MentorshipService(Firestore firestore, AttendanceService attendanceService) {
        this.firestore = firestore;
        this.attendanceService = attendanceService;
    }

    public void syncMenteeAcademicData(String institutionId, String studentId) throws ExecutionException, InterruptedException {
        logger.info("Syncing academic data for student: {}", studentId);
        List<com.example.backend.dto.SubjectWiseAttendance> subjectAttendance = attendanceService.getSubjectWiseAttendance(institutionId, studentId);
        
        if (subjectAttendance.isEmpty()) return;

        double totalPct = 0;
        for (com.example.backend.dto.SubjectWiseAttendance sa : subjectAttendance) {
            totalPct += sa.getAttendancePercentage();
        }
        double avgAttendance = totalPct / subjectAttendance.size();

        DocumentReference userRef = firestore.collection("Institutions").document(institutionId).collection("users").document(studentId);
        
        // Update current and add to history
        firestore.runTransaction(transaction -> {
            DocumentSnapshot snapshot = transaction.get(userRef).get();
            @SuppressWarnings("unchecked")
            List<Double> history = (List<Double>) snapshot.get("attendanceHistory");
            if (history == null) history = new ArrayList<>();
            
            // Keep only last 10 points for trend
            history.add(avgAttendance);
            if (history.size() > 10) history.remove(0);

            transaction.update(userRef, "attendancePercentage", avgAttendance);
            transaction.update(userRef, "attendanceHistory", history);
            return null;
        }).get();
    }

    public void assignMentor(String institutionId, String mentorId, List<String> studentIds) throws ExecutionException, InterruptedException {
        logger.info("Service: Assigning mentor {} to {} students", mentorId, studentIds.size());
        DocumentReference mentorRef = firestore.collection("Institutions").document(institutionId).collection("users").document(mentorId);
        DocumentSnapshot mentorDoc = mentorRef.get().get();
        String mentorName = mentorDoc.getString("displayName");

        CollectionReference usersRef = firestore.collection("Institutions").document(institutionId).collection("users");
        
        WriteBatch batch = firestore.batch();
        for (String studentId : studentIds) {
            DocumentReference studentRef = usersRef.document(studentId);
            batch.update(studentRef, "mentorId", mentorId);
            if (mentorName != null) {
                batch.update(studentRef, "mentorName", mentorName);
            }
        }
        batch.commit().get();
    }

    public List<User> getMentees(String institutionId, String mentorId) throws ExecutionException, InterruptedException {
        logger.info("Service: Querying mentees for mentorId: {} in institution: {}", mentorId, institutionId);
        CollectionReference usersRef = firestore.collection("Institutions").document(institutionId).collection("users");
        Query query = usersRef.whereEqualTo("mentorId", mentorId);
        
        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<User> mentees = new ArrayList<>();
        for (DocumentSnapshot document : querySnapshot.get().getDocuments()) {
            try {
                User user = document.toObject(User.class);
                if (user != null) {
                    user.setUid(document.getId());
                    mentees.add(user);
                }
            } catch (Exception e) {
                logger.error("Error converting document {} to User object", document.getId(), e);
            }
        }
        return mentees;
    }

    public User getMentee(String institutionId, String mentorId, String menteeId) throws ExecutionException, InterruptedException {
        DocumentReference userRef = firestore.collection("Institutions").document(institutionId).collection("users").document(menteeId);
        DocumentSnapshot userDoc = userRef.get().get();
        
        if (userDoc.exists()) {
            User user = userDoc.toObject(User.class);
            if (user != null) {
                // Security Check: Only allow if the mentor is actually assigned to this student
                if (mentorId.equals(user.getMentorId())) {
                    user.setUid(userDoc.getId());
                    return user;
                }
            }
        }
        return null;
    }

    public User getMentor(String institutionId, String studentId) throws ExecutionException, InterruptedException {
        DocumentReference studentRef = firestore.collection("Institutions").document(institutionId).collection("users").document(studentId);
        DocumentSnapshot studentDoc = studentRef.get().get();
        
        if (studentDoc.exists()) {
            String mentorId = studentDoc.getString("mentorId");
            if (mentorId != null) {
                DocumentSnapshot mentorDoc = firestore.collection("Institutions").document(institutionId).collection("users").document(mentorId).get().get();
                if (mentorDoc.exists()) {
                    User mentor = mentorDoc.toObject(User.class);
                    if (mentor != null) {
                        mentor.setUid(mentorDoc.getId());
                        return mentor;
                    }
                }
            }
        }
        return null;
    }

    public void createMeeting(String institutionId, MentorMeeting meeting) throws ExecutionException, InterruptedException {
        DocumentReference meetingRef = firestore.collection("Institutions").document(institutionId).collection("mentor_meetings").document();
        meeting.setId(meetingRef.getId());
        meetingRef.set(meeting).get();
    }

    public List<MentorMeeting> getMeetings(String institutionId, String userId, String role, String studentId) throws ExecutionException, InterruptedException {
        CollectionReference meetingsRef = firestore.collection("Institutions").document(institutionId).collection("mentor_meetings");
        Query query;
        if ("faculty".equals(role)) {
            query = meetingsRef.whereEqualTo("mentorId", userId);
            if (studentId != null && !studentId.isEmpty()) {
                query = query.whereEqualTo("studentId", studentId);
            }
        } else {
            query = meetingsRef.whereEqualTo("studentId", userId);
        }
        
        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<MentorMeeting> meetings = new ArrayList<>();
        for (DocumentSnapshot document : querySnapshot.get().getDocuments()) {
            meetings.add(document.toObject(MentorMeeting.class));
        }
        return meetings;
    }

    public void updateMeetingStatus(String institutionId, String meetingId, String status) throws ExecutionException, InterruptedException {
        DocumentReference meetingRef = firestore.collection("Institutions").document(institutionId).collection("mentor_meetings").document(meetingId);
        meetingRef.update("status", status).get();
    }

    public void completeMeeting(String institutionId, String meetingId, String notes, String followUp, List<String> attachments) throws ExecutionException, InterruptedException {
        DocumentReference meetingRef = firestore.collection("Institutions").document(institutionId).collection("mentor_meetings").document(meetingId);
        Map<String, Object> updates = new java.util.HashMap<>();
        updates.put("status", "Completed");
        updates.put("notes", notes);
        updates.put("followUpAction", followUp);
        updates.put("attachments", attachments);
        meetingRef.update(updates).get();
    }

    public void updateActionItems(String institutionId, String meetingId, List<Map<String, Object>> actionItems) throws ExecutionException, InterruptedException {
        DocumentReference meetingRef = firestore.collection("Institutions").document(institutionId).collection("mentor_meetings").document(meetingId);
        meetingRef.update("actionItems", actionItems).get();
    }

    public void raiseConcern(String institutionId, MenteeConcern concern) throws ExecutionException, InterruptedException {
        DocumentReference concernRef = firestore.collection("Institutions").document(institutionId).collection("mentee_concerns").document();
        concern.setId(concernRef.getId());
        concernRef.set(concern).get();
    }

    public List<MenteeConcern> getConcerns(String institutionId, String userId, String role, String studentId) throws ExecutionException, InterruptedException {
        CollectionReference concernsRef = firestore.collection("Institutions").document(institutionId).collection("mentee_concerns");
        Query query;
        if ("faculty".equals(role)) {
            query = concernsRef.whereEqualTo("mentorId", userId);
            if (studentId != null && !studentId.isEmpty()) {
                query = query.whereEqualTo("studentId", studentId);
            }
        } else {
            query = concernsRef.whereEqualTo("studentId", userId);
        }
        
        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        List<MenteeConcern> concerns = new ArrayList<>();
        for (DocumentSnapshot document : querySnapshot.get().getDocuments()) {
            concerns.add(document.toObject(MenteeConcern.class));
        }
        return concerns;
    }

    public void updateConcernStatus(String institutionId, String concernId, String status, String remarks) throws ExecutionException, InterruptedException {
        DocumentReference concernRef = firestore.collection("Institutions").document(institutionId).collection("mentee_concerns").document(concernId);
        Map<String, Object> updates = new java.util.HashMap<>();
        updates.put("status", status);
        if (remarks != null) {
            updates.put("mentorRemarks", remarks);
        }
        concernRef.update(updates).get();
    }

    public Map<String, Long> getMentorshipStats(String institutionId) throws ExecutionException, InterruptedException {
        CollectionReference meetingsRef = firestore.collection("Institutions").document(institutionId).collection("mentor_meetings");
        AggregateQuerySnapshot meetingsSnapshot = meetingsRef.count().get().get();
        long totalMeetings = meetingsSnapshot.getCount();

        CollectionReference concernsRef = firestore.collection("Institutions").document(institutionId).collection("mentee_concerns");
        AggregateQuerySnapshot concernsSnapshot = concernsRef.whereNotEqualTo("status", "Resolved").count().get().get();
        long activeConcerns = concernsSnapshot.getCount();

        Map<String, Long> stats = new java.util.HashMap<>();
        stats.put("totalMeetings", totalMeetings);
        stats.put("activeConcerns", activeConcerns);
        return stats;
    }
}
