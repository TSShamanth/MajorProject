package com.example.backend.models;

import java.util.List;

public class Course {
    private String courseCode;
    private String courseName;
    private String facultyUid;
    private String institutionId;
    private String program;
    private String semester;
    private List<String> studentsEnrolled;
    private String totalClasses;
    private String departmentId;
    private String credits; // Changed to String for better compatibility

    public Course() {
    }

    public Course(String courseCode, String courseName, String facultyUid, String institutionId, String program, String semester, List<String> studentsEnrolled, String totalClasses, String departmentId, String credits) {
        this.courseCode = courseCode;
        this.courseName = courseName;
        this.facultyUid = facultyUid;
        this.institutionId = institutionId;
        this.program = program;
        this.semester = semester;
        this.studentsEnrolled = studentsEnrolled;
        this.totalClasses = totalClasses;
        this.departmentId = departmentId;
        this.credits = credits;
    }

    public String getCredits() {
        return credits;
    }

    public void setCredits(String credits) {
        this.credits = credits;
    }

    public String getCourseCode() {
        return courseCode;
    }

    public void setCourseCode(String courseCode) {
        this.courseCode = courseCode;
    }

    public String getCourseName() {
        return courseName;
    }

    public void setCourseName(String courseName) {
        this.courseName = courseName;
    }

    public String getFacultyUid() {
        return facultyUid;
    }

    public void setFacultyUid(String facultyUid) {
        this.facultyUid = facultyUid;
    }

    public String getInstitutionId() {
        return institutionId;
    }

    public void setInstitutionId(String institutionId) {
        this.institutionId = institutionId;
    }

    public String getProgram() {
        return program;
    }

    public void setProgram(String program) {
        this.program = program;
    }

    public String getSemester() {
        return semester;
    }

    public void setSemester(String semester) {
        this.semester = semester;
    }

    public List<String> getStudentsEnrolled() {
        return studentsEnrolled;
    }

    public void setStudentsEnrolled(List<String> studentsEnrolled) {
        this.studentsEnrolled = studentsEnrolled;
    }

    public String getTotalClasses() {
        return totalClasses;
    }

    public void setTotalClasses(String totalClasses) {
        this.totalClasses = totalClasses;
    }

    public String getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(String departmentId) {
        this.departmentId = departmentId;
    }
}
