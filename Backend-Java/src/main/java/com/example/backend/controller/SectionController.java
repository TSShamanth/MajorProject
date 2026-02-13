package com.example.backend.controller;

import com.example.backend.models.Section;
import com.example.backend.service.SectionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/departments/{departmentId}/sections")
public class SectionController {

    private final SectionService sectionService;

    public SectionController(SectionService sectionService) {
        this.sectionService = sectionService;
    }

    @PostMapping
    public ResponseEntity<Section> createSection(@PathVariable String institutionId, @PathVariable String departmentId, @RequestBody Section section) {
        try {
            section.setInstitutionId(institutionId);
            section.setDepartmentId(departmentId);
            Section createdSection = sectionService.createSection(section);
            return ResponseEntity.ok(createdSection);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Section>> getSections(@PathVariable String institutionId, @PathVariable String departmentId) {
        try {
            List<Section> sections = sectionService.getSections(institutionId, departmentId);
            return ResponseEntity.ok(sections);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/{sectionId}")
    public ResponseEntity<Section> getSection(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String sectionId) {
        try {
            Section section = sectionService.getSection(institutionId, departmentId, sectionId);
            if (section != null) {
                return ResponseEntity.ok(section);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/{sectionId}")
    public ResponseEntity<Section> updateSection(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String sectionId, @RequestBody Section section) {
        try {
            section.setInstitutionId(institutionId);
            section.setDepartmentId(departmentId);
            Section updatedSection = sectionService.updateSection(institutionId, departmentId, sectionId, section);
            return ResponseEntity.ok(updatedSection);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/{sectionId}")
    public ResponseEntity<Void> deleteSection(@PathVariable String institutionId, @PathVariable String departmentId, @PathVariable String sectionId) {
        try {
            sectionService.deleteSection(institutionId, departmentId, sectionId);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
