package com.example.backend.dto;

import com.example.backend.models.ExamScheduleEntry;
import com.example.backend.models.Room;
import com.example.backend.models.SeatingEntry;

import java.util.Map;
import java.util.List;

public class HallTicketData {
    private String studentId;
    private String studentName;
    private String studentUsn;
    private String studentDepartment;
    private String studentSemester;

    private String examId;
    private String examName;
    private String examDepartmentId; // Department for which the exam is conducted
    private String examSemester;     // Semester for which the exam is conducted
    private List<String> subjects;
    private Map<String, ExamScheduleEntry> schedule;
    private Map<String, SeatingEntry> seatingArrangement; // Seating for all students in this exam
    private SeatingEntry studentSeatingEntry; // Specific seating for this student

    private Room studentRoomDetails; // Details of the room assigned to the student

    // Constructors
    public HallTicketData() {
    }

    public HallTicketData(String studentId, String studentName, String studentUsn, String studentDepartment, String studentSemester, String examId, String examName, String examDepartmentId, String examSemester, List<String> subjects, Map<String, ExamScheduleEntry> schedule, Map<String, SeatingEntry> seatingArrangement, SeatingEntry studentSeatingEntry, Room studentRoomDetails) {
        this.studentId = studentId;
        this.studentName = studentName;
        this.studentUsn = studentUsn;
        this.studentDepartment = studentDepartment;
        this.studentSemester = studentSemester;
        this.examId = examId;
        this.examName = examName;
        this.examDepartmentId = examDepartmentId;
        this.examSemester = examSemester;
        this.subjects = subjects;
        this.schedule = schedule;
        this.seatingArrangement = seatingArrangement;
        this.studentSeatingEntry = studentSeatingEntry;
        this.studentRoomDetails = studentRoomDetails;
    }

    // Getters and Setters
    public String getStudentId() {
        return studentId;
    }

    public void setStudentId(String studentId) {
        this.studentId = studentId;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }

    public String getStudentUsn() {
        return studentUsn;
    }

    public void setStudentUsn(String studentUsn) {
        this.studentUsn = studentUsn;
    }

    public String getStudentDepartment() {
        return studentDepartment;
    }

    public void setStudentDepartment(String studentDepartment) {
        this.studentDepartment = studentDepartment;
    }

    public String getStudentSemester() {
        return studentSemester;
    }

    public void setStudentSemester(String studentSemester) {
        this.studentSemester = studentSemester;
    }

    public String getExamId() {
        return examId;
    }

    public void setExamId(String examId) {
        this.examId = examId;
    }

    public String getExamName() {
        return examName;
    }

    public void setExamName(String examName) {
        this.examName = examName;
    }

    public String getExamDepartmentId() {
        return examDepartmentId;
    }

    public void setExamDepartmentId(String examDepartmentId) {
        this.examDepartmentId = examDepartmentId;
    }

    public String getExamSemester() {
        return examSemester;
    }

    public void setExamSemester(String examSemester) {
        this.examSemester = examSemester;
    }

    public List<String> getSubjects() {
        return subjects;
    }

    public void setSubjects(List<String> subjects) {
        this.subjects = subjects;
    }

    public Map<String, ExamScheduleEntry> getSchedule() {
        return schedule;
    }

    public void setSchedule(Map<String, ExamScheduleEntry> schedule) {
        this.schedule = schedule;
    }

    public Map<String, SeatingEntry> getSeatingArrangement() {
        return seatingArrangement;
    }

    public void setSeatingArrangement(Map<String, SeatingEntry> seatingArrangement) {
        this.seatingArrangement = seatingArrangement;
    }

    public SeatingEntry getStudentSeatingEntry() {
        return studentSeatingEntry;
    }

    public void setStudentSeatingEntry(SeatingEntry studentSeatingEntry) {
        this.studentSeatingEntry = studentSeatingEntry;
    }

    public Room getStudentRoomDetails() {
        return studentRoomDetails;
    }

    public void setStudentRoomDetails(Room studentRoomDetails) {
        this.studentRoomDetails = studentRoomDetails;
    }
}
