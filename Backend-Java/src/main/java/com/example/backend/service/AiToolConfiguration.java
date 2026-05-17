package com.example.backend.service;

import com.example.backend.models.MenteeConcern;
import com.example.backend.models.Announcement;
import com.example.backend.models.Event;
import com.example.backend.models.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Description;

import java.util.Map;
import java.util.function.Function;

@Configuration
public class AiToolConfiguration {

    private static final Logger logger = LoggerFactory.getLogger(AiToolConfiguration.class);
    private final MentorshipService mentorshipService;
    private final AnnouncementService announcementService;
    private final EventService eventService;

    public AiToolConfiguration(MentorshipService mentorshipService, AnnouncementService announcementService, EventService eventService) {
        this.mentorshipService = mentorshipService;
        this.announcementService = announcementService;
        this.eventService = eventService;
    }

    @Bean
    @Description("Creates a new Mentee Concern/Complaint (e.g. regarding Hostel, Academics, Personal matters) for the current student. Use this whenever the user complains about an issue.")
    public Function<CreateConcernRequest, Map<String, String>> createMenteeConcern() {
        return request -> {
            logger.info("AI TOOL: createMenteeConcern called with institution: {}, student: {}", request.getInstitutionId(), request.getStudentId());
            if (request.getInstitutionId() == null || request.getStudentId() == null) {
                return Map.of("error", "Missing institutionId or studentId in request.");
            }

            try {
                MenteeConcern concern = new MenteeConcern();
                concern.setStudentId(request.getStudentId());
                concern.setConcernType(request.getConcernType());
                concern.setDescription(request.getDescription());
                concern.setPriority(request.getPriority() != null ? request.getPriority() : "Medium");
                concern.setStatus("Raised");
                concern.setCreatedAt(java.time.LocalDateTime.now().toString());
                concern.setAttachments(new java.util.ArrayList<>());

                // Fetch the assigned mentor and attach their ID to the concern
                User mentor = mentorshipService.getMentor(request.getInstitutionId(), request.getStudentId());
                if (mentor != null && mentor.getUid() != null) {
                    concern.setMentorId(mentor.getUid());
                }
                
                mentorshipService.raiseConcern(request.getInstitutionId(), concern);
                logger.info("AI TOOL: Mentee concern RAISED in database!");
                
                return Map.of(
                    "status", "SUCCESS",
                    "redirection_link", "[View My Concerns](/" + request.getInstitutionId() + "/student/my-mentors)"
                );
            } catch (Exception e) {
                logger.error("Error creating AI mentee concern", e);
                return Map.of("error", "Failed to create concern due to system error.");
            }
        };
    }

    @Bean
    @Description("Creates a new Announcement. Use this whenever an admin or faculty wants to publish a general announcement to the institution.")
    public Function<CreateAnnouncementRequest, Map<String, String>> createAnnouncement() {
        return request -> {
            if (request.getInstitutionId() == null || request.getUserId() == null) {
                return Map.of("error", "Missing context.");
            }

            try {
                Announcement announcement = new Announcement();
                announcement.setTitle(request.getTitle());
                announcement.setDescription(request.getDescription());
                announcement.setContent(request.getContent());
                announcement.setPriority(request.getPriority() != null ? request.getPriority() : "MEDIUM");
                announcement.setCategory(request.getCategory() != null ? request.getCategory() : "OTHER");
                announcement.setTargetAudience(request.getTargetAudience());
                announcement.setCreatedBy(request.getUserId());
                announcement.setStatus("PUBLISHED");
                
                announcementService.createAnnouncement(announcement, request.getInstitutionId());
                return Map.of("message", "Successfully created and published the announcement.");
            } catch (Exception e) {
                logger.error("Error creating AI announcement", e);
                return Map.of("error", "System error.");
            }
        };
    }

    @Bean
    @Description("Creates a new Event. Use this whenever an admin or faculty wants to schedule or publish an event for the institution.")
    public Function<CreateEventRequest, Map<String, String>> createEvent() {
        return request -> {
            if (request.getInstitutionId() == null || request.getUserId() == null) {
                return Map.of("error", "Missing context.");
            }

            try {
                Event event = new Event();
                event.setTitle(request.getTitle());
                event.setDescription(request.getDescription());
                event.setCategory(request.getCategory() != null ? request.getCategory() : "WORKSHOP");
                event.setVenue(request.getVenue());
                event.setOnlineLink(request.getOnlineLink());
                event.setTargetAudience(request.getTargetAudience());
                event.setOrganizerId(request.getUserId());
                event.setStatus("PUBLISHED");
                
                eventService.createEvent(request.getInstitutionId(), event);
                return Map.of("message", "Successfully created and published the event.");
            } catch (Exception e) {
                logger.error("Error creating AI event", e);
                return Map.of("error", "System error.");
            }
        };
    }
}
