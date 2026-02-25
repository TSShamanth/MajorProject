package com.example.backend.models;

public class MenteeConcern {
    private String id;
    private String studentId;
    private String mentorId;
    private String concernType;
    private String description;
    private String priority; // Low, Medium, High
    private String mentorRemarks; // Response from mentor
    private String status;
    private String createdAt;
    private java.util.List<String> attachments; // Document URLs

    public MenteeConcern() {
    }

    public java.util.List<String> getAttachments() {
        return attachments;
    }

    public void setAttachments(java.util.List<String> attachments) {
        this.attachments = attachments;
    }

    public String getPriority() {
        return priority;
    }

    public void setPriority(String priority) {
        this.priority = priority;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getStudentId() {
        return studentId;
    }

    public void setStudentId(String studentId) {
        this.studentId = studentId;
    }

    public String getMentorId() {
        return mentorId;
    }

    public void setMentorId(String mentorId) {
        this.mentorId = mentorId;
    }

    public String getConcernType() {
        return concernType;
    }

    public void setConcernType(String concernType) {
        this.concernType = concernType;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getMentorRemarks() {
        return mentorRemarks;
    }

    public void setMentorRemarks(String mentorRemarks) {
        this.mentorRemarks = mentorRemarks;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
}
