package com.example.backend.models;

public class SeatingEntry {
    private String studentId;
    private String roomId;
    private String seatNumber;

    public SeatingEntry() {
    }

    public SeatingEntry(String studentId, String roomId, String seatNumber) {
        this.studentId = studentId;
        this.roomId = roomId;
        this.seatNumber = seatNumber;
    }

    // Getters and Setters
    public String getStudentId() {
        return studentId;
    }

    public void setStudentId(String studentId) {
        this.studentId = studentId;
    }

    public String getRoomId() {
        return roomId;
    }

    public void setRoomId(String roomId) {
        this.roomId = roomId;
    }

    public String getSeatNumber() {
        return seatNumber;
    }

    public void setSeatNumber(String seatNumber) {
        this.seatNumber = seatNumber;
    }
}
