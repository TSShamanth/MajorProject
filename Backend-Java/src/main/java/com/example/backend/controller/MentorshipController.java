package com.example.backend.controller;

import com.example.backend.models.MenteeConcern;
import com.example.backend.models.MentorMeeting;
import com.example.backend.models.User;
import com.example.backend.service.MentorshipService;
import com.google.firebase.auth.FirebaseToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/mentorship")
public class MentorshipController {

    private static final Logger logger = LoggerFactory.getLogger(MentorshipController.class);
    private final MentorshipService mentorshipService;

    public MentorshipController(MentorshipService mentorshipService) {
        this.mentorshipService = mentorshipService;
    }

    private String getCurrentUserUid() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) return null;
        Object principal = authentication.getPrincipal();
        if (principal instanceof FirebaseToken) {
            return ((FirebaseToken) principal).getUid();
        }
        return principal.toString();
    }

    private String getCurrentUserRole() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) return null;
        String role = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .findFirst()
                .orElse(null);
        if (role != null && role.startsWith("ROLE_")) {
            return role.substring(5).toLowerCase();
        }
        return role != null ? role.toLowerCase() : null;
    }

    @PostMapping("/assign")
    @SuppressWarnings("unchecked")
    public void assignMentor(@RequestParam String institutionId, @RequestBody Map<String, Object> body) throws ExecutionException, InterruptedException {
        logger.info("Assigning mentor for institution: {}", institutionId);
        String mentorId = (String) body.get("mentorId");
        List<String> studentIds = (List<String>) body.get("studentIds");
        mentorshipService.assignMentor(institutionId, mentorId, studentIds);
    }

    @GetMapping("/mentees")
    public List<User> getMentees(@RequestParam String institutionId) throws ExecutionException, InterruptedException {
        String mentorId = getCurrentUserUid();
        logger.info("Fetching mentees for mentor: {} in institution: {}", mentorId, institutionId);
        try {
            List<User> mentees = mentorshipService.getMentees(institutionId, mentorId);
            logger.info("Found {} mentees", mentees.size());
            return mentees;
        } catch (Exception e) {
            logger.error("Error fetching mentees", e);
            throw e;
        }
    }

    @GetMapping("/mentees/{menteeId}")
    public User getMenteeDetail(@RequestParam String institutionId, @PathVariable String menteeId) throws ExecutionException, InterruptedException {
        String mentorId = getCurrentUserUid();
        // Sync data before returning detail
        try {
            mentorshipService.syncMenteeAcademicData(institutionId, menteeId);
        } catch (Exception e) {
            logger.warn("Sync failed for mentee detail: {}", e.getMessage());
        }
        return mentorshipService.getMentee(institutionId, mentorId, menteeId);
    }

    @PostMapping("/mentees/{menteeId}/sync")
    public void syncMenteeData(@RequestParam String institutionId, @PathVariable String menteeId) throws ExecutionException, InterruptedException {
        mentorshipService.syncMenteeAcademicData(institutionId, menteeId);
    }

    @GetMapping("/mentor")
    public User getMentor(@RequestParam String institutionId) throws ExecutionException, InterruptedException {
        String studentId = getCurrentUserUid();
        return mentorshipService.getMentor(institutionId, studentId);
    }

    @PostMapping("/meetings")
    public void createMeeting(@RequestParam String institutionId, @RequestBody MentorMeeting meeting) throws ExecutionException, InterruptedException {
        String currentUserUid = getCurrentUserUid();
        String role = getCurrentUserRole();
        
        if ("faculty".equals(role)) {
            meeting.setMentorId(currentUserUid);
        } else if ("student".equals(role)) {
            meeting.setStudentId(currentUserUid);
            // Fetch and set mentorId
            try {
                User mentor = mentorshipService.getMentor(institutionId, currentUserUid);
                if (mentor != null && mentor.getUid() != null) {
                    meeting.setMentorId(mentor.getUid());
                }
            } catch (Exception e) {
                logger.warn("Could not fetch mentor for meeting: {}", e.getMessage());
            }
        }
        
        if (meeting.getStatus() == null) meeting.setStatus("Scheduled");
        mentorshipService.createMeeting(institutionId, meeting);
    }

    @GetMapping("/meetings")
    public List<MentorMeeting> getMeetings(@RequestParam String institutionId, @RequestParam(required = false) String studentId) throws ExecutionException, InterruptedException {
        String currentUserUid = getCurrentUserUid();
        String role = getCurrentUserRole();
        
        // If it's a student, they only see their meetings
        if ("student".equals(role)) {
            return mentorshipService.getMeetings(institutionId, currentUserUid, "student", null);
        } else if ("faculty".equals(role)) {
            // If faculty, filter by mentorId AND optionally studentId
            return mentorshipService.getMeetings(institutionId, currentUserUid, "faculty", studentId);
        }
        return List.of();
    }

    @PostMapping("/concerns")
    public void raiseConcern(@RequestParam String institutionId, @RequestBody MenteeConcern concern) throws ExecutionException, InterruptedException {
        String studentId = getCurrentUserUid();
        concern.setStudentId(studentId);
        
        // Fetch and set mentorId
        try {
            User mentor = mentorshipService.getMentor(institutionId, studentId);
            if (mentor != null && mentor.getUid() != null) {
                concern.setMentorId(mentor.getUid());
            }
        } catch (Exception e) {
            logger.warn("Could not fetch mentor for concern: {}", e.getMessage());
        }
        
        if (concern.getStatus() == null) concern.setStatus("Raised");
        if (concern.getCreatedAt() == null) concern.setCreatedAt(java.time.LocalDateTime.now().toString());

        mentorshipService.raiseConcern(institutionId, concern);
    }

    @GetMapping("/concerns")
    public List<MenteeConcern> getConcerns(@RequestParam String institutionId, @RequestParam(required = false) String studentId) throws ExecutionException, InterruptedException {
        String currentUserUid = getCurrentUserUid();
        String role = getCurrentUserRole();
        return mentorshipService.getConcerns(institutionId, currentUserUid, role, studentId);
    }

    @PatchMapping("/concerns/{concernId}/status")
    public void updateConcernStatus(@RequestParam String institutionId, @PathVariable String concernId, @RequestBody Map<String, String> body) throws ExecutionException, InterruptedException {
        String status = body.get("status");
        String remarks = body.get("mentorRemarks");
        mentorshipService.updateConcernStatus(institutionId, concernId, status, remarks);
    }

    @PatchMapping("/meetings/{meetingId}/status")
    public void updateMeetingStatus(@RequestParam String institutionId, @PathVariable String meetingId, @RequestBody Map<String, String> body) throws ExecutionException, InterruptedException {
        String status = body.get("status");
        mentorshipService.updateMeetingStatus(institutionId, meetingId, status);
    }

    @PostMapping("/meetings/{meetingId}/complete")
    @SuppressWarnings("unchecked")
    public void completeMeeting(@RequestParam String institutionId, @PathVariable String meetingId, @RequestBody Map<String, Object> body) throws ExecutionException, InterruptedException {
        String notes = (String) body.get("notes");
        String followUp = (String) body.get("followUpAction");
        List<String> attachments = (List<String>) body.get("attachments");
        mentorshipService.completeMeeting(institutionId, meetingId, notes, followUp, attachments);
    }

    @PatchMapping("/meetings/{meetingId}/action-items")
    public void updateActionItems(@RequestParam String institutionId, @PathVariable String meetingId, @RequestBody List<Map<String, Object>> actionItems) throws ExecutionException, InterruptedException {
        mentorshipService.updateActionItems(institutionId, meetingId, actionItems);
    }

    @GetMapping("/stats")
    public Map<String, Long> getMentorshipStats(@RequestParam String institutionId) throws ExecutionException, InterruptedException {
        return mentorshipService.getMentorshipStats(institutionId);
    }
}
