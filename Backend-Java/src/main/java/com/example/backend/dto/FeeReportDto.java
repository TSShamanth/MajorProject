package com.example.backend.dto;

public class FeeReportDto {
    private String studentName;
    private String usn;
    private String feeStructureTitle;
    private double totalAmount;
    private double paidAmount;
    private double balanceAmount;
    private String status;
    private String dueDate;
    private String facultyRemarks;

    // Constructors
    public FeeReportDto() {
    }

    public FeeReportDto(String studentName, String usn, String feeStructureTitle, double totalAmount, double paidAmount, double balanceAmount, String status, String dueDate, String facultyRemarks) {
        this.studentName = studentName;
        this.usn = usn;
        this.feeStructureTitle = feeStructureTitle;
        this.totalAmount = totalAmount;
        this.paidAmount = paidAmount;
        this.balanceAmount = balanceAmount;
        this.status = status;
        this.dueDate = dueDate;
        this.facultyRemarks = facultyRemarks;
    }

    // Getters and Setters
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

    public String getFeeStructureTitle() {
        return feeStructureTitle;
    }

    public void setFeeStructureTitle(String feeStructureTitle) {
        this.feeStructureTitle = feeStructureTitle;
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

    public String getDueDate() {
        return dueDate;
    }

    public void setDueDate(String dueDate) {
        this.dueDate = dueDate;
    }

    public String getFacultyRemarks() {
        return facultyRemarks;
    }

    public void setFacultyRemarks(String facultyRemarks) {
        this.facultyRemarks = facultyRemarks;
    }
}