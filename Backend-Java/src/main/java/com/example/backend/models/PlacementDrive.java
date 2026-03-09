package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;
import java.util.List;
import java.util.Map;

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
    private String salaryBreakdown;
    private int maxBacklogs;
    private double min10thPercentage;
    private double min12thPercentage;
    private List<String> allowedDepartments;
    private List<String> recruitmentRounds;
    private Map<String, Integer> pipelineStats;

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

    public String getSalaryBreakdown() { return salaryBreakdown; }
    public void setSalaryBreakdown(String salaryBreakdown) { this.salaryBreakdown = salaryBreakdown; }

    public int getMaxBacklogs() { return maxBacklogs; }
    public void setMaxBacklogs(int maxBacklogs) { this.maxBacklogs = maxBacklogs; }

    public double getMin10thPercentage() { return min10thPercentage; }
    public void setMin10thPercentage(double min10thPercentage) { this.min10thPercentage = min10thPercentage; }

    public double getMin12thPercentage() { return min12thPercentage; }
    public void setMin12thPercentage(double min12thPercentage) { this.min12thPercentage = min12thPercentage; }

    public List<String> getAllowedDepartments() { return allowedDepartments; }
    public void setAllowedDepartments(List<String> allowedDepartments) { this.allowedDepartments = allowedDepartments; }

    public List<String> getRecruitmentRounds() { return recruitmentRounds; }
    public void setRecruitmentRounds(List<String> recruitmentRounds) { this.recruitmentRounds = recruitmentRounds; }

    public Map<String, Integer> getPipelineStats() { return pipelineStats; }
    public void setPipelineStats(Map<String, Integer> pipelineStats) { this.pipelineStats = pipelineStats; }
}
