package com.example.backend.controller;

import com.example.backend.models.TimetableEntry;
import com.example.backend.service.TimetableService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/timetable")
public class TimetableController {

    private final TimetableService timetableService;

    public TimetableController(TimetableService timetableService) {
        this.timetableService = timetableService;
    }

    @PostMapping("/assign")
    public ResponseEntity<?> assignTimetable(@PathVariable String institutionId, @RequestBody TimetableEntry entry) {
        try {
            entry.setInstitutionId(institutionId);
            TimetableEntry createdEntry = timetableService.assignTimetable(entry);
            return ResponseEntity.ok(createdEntry);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/class/{departmentId}/{program}/{semester}/{sectionId}")
    public ResponseEntity<List<TimetableEntry>> getTimetableForClass(
            @PathVariable String institutionId,
            @PathVariable String departmentId,
            @PathVariable String program,
            @PathVariable String semester,
            @PathVariable String sectionId) {
        try {
            List<TimetableEntry> entries = timetableService.getTimetableForClass(institutionId, departmentId, program, semester, sectionId);
            return ResponseEntity.ok(entries);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/faculty/{facultyUid}")
    public ResponseEntity<List<TimetableEntry>> getTimetableForFaculty(
            @PathVariable String institutionId,
            @PathVariable String facultyUid) {
        try {
            List<TimetableEntry> entries = timetableService.getTimetableForFaculty(institutionId, facultyUid);
            return ResponseEntity.ok(entries);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/update")
    public ResponseEntity<?> updateTimetable(@PathVariable String institutionId, @RequestBody TimetableEntry entry) {
        try {
            entry.setInstitutionId(institutionId);
            timetableService.updateTimetable(entry);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTimetable(@PathVariable String institutionId, @PathVariable String id) {
        try {
            timetableService.deleteTimetable(institutionId, id);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
