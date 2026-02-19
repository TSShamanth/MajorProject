package com.example.backend.service;

import com.example.backend.models.Announcement;
import com.example.backend.service.UserService;
import com.example.backend.service.NotificationService;
import com.example.backend.models.Notification;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.WriteResult;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Query;
import org.springframework.stereotype.Service;

import java.util.Objects;
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
    private final UserService userService;
    private final NotificationService notificationService;
    private static final Logger logger = LoggerFactory.getLogger(AnnouncementService.class);

    public AnnouncementService(Firestore firestore, UserService userService, NotificationService notificationService) {
        this.firestore = firestore;
        this.userService = userService;
        this.notificationService = notificationService;
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

        // after storing announcement send notifications if it is published
        if (announcement.getStatus() != null && announcement.getStatus().equalsIgnoreCase("PUBLISHED")) {
            try {
                sendAnnouncementNotifications(announcement, institutionId);
            } catch (Exception e) {
                logger.error("Failed to create notifications for announcement {}: {}", announcementId, e.getMessage());
            }
        }

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

        // if status changed from draft to published, send notifications
        if (existing.getStatus() != null && existing.getStatus().equalsIgnoreCase("DRAFT")
                && announcement.getStatus() != null && announcement.getStatus().equalsIgnoreCase("PUBLISHED")) {
            try {
                sendAnnouncementNotifications(announcement, institutionId);
            } catch (Exception e) {
                logger.error("Notification send failed on update publish: {}", e.getMessage());
            }
        }

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

        // Fetch all announcements for the institution and filter in-memory
        ApiFuture<QuerySnapshot> future = firestore
                .collection("Institutions")
                .document(institutionId)
                .collection("announcements")
                .orderBy("createdAt", Query.Direction.DESCENDING)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        logger.info("Fetched {} total announcements to filter for audience", documents.size());

        final String finalSearchRole = (userRole != null) ? userRole.trim() : "";
        final String finalDeptId = (departmentId != null) ? departmentId.trim() : "";
        final String finalProg = (programme != null) ? programme.trim() : "";

        List<Announcement> filteredAnnouncements = documents.stream()
                .map(doc -> doc.toObject(Announcement.class))
                .filter(Objects::nonNull)
                .filter(announcement -> {
                    // 1. Status Check
                    if (!"PUBLISHED".equalsIgnoreCase(announcement.getStatus())) {
                        return false;
                    }

                    // 2. Audience Check (Role-based)
                    List<String> audience = announcement.getTargetAudience();
                    if (audience == null || audience.isEmpty()) {
                        logger.debug("Announcement '{}' has no target audience, skipping.", announcement.getTitle());
                        return false;
                    }
                    
                    boolean roleMatch = audience.stream().anyMatch(a -> {
                        if ("ALL".equalsIgnoreCase(a)) return true;
                        if (finalSearchRole.isEmpty()) return false;
                        if (a.equalsIgnoreCase(finalSearchRole)) return true;
                        
                        // Handle student/students variation
                        if (a.equalsIgnoreCase("STUDENT") && finalSearchRole.equalsIgnoreCase("STUDENTS")) return true;
                        if (a.equalsIgnoreCase("STUDENTS") && finalSearchRole.equalsIgnoreCase("STUDENT")) return true;
                        
                        return false;
                    });
                    
                    if (!roleMatch) {
                        logger.debug("Announcement '{}' audience {} does not match user role '{}'", 
                                announcement.getTitle(), audience, finalSearchRole);
                        return false;
                    }

                    // 3. Department/Programme Check
                    List<String> targetDepts = announcement.getTargetDepartments();
                    // If no departments are targeted or "ALL" is specified, it's for everyone in that role
                    if (targetDepts == null || targetDepts.isEmpty() || 
                        targetDepts.stream().anyMatch(d -> "ALL".equalsIgnoreCase(d))) {
                        return true;
                    }

                    boolean matchesDeptId = (!finalDeptId.isEmpty() && 
                        targetDepts.stream().anyMatch(d -> d.equalsIgnoreCase(finalDeptId)));
                    boolean matchesProgramme = (!finalProg.isEmpty() && 
                        targetDepts.stream().anyMatch(p -> p.equalsIgnoreCase(finalProg)));
                    
                    boolean deptMatch = matchesDeptId || matchesProgramme;
                    
                    if (!deptMatch) {
                        logger.debug("Announcement '{}' targetDepts {} does not match user DeptId '{}' or Programme '{}'", 
                                announcement.getTitle(), targetDepts, finalDeptId, finalProg);
                    }
                    
                    return deptMatch;
                })
                .sorted((a1, a2) -> {
                    // Sort by pinned first, then by createdAt descending
                    if (a1.isPinned() && !a2.isPinned()) return -1;
                    if (!a1.isPinned() && a2.isPinned()) return 1;
                    return Long.compare(a2.getCreatedAt(), a1.getCreatedAt());
                })
                .collect(Collectors.toList());

        logger.info("Returning {} filtered announcements for audience", filteredAnnouncements.size());
        return filteredAnnouncements;
    }

    /**
     * Send notifications to all users who match the announcement's audience and department/programme filters.
     */
    private void sendAnnouncementNotifications(Announcement announcement, String institutionId)
            throws ExecutionException, InterruptedException {
        List<String> audience = announcement.getTargetAudience();
        List<String> targetDepts = announcement.getTargetDepartments();
        if (audience == null || audience.isEmpty()) {
            // nothing to send
            return;
        }

        // collect unique userIds
        java.util.Set<String> userIds = new java.util.HashSet<>();
        boolean allRoles = audience.stream().anyMatch(a -> "ALL".equalsIgnoreCase(a));

        if (allRoles) {
            // fetch all users
            List<com.example.backend.models.User> allUsers = userService.getUsers(institutionId, null);
            for (com.example.backend.models.User u : allUsers) {
                if (matchesDepartmentFilter(u, targetDepts)) {
                    userIds.add(u.getUid());
                }
            }
        } else {
            for (String role : audience) {
                String normalized = role.trim().toLowerCase();
                // strip plural s if present (student -> student, students -> student)
                if (normalized.endsWith("s")) {
                    normalized = normalized.substring(0, normalized.length() - 1);
                }
                List<com.example.backend.models.User> users = userService.getUsers(institutionId, normalized);
                for (com.example.backend.models.User u : users) {
                    if (matchesDepartmentFilter(u, targetDepts)) {
                        userIds.add(u.getUid());
                    }
                }
            }
        }

        // create notification object once and send for each user id
        for (String uid : userIds) {
            Notification notif = new Notification();
            notif.setTitle("New Announcement");
            notif.setMessage(announcement.getTitle());
            // route pushed from client will prefix institutionId automatically
            notif.setRoute("/announcements/" + announcement.getId());
            try {
                notificationService.createNotification(institutionId, uid, notif);
            } catch (Exception e) {
                logger.error("Error creating announcement notification for user {}: {}", uid, e.getMessage());
            }
        }
    }

    private boolean matchesDepartmentFilter(com.example.backend.models.User user, List<String> targetDepts) {
        if (targetDepts == null || targetDepts.isEmpty()) {
            return true; // no department restriction
        }
        // if 'ALL' present, matches everyone
        if (targetDepts.stream().anyMatch(d -> "ALL".equalsIgnoreCase(d))) {
            return true;
        }
        String userDept = user.getDepartmentId();
        String userProg = user.getProgramme();
        for (String t : targetDepts) {
            if (t == null) continue;
            if (t.equalsIgnoreCase(userDept) || t.equalsIgnoreCase(userProg)) {
                return true;
            }
        }
        return false;
    }
}
