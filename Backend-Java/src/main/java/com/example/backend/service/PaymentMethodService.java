package com.example.backend.service;

import com.example.backend.models.SavedPaymentMethod;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class PaymentMethodService {

    private final Firestore firestore;

    public PaymentMethodService(Firestore firestore) {
        this.firestore = firestore;
    }

    public List<SavedPaymentMethod> getPaymentMethodsForUser(String institutionId, String userId) throws ExecutionException, InterruptedException {
        List<SavedPaymentMethod> methods = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId)
                .collection("users").document(userId)
                .collection("paymentMethods").get();
        
        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            methods.add(document.toObject(SavedPaymentMethod.class));
        }
        return methods;
    }

    public SavedPaymentMethod savePaymentMethod(String institutionId, String userId, SavedPaymentMethod method) throws ExecutionException, InterruptedException {
        String id = UUID.randomUUID().toString();
        method.setId(id);
        method.setUserId(userId);

        firestore.collection("Institutions").document(institutionId)
                .collection("users").document(userId)
                .collection("paymentMethods").document(id).set(method).get();
        
        return method;
    }

    public void deletePaymentMethod(String institutionId, String userId, String methodId) throws ExecutionException, InterruptedException {
        firestore.collection("Institutions").document(institutionId)
                .collection("users").document(userId)
                .collection("paymentMethods").document(methodId).delete().get();
    }
}
