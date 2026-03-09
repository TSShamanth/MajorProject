package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;

public class Company {
    @DocumentId
    private String id;
    private String name;
    private String industry;
    private String website;
    private String hrEmail;
    private String description;
    private String tier;

    public Company() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getIndustry() { return industry; }
    public void setIndustry(String industry) { this.industry = industry; }

    public String getWebsite() { return website; }
    public void setWebsite(String website) { this.website = website; }

    public String getHrEmail() { return hrEmail; }
    public void setHrEmail(String hrEmail) { this.hrEmail = hrEmail; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getTier() { return tier; }
    public void setTier(String tier) { this.tier = tier; }
}
