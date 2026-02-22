package com.example.backend.models;

public class TimetableEntry {
    private String id;
    private String institutionId;
    private String departmentId;
    private String program;
    private String semester;
    private String sectionId;
    private String day; // Monday, Tuesday...
    private String timeSlotId;
    private String courseCode; // Subject
    private String facultyUid;
    private String roomId;
    private String academicYear;

    public TimetableEntry() {
    }

    public TimetableEntry(String id, String institutionId, String departmentId, String program, String semester, String sectionId, String day, String timeSlotId, String courseCode, String facultyUid, String roomId, String academicYear) {
        this.id = id;
        this.institutionId = institutionId;
        this.departmentId = departmentId;
        this.program = program;
        this.semester = semester;
        this.sectionId = sectionId;
        this.day = day;
        this.timeSlotId = timeSlotId;
        this.courseCode = courseCode;
        this.facultyUid = facultyUid;
        this.roomId = roomId;
        this.academicYear = academicYear;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
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

    public String getSectionId() {
        return sectionId;
    }

    public void setSectionId(String sectionId) {
        this.sectionId = sectionId;
    }

    public String getDay() {
        return day;
    }

    public void setDay(String day) {
        this.day = day;
    }

    public String getTimeSlotId() {
        return timeSlotId;
    }

    public void setTimeSlotId(String timeSlotId) {
        this.timeSlotId = timeSlotId;
    }

    public String getCourseCode() {
        return courseCode;
    }

    public void setCourseCode(String courseCode) {
        this.courseCode = courseCode;
    }

    public String getFacultyUid() {
        return facultyUid;
    }

    public void setFacultyUid(String facultyUid) {
        this.facultyUid = facultyUid;
    }

    public String getRoomId() {
        return roomId;
    }

    public void setRoomId(String roomId) {
        this.roomId = roomId;
    }

    public String getAcademicYear() {
        return academicYear;
    }

    public void setAcademicYear(String academicYear) {
        this.academicYear = academicYear;
    }
}
