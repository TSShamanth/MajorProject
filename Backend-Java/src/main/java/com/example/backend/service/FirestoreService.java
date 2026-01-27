package com.example.backend.service;

import com.example.backend.models.Institution;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class FirestoreService {

    public List<Institution> getInstitutions() throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        List<Institution> institutions = new ArrayList<>();
        db.collection("Institutions").get().get().forEach(document -> {
            Institution institution = new Institution();
            institution.setId(document.getId());
            institution.setName(document.getString("name"));
            institutions.add(institution);
        });
        return institutions;
    }
}
