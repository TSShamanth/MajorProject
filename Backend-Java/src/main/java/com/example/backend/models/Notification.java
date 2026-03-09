package com.example.backend.models;

import com.google.cloud.firestore.annotation.DocumentId;

public class Notification {
    @DocumentId
    private String id;
    private String userId;
    private String title;
    private String message;
    private String route; // relative path (no institutionId prefix)
    private long createdAt;
    private boolean read;

    public Notification() {
    }

    public Notification(String id, String userId, String title, String message, String route, long createdAt, boolean read) {
        this.id = id;
        this.userId = userId;
        this.title = title;
        this.message = message;
        this.route = route;
        this.createdAt = createdAt;
        this.read = read;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getRoute() {
        return route;
    }

    public void setRoute(String route) {
        this.route = route;
    }

    public long getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(long createdAt) {
        this.createdAt = createdAt;
    }

    public boolean isRead() {
        return read;
    }

    public void setRead(boolean read) {
        this.read = read;
    }
}