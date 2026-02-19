package com.example.backend.service;

import com.example.backend.models.FeeCategory;
import com.example.backend.models.FeeStructure;
import com.example.backend.models.StudentFee;
import com.example.backend.models.User;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class FeeService {

    private final Firestore firestore;
    private final UserService userService;

    public FeeService(Firestore firestore, UserService userService) {
        this.firestore = firestore;
        this.userService = userService;
    }

    // == Fee Categories CRUD ==
    public FeeCategory createFeeCategory(FeeCategory category) throws ExecutionException, InterruptedException {
        String id = UUID.randomUUID().toString();
        category.setId(id);
        firestore.collection("Institutions").document(category.getInstitutionId())
                .collection("feeCategories").document(id).set(category).get();
        return category;
    }

    public List<FeeCategory> getFeeCategories(String institutionId) throws ExecutionException, InterruptedException {
        List<FeeCategory> categories = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId)
                .collection("feeCategories").get();
        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            categories.add(document.toObject(FeeCategory.class));
        }
        return categories;
    }

    public void deleteFeeCategory(String institutionId, String categoryId) throws ExecutionException, InterruptedException {
        firestore.collection("Institutions").document(institutionId)
                .collection("feeCategories").document(categoryId).delete().get();
    }

    // == Fee Structures CRUD ==
    public FeeStructure createFeeStructure(FeeStructure structure) throws ExecutionException, InterruptedException {
        String id = UUID.randomUUID().toString();
        structure.setId(id);
        firestore.collection("Institutions").document(structure.getInstitutionId())
                .collection("feeStructures").document(id).set(structure).get();
        return structure;
    }

    public List<FeeStructure> getFeeStructures(String institutionId) throws ExecutionException, InterruptedException {
        List<FeeStructure> structures = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId)
                .collection("feeStructures").get();
        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            structures.add(document.toObject(FeeStructure.class));
        }
        return structures;
    }

    public FeeStructure getFeeStructureById(String institutionId, String structureId) throws ExecutionException, InterruptedException {
        DocumentSnapshot doc = firestore.collection("Institutions").document(institutionId)
                .collection("feeStructures").document(structureId).get().get();
        if (doc.exists()) {
            return doc.toObject(FeeStructure.class);
        }
        return null;
    }

    public FeeStructure updateFeeStructure(FeeStructure structure) throws ExecutionException, InterruptedException {
        firestore.collection("Institutions").document(structure.getInstitutionId())
                .collection("feeStructures").document(structure.getId()).set(structure).get();
        return structure;
    }

    public void deleteFeeStructure(String institutionId, String structureId) throws ExecutionException, InterruptedException {
        firestore.collection("Institutions").document(institutionId)
                .collection("feeStructures").document(structureId).delete().get();
    }
    
    // == Student Fees Operations ==
    public void generateFeesForStudents(String institutionId, String feeStructureId, java.util.Date dueDate) throws ExecutionException, InterruptedException {
        FeeStructure structure = getFeeStructureById(institutionId, feeStructureId);
        if (structure == null) throw new RuntimeException("Fee Structure not found");

        List<User> students;
        if ("ALL".equals(structure.getDepartmentId()) && "ALL".equals(structure.getSemester())) {
            students = userService.getUsers(institutionId, "student");
        } else if (!"ALL".equals(structure.getDepartmentId()) && "ALL".equals(structure.getSemester())) {
            students = userService.getUsers(institutionId, "student").stream()
                .filter(s -> structure.getDepartmentId().equals(s.getDepartmentId()))
                .toList();
        } else {
            students = userService.getStudentsByDepartmentAndSemester(institutionId, structure.getDepartmentId(), structure.getSemester());
        }

        for (User student : students) {
            StudentFee studentFee = new StudentFee();
            String id = UUID.randomUUID().toString();
            studentFee.setId(id);
            studentFee.setStudentId(student.getUid());
            studentFee.setStudentName(student.getDisplayName());
            studentFee.setUsn(student.getUsn());
            studentFee.setInstitutionId(institutionId);
            studentFee.setFeeStructureId(feeStructureId);
            studentFee.setFeeStructureTitle(structure.getTitle());
            studentFee.setComponents(structure.getComponents());
            studentFee.setTotalAmount(structure.getTotalAmount());
            studentFee.setPaidAmount(0);
            studentFee.setBalanceAmount(structure.getTotalAmount());
            studentFee.setStatus("UNPAID");
            studentFee.setDueDate(dueDate);
            studentFee.setCreatedAt(new java.util.Date());

            firestore.collection("Institutions").document(institutionId)
                    .collection("studentFees").document(id).set(studentFee).get();
        }
    }

    public List<StudentFee> getStudentFees(String institutionId) throws ExecutionException, InterruptedException {
        List<StudentFee> fees = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId)
                .collection("studentFees").get();
        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            fees.add(document.toObject(StudentFee.class));
        }
        return fees;
    }

    public List<StudentFee> getStudentFeesByStudentId(String institutionId, String studentId) throws ExecutionException, InterruptedException {
        List<StudentFee> fees = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId)
                .collection("studentFees").whereEqualTo("studentId", studentId).get();
        for (QueryDocumentSnapshot document : future.get().getDocuments()) {
            fees.add(document.toObject(StudentFee.class));
        }
        return fees;
    }

    public Map<String, Object> getFeeStats(String institutionId) throws ExecutionException, InterruptedException {
        List<StudentFee> allFees = getStudentFees(institutionId);
        double totalCollected = 0;
        double totalPending = 0;
        double overdue = 0;
        java.util.Date now = new java.util.Date();

        for (StudentFee fee : allFees) {
            totalCollected += fee.getPaidAmount();
            totalPending += fee.getBalanceAmount();
            if (fee.getBalanceAmount() > 0 && fee.getDueDate() != null && fee.getDueDate().before(now)) {
                overdue += fee.getBalanceAmount();
            }
        }

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalCollected", totalCollected);
        stats.put("totalPending", totalPending);
        stats.put("overdue", overdue);
        stats.put("totalCount", allFees.size());
        return stats;
    }
}
