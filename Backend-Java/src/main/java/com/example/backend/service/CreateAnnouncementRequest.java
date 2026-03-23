package com.example.backend.service;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyDescription;
import java.util.List;

public class CreateAnnouncementRequest {
    @JsonProperty(required = true)
    @JsonPropertyDescription("The ID of the institution. Take this from the system context.")
    private String institutionId;

    @JsonProperty(required = true)
    @JsonPropertyDescription("The ID of the user. Take this from the system context.")
    private String userId;

    @JsonProperty(required = true)
    @JsonPropertyDescription("The title of the announcement")
    private String title;

    @JsonProperty(required = true)
    @JsonPropertyDescription("A short summary or description of the announcement")
    private String description;

    @JsonProperty(required = true)
    @JsonPropertyDescription("The detailed content/body of the announcement")
    private String content;

    @JsonProperty(required = true)
    @JsonPropertyDescription("Priority level: 'HIGH', 'MEDIUM', or 'LOW'")
    private String priority;

    @JsonProperty(required = true)
    @JsonPropertyDescription("Category: 'ACADEMIC', 'ADMINISTRATIVE', 'PLACEMENT', 'EVENT', or 'OTHER'")
    private String category;

    @JsonProperty(required = true)
    @JsonPropertyDescription("Target audience list. Can contain 'ALL', 'STUDENTS', 'FACULTY', 'ADMIN', 'ALUMNI'")
    private List<String> targetAudience;

    public String getInstitutionId() { return institutionId; }
    public void setInstitutionId(String institutionId) { this.institutionId = institutionId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public List<String> getTargetAudience() { return targetAudience; }
    public void setTargetAudience(List<String> targetAudience) { this.targetAudience = targetAudience; }
}
