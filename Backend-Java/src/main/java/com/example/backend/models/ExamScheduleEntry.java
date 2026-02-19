package com.example.backend.models;

public class ExamScheduleEntry {
    private String date;
    private String startTime;
    private String endTime;
    private String duration; // e.g., "3 hours", "90 minutes"

    public ExamScheduleEntry() {}

    public ExamScheduleEntry(String date, String startTime, String endTime, String duration) {
        this.date = date;
        this.startTime = startTime;
        this.endTime = endTime;
        this.duration = duration;
    }

    // Getters and Setters
    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }
    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }
    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }
    public String getDuration() { return duration; }
    public void setDuration(String duration) { this.duration = duration; }
}
