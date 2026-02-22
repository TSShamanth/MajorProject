package com.example.backend.controller;

import com.example.backend.models.TimeSlot;
import com.example.backend.service.TimeSlotService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/timeslots")
public class TimeSlotController {

    private final TimeSlotService timeSlotService;

    public TimeSlotController(TimeSlotService timeSlotService) {
        this.timeSlotService = timeSlotService;
    }

    @PostMapping
    public ResponseEntity<TimeSlot> createTimeSlot(@PathVariable String institutionId, @RequestBody TimeSlot timeSlot) {
        try {
            timeSlot.setInstitutionId(institutionId);
            TimeSlot createdTimeSlot = timeSlotService.createTimeSlot(timeSlot);
            return ResponseEntity.ok(createdTimeSlot);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping
    public ResponseEntity<List<TimeSlot>> getTimeSlots(@PathVariable String institutionId) {
        try {
            List<TimeSlot> timeSlots = timeSlotService.getTimeSlots(institutionId);
            return ResponseEntity.ok(timeSlots);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/{timeSlotId}")
    public ResponseEntity<Void> deleteTimeSlot(@PathVariable String institutionId, @PathVariable String timeSlotId) {
        try {
            timeSlotService.deleteTimeSlot(institutionId, timeSlotId);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
