package com.example.backend.service;

import com.example.backend.models.Course;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class CourseService {

    private final Firestore firestore;

    public CourseService(Firestore firestore) {
        this.firestore = firestore;
    }

    public Course createCourse(String institutionId, String departmentId, Course course) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").document(course.getCourseCode()).set(course);
        future.get();
        return course;
    }

    public List<Course> getCourses(String institutionId, String departmentId) throws ExecutionException, InterruptedException {
        List<Course> courses = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            courses.add(document.toObject(Course.class));
        }
        return courses;
    }

    public Course getCourse(String institutionId, String departmentId, String courseCode) throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").whereEqualTo("courseCode", courseCode).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        if (documents.isEmpty()) {
            return null;
        }
        return documents.get(0).toObject(Course.class);
    }

    public Course updateCourse(String institutionId, String departmentId, Course course) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").document(course.getCourseCode()).set(course);
        future.get();
        return course;
    }

    public void deleteCourse(String institutionId, String departmentId, String courseCode) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").document(courseCode).delete();
        future.get();
    }
    public void unassignFaculty(String institutionId, String departmentId, String facultyId) throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").whereEqualTo("facultyUid", facultyId).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            document.getReference().update("facultyUid", null);
        }
    }    public void unassignStudent(String institutionId, String departmentId, String studentId) throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").whereArrayContains("studentsEnrolled", studentId).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            Course course = document.toObject(Course.class);
            course.getStudentsEnrolled().remove(studentId);
            document.getReference().set(course);
        }
    }
    public void updateFacultyCourses(String institutionId, String departmentId, String facultyId, List<String> courseCodes) throws ExecutionException, InterruptedException {
        unassignFaculty(institutionId, departmentId, facultyId);
        for (String courseCode : courseCodes) {
            firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").document(courseCode).update("facultyUid", facultyId);
        }
    }
    public void updateStudentCourses(String institutionId, String departmentId, String studentId, List<String> courseCodes) throws ExecutionException, InterruptedException {
        unassignStudent(institutionId, departmentId, studentId);
        for (String courseCode : courseCodes) {
            firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").document(courseCode).update("studentsEnrolled", com.google.cloud.firestore.FieldValue.arrayUnion(studentId));
        }
    }
}
