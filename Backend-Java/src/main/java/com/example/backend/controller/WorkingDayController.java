package com.example.backend.controller;

import com.example.backend.models.WorkingDay;
import com.example.backend.service.WorkingDayService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/working-days")
public class WorkingDayController {

    private final WorkingDayService workingDayService;

    public WorkingDayController(WorkingDayService workingDayService) {
        this.workingDayService = workingDayService;
    }

    @PostMapping
    public ResponseEntity<WorkingDay> createWorkingDay(@PathVariable String institutionId, @RequestBody WorkingDay workingDay) {
        try {
            workingDay.setInstitutionId(institutionId);
            WorkingDay createdWorkingDay = workingDayService.createWorkingDay(workingDay);
            return ResponseEntity.ok(createdWorkingDay);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping
    public ResponseEntity<List<WorkingDay>> getWorkingDays(@PathVariable String institutionId) {
        try {
            List<WorkingDay> workingDays = workingDayService.getWorkingDays(institutionId);
            return ResponseEntity.ok(workingDays);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping
    public ResponseEntity<Void> updateWorkingDay(@PathVariable String institutionId, @RequestBody WorkingDay workingDay) {
        try {
            workingDay.setInstitutionId(institutionId);
            workingDayService.updateWorkingDay(workingDay);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
