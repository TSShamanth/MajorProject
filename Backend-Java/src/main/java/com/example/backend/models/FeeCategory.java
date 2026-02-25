package com.example.backend.models;

public class FeeCategory {
    private String id;
    private String name;
    private String institutionId;

    public FeeCategory() {
    }

    public FeeCategory(String id, String name, String institutionId) {
        this.id = id;
        this.name = name;
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

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }
}
