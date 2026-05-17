package com.example.backend.controller;

import com.example.backend.dto.FeeReportDto;
import com.example.backend.dto.GenerateFeeRequest;
import com.example.backend.dto.RecordPaymentRequest;
import com.example.backend.models.FeeCategory;
import com.example.backend.models.FeeStructure;
import com.example.backend.models.Institution;
import com.example.backend.models.Payment;
import com.example.backend.models.StudentFee;
import com.example.backend.models.User;
import com.example.backend.service.FeeService;
import com.example.backend.service.FirestoreService;
import com.example.backend.service.PdfService;
import com.example.backend.service.UserService;
import com.lowagie.text.DocumentException;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.io.ByteArrayOutputStream;
import java.io.PrintWriter;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/{institutionId}/api/fees")
public class FeeController {

    private final FeeService feeService;
    private final PdfService pdfService;
    private final FirestoreService firestoreService;
    private final UserService userService;

    public FeeController(FeeService feeService, PdfService pdfService, FirestoreService firestoreService, UserService userService) {
        this.feeService = feeService;
        this.pdfService = pdfService;
        this.firestoreService = firestoreService;
        this.userService = userService;
    }

    // == Student Fees Operations ==
    @PostMapping("/generate")
    @PreAuthorize("hasAnyRole('ADMIN', 'FINANCE_ADMIN')")
    public ResponseEntity<Void> generateFees(@PathVariable String institutionId, @RequestBody GenerateFeeRequest request) {
        try {
            feeService.generateFeesForStudents(institutionId, request.getFeeStructureId(), request.getDueDate());
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/payments/{paymentId}/receipt")
    public ResponseEntity<byte[]> downloadReceipt(
            @PathVariable String institutionId,
            @PathVariable String paymentId) {
        try {
            Payment payment = feeService.getPaymentById(institutionId, paymentId);
            if (payment == null) return ResponseEntity.notFound().build();

            StudentFee studentFee = feeService.getStudentFeeById(institutionId, payment.getStudentFeeId());
            if (studentFee == null) return ResponseEntity.notFound().build();

            User student = userService.getUserById(institutionId, payment.getStudentId());
            if (student == null) return ResponseEntity.notFound().build();

            Institution institution = firestoreService.getInstitutionById(institutionId);
            if (institution == null) return ResponseEntity.notFound().build();

            byte[] pdfContent = pdfService.generateFeeReceipt(institution, student, studentFee, payment);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDispositionFormData("attachment", "Receipt_" + payment.getReceiptNumber() + ".pdf");
            
            return ResponseEntity.ok().headers(headers).body(pdfContent);
        } catch (ExecutionException | InterruptedException | DocumentException e) {
            return ResponseEntity.status(500).build();
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
    @PreAuthorize("hasAnyRole('ADMIN', 'FINANCE_ADMIN')")
    public ResponseEntity<Payment> recordPayment(
            @PathVariable String institutionId,
            @PathVariable String studentFeeId,
            @RequestBody RecordPaymentRequest request) {
        try {
            Payment payment = feeService.recordPayment(institutionId, studentFeeId, request);
            return ResponseEntity.ok(payment);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(null);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/student-fees/{studentFeeId}/payments")
    public ResponseEntity<List<Payment>> getPaymentHistory(@PathVariable String institutionId, @PathVariable String studentFeeId) {
        try {
            return ResponseEntity.ok(feeService.getPaymentsForStudentFee(institutionId, studentFeeId));
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/student-fees/{studentFeeId}/remarks")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'FINANCE_ADMIN')")
    public ResponseEntity<StudentFee> updateStudentFeeRemarks(
            @AuthenticationPrincipal String requesterUid,
            @PathVariable String institutionId,
            @PathVariable String studentFeeId,
            @RequestBody Map<String, String> requestBody) {
        try {
            String remarks = requestBody.get("remarks");
            StudentFee updatedFee = feeService.updateFacultyRemarks(institutionId, studentFeeId, remarks);
            return ResponseEntity.ok(updatedFee);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/faculty/student-fees")
    public ResponseEntity<List<StudentFee>> getStudentFeesForFaculty(
            @AuthenticationPrincipal String requesterUid,
            @PathVariable String institutionId) {
        try {
            User requestingUser = userService.getUserById(institutionId, requesterUid);
            if (requestingUser == null || (!"admin".equals(requestingUser.getRole()) && !"faculty".equals(requestingUser.getRole()))) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
            List<StudentFee> fees = feeService.getStudentFeesForFaculty(institutionId, requestingUser.getDisplayName());
            return ResponseEntity.ok(fees);
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/report/csv")
    @PreAuthorize("hasAnyRole('ADMIN', 'FINANCE_ADMIN')")
    public ResponseEntity<byte[]> getFeeReportCsv(
            @AuthenticationPrincipal String requesterUid,
            @PathVariable String institutionId) {
        try {
            List<FeeReportDto> reportData = feeService.generateFeeReportData(institutionId);
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            String[] csvHeaders = {"Student Name", "USN", "Fee Structure", "Total Amount", "Paid Amount", "Balance Amount", "Status", "Due Date", "Faculty Remarks"};
            
            CSVFormat format = CSVFormat.Builder.create(CSVFormat.DEFAULT).setHeader(csvHeaders).build();

            try (CSVPrinter csvPrinter = new CSVPrinter(new PrintWriter(bos), format)) {
                for (FeeReportDto data : reportData) {
                    csvPrinter.printRecord(data.getStudentName(), data.getUsn(), data.getFeeStructureTitle(),
                            data.getTotalAmount(), data.getPaidAmount(), data.getBalanceAmount(),
                            data.getStatus(), data.getDueDate(), data.getFacultyRemarks());
                }
                csvPrinter.flush();
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("text/csv"));
            headers.setContentDispositionFormData("attachment", "fee_report_" + institutionId + ".csv");
            
            return ResponseEntity.ok().headers(headers).body(bos.toByteArray());

        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }

    // == Fee Categories CRUD ==
    @PostMapping("/categories")
    @PreAuthorize("hasAnyRole('ADMIN', 'FINANCE_ADMIN')")
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
    @PreAuthorize("hasAnyRole('ADMIN', 'FINANCE_ADMIN')")
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
    @PreAuthorize("hasAnyRole('ADMIN', 'FINANCE_ADMIN')")
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
    @PreAuthorize("hasAnyRole('ADMIN', 'FINANCE_ADMIN')")
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
    @PreAuthorize("hasAnyRole('ADMIN', 'FINANCE_ADMIN')")
    public ResponseEntity<Void> deleteFeeStructure(@PathVariable String institutionId, @PathVariable String structureId) {
        try {
            feeService.deleteFeeStructure(institutionId, structureId);
            return ResponseEntity.ok().build();
        } catch (ExecutionException | InterruptedException e) {
            return ResponseEntity.status(500).build();
        }
    }
}
