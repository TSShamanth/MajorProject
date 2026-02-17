package com.example.backend.dto;

public class SubjectWiseAttendance {
    private String courseName;
    private String courseCode;
    private String facultyName;
    private double attendancePercentage;
    private int totalClasses;
    private int attendedClasses;

    public SubjectWiseAttendance(String courseName, String courseCode, String facultyName, double attendancePercentage, int totalClasses, int attendedClasses) {
        this.courseName = courseName;
        this.courseCode = courseCode;
        this.facultyName = facultyName;
        this.attendancePercentage = attendancePercentage;
        this.totalClasses = totalClasses;
        this.attendedClasses = attendedClasses;
    }

    public String getCourseName() {
        return courseName;
    }

    public void setCourseName(String courseName) {
        this.courseName = courseName;
    }

    public String getCourseCode() {
        return courseCode;
    }

    public void setCourseCode(String courseCode) {
        this.courseCode = courseCode;
    }

    public String getFacultyName() {
        return facultyName;
    }

    public void setFacultyName(String facultyName) {
        this.facultyName = facultyName;
    }

    public double getAttendancePercentage() {
        return attendancePercentage;
    }

    public void setAttendancePercentage(double attendancePercentage) {
        this.attendancePercentage = attendancePercentage;
    }

    public int getTotalClasses() {
        return totalClasses;
    }

    public void setTotalClasses(int totalClasses) {
        this.totalClasses = totalClasses;
    }

    public int getAttendedClasses() {
        return attendedClasses;
    }

    public void setAttendedClasses(int attendedClasses) {
        this.attendedClasses = attendedClasses;
    }
}
