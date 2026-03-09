package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;
import java.util.Map;

public class FormResponse {
    @DocumentId
    private String id;
    private String formId;
    private String userId;
    private String institutionId;
    private long submittedAt;
    private Map<String, Object> answers; // Map of fieldId to value (String, List<String>, Integer)

    public FormResponse() {}

    public FormResponse(String id, String formId, String userId, String institutionId, long submittedAt, Map<String, Object> answers) {
        this.id = id;
        this.formId = formId;
        this.userId = userId;
        this.institutionId = institutionId;
        this.submittedAt = submittedAt;
        this.answers = answers;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getFormId() { return formId; }
    public void setFormId(String formId) { this.formId = formId; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getInstitutionId() { return institutionId; }
    public void setInstitutionId(String institutionId) { this.institutionId = institutionId; }
    public long getSubmittedAt() { return submittedAt; }
    public void setSubmittedAt(long submittedAt) { this.submittedAt = submittedAt; }
    public Map<String, Object> getAnswers() { return answers; }
    public void setAnswers(Map<String, Object> answers) { this.answers = answers; }
}
