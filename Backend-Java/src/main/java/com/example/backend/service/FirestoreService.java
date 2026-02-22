package com.example.backend.service;

import com.example.backend.models.Institution;
import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class FirestoreService {

    private final Firestore firestore;

    public FirestoreService(Firestore firestore) {
        this.firestore = firestore;
    }

    public List<Institution> getInstitutions() throws ExecutionException, InterruptedException {
        List<Institution> institutions = new ArrayList<>();
        firestore.collection("Institutions").get().get().forEach(document -> {
            Institution institution = new Institution();
            institution.setId(document.getId());
            institution.setName(document.getString("name"));
            institutions.add(institution);
        });
        return institutions;
    }

    public Institution getInstitutionById(String institutionId) throws ExecutionException, InterruptedException {
        com.google.cloud.firestore.DocumentSnapshot document = firestore.collection("Institutions").document(institutionId).get().get();
        if (document.exists()) {
            return document.toObject(Institution.class);
        }
        return null;
    }
}
