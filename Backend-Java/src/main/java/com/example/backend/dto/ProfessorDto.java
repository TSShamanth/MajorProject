package com.example.backend.dto;

public class ProfessorDto {
    private String uid;
    private String displayName;

    public ProfessorDto(String uid, String displayName) {
        this.uid = uid;
        this.displayName = displayName;
    }

    public ProfessorDto() {
    }

    public String getUid() {
        return uid;
    }

    public void setUid(String uid) {
        this.uid = uid;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    @Override
    public String toString() {
        return "ProfessorDto{" +
                "uid='" + uid + '\'' +
                ", displayName='" + displayName + '\'' +
                '}';
    }
}
