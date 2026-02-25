package com.example.backend.models;

import java.util.List;

public class FeeStructure {
    private String id;
    private String title;
    private String institutionId;
    private String departmentId; // Can be "ALL"
    private String semester; // Can be "ALL"
    private List<FeeComponent> components;
    private double totalAmount;

    public FeeStructure() {
    }

    public FeeStructure(String id, String title, String institutionId, String departmentId, String semester, List<FeeComponent> components, double totalAmount) {
        this.id = id;
        this.title = title;
        this.institutionId = institutionId;
        this.departmentId = departmentId;
        this.semester = semester;
        this.components = components;
        this.totalAmount = totalAmount;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }

    public String getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(String departmentId) {
        this.departmentId = departmentId;
    }

    public String getSemester() {
        return semester;
    }

    public void setSemester(String semester) {
        this.semester = semester;
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
}
