package com.example.backend.models;

public class Assessment {
    private String id;
    private String institutionId;
    private String courseCode;
    private String semester;
    private String type; // "Assignment", "Internal Test", "Project", "Final Exam"
    private String title; // e.g., "Unit Test 1"
    private double maxMarks;
    private double weightage; // e.g., 0.1 for 10%
    private long date;
    private String createdBy; // Faculty UID
    private String instructions;
    private String markingScheme; // Description of how marks are awarded
    private boolean isSubmissionRequired; // True if students need to upload a file

    public Assessment() {}
    
    // ... existing getters/setters ...

    public String getInstructions() { return instructions; }
    public void setInstructions(String instructions) { this.instructions = instructions; }

    public String getMarkingScheme() { return markingScheme; }
    public void setMarkingScheme(String markingScheme) { this.markingScheme = markingScheme; }

    public boolean isSubmissionRequired() { return isSubmissionRequired; }
    public void setSubmissionRequired(boolean submissionRequired) { isSubmissionRequired = submissionRequired; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getInstitutionId() { return institutionId; }
    public void setInstitutionId(String institutionId) { this.institutionId = institutionId; }

    public String getCourseCode() { return courseCode; }
    public void setCourseCode(String courseCode) { this.courseCode = courseCode; }

    public String getSemester() { return semester; }
    public void setSemester(String semester) { this.semester = semester; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public double getMaxMarks() { return maxMarks; }
    public void setMaxMarks(double maxMarks) { this.maxMarks = maxMarks; }

    public double getWeightage() { return weightage; }
    public void setWeightage(double weightage) { this.weightage = weightage; }

    public long getDate() { return date; }
    public void setDate(long date) { this.date = date; }

    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }
}
