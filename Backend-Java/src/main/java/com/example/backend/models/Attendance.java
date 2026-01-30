package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;

import java.util.Objects;

public class Attendance {
    @DocumentId
    private String id;
    private String courseCode;
    private String studentUid;
    private String date; // Stored as "yyyy-MM-dd"
    private String status; // "Present" or "Absent"
    private String remarks; // Optional
    private String facultyUid;
    private String institutionId;
    private String departmentId;

    public Attendance() {
    }

    public Attendance(String id, String courseCode, String studentUid, String date, String status, String remarks, String facultyUid, String institutionId, String departmentId) {
        this.id = id;
        this.courseCode = courseCode;
        this.studentUid = studentUid;
        this.date = date;
        this.status = status;
        this.remarks = remarks;
        this.facultyUid = facultyUid;
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

    public String getCourseCode() {
        return courseCode;
    }

    public void setCourseCode(String courseCode) {
        this.courseCode = courseCode;
    }

    public String getStudentUid() {
        return studentUid;
    }

    public void setStudentUid(String studentUid) {
        this.studentUid = studentUid;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getRemarks() {
        return remarks;
    }

    public void setRemarks(String remarks) {
        this.remarks = remarks;
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

    public String getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(String departmentId) {
        this.departmentId = departmentId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Attendance that = (Attendance) o;
        return Objects.equals(id, that.id) &&
               Objects.equals(courseCode, that.courseCode) &&
               Objects.equals(studentUid, that.studentUid) &&
               Objects.equals(date, that.date) &&
               Objects.equals(status, that.status) &&
               Objects.equals(remarks, that.remarks) &&
               Objects.equals(facultyUid, that.facultyUid) &&
               Objects.equals(institutionId, that.institutionId) &&
               Objects.equals(departmentId, that.departmentId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, courseCode, studentUid, date, status, remarks, facultyUid, institutionId, departmentId);
    }

    @Override
    public String toString() {
        return "Attendance{"
               + "id='" + id + "'"
               + ", courseCode='" + courseCode + "'"
               + ", studentUid='" + studentUid + "'"
               + ", date='" + date + "'"
               + ", status='" + status + "'"
               + ", remarks='" + remarks + "'"
               + ", facultyUid='" + facultyUid + "'"
               + ", institutionId='" + institutionId + "'"
               + ", departmentId='" + departmentId + "'"
               + '}';
    }
}
