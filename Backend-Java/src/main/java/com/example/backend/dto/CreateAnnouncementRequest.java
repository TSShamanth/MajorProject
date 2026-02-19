package com.example.backend.dto;

import java.util.List;

public class CreateAnnouncementRequest {
    private String title;
    private String description;
    private String content;
    private String priority; // HIGH, MEDIUM, LOW
    private String category; // ACADEMIC, ADMINISTRATIVE, PLACEMENT, EVENT, OTHER
    private String status; // DRAFT, PUBLISHED
    private List<String> targetAudience;
    private List<String> targetDepartments;
    private long scheduledFor; // 0 for immediate
    private List<String> attachmentUrls;

    public CreateAnnouncementRequest() {
    }

    public CreateAnnouncementRequest(String title, String description, String content, String priority,
            String category, String status, List<String> targetAudience,
            List<String> targetDepartments, long scheduledFor, List<String> attachmentUrls) {
        this.title = title;
        this.description = description;
        this.content = content;
        this.priority = priority;
        this.category = category;
        this.status = status;
        this.targetAudience = targetAudience;
        this.targetDepartments = targetDepartments;
        this.scheduledFor = scheduledFor;
        this.attachmentUrls = attachmentUrls;
    }

    // Getters and Setters
    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getPriority() {
        return priority;
    }

    public void setPriority(String priority) {
        this.priority = priority;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public List<String> getTargetAudience() {
        return targetAudience;
    }

    public void setTargetAudience(List<String> targetAudience) {
        this.targetAudience = targetAudience;
    }

    public List<String> getTargetDepartments() {
        return targetDepartments;
    }

    public void setTargetDepartments(List<String> targetDepartments) {
        this.targetDepartments = targetDepartments;
    }

    public long getScheduledFor() {
        return scheduledFor;
    }

    public void setScheduledFor(long scheduledFor) {
        this.scheduledFor = scheduledFor;
    }

    public List<String> getAttachmentUrls() {
        return attachmentUrls;
    }

    public void setAttachmentUrls(List<String> attachmentUrls) {
        this.attachmentUrls = attachmentUrls;
    }
}
