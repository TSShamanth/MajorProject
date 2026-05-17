package com.example.backend.service;

public class ChatContext {
    private String institutionId;
    private String studentId;

    public ChatContext(String institutionId, String studentId) {
        this.institutionId = institutionId;
        this.studentId = studentId;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public String getStudentId() {
        return studentId;
    }
}
