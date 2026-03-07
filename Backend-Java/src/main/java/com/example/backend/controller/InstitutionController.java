package com.example.backend.controller;

import com.example.backend.models.Institution;
import com.example.backend.service.FirestoreService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
public class InstitutionController {

    @Autowired
    private FirestoreService firestoreService;

    @GetMapping("/institutions")
    public List<Institution> getInstitutions() throws ExecutionException, InterruptedException {
        return firestoreService.getInstitutions();
    }

    @GetMapping("/institutions/{id}")
    public Institution getInstitution(@PathVariable String id) throws ExecutionException, InterruptedException {
        return firestoreService.getInstitutionById(id);
    }

    @PutMapping("/institutions/{id}")
    public String updateInstitution(@PathVariable String id, @RequestBody Institution institution) throws ExecutionException, InterruptedException {
        institution.setId(id);
        firestoreService.updateInstitution(id, institution);
        return "Institution updated successfully";
    }
}
