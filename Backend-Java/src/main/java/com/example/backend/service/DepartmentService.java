package com.example.backend.service;

import com.example.backend.models.Department;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class DepartmentService {

    private final Firestore firestore;

    public DepartmentService(Firestore firestore) {
        this.firestore = firestore;
    }

    public Department createDepartment(Department department) throws ExecutionException, InterruptedException {
        String departmentId = UUID.randomUUID().toString();
        department.setId(departmentId);
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(department.getInstitutionId()).collection("departments").document(departmentId).set(department);
        future.get();
        return department;
    }

    public List<Department> getDepartments(String institutionId) throws ExecutionException, InterruptedException {
        List<Department> departments = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId).collection("departments").get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            departments.add(document.toObject(Department.class));
        }
        return departments;
    }

    public void deleteDepartment(String institutionId, String departmentId) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("departments").document(departmentId).delete();
        future.get();
    }
}
