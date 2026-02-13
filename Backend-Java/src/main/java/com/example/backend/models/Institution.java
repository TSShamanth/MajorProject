package com.example.backend.models;

public class Institution {
    private String id;
    private String name;
    private Double latitude;
    private Double longitude;
    private Double geofenceRadius; // in meters

    public Institution() {
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

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public Double getGeofenceRadius() {
        return geofenceRadius;
    }

    public void setGeofenceRadius(Double geofenceRadius) {
        this.geofenceRadius = geofenceRadius;
    }
}
