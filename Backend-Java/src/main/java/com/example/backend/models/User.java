package com.example.backend.models;

import java.util.List;

public class User {
    private String uid;
    private String email;
    private String displayName;
    private String role;
    private String name;
    private String usn;
    private String phone;
    private String sem;
    private String departmentId; // New field
    private String mentorId; // New field for mentorship
    private String sectionId; // New field
    private String mentorName;
    private String photoUrl;
    private String programme;
    private String school;
    private String address;
    private String dob;
    private String bloodGroup;
    private String emergencyContact;
    private String validUpto;
    private List<String> enrolledCourseCodes; // For students
    private List<String> assignedCourseCodes;  // For faculty
    private String attendanceStatus;
    private String activeLogId;
    private boolean isDetained; // New field for student eligibility
    private double attendancePercentage; // For mentorship snapshot
    private double currentGPA; // For mentorship snapshot
    private List<Double> attendanceHistory; // Trend data
    private List<Double> gpaHistory; // Trend data

    public User() {
    }

    public List<Double> getAttendanceHistory() {
        return attendanceHistory;
    }

    public void setAttendanceHistory(List<Double> attendanceHistory) {
        this.attendanceHistory = attendanceHistory;
    }

    public List<Double> getGpaHistory() {
        return gpaHistory;
    }

    public void setGpaHistory(List<Double> gpaHistory) {
        this.gpaHistory = gpaHistory;
    }

    public double getAttendancePercentage() {
        return attendancePercentage;
    }

    public void setAttendancePercentage(double attendancePercentage) {
        this.attendancePercentage = attendancePercentage;
    }

    public double getCurrentGPA() {
        return currentGPA;
    }

    public void setCurrentGPA(double currentGPA) {
        this.currentGPA = currentGPA;
    }

    public String getMentorId() {
        return mentorId;
    }

    public void setMentorId(String mentorId) {
        this.mentorId = mentorId;
    }

    public boolean getIsDetained() {
        return isDetained;
    }

    public void setIsDetained(boolean detained) {
        this.isDetained = detained;
    }

    public String getUid() {
        return uid;
    }

    public void setUid(String uid) {
        this.uid = uid;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getUsn() {
        return usn;
    }

    public void setUsn(String usn) {
        this.usn = usn;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getSem() {
        return sem;
    }

    public void setSem(String sem) {
        this.sem = sem;
    }

    public String getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(String departmentId) {
        this.departmentId = departmentId;
    }

    public String getSectionId() {
        return sectionId;
    }

    public void setSectionId(String sectionId) {
        this.sectionId = sectionId;
    }

    public String getMentorName() {
        return mentorName;
    }

    public void setMentorName(String mentorName) {
        this.mentorName = mentorName;
    }

    public String getPhotoUrl() {
        return photoUrl;
    }

    public void setPhotoUrl(String photoUrl) {
        this.photoUrl = photoUrl;
    }

    public String getProgramme() {
        return programme;
    }

    public void setProgramme(String programme) {
        this.programme = programme;
    }

    public String getSchool() {
        return school;
    }

    public void setSchool(String school) {
        this.school = school;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getDob() {
        return dob;
    }

    public void setDob(String dob) {
        this.dob = dob;
    }

    public String getBloodGroup() {
        return bloodGroup;
    }

    public void setBloodGroup(String bloodGroup) {
        this.bloodGroup = bloodGroup;
    }

    public String getEmergencyContact() {
        return emergencyContact;
    }

    public void setEmergencyContact(String emergencyContact) {
        this.emergencyContact = emergencyContact;
    }

    public String getValidUpto() {
        return validUpto;
    }

    public void setValidUpto(String validUpto) {
        this.validUpto = validUpto;
    }

    public List<String> getEnrolledCourseCodes() {
        return enrolledCourseCodes;
    }

    public void setEnrolledCourseCodes(List<String> enrolledCourseCodes) {
        this.enrolledCourseCodes = enrolledCourseCodes;
    }

    public List<String> getAssignedCourseCodes() {
        return assignedCourseCodes;
    }

    public void setAssignedCourseCodes(List<String> assignedCourseCodes) {
        this.assignedCourseCodes = assignedCourseCodes;
    }

    public String getAttendanceStatus() {
        return attendanceStatus;
    }

    public void setAttendanceStatus(String attendanceStatus) {
        this.attendanceStatus = attendanceStatus;
    }

    public String getActiveLogId() {
        return activeLogId;
    }

    public void setActiveLogId(String activeLogId) {
        this.activeLogId = activeLogId;
    }
}