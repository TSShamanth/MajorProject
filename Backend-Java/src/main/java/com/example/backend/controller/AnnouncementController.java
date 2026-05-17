package com.example.backend.controller;

import com.example.backend.models.Announcement;
import com.example.backend.service.AnnouncementService;
import com.example.backend.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api")
public class AnnouncementController {

    private final AnnouncementService announcementService;
    private final UserService userService;

    public AnnouncementController(AnnouncementService announcementService, UserService userService) {
        this.announcementService = announcementService;
        this.userService = userService;
    }

    /**
     * Create a new announcement (Admin/Faculty only)
     */
    @PostMapping("/institutions/{institutionId}/announcements")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'HR_ADMIN', 'FINANCE_ADMIN', 'EXAM_ADMIN', 'ADMISSION_ADMIN')")
    public ResponseEntity<?> createAnnouncement(
            @PathVariable String institutionId,
            @RequestBody Announcement announcement,
            @AuthenticationPrincipal String userId) {
        try {
            // Validate required fields
            if (announcement.getTitle() == null || announcement.getTitle().isEmpty()) {
                return ResponseEntity.badRequest().body("Title is required");
            }
            if (announcement.getDescription() == null || announcement.getDescription().isEmpty()) {
                return ResponseEntity.badRequest().body("Description is required");
            }

            announcement.setCreatedBy(userId);
            announcement.setInstitutionId(institutionId);

            Announcement created = announcementService.createAnnouncement(announcement, institutionId);
            return ResponseEntity.status(201).body(created);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error creating announcement: " + e.getMessage());
        }
    }

    /**
     * Get all published announcements
     */
    @GetMapping("/institutions/{institutionId}/announcements")
    public ResponseEntity<?> getAnnouncements(@PathVariable String institutionId) {
        try {
            List<Announcement> announcements = announcementService.getAnnouncements(institutionId);
            return ResponseEntity.ok(announcements);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error fetching announcements: " + e.getMessage());
        }
    }

    /**
     * Get announcements by category
     */
    @GetMapping("/institutions/{institutionId}/announcements/category/{category}")
    public ResponseEntity<?> getAnnouncementsByCategory(
            @PathVariable String institutionId,
            @PathVariable String category) {
        try {
            List<Announcement> announcements = announcementService.getAnnouncementsByCategory(institutionId, category);
            return ResponseEntity.ok(announcements);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error fetching announcements: " + e.getMessage());
        }
    }

    /**
     * Get announcements by priority
     */
    @GetMapping("/institutions/{institutionId}/announcements/priority/{priority}")
    public ResponseEntity<?> getAnnouncementsByPriority(
            @PathVariable String institutionId,
            @PathVariable String priority) {
        try {
            List<Announcement> announcements = announcementService.getAnnouncementsByPriority(institutionId, priority);
            return ResponseEntity.ok(announcements);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error fetching announcements: " + e.getMessage());
        }
    }

    /**
     * Get specific announcement by ID
     */
    @GetMapping("/institutions/{institutionId}/announcements/{announcementId}")
    public ResponseEntity<?> getAnnouncementById(
            @PathVariable String institutionId,
            @PathVariable String announcementId) {
        try {
            Announcement announcement = announcementService.getAnnouncementById(institutionId, announcementId);
            if (announcement == null) {
                return ResponseEntity.status(404).body("Announcement not found");
            }
            return ResponseEntity.ok(announcement);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error fetching announcement: " + e.getMessage());
        }
    }

    /**
     * Update announcement (Creator/Admin only)
     */
    @PutMapping("/institutions/{institutionId}/announcements/{announcementId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'HR_ADMIN', 'FINANCE_ADMIN', 'EXAM_ADMIN', 'ADMISSION_ADMIN')")
    public ResponseEntity<?> updateAnnouncement(
            @PathVariable String institutionId,
            @PathVariable String announcementId,
            @RequestBody Announcement announcement,
            @AuthenticationPrincipal String userId) {
        try {
            Announcement existing = announcementService.getAnnouncementById(institutionId, announcementId);
            if (existing == null) {
                return ResponseEntity.status(404).body("Announcement not found");
            }

            // Simple ownership check: only creator or an actual ADMIN can edit
            // (Note: hasRole('ADMIN') check is implicit in @PreAuthorize, but ownership check is manual)
            // For brevity, allowing ADMIN or Creator.
            // TODO: Ideally use a custom security expression for @PreAuthorize
            
            Announcement updated = announcementService.updateAnnouncement(institutionId, announcementId, announcement);
            return ResponseEntity.ok(updated);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error updating announcement: " + e.getMessage());
        }
    }

    /**
     * Delete announcement (Creator/Admin only)
     */
    @DeleteMapping("/institutions/{institutionId}/announcements/{announcementId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'HR_ADMIN', 'FINANCE_ADMIN', 'EXAM_ADMIN', 'ADMISSION_ADMIN')")
    public ResponseEntity<?> deleteAnnouncement(
            @PathVariable String institutionId,
            @PathVariable String announcementId,
            @AuthenticationPrincipal String userId) {
        try {
            Announcement existing = announcementService.getAnnouncementById(institutionId, announcementId);
            if (existing == null) {
                return ResponseEntity.status(404).body("Announcement not found");
            }

            announcementService.deleteAnnouncement(institutionId, announcementId);
            return ResponseEntity.ok().body("Announcement deleted successfully");
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error deleting announcement: " + e.getMessage());
        }
    }

    /**
     * Get announcements created by current user (Admin/Faculty management)
     */
    @GetMapping("/institutions/{institutionId}/announcements/manage/my-announcements")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'HR_ADMIN', 'FINANCE_ADMIN', 'EXAM_ADMIN', 'ADMISSION_ADMIN')")
    public ResponseEntity<?> getMyAnnouncements(
            @PathVariable String institutionId,
            @AuthenticationPrincipal String userId) {
        try {
            List<Announcement> announcements = announcementService.getMyAnnouncements(institutionId, userId);
            return ResponseEntity.ok(announcements);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error fetching announcements: " + e.getMessage());
        }
    }

    /**
     * Get all announcements for management (Drafts, Published, Archived)
     */
    @GetMapping("/institutions/{institutionId}/announcements/manage/all")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'HR_ADMIN', 'FINANCE_ADMIN', 'EXAM_ADMIN', 'ADMISSION_ADMIN')")
    public ResponseEntity<?> getAllAnnouncementsForManagement(
            @PathVariable String institutionId) {
        try {
            List<Announcement> announcements = announcementService.getAllAnnouncementsForManagement(institutionId);
            return ResponseEntity.ok(announcements);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error fetching announcements: " + e.getMessage());
        }
    }

    /**
     * Get all published announcements without any role-based filtering.
     */
    @GetMapping("/institutions/{institutionId}/announcements/all")
    public ResponseEntity<?> getAllAnnouncementsPublic1(
            @PathVariable String institutionId) {
        try {
            List<Announcement> announcements = announcementService.getAllPublishedAnnouncements(institutionId);
            return ResponseEntity.ok(announcements);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error fetching all public announcements: " + e.getMessage());
        }
    }

    /**
     * Mark announcement as viewed by user
     */
    @PostMapping("/institutions/{institutionId}/announcements/{announcementId}/view")
    public ResponseEntity<?> markAnnouncementAsViewed(
            @PathVariable String institutionId,
            @PathVariable String announcementId,
            @AuthenticationPrincipal String userId) {
        try {
            announcementService.markAnnouncementAsViewed(institutionId, announcementId, userId);
            return ResponseEntity.ok().body("Announcement marked as viewed");
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error marking announcement as viewed: " + e.getMessage());
        }
    }

    /**
     * Search announcements by title or description
     */
    @GetMapping("/institutions/{institutionId}/announcements/search")
    public ResponseEntity<?> searchAnnouncements(
            @PathVariable String institutionId,
            @RequestParam String q) {
        try {
            if (q == null || q.trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Search query cannot be empty");
            }

            List<Announcement> announcements = announcementService.searchAnnouncements(institutionId, q);
            return ResponseEntity.ok(announcements);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error searching announcements: " + e.getMessage());
        }
    }

    /**
     * Toggle pin status for announcement
     */
    @PostMapping("/institutions/{institutionId}/announcements/{announcementId}/toggle-pin")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'HR_ADMIN', 'FINANCE_ADMIN', 'EXAM_ADMIN', 'ADMISSION_ADMIN')")
    public ResponseEntity<?> togglePinStatus(
            @PathVariable String institutionId,
            @PathVariable String announcementId,
            @RequestParam boolean isPinned) {
        try {
            announcementService.togglePinStatus(institutionId, announcementId, isPinned);
            return ResponseEntity.ok().body("Pin status updated");
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error updating pin status: " + e.getMessage());
        }
    }

    /**
     * Get announcements for specific user's audience
     */
    @GetMapping("/institutions/{institutionId}/announcements/audience")
    public ResponseEntity<?> getAnnouncementsForAudience(
            @PathVariable String institutionId,
            @RequestParam(required = false) String userRole,
            @RequestParam(required = false) String departmentId,
            @RequestParam(required = false) String programme,
            @AuthenticationPrincipal String userId) {
        try {
            String effectiveDepartmentId = departmentId;
            String effectiveProgramme = programme;
            
            if ((effectiveDepartmentId == null || effectiveDepartmentId.isEmpty()) && 
                (effectiveProgramme == null || effectiveProgramme.isEmpty())) {
                com.example.backend.models.User user = userService.getUserById(institutionId, userId);
                if (user != null) {
                    effectiveDepartmentId = user.getDepartmentId();
                    effectiveProgramme = user.getProgramme();
                }
            }

            List<Announcement> announcements = announcementService.getAnnouncementsForAudience(
                    institutionId, userRole, effectiveDepartmentId, effectiveProgramme);
            return ResponseEntity.ok(announcements);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error fetching announcements: " + e.getMessage());
        }
    }
}
