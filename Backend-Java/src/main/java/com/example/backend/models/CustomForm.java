package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;
import com.google.cloud.firestore.annotation.PropertyName;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public class CustomForm {
    @DocumentId
    private String id;
    private String institutionId;
    private String title;
    private String description;
    private String createdBy;
    private long createdAt;
    private long updatedAt;
    private long expiryDate;
    
    @PropertyName("isOpen")
    @JsonProperty("isOpen")
    private Boolean isOpen = true;

    @PropertyName("allowMultipleSubmissions")
    @JsonProperty("allowMultipleSubmissions")
    private boolean allowMultipleSubmissions = false;

    private List<String> targetAudience;
    private List<FormField> fields;

    public CustomForm() {}

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getInstitutionId() { return institutionId; }
    public void setInstitutionId(String institutionId) { this.institutionId = institutionId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }
    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }
    public long getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(long updatedAt) { this.updatedAt = updatedAt; }
    public long getExpiryDate() { return expiryDate; }
    public void setExpiryDate(long expiryDate) { this.expiryDate = expiryDate; }
    
    @PropertyName("isOpen")
    @JsonProperty("isOpen")
    public Boolean getIsOpen() { return isOpen; }
    @PropertyName("isOpen")
    @JsonProperty("isOpen")
    public void setIsOpen(Boolean open) { isOpen = open; }
    
    @PropertyName("allowMultipleSubmissions")
    @JsonProperty("allowMultipleSubmissions")
    public boolean isAllowMultipleSubmissions() { return allowMultipleSubmissions; }
    @PropertyName("allowMultipleSubmissions")
    @JsonProperty("allowMultipleSubmissions")
    public void setAllowMultipleSubmissions(boolean allowMultipleSubmissions) { this.allowMultipleSubmissions = allowMultipleSubmissions; }

    public boolean isOpen() { return isOpen != null && isOpen; }

    public List<String> getTargetAudience() { return targetAudience; }
    public void setTargetAudience(List<String> targetAudience) { this.targetAudience = targetAudience; }
    public List<FormField> getFields() { return fields; }
    public void setFields(List<FormField> fields) { this.fields = fields; }

    public static class FormField {
        private String id;
        private String type;
        private String label;
        private String placeholder;
        
        @PropertyName("isRequired")
        @JsonProperty("isRequired")
        private boolean isRequired;

        private List<String> options;
        private Integer minScale;
        private Integer maxScale;

        public FormField() {}

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getType() { return type; }
        public void setType(String type) { this.type = type; }
        public String getLabel() { return label; }
        public void setLabel(String label) { this.label = label; }
        public String getPlaceholder() { return placeholder; }
        public void setPlaceholder(String placeholder) { this.placeholder = placeholder; }

        @PropertyName("isRequired")
        @JsonProperty("isRequired")
        public boolean isRequired() { return isRequired; }
        @PropertyName("isRequired")
        @JsonProperty("isRequired")
        public void setRequired(boolean required) { isRequired = required; }

        public List<String> getOptions() { return options; }
        public void setOptions(List<String> options) { this.options = options; }
        public Integer getMinScale() { return minScale; }
        public void setMinScale(Integer minScale) { this.minScale = minScale; }
        public Integer getMaxScale() { return maxScale; }
        public void setMaxScale(Integer maxScale) { this.maxScale = maxScale; }
    }
}
