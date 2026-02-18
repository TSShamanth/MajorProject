package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;
import java.util.List;
import java.util.Map;

public class Announcement {
    @DocumentId
    private String id;
    private String institutionId;
    private String title;
    private String description;
    private String content;
    private String createdBy;
    private String creatorName;
    private String creatorPhotoUrl;
    private long createdAt;
    private long updatedAt;
    private String priority; // HIGH, MEDIUM, LOW
    private String category; // ACADEMIC, ADMINISTRATIVE, PLACEMENT, EVENT, OTHER
    private String status; // DRAFT, PUBLISHED, ARCHIVED
    private List<String> targetAudience; // ALL, STUDENTS, FACULTY, ADMIN, ALUMNI
    private List<String> targetDepartments; // List of department IDs for targeted announcements
    private long scheduledFor; // Timestamp for scheduled announcements (0 if immediate)
    private List<String> attachmentUrls;
    private int viewCount;
    private List<Map<String, Object>> viewers; // List of {uid, viewedAt} objects
    private boolean isPinned;

    public Announcement() {
    }

    public Announcement(String id, String institutionId, String title, String description, String content,
            String createdBy, String creatorName, String creatorPhotoUrl, long createdAt,
            long updatedAt, String priority, String category, String status,
            List<String> targetAudience, List<String> targetDepartments,
            long scheduledFor, List<String> attachmentUrls, int viewCount,
            List<Map<String, Object>> viewers, boolean isPinned) {
        this.id = id;
        this.institutionId = institutionId;
        this.title = title;
        this.description = description;
        this.content = content;
        this.createdBy = createdBy;
        this.creatorName = creatorName;
        this.creatorPhotoUrl = creatorPhotoUrl;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.priority = priority;
        this.category = category;
        this.status = status;
        this.targetAudience = targetAudience;
        this.targetDepartments = targetDepartments;
        this.scheduledFor = scheduledFor;
        this.attachmentUrls = attachmentUrls;
        this.viewCount = viewCount;
        this.viewers = viewers;
        this.isPinned = isPinned;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }

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

    public String getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(String createdBy) {
        this.createdBy = createdBy;
    }

    public String getCreatorName() {
        return creatorName;
    }

    public void setCreatorName(String creatorName) {
        this.creatorName = creatorName;
    }

    public String getCreatorPhotoUrl() {
        return creatorPhotoUrl;
    }

    public void setCreatorPhotoUrl(String creatorPhotoUrl) {
        this.creatorPhotoUrl = creatorPhotoUrl;
    }

    public long getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(long createdAt) {
        this.createdAt = createdAt;
    }

    public long getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(long updatedAt) {
        this.updatedAt = updatedAt;
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

    public int getViewCount() {
        return viewCount;
    }

    public void setViewCount(int viewCount) {
        this.viewCount = viewCount;
    }

    public List<Map<String, Object>> getViewers() {
        return viewers;
    }

    public void setViewers(List<Map<String, Object>> viewers) {
        this.viewers = viewers;
    }

    public boolean isPinned() {
        return isPinned;
    }

    public void setPinned(boolean pinned) {
        isPinned = pinned;
    }
}
