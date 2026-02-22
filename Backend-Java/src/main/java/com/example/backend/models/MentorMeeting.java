package com.example.backend.models;

public class MentorMeeting {
    private String id;
    private String mentorId;
    private String studentId;
    private String studentName;
    private String date; // ISO-8601 String
    private String notes;
    private String followUpAction;
    private java.util.List<java.util.Map<String, Object>> actionItems; // Checklist items
    private String status;
    private String mode; // Online, Offline
    private java.util.List<String> attachments; // Document URLs

    public MentorMeeting() {
    }

    public java.util.List<String> getAttachments() {
        return attachments;
    }

    public void setAttachments(java.util.List<String> attachments) {
        this.attachments = attachments;
    }

    public String getMode() {
        return mode;
    }

    public void setMode(String mode) {
        this.mode = mode;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getMentorId() {
        return mentorId;
    }

    public void setMentorId(String mentorId) {
        this.mentorId = mentorId;
    }

    public String getStudentId() {
        return studentId;
    }

    public void setStudentId(String studentId) {
        this.studentId = studentId;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public String getFollowUpAction() {
        return followUpAction;
    }

    public void setFollowUpAction(String followUpAction) {
        this.followUpAction = followUpAction;
    }

    public java.util.List<java.util.Map<String, Object>> getActionItems() {
        return actionItems;
    }

    public void setActionItems(java.util.List<java.util.Map<String, Object>> actionItems) {
        this.actionItems = actionItems;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
