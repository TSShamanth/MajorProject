package com.example.backend.dto;

import com.google.cloud.Timestamp;

public class LeaveApplicationDto {

    private String id;
    private String userId;
    private String studentName;
    private String institutionId;
    private String leaveType;
    private String startDate;
    private String endDate;
    private String reason;
    private String professorId;
    private String professorName;
    private String status;
    private String documentUrl;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    // Required for Firestore
    public LeaveApplicationDto() {
    }

    public LeaveApplicationDto(String id,
                               String userId,
                               String institutionId,
                               String leaveType,
                               String startDate,
                               String endDate,
                               String reason,
                               String professorId,
                               String professorName,
                               String status,
                               Timestamp createdAt,
                               Timestamp updatedAt) {
        this.id = id;
        this.userId = userId;
        this.institutionId = institutionId;
        this.leaveType = leaveType;
        this.startDate = startDate;
        this.endDate = endDate;
        this.reason = reason;
        this.professorId = professorId;
        this.professorName = professorName;
        this.status = status;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    // Getters and Setters

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public String getInstitutionId() { return institutionId; }
    public void setInstitutionId(String institutionId) { this.institutionId = institutionId; }

    public String getLeaveType() { return leaveType; }
    public void setLeaveType(String leaveType) { this.leaveType = leaveType; }

    public String getStartDate() { return startDate; }
    public void setStartDate(String startDate) { this.startDate = startDate; }

    public String getEndDate() { return endDate; }
    public void setEndDate(String endDate) { this.endDate = endDate; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getProfessorId() { return professorId; }
    public void setProfessorId(String professorId) { this.professorId = professorId; }

    public String getProfessorName() { return professorName; }
    public void setProfessorName(String professorName) { this.professorName = professorName; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getDocumentUrl() { return documentUrl; }
    public void setDocumentUrl(String documentUrl) { this.documentUrl = documentUrl; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }
}