package com.example.backend.service;

import com.example.backend.models.Marks;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class MarksService {

    private final Firestore firestore;
    private final CourseService courseService;

    public MarksService(Firestore firestore, CourseService courseService) {
        this.firestore = firestore;
        this.courseService = courseService;
    }

    public Marks saveMarks(String institutionId, Marks marks) throws ExecutionException, InterruptedException {
        if (marks.getId() == null || marks.getId().isEmpty()) {
            marks.setId(UUID.randomUUID().toString());
        }
        if (marks.getTimestamp() == 0) {
            marks.setTimestamp(System.currentTimeMillis());
        }
        
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId)
                .collection("marks").document(marks.getId()).set(marks);
        future.get();
        return marks;
    }

    public List<Marks> getMarksByStudent(String institutionId, String studentId) throws ExecutionException, InterruptedException {
        List<Marks> marksList = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId)
                .collection("marks").whereEqualTo("studentId", studentId).get();
        
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            marksList.add(document.toObject(Marks.class));
        }
        return marksList;
    }

    public Map<String, Object> getAcademicSummary(String institutionId, String studentId) throws ExecutionException, InterruptedException {
        List<Marks> allMarks = getMarksByStudent(institutionId, studentId);
        
        int assignmentsCount = 0;
        int assignmentsTotal = 5; // Placeholder target, could be dynamic
        
        int testsCount = 0;
        int testsTotal = 3; // Placeholder target
        
        int projectsCount = 0;
        int projectsTotal = 1; // Placeholder target

        double totalObtained = 0;
        double totalMax = 0;
        int examsCount = 0;

        double earnedCredits = 0;
        double totalCredits = 0;
        Set<String> processedCourses = new HashSet<>();

        for (Marks m : allMarks) {
            if ("Assignment".equalsIgnoreCase(m.getType())) assignmentsCount++;
            else if ("Internal Test".equalsIgnoreCase(m.getType())) testsCount++;
            else if ("Project".equalsIgnoreCase(m.getType())) projectsCount++;
            else if ("Final Exam".equalsIgnoreCase(m.getType())) {
                examsCount++;
                totalObtained += m.getObtainedMarks();
                totalMax += m.getTotalMarks();

                // Credit calculation: use actual course credits
                if (!processedCourses.contains(m.getCourseCode())) {
                    int courseCredits = 4; // Default
                    try {
                        com.example.backend.models.Course course = courseService.getCourseByCode(institutionId, m.getCourseCode());
                        if (course != null) {
                            courseCredits = course.getCredits();
                        }
                    } catch (Exception e) {
                        // Keep default
                    }

                    totalCredits += courseCredits;
                    if (m.getTotalMarks() > 0 && (m.getObtainedMarks() / m.getTotalMarks() >= 0.4)) {
                        earnedCredits += courseCredits;
                    }
                    processedCourses.add(m.getCourseCode());
                }
            }
        }

        Map<String, Object> summary = new HashMap<>();
        summary.put("assignmentsCompleted", assignmentsCount);
        summary.put("assignmentsTotal", assignmentsTotal);
        summary.put("testsAttempted", testsCount);
        summary.put("testsTotal", testsTotal);
        summary.put("projectsSubmitted", projectsCount);
        summary.put("projectsTotal", projectsTotal);
        summary.put("examsTaken", examsCount);
        summary.put("averageExamScore", totalMax > 0 ? (totalObtained / totalMax * 100) : 0.0);
        
        summary.put("earnedCredits", earnedCredits);
        summary.put("totalCredits", totalCredits);
        summary.put("creditsPercentage", totalCredits > 0 ? (earnedCredits / totalCredits * 100) : 0.0);
        
        // Calculate percentages
        summary.put("assignmentsPercentage", (double) assignmentsCount / assignmentsTotal * 100);
        summary.put("testsPercentage", (double) testsCount / testsTotal * 100);
        summary.put("projectsPercentage", (double) projectsCount / projectsTotal * 100);
        summary.put("examsPercentage", totalMax > 0 ? (totalObtained / totalMax * 100) : 0.0);

        return summary;
    }
}
