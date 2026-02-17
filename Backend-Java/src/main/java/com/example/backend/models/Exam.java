package com.example.backend.models;

import java.util.List;
import java.util.Map; // Import Map

public class Exam {
    private String id;
    private String name;
    private String departmentId;
    private String semester;
    private List<String> subjects;
    private Map<String, ExamScheduleEntry> schedule; // New field for per-subject scheduling
    private List<String> frozenCandidateList; // New field for storing frozen eligible student UIDs

    public Exam() {
    }

    public Exam(String id, String name, String departmentId, String semester, List<String> subjects, Map<String, ExamScheduleEntry> schedule, List<String> frozenCandidateList) {
        this.id = id;
        this.name = name;
        this.departmentId = departmentId;
        this.semester = semester;
        this.subjects = subjects;
        this.schedule = schedule;
        this.frozenCandidateList = frozenCandidateList;
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

    public Map<String, ExamScheduleEntry> getSchedule() { // Getter for schedule
        return schedule;
    }

    public void setSchedule(Map<String, ExamScheduleEntry> schedule) { // Setter for schedule
        this.schedule = schedule;
    }

    public List<String> getFrozenCandidateList() {
        return frozenCandidateList;
    }

    public void setFrozenCandidateList(List<String> frozenCandidateList) {
        this.frozenCandidateList = frozenCandidateList;
    }
}
