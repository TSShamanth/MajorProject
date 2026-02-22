package com.example.backend.models;

import java.util.List;

public class Section {
    private String id;
    private String name;
    private String departmentId;
    private String institutionId;
    private String facultyId;
    private List<String> studentIds;

    public Section() {
    }

    public Section(String id, String name, String departmentId, String institutionId, String facultyId, List<String> studentIds) {
        this.id = id;
        this.name = name;
        this.departmentId = departmentId;
        this.institutionId = institutionId;
        this.facultyId = facultyId;
        this.studentIds = studentIds;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(String departmentId) {
        this.departmentId = departmentId;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }

    public String getFacultyId() {
        return facultyId;
    }

    public void setFacultyId(String facultyId) {
        this.facultyId = facultyId;
    }

    public List<String> getStudentIds() {
        return studentIds;
    }

    public void setStudentIds(List<String> studentIds) {
        this.studentIds = studentIds;
    }
}
