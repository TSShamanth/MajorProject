package com.example.backend.controller;

public class ChatRequest {
    private String message;
    private String institutionId;

    public ChatRequest() {}

    public ChatRequest(String message, String institutionId) {
        this.message = message;
        this.institutionId = institutionId;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }
}
