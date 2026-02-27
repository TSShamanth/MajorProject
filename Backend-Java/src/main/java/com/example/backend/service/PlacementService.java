package com.example.backend.service;

import com.example.backend.models.InterviewSlot;
import com.example.backend.models.Company;
import com.example.backend.models.PlacementDrive;
import com.example.backend.models.PlacementApplication;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class PlacementService {

    private final Firestore firestore;

    public PlacementService(Firestore firestore) {
        this.firestore = firestore;
    }

    // --- Interviews ---

    public InterviewSlot createInterviewSlot(String institutionId, InterviewSlot slot) throws ExecutionException, InterruptedException {
        String id = UUID.randomUUID().toString();
        slot.setId(id);
        firestore.collection("Institutions").document(institutionId)
                .collection("placement_interviews").document(id).set(slot).get();
        return slot;
    }

    public List<InterviewSlot> getInterviewSlots(String institutionId) throws ExecutionException, InterruptedException {
        List<InterviewSlot> slots = new ArrayList<>();
        QuerySnapshot querySnapshot = firestore.collection("Institutions").document(institutionId)
                .collection("placement_interviews").get().get();
        for (QueryDocumentSnapshot doc : querySnapshot.getDocuments()) {
            slots.add(doc.toObject(InterviewSlot.class));
        }
        return slots;
    }

    // --- Companies ---

    public Company createCompany(String institutionId, Company company) throws ExecutionException, InterruptedException {
        String id = UUID.randomUUID().toString();
        company.setId(id);
        firestore.collection("Institutions").document(institutionId)
                .collection("placement_companies").document(id).set(company).get();
        return company;
    }

    public List<Company> getCompanies(String institutionId) throws ExecutionException, InterruptedException {
        List<Company> companies = new ArrayList<>();
        QuerySnapshot querySnapshot = firestore.collection("Institutions").document(institutionId)
                .collection("placement_companies").get().get();
        for (QueryDocumentSnapshot doc : querySnapshot.getDocuments()) {
            companies.add(doc.toObject(Company.class));
        }
        return companies;
    }

    // --- Placement Drives ---

    public PlacementDrive createDrive(String institutionId, PlacementDrive drive) throws ExecutionException, InterruptedException {
        String id = UUID.randomUUID().toString();
        drive.setId(id);
        firestore.collection("Institutions").document(institutionId)
                .collection("placement_drives").document(id).set(drive).get();
        return drive;
    }

    public List<PlacementDrive> getDrives(String institutionId) throws ExecutionException, InterruptedException {
        List<PlacementDrive> drives = new ArrayList<>();
        QuerySnapshot querySnapshot = firestore.collection("Institutions").document(institutionId)
                .collection("placement_drives").get().get();
        for (QueryDocumentSnapshot doc : querySnapshot.getDocuments()) {
            drives.add(doc.toObject(PlacementDrive.class));
        }
        return drives;
    }

    // --- Applications ---

    public List<PlacementApplication> getApplications(String institutionId, String driveId) throws ExecutionException, InterruptedException {
        List<PlacementApplication> applications = new ArrayList<>();
        CollectionReference appRef = firestore.collection("Institutions").document(institutionId)
                .collection("placement_applications");
        
        Query query = (driveId != null) ? appRef.whereEqualTo("driveId", driveId) : appRef;
        QuerySnapshot querySnapshot = query.get().get();
        
        for (QueryDocumentSnapshot doc : querySnapshot.getDocuments()) {
            applications.add(doc.toObject(PlacementApplication.class));
        }
        return applications;
    }

    public PlacementApplication updateApplication(String institutionId, String applicationId, Map<String, Object> updates) throws ExecutionException, InterruptedException {
        DocumentReference docRef = firestore.collection("Institutions").document(institutionId)
                .collection("placement_applications").document(applicationId);
        docRef.update(updates).get();
        return docRef.get().get().toObject(PlacementApplication.class);
    }

    // --- Stats ---

    public Map<String, Object> getPlacementStats(String institutionId) throws ExecutionException, InterruptedException {
        Map<String, Object> stats = new HashMap<>();
        
        // Fetch all data for computation
        List<Company> companies = getCompanies(institutionId);
        List<PlacementDrive> drives = getDrives(institutionId);
        List<PlacementApplication> applications = getApplications(institutionId, null);

        long activeDrives = drives.stream().filter(d -> "Active".equalsIgnoreCase(d.getStatus())).count();
        long totalOffers = applications.stream().filter(a -> "Selected".equalsIgnoreCase(a.getStatus())).count();
        double maxPackage = drives.stream().mapToDouble(PlacementDrive::getSalaryPackage).max().orElse(0.0);

        // Get total student count to calculate percentage
        long totalStudents = firestore.collection("Institutions").document(institutionId)
                .collection("users").whereEqualTo("role", "student").get().get().size();

        double placedPercentage = totalStudents > 0 ? (double) totalOffers / totalStudents * 100 : 0;

        stats.put("totalCompanies", companies.size());
        stats.put("activeDrives", activeDrives);
        stats.put("totalOffers", totalOffers);
        stats.put("maxPackage", maxPackage);
        stats.put("placedPercentage", Math.round(placedPercentage * 100.0) / 100.0);
        stats.put("newCompaniesMonth", 3); // Still a bit hard to compute without 'createdAt', but better than nothing
        stats.put("closingSoon", drives.stream().filter(d -> "Active".equalsIgnoreCase(d.getStatus())).count()); // Placeholder logic

        return stats;
    }
}
