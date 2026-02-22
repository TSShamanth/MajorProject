package com.example.backend.controller;

import com.example.backend.models.SavedPaymentMethod;
import com.example.backend.service.PaymentMethodService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/me/payment-methods")
public class PaymentMethodController {

    private final PaymentMethodService paymentMethodService;

    public PaymentMethodController(PaymentMethodService paymentMethodService) {
        this.paymentMethodService = paymentMethodService;
    }

    @GetMapping
    public ResponseEntity<List<SavedPaymentMethod>> getMyPaymentMethods(
            @AuthenticationPrincipal String uid,
            @PathVariable String institutionId) {
        try {
            // Optional: You could add a role check here if needed, but typically users manage their own methods.
            List<SavedPaymentMethod> methods = paymentMethodService.getPaymentMethodsForUser(institutionId, uid);
            return ResponseEntity.ok(methods);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PostMapping
    public ResponseEntity<SavedPaymentMethod> saveMyPaymentMethod(
            @AuthenticationPrincipal String uid,
            @PathVariable String institutionId,
            @RequestBody SavedPaymentMethod method) {
        try {
            SavedPaymentMethod savedMethod = paymentMethodService.savePaymentMethod(institutionId, uid, method);
            return ResponseEntity.ok(savedMethod);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/{methodId}")
    public ResponseEntity<Void> deleteMyPaymentMethod(
            @AuthenticationPrincipal String uid,
            @PathVariable String institutionId,
            @PathVariable String methodId) {
        try {
            // Optional: Add check to ensure user can only delete their own methods.
            // The current service logic implicitly does this by using the UID in the path.
            paymentMethodService.deletePaymentMethod(institutionId, uid, methodId);
            return ResponseEntity.noContent().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
