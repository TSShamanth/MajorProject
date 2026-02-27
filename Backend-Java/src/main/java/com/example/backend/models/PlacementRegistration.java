package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;
import java.util.List;

public class PlacementRegistration {
    @DocumentId
    private String uid;
    private String resumeUrl;
    private String photoUrl;
    private double cgpa;
    private List<String> skills;
    private int backlogCount;
    private List<String> interestedDepartments;
    private String registrationDate;

    public PlacementRegistration() {}

    public String getUid() { return uid; }
    public void setUid(String uid) { this.uid = uid; }

    public String getResumeUrl() { return resumeUrl; }
    public void setResumeUrl(String resumeUrl) { this.resumeUrl = resumeUrl; }

    public String getPhotoUrl() { return photoUrl; }
    public void setPhotoUrl(String photoUrl) { this.photoUrl = photoUrl; }

    public double getCgpa() { return cgpa; }
    public void setCgpa(double cgpa) { this.cgpa = cgpa; }

    public List<String> getSkills() { return skills; }
    public void setSkills(List<String> skills) { this.skills = skills; }

    public int getBacklogCount() { return backlogCount; }
    public void setBacklogCount(int backlogCount) { this.backlogCount = backlogCount; }

    public List<String> getInterestedDepartments() { return interestedDepartments; }
    public void setInterestedDepartments(List<String> interestedDepartments) { this.interestedDepartments = interestedDepartments; }

    public String getRegistrationDate() { return registrationDate; }
    public void setRegistrationDate(String registrationDate) { this.registrationDate = registrationDate; }
}
