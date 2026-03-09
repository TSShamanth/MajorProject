package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;

public class PlacementApplication {
    @DocumentId
    private String id;
    private String driveId;
    private String studentUid;
    private String studentName;
    private String companyName;
    private String jobRole;
    private String currentRound;
    private String status;
    private String appliedDate;

    public PlacementApplication() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getDriveId() { return driveId; }
    public void setDriveId(String driveId) { this.driveId = driveId; }

    public String getStudentUid() { return studentUid; }
    public void setStudentUid(String studentUid) { this.studentUid = studentUid; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getJobRole() { return jobRole; }
    public void setJobRole(String jobRole) { this.jobRole = jobRole; }

    public String getCurrentRound() { return currentRound; }
    public void setCurrentRound(String currentRound) { this.currentRound = currentRound; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getAppliedDate() { return appliedDate; }
    public void setAppliedDate(String appliedDate) { this.appliedDate = appliedDate; }
}
