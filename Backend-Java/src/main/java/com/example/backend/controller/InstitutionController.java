package com.example.backend.controller;

import com.example.backend.models.Institution;
import com.example.backend.service.FirestoreService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

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
}
