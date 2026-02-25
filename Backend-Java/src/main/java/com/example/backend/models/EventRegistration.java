package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;

public class EventRegistration {
    @DocumentId
    private String id; // Typically eventId + "_" + userId
    private String eventId;
    private String userId;
    private String institutionId;
    
    private String userName;
    private String userEmail;
    private String userRole;
    private String departmentId;
    
    private Long registeredAt;
    private String status; // REGISTERED, WAITLISTED, ATTENDED, CANCELLED
    
    private String feedbackRating; // Added for Feedback System
    private String feedbackComment;

    public EventRegistration() {
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getInstitutionId() { return institutionId; }
    public void setInstitutionId(String institutionId) { this.institutionId = institutionId; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public String getUserRole() { return userRole; }
    public void setUserRole(String userRole) { this.userRole = userRole; }

    public String getDepartmentId() { return departmentId; }
    public void setDepartmentId(String departmentId) { this.departmentId = departmentId; }

    public long getRegisteredAt() { return registeredAt; }
    public void setRegisteredAt(long registeredAt) { this.registeredAt = registeredAt; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getFeedbackRating() { return feedbackRating; }
    public void setFeedbackRating(String feedbackRating) { this.feedbackRating = feedbackRating; }

    public String getFeedbackComment() { return feedbackComment; }
    public void setFeedbackComment(String feedbackComment) { this.feedbackComment = feedbackComment; }
}
