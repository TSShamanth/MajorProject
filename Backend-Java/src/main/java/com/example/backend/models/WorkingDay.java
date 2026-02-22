package com.example.backend.models;

public class WorkingDay {
    private String id;
    private String dayName;
    private boolean isWorking;
    private String institutionId;

    public WorkingDay() {
    }

    public WorkingDay(String id, String dayName, boolean isWorking, String institutionId) {
        this.id = id;
        this.dayName = dayName;
        this.isWorking = isWorking;
        this.institutionId = institutionId;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getDayName() {
        return dayName;
    }

    public void setDayName(String dayName) {
        this.dayName = dayName;
    }

    public boolean isWorking() {
        return isWorking;
    }

    public void setWorking(boolean working) {
        isWorking = working;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }
}
