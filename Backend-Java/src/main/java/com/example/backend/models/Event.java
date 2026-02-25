package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;
import java.util.List;

public class Event {
    @DocumentId
    private String id;
    private String institutionId;
    private String title;
    private String description;
    private String category; // ACADEMIC, PLACEMENT, CULTURAL, ADMINISTRATIVE, WORKSHOP, etc.
    private String status; // DRAFT, PENDING_APPROVAL, APPROVED, PUBLISHED, CANCELLED, COMPLETED
    
    private Long startDateTime;
    private Long endDateTime;
    private String venue;
    private String onlineLink;
    
    private String organizerId;
    private String organizerName;
    private String organizerPhotoUrl;
    
    private Integer capacityLimit; // 0 for unlimited
    private Integer currentParticipants;
    private Long registrationDeadline;
    
    private List<String> targetAudience; // ALL, STUDENTS, FACULTY, ADMIN, ALUMNI
    private List<String> targetDepartments; // List of department IDs or "ALL"
    
    private String posterUrl;
    private List<String> attachmentUrls;
    
    private Long createdAt;
    private Long updatedAt;
    private String createdBy;
    
    private Boolean isApprovalRequired;
    private String approvedBy;
    private Long approvedAt;

    public Event() {
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getInstitutionId() { return institutionId; }
    public void setInstitutionId(String institutionId) { this.institutionId = institutionId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Long getStartDateTime() { return startDateTime; }
    public void setStartDateTime(Long startDateTime) { this.startDateTime = startDateTime; }

    public Long getEndDateTime() { return endDateTime; }
    public void setEndDateTime(Long endDateTime) { this.endDateTime = endDateTime; }

    public String getVenue() { return venue; }
    public void setVenue(String venue) { this.venue = venue; }

    public String getOnlineLink() { return onlineLink; }
    public void setOnlineLink(String onlineLink) { this.onlineLink = onlineLink; }

    public String getOrganizerId() { return organizerId; }
    public void setOrganizerId(String organizerId) { this.organizerId = organizerId; }

    public String getOrganizerName() { return organizerName; }
    public void setOrganizerName(String organizerName) { this.organizerName = organizerName; }

    public String getOrganizerPhotoUrl() { return organizerPhotoUrl; }
    public void setOrganizerPhotoUrl(String organizerPhotoUrl) { this.organizerPhotoUrl = organizerPhotoUrl; }

    public Integer getCapacityLimit() { return capacityLimit; }
    public void setCapacityLimit(Integer capacityLimit) { this.capacityLimit = capacityLimit; }

    public Integer getCurrentParticipants() { return currentParticipants; }
    public void setCurrentParticipants(Integer currentParticipants) { this.currentParticipants = currentParticipants; }

    public Long getRegistrationDeadline() { return registrationDeadline; }
    public void setRegistrationDeadline(Long registrationDeadline) { this.registrationDeadline = registrationDeadline; }

    public List<String> getTargetAudience() { return targetAudience; }
    public void setTargetAudience(List<String> targetAudience) { this.targetAudience = targetAudience; }

    public List<String> getTargetDepartments() { return targetDepartments; }
    public void setTargetDepartments(List<String> targetDepartments) { this.targetDepartments = targetDepartments; }

    public String getPosterUrl() { return posterUrl; }
    public void setPosterUrl(String posterUrl) { this.posterUrl = posterUrl; }

    public List<String> getAttachmentUrls() { return attachmentUrls; }
    public void setAttachmentUrls(List<String> attachmentUrls) { this.attachmentUrls = attachmentUrls; }

    public Long getCreatedAt() { return createdAt; }
    public void setCreatedAt(Long createdAt) { this.createdAt = createdAt; }

    public Long getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Long updatedAt) { this.updatedAt = updatedAt; }

    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }

    public Boolean getIsApprovalRequired() { return isApprovalRequired; }
    public void setIsApprovalRequired(Boolean approvalRequired) { isApprovalRequired = approvalRequired; }

    public String getApprovedBy() { return approvedBy; }
    public void setApprovedBy(String approvedBy) { this.approvedBy = approvedBy; }

    public Long getApprovedAt() { return approvedAt; }
    public void setApprovedAt(Long approvedAt) { this.approvedAt = approvedAt; }
}
