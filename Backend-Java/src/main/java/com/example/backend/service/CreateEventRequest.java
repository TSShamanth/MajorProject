package com.example.backend.service;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyDescription;
import java.util.List;

public class CreateEventRequest {
    @JsonProperty(required = true)
    @JsonPropertyDescription("The ID of the institution. Take this from the system context.")
    private String institutionId;

    @JsonProperty(required = true)
    @JsonPropertyDescription("The ID of the user. Take this from the system context.")
    private String userId;

    @JsonProperty(required = true)
    @JsonPropertyDescription("The title of the event")
    private String title;

    @JsonProperty(required = true)
    @JsonPropertyDescription("Detailed description of the event")
    private String description;

    @JsonProperty(required = true)
    @JsonPropertyDescription("Category: 'ACADEMIC', 'PLACEMENT', 'CULTURAL', 'ADMINISTRATIVE', 'WORKSHOP'")
    private String category;

    @JsonProperty(required = true)
    @JsonPropertyDescription("The physical venue or location of the event")
    private String venue;

    @JsonProperty(required = false)
    @JsonPropertyDescription("An optional link if the event is online")
    private String onlineLink;

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

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getVenue() { return venue; }
    public void setVenue(String venue) { this.venue = venue; }

    public String getOnlineLink() { return onlineLink; }
    public void setOnlineLink(String onlineLink) { this.onlineLink = onlineLink; }

    public List<String> getTargetAudience() { return targetAudience; }
    public void setTargetAudience(List<String> targetAudience) { this.targetAudience = targetAudience; }
}
