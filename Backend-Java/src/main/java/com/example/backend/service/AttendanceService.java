package com.example.backend.service;

import com.example.backend.models.Attendance;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;

import java.util.List;

import java.util.concurrent.ExecutionException;

@Service
public class AttendanceService {

    private final Firestore firestore;

    @Autowired
    public AttendanceService(Firestore firestore) {
        this.firestore = firestore;
    }

    private CollectionReference getAttendanceCollection(String institutionId, String departmentId, String courseCode) {
        return firestore.collection("Institutions").document(institutionId)
                .collection("departments").document(departmentId)
                .collection("courses").document(courseCode)
                .collection("attendance");
    }

    /**
     * Marks attendance for a list of students for a specific course and date.
     * Overwrites existing attendance for the same course, date, and student.
     */
    public List<Attendance> markAttendance(
            String institutionId, String departmentId, String courseCode, List<Attendance> attendanceRecords)
            throws ExecutionException, InterruptedException {

        WriteBatch batch = firestore.batch();
        List<Attendance> savedRecords = new ArrayList<>();

        for (Attendance record : attendanceRecords) {
            record.setInstitutionId(institutionId);
            record.setDepartmentId(departmentId);
            record.setCourseCode(courseCode);

            // Generate a document ID if not provided, or use existing for updates
            String docId = (record.getId() != null && !record.getId().isEmpty()) ? record.getId() :
                    getAttendanceCollection(institutionId, departmentId, courseCode).document().getId();
            record.setId(docId);

            DocumentReference docRef = getAttendanceCollection(institutionId, departmentId, courseCode).document(docId);
            batch.set(docRef, record);
            savedRecords.add(record);
        }

        batch.commit().get();
        return savedRecords;
    }

    /**
     * Retrieves all attendance records for a given course.
     */
    public List<Attendance> getAttendanceForCourse(String institutionId, String departmentId, String courseCode)
            throws ExecutionException, InterruptedException {
        CollectionReference attendanceRef = getAttendanceCollection(institutionId, departmentId, courseCode);
        ApiFuture<QuerySnapshot> future = attendanceRef.get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        List<Attendance> attendanceList = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            attendanceList.add(document.toObject(Attendance.class));
        }
        return attendanceList;
    }

    /**
     * Retrieves all attendance records for a given student across all courses they are enrolled in.
     * This requires iterating through courses to find student-specific attendance.
     */
    public List<Attendance> getAttendanceForStudent(String institutionId, String studentUid)
            throws ExecutionException, InterruptedException {
        List<Attendance> studentAttendance = new ArrayList<>();

        // Get all departments for the institution
        CollectionReference departmentsRef = firestore.collection("Institutions").document(institutionId)
                .collection("departments");
        ApiFuture<QuerySnapshot> departmentsFuture = departmentsRef.get();
        List<QueryDocumentSnapshot> departmentDocuments = departmentsFuture.get().getDocuments();

        for (QueryDocumentSnapshot deptDoc : departmentDocuments) {
            String departmentId = deptDoc.getId();

            // Get all courses for each department
            CollectionReference coursesRef = firestore.collection("institutions").document(institutionId)
                    .collection("departments").document(departmentId)
                    .collection("courses");
            ApiFuture<QuerySnapshot> coursesFuture = coursesRef.get();
            List<QueryDocumentSnapshot> courseDocuments = coursesFuture.get().getDocuments();

            for (QueryDocumentSnapshot courseDoc : courseDocuments) {
                String courseCode = courseDoc.getId();

                // Get attendance for this specific course, filtering by studentUid
                CollectionReference attendanceRef = getAttendanceCollection(institutionId, departmentId, courseCode);
                ApiFuture<QuerySnapshot> attendanceFuture = attendanceRef.whereEqualTo("studentUid", studentUid).get();
                List<QueryDocumentSnapshot> attendanceDocuments = attendanceFuture.get().getDocuments();

                for (QueryDocumentSnapshot attendanceDoc : attendanceDocuments) {
                    studentAttendance.add(attendanceDoc.toObject(Attendance.class));
                }
            }
        }
        return studentAttendance;
    }
    
    /**
     * Retrieves all attendance records for a given course and specific date.
     */
    public List<Attendance> getAttendanceForDate(String institutionId, String departmentId, String courseCode, String date)
            throws ExecutionException, InterruptedException {
        CollectionReference attendanceRef = getAttendanceCollection(institutionId, departmentId, courseCode);
        ApiFuture<QuerySnapshot> future = attendanceRef.whereEqualTo("date", date).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        List<Attendance> attendanceList = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            attendanceList.add(document.toObject(Attendance.class));
        }
        return attendanceList;
    }
}