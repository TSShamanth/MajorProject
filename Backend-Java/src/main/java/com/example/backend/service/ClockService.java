package com.example.backend.service;

import com.example.backend.dto.ClockRequest;
import com.example.backend.models.AttendanceLog;
import com.example.backend.models.Institution;
import com.example.backend.models.User;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

@Service
public class ClockService {

    private final Firestore firestore;
    private final UserService userService;
    private final FirestoreService firestoreService;

    private static final double EARTH_RADIUS = 6371e3; // meters

    public ClockService(Firestore firestore, UserService userService, FirestoreService firestoreService) {
        this.firestore = firestore;
        this.userService = userService;
        this.firestoreService = firestoreService;
    }

    private boolean isWithinGeofence(String institutionId, double userLat, double userLon, Institution institution) throws ExecutionException, InterruptedException {
        if (institution == null || institution.getLatitude() == null || institution.getLongitude() == null || institution.getGeofenceRadius() == null) {
            return true; // Default to true if geofence is not configured
        }

        double instLat = institution.getLatitude();
        double instLon = institution.getLongitude();
        double radius = institution.getGeofenceRadius();

        double latDistance = Math.toRadians(userLat - instLat);
        double lonDistance = Math.toRadians(userLon - instLon);

        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(instLat)) * Math.cos(Math.toRadians(userLat))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        double distance = EARTH_RADIUS * c;

        return distance <= radius;
    }

    public User clockIn(String institutionId, String facultyId, ClockRequest clockRequest) throws ExecutionException, InterruptedException {
        Institution institution = firestoreService.getInstitutionById(institutionId);
        boolean isWithinFence = isWithinGeofence(institutionId, clockRequest.getLatitude(), clockRequest.getLongitude(), institution);

        User faculty = userService.getUserById(institutionId, facultyId);
        if (faculty == null) {
            throw new IllegalArgumentException("Faculty not found.");
        }
        if ("Clocked-in".equals(faculty.getAttendanceStatus())) {
            throw new IllegalStateException("User is already clocked in.");
        }

        String logId = UUID.randomUUID().toString();
        AttendanceLog log = new AttendanceLog();
        log.setId(logId);
        log.setFacultyId(facultyId);
        log.setInstitutionId(institutionId);
        log.setClockInTime(new Date());
        log.setClockInLatitude(clockRequest.getLatitude());
        log.setClockInLongitude(clockRequest.getLongitude());
        
        if(isWithinFence) {
            log.setLocationStatus("On-Campus");
            log.setLocationDetail(institution.getName());
        } else {
            log.setLocationStatus("Off-Campus");
            log.setLocationDetail(String.format("Lat: %.4f, Lon: %.4f", clockRequest.getLatitude(), clockRequest.getLongitude()));
        }

        firestore.collection("Institutions").document(institutionId)
                .collection("attendance_logs").document(logId).set(log).get();

        faculty.setAttendanceStatus("Clocked-in");
        faculty.setActiveLogId(logId);
        userService.updateUser(institutionId, facultyId, faculty);

        return faculty;
    }

    public User clockOut(String institutionId, String facultyId, ClockRequest clockRequest) throws ExecutionException, InterruptedException {
        Institution institution = firestoreService.getInstitutionById(institutionId);
        boolean isWithinFence = isWithinGeofence(institutionId, clockRequest.getLatitude(), clockRequest.getLongitude(), institution);

        User faculty = userService.getUserById(institutionId, facultyId);
        if (faculty == null) {
            throw new IllegalArgumentException("Faculty not found.");
        }
        if (!"Clocked-in".equals(faculty.getAttendanceStatus()) || faculty.getActiveLogId() == null) {
            throw new IllegalStateException("User is not clocked in or has no active log.");
        }

        String logId = faculty.getActiveLogId();
        DocumentReference logRef = firestore.collection("Institutions").document(institutionId)
                .collection("attendance_logs").document(logId);
        AttendanceLog log = logRef.get().get().toObject(AttendanceLog.class);

        if (log == null) {
            faculty.setAttendanceStatus("Clocked-out");
            faculty.setActiveLogId(null);
            userService.updateUser(institutionId, facultyId, faculty);
            throw new IllegalStateException("Active attendance log not found. Forcing clock-out.");
        }

        Date clockOutTime = new Date();
        log.setClockOutTime(clockOutTime);
        log.setClockOutLatitude(clockRequest.getLatitude());
        log.setClockOutLongitude(clockRequest.getLongitude());

        // We can reuse the status from clock-in, but let's re-evaluate for clock-out
        if(isWithinFence) {
            log.setLocationStatus("On-Campus");
            // locationDetail would already be set from clock-in
        } else {
            // If they were on-campus for clock-in but off-campus for clock-out, we flag it.
            // For simplicity, we can just use the clock-out status.
            log.setLocationStatus("Off-Campus");
            log.setLocationDetail(String.format("Lat: %.4f, Lon: %.4f", clockRequest.getLatitude(), clockRequest.getLongitude()));
        }

        long diffInMillis = Math.abs(clockOutTime.getTime() - log.getClockInTime().getTime());
        long durationInMinutes = TimeUnit.MINUTES.convert(diffInMillis, TimeUnit.MILLISECONDS);
        log.setDuration(durationInMinutes);

        logRef.set(log).get();

        faculty.setAttendanceStatus("Clocked-out");
        faculty.setActiveLogId(null);
        userService.updateUser(institutionId, facultyId, faculty);

        return faculty;
    }

    public List<AttendanceLog> getAttendanceHistory(String institutionId, String facultyId) throws ExecutionException, InterruptedException {
        List<AttendanceLog> history = new ArrayList<>();
        firestore.collection("Institutions").document(institutionId)
                .collection("attendance_logs")
                .whereEqualTo("facultyId", facultyId)
                .orderBy("clockInTime", Query.Direction.DESCENDING)
                .get()
                .get()
                .forEach(document -> history.add(document.toObject(AttendanceLog.class)));
        return history;
    }
}
