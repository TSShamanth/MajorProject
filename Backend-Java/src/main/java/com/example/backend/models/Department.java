package com.example.backend.models;

public class Department {
    private String id;
    private String name;
    private String shortName;
    private String institutionId;

    public Department() {
    }

    public Department(String id, String name, String shortName, String institutionId) {
        this.id = id;
        this.name = name;
        this.shortName = shortName;
        this.institutionId = institutionId;
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

    public String getShortName() {
        return shortName;
    }

    public void setShortName(String shortName) {
        this.shortName = shortName;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }
}
