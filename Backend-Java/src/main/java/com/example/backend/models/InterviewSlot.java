package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;

public class InterviewSlot {
    @DocumentId
    private String id;
    private String studentUid;
    private String studentName;
    private String companyName;
    private String driveId;
    private String roundName;
    private String dateTime; // ISO string
    private String location; // e.g. "Room 302" or "Online"
    private String panelName;
    private String status; // "Scheduled", "Completed", "Cancelled"

    public InterviewSlot() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getStudentUid() { return studentUid; }
    public void setStudentUid(String studentUid) { this.studentUid = studentUid; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getDriveId() { return driveId; }
    public void setDriveId(String driveId) { this.driveId = driveId; }

    public String getRoundName() { return roundName; }
    public void setRoundName(String roundName) { this.roundName = roundName; }

    public String getDateTime() { return dateTime; }
    public void setDateTime(String dateTime) { this.dateTime = dateTime; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getPanelName() { return panelName; }
    public void setPanelName(String panelName) { this.panelName = panelName; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
