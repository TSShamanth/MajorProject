package com.example.backend.models;

public class Marks {
    private String id;
    private String studentId;
    private String courseCode;
    private String institutionId;
    private String semester;
    private String type; // "Assignment", "Internal Test", "Project", "Final Exam"
    private String title; // e.g., "Unit Test 1", "Lab Project"
    private double obtainedMarks;
    private double totalMarks;
    private String examId; // Optional: Link to a specific Exam if type is "Final Exam" or "Internal Test"
    private long timestamp;

    public Marks() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }

    public String getCourseCode() { return courseCode; }
    public void setCourseCode(String courseCode) { this.courseCode = courseCode; }

    public String getInstitutionId() { return institutionId; }
    public void setInstitutionId(String institutionId) { this.institutionId = institutionId; }

    public String getSemester() { return semester; }
    public void setSemester(String semester) { this.semester = semester; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public double getObtainedMarks() { return obtainedMarks; }
    public void setObtainedMarks(double obtainedMarks) { this.obtainedMarks = obtainedMarks; }

    public double getTotalMarks() { return totalMarks; }
    public void setTotalMarks(double totalMarks) { this.totalMarks = totalMarks; }

    public String getExamId() { return examId; }
    public void setExamId(String examId) { this.examId = examId; }

    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }
}
