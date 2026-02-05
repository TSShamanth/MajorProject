package com.example.backend.controller;

import com.example.backend.models.Department;
import com.example.backend.service.DepartmentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/departments")
public class DepartmentController {

    private final DepartmentService departmentService;

    public DepartmentController(DepartmentService departmentService) {
        this.departmentService = departmentService;
    }

    @PostMapping
    public ResponseEntity<Department> createDepartment(@PathVariable String institutionId, @RequestBody Department department) {
        try {
            department.setInstitutionId(institutionId);
            Department createdDepartment = departmentService.createDepartment(department);
            return ResponseEntity.ok(createdDepartment);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Department>> getDepartments(@PathVariable String institutionId) {
        try {
            List<Department> departments = departmentService.getDepartments(institutionId);
            return ResponseEntity.ok(departments);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/{departmentId}")
    public ResponseEntity<Void> deleteDepartment(@PathVariable String institutionId, @PathVariable String departmentId) {
        try {
            departmentService.deleteDepartment(institutionId, departmentId);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
