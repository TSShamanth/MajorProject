package com.example.backend.dto;

import java.util.Date;

public class RegularisationRequestDTO {
    private Date targetDate;
    private String targetTime; // e.g., "09:30" - for missed entry
    private String type; // "Clock-in" or "Clock-out" - for missed entry
    private String newClockInTime; // e.g., "09:30" - for modifying existing log
    private String newClockOutTime; // e.g., "17:30" - for modifying existing log
    private String reason;
    private String attendanceLogId; // For modifying existing log

    // Getters and Setters

    public Date getTargetDate() {
        return targetDate;
    }

    public void setTargetDate(Date targetDate) {
        this.targetDate = targetDate;
    }

    public String getTargetTime() {
        return targetTime;
    }

    public void setTargetTime(String targetTime) {
        this.targetTime = targetTime;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getNewClockInTime() {
        return newClockInTime;
    }

    public void setNewClockInTime(String newClockInTime) {
        this.newClockInTime = newClockInTime;
    }

    public String getNewClockOutTime() {
        return newClockOutTime;
    }

    public void setNewClockOutTime(String newClockOutTime) {
        this.newClockOutTime = newClockOutTime;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public String getAttendanceLogId() {
        return attendanceLogId;
    }

    public void setAttendanceLogId(String attendanceLogId) {
        this.attendanceLogId = attendanceLogId;
    }
}
