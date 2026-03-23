package com.example.backend.service;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyDescription;

public class CreateConcernRequest {
    @JsonProperty(required = true)
    @JsonPropertyDescription("The ID of the institution. Take this from the system context.")
    private String institutionId;

    @JsonProperty(required = true)
    @JsonPropertyDescription("The ID of the student. Take this from the system context.")
    private String studentId;

    @JsonProperty(required = true)
    @JsonPropertyDescription("The type of concern, e.g., 'Hostel', 'Academic', 'Personal', 'Financial'")
    private String concernType;

    @JsonProperty(required = true)
    @JsonPropertyDescription("A detailed description of the student's problem or concern")
    private String description;

    @JsonProperty(required = true)
    @JsonPropertyDescription("Priority level of the concern: 'Low', 'Medium', or 'High'")
    private String priority;

    public String getInstitutionId() { return institutionId; }
    public void setInstitutionId(String institutionId) { this.institutionId = institutionId; }

    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }

    public String getConcernType() { return concernType; }
    public void setConcernType(String concernType) { this.concernType = concernType; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }
}
