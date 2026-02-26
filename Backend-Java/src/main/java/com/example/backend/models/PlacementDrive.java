package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;
import java.util.List;

public class PlacementDrive {
    @DocumentId
    private String id;
    private String companyId;
    private String companyName;
    private String jobRole;
    private double salaryPackage;
    private String date;
    private String status;
    private String eligibilityCriteria;
    private double minCgpa;
    private List<String> allowedDepartments;
    private List<String> recruitmentRounds;

    public PlacementDrive() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCompanyId() { return companyId; }
    public void setCompanyId(String companyId) { this.companyId = companyId; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getJobRole() { return jobRole; }
    public void setJobRole(String jobRole) { this.jobRole = jobRole; }

    public double getSalaryPackage() { return salaryPackage; }
    public void setSalaryPackage(double salaryPackage) { this.salaryPackage = salaryPackage; }

    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getEligibilityCriteria() { return eligibilityCriteria; }
    public void setEligibilityCriteria(String eligibilityCriteria) { this.eligibilityCriteria = eligibilityCriteria; }

    public double getMinCgpa() { return minCgpa; }
    public void setMinCgpa(double minCgpa) { this.minCgpa = minCgpa; }

    public List<String> getAllowedDepartments() { return allowedDepartments; }
    public void setAllowedDepartments(List<String> allowedDepartments) { this.allowedDepartments = allowedDepartments; }

    public List<String> getRecruitmentRounds() { return recruitmentRounds; }
    public void setRecruitmentRounds(List<String> recruitmentRounds) { this.recruitmentRounds = recruitmentRounds; }
}
