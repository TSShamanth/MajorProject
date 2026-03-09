package com.example.backend.service;

import com.example.backend.models.CustomForm;
import com.example.backend.models.FormResponse;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class FormService {

    private final Firestore firestore;

    public FormService(Firestore firestore) {
        this.firestore = firestore;
    }

    public CustomForm createForm(String institutionId, CustomForm form) throws ExecutionException, InterruptedException {
        String formId = UUID.randomUUID().toString();
        form.setId(formId);
        form.setInstitutionId(institutionId);
        form.setCreatedAt(System.currentTimeMillis());
        form.setUpdatedAt(System.currentTimeMillis());

        firestore.collection("Institutions")
                .document(institutionId)
                .collection("forms")
                .document(formId)
                .set(form)
                .get();

        return form;
    }

    public List<CustomForm> getForms(String institutionId) throws ExecutionException, InterruptedException {
        List<CustomForm> forms = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions")
                .document(institutionId)
                .collection("forms")
                .get();

        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            forms.add(document.toObject(CustomForm.class));
        }
        return forms;
    }

    public List<CustomForm> getFormsForAudience(String institutionId, String role) throws ExecutionException, InterruptedException {
        List<CustomForm> allForms = getForms(institutionId);
        String finalRole = role != null ? role.toUpperCase() : "";
        
        return allForms.stream()
                .filter(form -> {
                    // Safety check: a form is "Open" if isOpen is true OR null (default to open)
                    boolean isActuallyOpen = form.isOpen();
                    
                    // Check audience
                    boolean audienceMatch = form.getTargetAudience() == null || 
                                           form.getTargetAudience().isEmpty() || 
                                           form.getTargetAudience().stream().anyMatch(a -> a.equalsIgnoreCase("ALL")) ||
                                           form.getTargetAudience().stream().anyMatch(a -> a.equalsIgnoreCase(finalRole));
                    
                    return isActuallyOpen && audienceMatch;
                })
                .collect(Collectors.toList());
    }

    public CustomForm getFormById(String institutionId, String formId) throws ExecutionException, InterruptedException {
        DocumentSnapshot doc = firestore.collection("Institutions")
                .document(institutionId)
                .collection("forms")
                .document(formId)
                .get()
                .get();

        return doc.exists() ? doc.toObject(CustomForm.class) : null;
    }

    public CustomForm updateForm(String institutionId, String formId, CustomForm form) throws ExecutionException, InterruptedException {
        form.setId(formId);
        form.setInstitutionId(institutionId);
        form.setUpdatedAt(System.currentTimeMillis());

        firestore.collection("Institutions")
                .document(institutionId)
                .collection("forms")
                .document(formId)
                .set(form, SetOptions.merge())
                .get();

        return form;
    }

    public void deleteForm(String institutionId, String formId) throws ExecutionException, InterruptedException {
        firestore.collection("Institutions")
                .document(institutionId)
                .collection("forms")
                .document(formId)
                .delete()
                .get();
        
        // Optionally delete all responses associated with this form
        QuerySnapshot responses = firestore.collection("Institutions")
                .document(institutionId)
                .collection("formResponses")
                .whereEqualTo("formId", formId)
                .get()
                .get();
        
        WriteBatch batch = firestore.batch();
        for (QueryDocumentSnapshot doc : responses.getDocuments()) {
            batch.delete(doc.getReference());
        }
        batch.commit().get();
    }

    public FormResponse submitResponse(String institutionId, FormResponse response) throws ExecutionException, InterruptedException {
        // If an ID is provided, it's an update (Edit Response)
        String responseId = response.getId() != null && !response.getId().isEmpty() 
            ? response.getId() 
            : UUID.randomUUID().toString();
        
        response.setId(responseId);
        response.setInstitutionId(institutionId);
        response.setSubmittedAt(System.currentTimeMillis());

        firestore.collection("Institutions")
                .document(institutionId)
                .collection("formResponses")
                .document(responseId)
                .set(response)
                .get();

        return response;
    }

    public FormResponse getUserResponseForForm(String institutionId, String formId, String userId) throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions")
                .document(institutionId)
                .collection("formResponses")
                .whereEqualTo("formId", formId)
                .whereEqualTo("userId", userId)
                .limit(1)
                .get();

        List<QueryDocumentSnapshot> docs = future.get().getDocuments();
        return docs.isEmpty() ? null : docs.get(0).toObject(FormResponse.class);
    }

    public long getResponseCountForForm(String institutionId, String formId) throws ExecutionException, InterruptedException {
        ApiFuture<AggregateQuerySnapshot> countFuture = firestore.collection("Institutions")
                .document(institutionId)
                .collection("formResponses")
                .whereEqualTo("formId", formId)
                .count()
                .get();
        return countFuture.get().getCount();
    }

    public List<FormResponse> getResponsesForForm(String institutionId, String formId) throws ExecutionException, InterruptedException {
        List<FormResponse> responses = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions")
                .document(institutionId)
                .collection("formResponses")
                .whereEqualTo("formId", formId)
                .get();

        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            responses.add(document.toObject(FormResponse.class));
        }
        return responses;
    }

    public List<FormResponse> getResponsesForUser(String institutionId, String userId) throws ExecutionException, InterruptedException {
        List<FormResponse> responses = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions")
                .document(institutionId)
                .collection("formResponses")
                .whereEqualTo("userId", userId)
                .get();

        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            responses.add(document.toObject(FormResponse.class));
        }
        return responses;
    }
}
