package com.example.backend.models;

public class InvigilatorAssignment {
    private String id;
    private String examId;
    private String roomId;
    private String facultyId;
    private String institutionId;
    private String session; // e.g., "Morning", "Afternoon", or could be tied to exam schedule entry

    public InvigilatorAssignment() {
    }

    public InvigilatorAssignment(String id, String examId, String roomId, String facultyId, String institutionId, String session) {
        this.id = id;
        this.examId = examId;
        this.roomId = roomId;
        this.facultyId = facultyId;
        this.institutionId = institutionId;
        this.session = session;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getExamId() {
        return examId;
    }

    public void setExamId(String examId) {
        this.examId = examId;
    }

    public String getRoomId() {
        return roomId;
    }

    public void setRoomId(String roomId) {
        this.roomId = roomId;
    }

    public String getFacultyId() {
        return facultyId;
    }

    public void setFacultyId(String facultyId) {
        this.facultyId = facultyId;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }

    public String getSession() {
        return session;
    }

    public void setSession(String session) {
        this.session = session;
    }
}
