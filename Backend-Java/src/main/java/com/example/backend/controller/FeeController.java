package com.example.backend.controller;

import com.example.backend.dto.GenerateFeeRequest;
import com.example.backend.dto.RecordPaymentRequest;
import com.example.backend.models.FeeCategory;
import com.example.backend.models.FeeStructure;
import com.example.backend.models.Payment;
import com.example.backend.models.StudentFee;
import com.example.backend.service.FeeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/fees")
public class FeeController {

    private final FeeService feeService;

    public FeeController(FeeService feeService) {
        this.feeService = feeService;
    }

    // == Student Fees Operations ==
    @PostMapping("/generate")
    public ResponseEntity<Void> generateFees(@PathVariable String institutionId, @RequestBody GenerateFeeRequest request) {
        try {
            feeService.generateFeesForStudents(institutionId, request.getFeeStructureId(), request.getDueDate());
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        } catch (RuntimeException e) { // Catch RuntimeException for Fee Structure not found
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/student-fees")
    public ResponseEntity<List<StudentFee>> getStudentFees(@PathVariable String institutionId, @RequestParam(required = false) String studentId) {
        try {
            if (studentId != null) {
                return ResponseEntity.ok(feeService.getStudentFeesByStudentId(institutionId, studentId));
            }
            return ResponseEntity.ok(feeService.getStudentFees(institutionId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getFeeStats(@PathVariable String institutionId) {
        try {
            return ResponseEntity.ok(feeService.getFeeStats(institutionId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PostMapping("/student-fees/{studentFeeId}/payments")
    public ResponseEntity<Payment> recordPayment(
            @PathVariable String institutionId,
            @PathVariable String studentFeeId,
            @RequestBody RecordPaymentRequest request) {
        try {
            Payment payment = feeService.recordPayment(institutionId, studentFeeId, request);
            return ResponseEntity.ok(payment);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(null); // Return 400 Bad Request for validation errors
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        } catch (RuntimeException e) { // Catch RuntimeException for Student Fee not found
            return ResponseEntity.notFound().build();
        }
    }

    // == Fee Categories CRUD ==
    @PostMapping("/categories")
    public ResponseEntity<FeeCategory> createFeeCategory(@PathVariable String institutionId, @RequestBody FeeCategory category) {
        try {
            category.setInstitutionId(institutionId);
            return ResponseEntity.ok(feeService.createFeeCategory(category));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/categories")
    public ResponseEntity<List<FeeCategory>> getFeeCategories(@PathVariable String institutionId) {
        try {
            return ResponseEntity.ok(feeService.getFeeCategories(institutionId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/categories/{categoryId}")
    public ResponseEntity<Void> deleteFeeCategory(@PathVariable String institutionId, @PathVariable String categoryId) {
        try {
            feeService.deleteFeeCategory(institutionId, categoryId);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    // == Fee Structures CRUD ==
    @PostMapping("/structures")
    public ResponseEntity<FeeStructure> createFeeStructure(@PathVariable String institutionId, @RequestBody FeeStructure structure) {
        try {
            structure.setInstitutionId(institutionId);
            return ResponseEntity.ok(feeService.createFeeStructure(structure));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/structures")
    public ResponseEntity<List<FeeStructure>> getFeeStructures(@PathVariable String institutionId) {
        try {
            return ResponseEntity.ok(feeService.getFeeStructures(institutionId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/structures/{structureId}")
    public ResponseEntity<FeeStructure> getFeeStructureById(@PathVariable String institutionId, @PathVariable String structureId) {
        try {
            FeeStructure structure = feeService.getFeeStructureById(institutionId, structureId);
            if (structure != null) {
                return ResponseEntity.ok(structure);
            }
            return ResponseEntity.notFound().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/structures/{structureId}")
    public ResponseEntity<FeeStructure> updateFeeStructure(@PathVariable String institutionId, @PathVariable String structureId, @RequestBody FeeStructure structure) {
        try {
            structure.setInstitutionId(institutionId);
            structure.setId(structureId);
            return ResponseEntity.ok(feeService.updateFeeStructure(structure));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/structures/{structureId}")
    public ResponseEntity<Void> deleteFeeStructure(@PathVariable String institutionId, @PathVariable String structureId) {
        try {
            feeService.deleteFeeStructure(institutionId, structureId);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
