package com.example.backend.models;

public class Room {
    private String id;
    private String name;
    private int capacity;
    private String institutionId;
    private String departmentId; // Optional: to associate a room with a department

    public Room() {
    }

    public Room(String id, String name, int capacity, String institutionId, String departmentId) {
        this.id = id;
        this.name = name;
        this.capacity = capacity;
        this.institutionId = institutionId;
        this.departmentId = departmentId;
    }

    // Getters and Setters
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

    public int getCapacity() {
        return capacity;
    }

    public void setCapacity(int capacity) {
        this.capacity = capacity;
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
}
