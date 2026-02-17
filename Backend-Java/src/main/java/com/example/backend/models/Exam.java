package com.example.backend.models;

import java.util.List;

public class Exam {
    private String id;
    private String name;
    private String departmentId;
    private String semester;
    private List<String> subjects;
    private String examDate;
    private String startTime;
    private String endTime;
    private String duration;

    public Exam() {
    }

    public Exam(String id, String name, String departmentId, String semester, List<String> subjects, String examDate, String startTime, String endTime, String duration) {
        this.id = id;
        this.name = name;
        this.departmentId = departmentId;
        this.semester = semester;
        this.subjects = subjects;
        this.examDate = examDate;
        this.startTime = startTime;
        this.endTime = endTime;
        this.duration = duration;
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

    public String getSemester() {
        return semester;
    }

    public void setSemester(String semester) {
        this.semester = semester;
    }

    public List<String> getSubjects() {
        return subjects;
    }

    public void setSubjects(List<String> subjects) {
        this.subjects = subjects;
    }

    public String getExamDate() {
        return examDate;
    }

    public void setExamDate(String examDate) {
        this.examDate = examDate;
    }

    public String getStartTime() {
        return startTime;
    }

    public void setStartTime(String startTime) {
        this.startTime = startTime;
    }

    public String getEndTime() {
        return endTime;
    }

    public void setEndTime(String endTime) {
        this.endTime = endTime;
    }

    public String getDuration() {
        return duration;
    }

    public void setDuration(String duration) {
        this.duration = duration;
    }
}
