package com.example.backend.models;

import java.util.Date;

public class RegularisationRequest {

    private String id;
    private String facultyId;
    private String institutionId;
    private Date requestDate;
    private Date targetDate;
    private String targetTime; // e.g., "09:30" - for missed entry
    private String type; // "Clock-in" or "Clock-out" - for missed entry
    private String newClockInTime; // e.g., "09:30" - for modifying existing log
    private String newClockOutTime; // e.g., "17:30" - for modifying existing log
    private String reason;
    private String status; // "Pending", "Approved", "Denied"
    private String approvedBy; // UID of the admin
    private Date approvedOn;
    private String attendanceLogId; // For modifying existing log

    // Getters and Setters

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getFacultyId() {
        return facultyId;
    }

    public void setFacultyId(String facultyId) {
        this.facultyId = facultyId;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }

    public Date getRequestDate() {
        return requestDate;
    }

    public void setRequestDate(Date requestDate) {
        this.requestDate = requestDate;
    }

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

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getApprovedBy() {
        return approvedBy;
    }

    public void setApprovedBy(String approvedBy) {
        this.approvedBy = approvedBy;
    }

    public Date getApprovedOn() {
        return approvedOn;
    }

    public void setApprovedOn(Date approvedOn) {
        this.approvedOn = approvedOn;
    }

    public String getAttendanceLogId() {
        return attendanceLogId;
    }

    public void setAttendanceLogId(String attendanceLogId) {
        this.attendanceLogId = attendanceLogId;
    }
}
