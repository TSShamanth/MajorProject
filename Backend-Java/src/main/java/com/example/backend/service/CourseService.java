package com.example.backend.service;

import com.example.backend.models.Course;
import com.example.backend.models.User;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.lang.InterruptedException; // Explicitly adding for clarity
@Service
public class CourseService {

    private final Firestore firestore;
    private final UserService userService; // Inject UserService

    public CourseService(Firestore firestore, UserService userService) {
        this.firestore = firestore;
        this.userService = userService;
    }

    public Course createCourse(String institutionId, String departmentId, Course course) throws ExecutionException, InterruptedException {
        course.setDepartmentId(departmentId); // Explicitly set departmentId
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

    /**
     * Retrieves a Course by its courseCode, searching across all departments within an institution.
     * @param institutionId The ID of the institution.
     * @param courseCode The course code to search for.
     * @return The Course object if found, otherwise null.
     */
    public Course getCourseByCode(String institutionId, String courseCode) throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> departmentsFuture = firestore.collection("Institutions").document(institutionId).collection("departments").get();
        List<QueryDocumentSnapshot> departmentDocuments = departmentsFuture.get().getDocuments();

        for (QueryDocumentSnapshot deptDoc : departmentDocuments) {
            Course course = getCourse(institutionId, deptDoc.getId(), courseCode);
            if (course != null) {
                return course;
            }
        }
        return null;
    }

    public Course updateCourse(String institutionId, String departmentId, Course course) throws ExecutionException, InterruptedException {
        course.setDepartmentId(departmentId); // Explicitly set departmentId
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
        userService.updateAssignedCourses(institutionId, facultyId, new ArrayList<>()); // Update user document
    }    public void unassignStudent(String institutionId, String departmentId, String studentId) throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").whereArrayContains("studentsEnrolled", studentId).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        List<String> enrolledCourseCodes = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            Course course = document.toObject(Course.class);
            course.getStudentsEnrolled().remove(studentId);
            document.getReference().set(course);
            enrolledCourseCodes.add(course.getCourseCode());
        }
        userService.updateEnrolledCourses(institutionId, studentId, new ArrayList<>()); // Update user document
    }
    public void updateFacultyCourses(String institutionId, String departmentId, String facultyId, List<String> courseCodes) throws ExecutionException, InterruptedException {
        unassignFaculty(institutionId, departmentId, facultyId);
        for (String courseCode : courseCodes) {
            firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").document(courseCode).update("facultyUid", facultyId);
        }
        userService.updateAssignedCourses(institutionId, facultyId, courseCodes); // Update user document
    }
    public void updateStudentCourses(String institutionId, String departmentId, String studentId, List<String> courseCodes) throws ExecutionException, InterruptedException {
        unassignStudent(institutionId, departmentId, studentId);
        for (String courseCode : courseCodes) {
            firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).collection("courses").document(courseCode).update("studentsEnrolled", com.google.cloud.firestore.FieldValue.arrayUnion(studentId));
        }
        userService.updateEnrolledCourses(institutionId, studentId, courseCodes); // Update user document
    }

    /**
     * Retrieves all courses assigned to a specific faculty member.
     * @param institutionId The ID of the institution.
     * @param facultyUid The UID of the faculty member.
     * @return A list of Course objects assigned to the faculty.
     */
    public List<Course> getFacultyCourses(String institutionId, String facultyUid) throws ExecutionException, InterruptedException {
        List<Course> facultyCourses = new ArrayList<>();
        User faculty = userService.getUserById(institutionId, facultyUid);

        if (faculty != null && faculty.getAssignedCourseCodes() != null) {
            for (String courseCode : faculty.getAssignedCourseCodes()) {
                // To get a Course by courseCode, we need its departmentId.
                // Since assignedCourseCodes only contains courseCode, we need to search across departments.
                // This is not the most efficient, but works with current data model.
                ApiFuture<QuerySnapshot> departmentsFuture = firestore.collection("Institutions").document(institutionId).collection("departments").get();
                List<QueryDocumentSnapshot> departmentDocuments = departmentsFuture.get().getDocuments();

                for (QueryDocumentSnapshot deptDoc : departmentDocuments) {
                    Course course = getCourse(institutionId, deptDoc.getId(), courseCode);
                    if (course != null) {
                        facultyCourses.add(course);
                        break; // Found the course, move to next assignedCourseCode
                    }
                }
            }
        }
        return facultyCourses;
    }

    /**
     * Retrieves all students enrolled in a specific course.
     * @param institutionId The ID of the institution.
     * @param departmentId The ID of the department.
     * @param courseCode The code of the course.
     * @return A list of User objects (students) enrolled in the course.
     */
    public List<User> getStudentsForCourse(String institutionId, String departmentId, String courseCode) throws ExecutionException, InterruptedException {
        List<User> students = new ArrayList<>();
        Course course = getCourse(institutionId, departmentId, courseCode);
        if (course != null && course.getStudentsEnrolled() != null && !course.getStudentsEnrolled().isEmpty()) {
            for (String studentUid : course.getStudentsEnrolled()) {
                User student = userService.getUserById(institutionId, studentUid);
                if (student != null) {
                    students.add(student);
                }
            }
        }
        return students;
    }
}
