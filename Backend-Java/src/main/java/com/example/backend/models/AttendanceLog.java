package com.example.backend.models;

import java.util.Date;

public class AttendanceLog {
    private String id;
    private String facultyId;
    private String institutionId;
    private Date clockInTime;
    private Date clockOutTime;
    private long duration; // in minutes
    private Double clockInLatitude;
    private Double clockInLongitude;
    private Double clockOutLatitude;
    private Double clockOutLongitude;
    private String locationStatus; // e.g., "On-Campus", "Off-Campus"
    private String locationDetail; // e.g., "RVU Campus" or "Lat: 12.9, Lon: 77.4"
    private String regularisationStatus;

    public AttendanceLog() {
    }

    // Getters and Setters for all fields

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

    public Date getClockInTime() {
        return clockInTime;
    }

    public void setClockInTime(Date clockInTime) {
        this.clockInTime = clockInTime;
    }

    public Date getClockOutTime() {
        return clockOutTime;
    }

    public void setClockOutTime(Date clockOutTime) {
        this.clockOutTime = clockOutTime;
    }

    public long getDuration() {
        return duration;
    }

    public void setDuration(long duration) {
        this.duration = duration;
    }

    public Double getClockInLatitude() {
        return clockInLatitude;
    }

    public void setClockInLatitude(Double clockInLatitude) {
        this.clockInLatitude = clockInLatitude;
    }

    public Double getClockInLongitude() {
        return clockInLongitude;
    }

    public void setClockInLongitude(Double clockInLongitude) {
        this.clockInLongitude = clockInLongitude;
    }

    public Double getClockOutLatitude() {
        return clockOutLatitude;
    }

    public void setClockOutLatitude(Double clockOutLatitude) {
        this.clockOutLatitude = clockOutLatitude;
    }

    public Double getClockOutLongitude() {
        return clockOutLongitude;
    }

    public void setClockOutLongitude(Double clockOutLongitude) {
        this.clockOutLongitude = clockOutLongitude;
    }

    public String getLocationStatus() {
        return locationStatus;
    }

    public void setLocationStatus(String locationStatus) {
        this.locationStatus = locationStatus;
    }

    public String getLocationDetail() {
        return locationDetail;
    }

    public void setLocationDetail(String locationDetail) {
        this.locationDetail = locationDetail;
    }

    public String getRegularisationStatus() {
        return regularisationStatus;
    }

    public void setRegularisationStatus(String regularisationStatus) {
        this.regularisationStatus = regularisationStatus;
    }
}
