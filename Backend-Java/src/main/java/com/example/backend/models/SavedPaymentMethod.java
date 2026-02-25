package com.example.backend.models;

import java.util.Map;

public class SavedPaymentMethod {
    private String id;
    private String userId;
    private String methodType; // e.g., "CARD", "UPI"
    private String displayName; // e.g., "**** **** **** 1234", "my-upi@bank"
    private Map<String, String> details; // Non-sensitive details for display and mock processing

    public SavedPaymentMethod() {
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getMethodType() {
        return methodType;
    }

    public void setMethodType(String methodType) {
        this.methodType = methodType;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public Map<String, String> getDetails() {
        return details;
    }

    public void setDetails(Map<String, String> details) {
        this.details = details;
    }
}
