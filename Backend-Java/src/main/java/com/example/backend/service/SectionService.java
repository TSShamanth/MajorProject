package com.example.backend.service;

import com.example.backend.models.Section;
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
import java.util.stream.Collectors;

@Service
public class SectionService {

    private final Firestore firestore;

    public SectionService(Firestore firestore) {
        this.firestore = firestore;
    }

    private List<Section> getAllSectionsInDepartment(String institutionId, String departmentId) throws ExecutionException, InterruptedException {
        List<Section> sections = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId)
                .collection("departments").document(departmentId)
                .collection("sections").get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            sections.add(document.toObject(Section.class));
        }
        return sections;
    }

    public Section createSection(Section section) throws ExecutionException, InterruptedException {
        String sectionId = UUID.randomUUID().toString();
        section.setId(sectionId);

        List<Section> allSections = getAllSectionsInDepartment(section.getInstitutionId(), section.getDepartmentId());

        // Validate faculty assignment
        if (section.getFacultyId() != null) {
            boolean facultyAssigned = allSections.stream()
                .anyMatch(s -> section.getFacultyId().equals(s.getFacultyId()));
            if (facultyAssigned) {
                throw new IllegalArgumentException("Faculty is already assigned to another section in this department.");
            }
        }
        
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(section.getInstitutionId())
                .collection("departments").document(section.getDepartmentId())
                .collection("sections").document(sectionId).set(section);
        future.get();
        return section;
    }

    public List<Section> getSections(String institutionId, String departmentId) throws ExecutionException, InterruptedException {
        return getAllSectionsInDepartment(institutionId, departmentId);
    }

    public Section getSection(String institutionId, String departmentId, String sectionId) throws ExecutionException, InterruptedException {
        ApiFuture<com.google.cloud.firestore.DocumentSnapshot> future = firestore.collection("Institutions").document(institutionId)
                .collection("departments").document(departmentId)
                .collection("sections").document(sectionId).get();
        com.google.cloud.firestore.DocumentSnapshot document = future.get();
        if (document.exists()) {
            return document.toObject(Section.class);
        }
        return null;
    }

    public Section updateSection(String institutionId, String departmentId, String sectionId, Section section) throws ExecutionException, InterruptedException {
        section.setId(sectionId);
        
        List<Section> otherSections = getAllSectionsInDepartment(institutionId, departmentId)
                .stream()
                .filter(s -> !s.getId().equals(sectionId))
                .collect(Collectors.toList());

        // Validate faculty
        if (section.getFacultyId() != null) {
            boolean facultyAssigned = otherSections.stream()
                .anyMatch(s -> section.getFacultyId().equals(s.getFacultyId()));
            if (facultyAssigned) {
                throw new IllegalArgumentException("Faculty is already assigned to another section in this department.");
            }
        }

        // Validate students
        if (section.getStudentIds() != null && !section.getStudentIds().isEmpty()) {
            List<String> otherStudentIds = otherSections.stream()
                .flatMap(s -> s.getStudentIds().stream())
                .collect(Collectors.toList());
            
            boolean studentAssigned = section.getStudentIds().stream()
                .anyMatch(studentId -> otherStudentIds.contains(studentId));

            if (studentAssigned) {
                throw new IllegalArgumentException("One or more students are already in another section in this department.");
            }
        }

        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId)
                .collection("departments").document(departmentId)
                .collection("sections").document(sectionId).set(section);
        future.get();
        return section;
    }

    public void deleteSection(String institutionId, String departmentId, String sectionId) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId)
                .collection("departments").document(departmentId)
                .collection("sections").document(sectionId).delete();
        future.get();
    }
}
