package com.example.backend.service;

import com.example.backend.models.Announcement;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.WriteResult;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Query;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class AnnouncementService {

    private final Firestore firestore;
    private static final Logger logger = LoggerFactory.getLogger(AnnouncementService.class);

    public AnnouncementService(Firestore firestore) {
        this.firestore = firestore;
    }

    /**
     * Create a new announcement
     */
    public Announcement createAnnouncement(Announcement announcement, String institutionId)
            throws ExecutionException, InterruptedException {
        String announcementId = UUID.randomUUID().toString();
        announcement.setId(announcementId);
        announcement.setInstitutionId(institutionId);
        announcement.setCreatedAt(System.currentTimeMillis());
        announcement.setUpdatedAt(System.currentTimeMillis());
        announcement.setViewCount(0);
        // Set default status if not provided
        if (announcement.getStatus() == null || announcement.getStatus().isEmpty()) {
            announcement.setStatus("PUBLISHED");
        }

        ApiFuture<WriteResult> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .document(announcementId)
                .set(announcement);
        future.get();
        return announcement;
    }

    public List<Announcement> getAnnouncements(String institutionId)
            throws ExecutionException, InterruptedException {
        logger.info("Fetching EVERY announcement for institution: {}", institutionId);
        List<Announcement> announcements = new ArrayList<>();
        // Removed status filter and isPinned ordering which can cause Firestore to skip documents
        ApiFuture<QuerySnapshot> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .orderBy("createdAt", Query.Direction.DESCENDING)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        logger.info("Found {} total records for 'All Announcements'.", documents.size());
        for (QueryDocumentSnapshot document : documents) {
            announcements.add(document.toObject(Announcement.class));
        }
        return announcements;
    }

    /**
     * Get all published announcements without audience-specific filtering.
     * Reuses the existing getAnnouncements method.
     */
    public List<Announcement> getAllPublishedAnnouncements(String institutionId)
            throws ExecutionException, InterruptedException {
        return getAnnouncements(institutionId);
    }

    /**
     * Get announcements by category
     */
    public List<Announcement> getAnnouncementsByCategory(String institutionId, String category)
            throws ExecutionException, InterruptedException {
        List<Announcement> announcements = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .whereEqualTo("status", "PUBLISHED")
                .whereEqualTo("category", category)
                .orderBy("createdAt", Query.Direction.DESCENDING)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            announcements.add(document.toObject(Announcement.class));
        }
        return announcements;
    }

    /**
     * Get announcements by priority
     */
    public List<Announcement> getAnnouncementsByPriority(String institutionId, String priority)
            throws ExecutionException, InterruptedException {
        List<Announcement> announcements = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .whereEqualTo("status", "PUBLISHED")
                .whereEqualTo("priority", priority)
                .orderBy("createdAt", Query.Direction.DESCENDING)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            announcements.add(document.toObject(Announcement.class));
        }
        return announcements;
    }

    /**
     * Get announcement by ID
     */
    public Announcement getAnnouncementById(String institutionId, String announcementId)
            throws ExecutionException, InterruptedException {
        ApiFuture<DocumentSnapshot> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .document(announcementId)
                .get();

        DocumentSnapshot document = future.get();
        if (document.exists()) {
            return document.toObject(Announcement.class);
        }
        return null;
    }

    /**
     * Update announcement
     */
    public Announcement updateAnnouncement(String institutionId, String announcementId, Announcement announcement)
            throws ExecutionException, InterruptedException {
        // Fetch existing announcement
        Announcement existing = getAnnouncementById(institutionId, announcementId);
        if (existing == null) {
            throw new IllegalArgumentException("Announcement not found with ID: " + announcementId);
        }

        // Preserve creation details
        announcement.setId(announcementId);
        announcement.setInstitutionId(institutionId);
        announcement.setCreatedAt(existing.getCreatedAt());
        announcement.setCreatedBy(existing.getCreatedBy());
        announcement.setUpdatedAt(System.currentTimeMillis());
        announcement.setViewCount(existing.getViewCount());
        announcement.setViewers(existing.getViewers());

        ApiFuture<WriteResult> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .document(announcementId)
                .set(announcement);
        future.get();
        return announcement;
    }

    /**
     * Delete announcement
     */
    public void deleteAnnouncement(String institutionId, String announcementId)
            throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .document(announcementId)
                .delete();
        future.get();
    }

    /**
     * Get announcements created by user (admin/faculty management)
     */
    public List<Announcement> getMyAnnouncements(String institutionId, String userId)
            throws ExecutionException, InterruptedException {
        List<Announcement> announcements = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .whereEqualTo("createdBy", userId)
                .orderBy("createdAt", Query.Direction.DESCENDING)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            announcements.add(document.toObject(Announcement.class));
        }
        return announcements;
    }

    /**
     * Get all announcements for admin management (including drafts and archived)
     */
    public List<Announcement> getAllAnnouncementsForManagement(String institutionId)
            throws ExecutionException, InterruptedException {
        List<Announcement> announcements = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .orderBy("createdAt", Query.Direction.DESCENDING)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            announcements.add(document.toObject(Announcement.class));
        }
        return announcements;
    }

    /**
     * Mark announcement as viewed by user
     */
    public void markAnnouncementAsViewed(String institutionId, String announcementId, String userId)
            throws ExecutionException, InterruptedException {
        Announcement announcement = getAnnouncementById(institutionId, announcementId);
        if (announcement == null) {
            throw new IllegalArgumentException("Announcement not found with ID: " + announcementId);
        }

        // Check if user has already viewed
        List<Map<String, Object>> viewers = announcement.getViewers();
        if (viewers == null) {
            viewers = new ArrayList<>();
        }

        boolean alreadyViewed = viewers.stream()
                .anyMatch(viewer -> userId.equals(viewer.get("uid")));

        if (!alreadyViewed) {
            Map<String, Object> viewerInfo = new HashMap<>();
            viewerInfo.put("uid", userId);
            viewerInfo.put("viewedAt", System.currentTimeMillis());
            viewers.add(viewerInfo);
            announcement.setViewers(viewers);
            announcement.setViewCount(announcement.getViewCount() + 1);

            ApiFuture<WriteResult> future = firestore
                    .collection("Institutions")
                    .document(institutionId)
                    .collection("announcements")
                    .document(announcementId)
                    .update("viewers", viewers, "viewCount", announcement.getViewCount());
            future.get();
        }
    }

    /**
     * Search announcements by title or description
     */
    public List<Announcement> searchAnnouncements(String institutionId, String searchQuery)
            throws ExecutionException, InterruptedException {
        List<Announcement> allAnnouncements = getAnnouncements(institutionId);
        String query = searchQuery.toLowerCase();

        return allAnnouncements.stream()
                .filter(announcement -> announcement.getTitle().toLowerCase().contains(query) ||
                        announcement.getDescription().toLowerCase().contains(query) ||
                        announcement.getContent().toLowerCase().contains(query))
                .collect(Collectors.toList());
    }

    /**
     * Toggle pin status
     */
    public void togglePinStatus(String institutionId, String announcementId, boolean isPinned)
            throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .document(announcementId)
                .update("isPinned", isPinned);
        future.get();
    }

    /**
     * Get announcements for specific audience
     */
    public List<Announcement> getAnnouncementsForAudience(String institutionId, String userRole, String departmentId, String programme)
            throws ExecutionException, InterruptedException {
        logger.info("getAnnouncementsForAudience called with institutionId: {}, userRole: {}, departmentId: {}, programme: {}",
                institutionId, userRole, departmentId, programme);

        List<Announcement> announcements = new ArrayList<>();
        Map<String, Announcement> uniqueAnnouncements = new HashMap<>();

        // Query 1: Get announcements targeting "ALL"
        Query queryAll = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .whereEqualTo("status", "PUBLISHED")
                .whereArrayContains("targetAudience", "ALL")
                .orderBy("isPinned", Query.Direction.DESCENDING)
                .orderBy("createdAt", Query.Direction.DESCENDING);

        ApiFuture<QuerySnapshot> futureAll = queryAll.get();
        List<QueryDocumentSnapshot> docsAll = futureAll.get().getDocuments();
        logger.info("Query 1 (targetAudience: ALL) returned {} documents.", docsAll.size());
        for (QueryDocumentSnapshot document : docsAll) {
            Announcement announcement = document.toObject(Announcement.class);
            uniqueAnnouncements.put(announcement.getId(), announcement);
        }
        logger.info("After Query 1, uniqueAnnouncements size: {}", uniqueAnnouncements.size());

        // Query 2: Get announcements targeting the specific userRole
        // Exclude "ALL" from this query if userRole is not "ALL" to avoid redundant results if already fetched
        if (userRole != null && !"ALL".equalsIgnoreCase(userRole)) { // Added null check for userRole
            // Map frontend role names to backend expectations if necessary
            String searchRole = userRole.toUpperCase();
            if ("STUDENT".equals(searchRole)) searchRole = "STUDENTS";
            
            logger.info("Executing Query 2 for specific userRole (normalized): {}", searchRole);
            Query queryRole = firestore
                    .collection("Institutions")
                    .document(institutionId)
                    .collection("announcements")
                    .whereEqualTo("status", "PUBLISHED")
                    .whereArrayContains("targetAudience", searchRole)
                    .orderBy("isPinned", Query.Direction.DESCENDING)
                    .orderBy("createdAt", Query.Direction.DESCENDING);

            ApiFuture<QuerySnapshot> futureRole = queryRole.get();
            List<QueryDocumentSnapshot> docsRole = futureRole.get().getDocuments();
            logger.info("Query 2 (targetAudience: {}) returned {} documents.", searchRole, docsRole.size());
            for (QueryDocumentSnapshot document : docsRole) {
                Announcement announcement = document.toObject(Announcement.class);
                uniqueAnnouncements.put(announcement.getId(), announcement); // put will replace if already exists
            }
            logger.info("After Query 2, uniqueAnnouncements size: {}", uniqueAnnouncements.size());
        }
        
        announcements.addAll(uniqueAnnouncements.values());
        logger.info("Combined announcements list size before department filter: {}", announcements.size());

        // Apply in-memory filtering for departmentId or programme if provided
        if ((departmentId != null && !departmentId.isEmpty()) || (programme != null && !programme.isEmpty())) {
            logger.info("Applying in-memory filter for departmentId: {} or programme: {}", departmentId, programme);
            List<Announcement> filteredByDepartment = announcements.stream()
                    .filter(announcement -> {
                        List<String> targetDepts = announcement.getTargetDepartments();
                        // If no departments are targeted, it's for everyone
                        if (targetDepts == null || targetDepts.isEmpty() || targetDepts.contains("ALL")) {
                            return true;
                        }
                        
                        boolean matchesDeptId = (departmentId != null && targetDepts.contains(departmentId));
                        boolean matchesProgramme = (programme != null && targetDepts.contains(programme));
                        
                        boolean matches = matchesDeptId || matchesProgramme;
                        
                        logger.debug("Announcement '{}' (targetDepts: {}) matches: {}",
                                announcement.getTitle(), targetDepts, matches);
                        return matches;
                    })
                    .collect(Collectors.toList());
            logger.info("After filter, list size: {}", filteredByDepartment.size());
            return filteredByDepartment;
        }

        logger.info("Final announcements list size: {}", announcements.size());
        return announcements;
    }
}
