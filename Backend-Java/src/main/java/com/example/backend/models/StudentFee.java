package com.example.backend.models;

import java.util.Date;
import java.util.List;

public class StudentFee {
    private String id;
    private String studentId;
    private String studentName;
    private String usn;
    private String institutionId;
    private String feeStructureId;
    private String feeStructureTitle;
    private List<FeeComponent> components;
    private double totalAmount;
    private double paidAmount;
    private double balanceAmount;
    private String status; // UNPAID, PARTIAL, PAID
    private Date dueDate;
    private Date createdAt;

    public StudentFee() {
    }

    public StudentFee(String id, String studentId, String studentName, String usn, String institutionId, String feeStructureId, String feeStructureTitle, List<FeeComponent> components, double totalAmount, double paidAmount, double balanceAmount, String status, Date dueDate, Date createdAt) {
        this.id = id;
        this.studentId = studentId;
        this.studentName = studentName;
        this.usn = usn;
        this.institutionId = institutionId;
        this.feeStructureId = feeStructureId;
        this.feeStructureTitle = feeStructureTitle;
        this.components = components;
        this.totalAmount = totalAmount;
        this.paidAmount = paidAmount;
        this.balanceAmount = balanceAmount;
        this.status = status;
        this.dueDate = dueDate;
        this.createdAt = createdAt;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getStudentId() {
        return studentId;
    }

    public void setStudentId(String studentId) {
        this.studentId = studentId;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }

    public String getUsn() {
        return usn;
    }

    public void setUsn(String usn) {
        this.usn = usn;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }

    public String getFeeStructureId() {
        return feeStructureId;
    }

    public void setFeeStructureId(String feeStructureId) {
        this.feeStructureId = feeStructureId;
    }

    public String getFeeStructureTitle() {
        return feeStructureTitle;
    }

    public void setFeeStructureTitle(String feeStructureTitle) {
        this.feeStructureTitle = feeStructureTitle;
    }

    public List<FeeComponent> getComponents() {
        return components;
    }

    public void setComponents(List<FeeComponent> components) {
        this.components = components;
    }

    public double getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(double totalAmount) {
        this.totalAmount = totalAmount;
    }

    public double getPaidAmount() {
        return paidAmount;
    }

    public void setPaidAmount(double paidAmount) {
        this.paidAmount = paidAmount;
    }

    public double getBalanceAmount() {
        return balanceAmount;
    }

    public void setBalanceAmount(double balanceAmount) {
        this.balanceAmount = balanceAmount;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Date getDueDate() {
        return dueDate;
    }

    public void setDueDate(Date dueDate) {
        this.dueDate = dueDate;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }
}
