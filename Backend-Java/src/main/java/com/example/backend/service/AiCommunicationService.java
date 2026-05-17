package com.example.backend.service;

import com.example.backend.models.*;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class AiCommunicationService {

    private final ChatClient chatClient;
    private final AnnouncementService announcementService;
    private final EventService eventService;
    private final UserService userService;

    public AiCommunicationService(ChatClient.Builder builder,
                                   AnnouncementService announcementService,
                                   EventService eventService,
                                   UserService userService) {
        this.chatClient = builder
                .defaultSystem("You are a Campus Communication Assistant. Your job is to help students stay informed by summarizing long announcements and recommending events based on their profile.")
                .build();
        this.announcementService = announcementService;
        this.eventService = eventService;
        this.userService = userService;
    }

    public String summarizeAnnouncement(String institutionId, String announcementId) throws ExecutionException, InterruptedException {
        Announcement announcement = announcementService.getAnnouncementById(institutionId, announcementId);
        if (announcement == null) return "Announcement not found.";

        String content = (announcement.getContent() != null && !announcement.getContent().isEmpty()) 
                         ? announcement.getContent() 
                         : announcement.getDescription();

        return chatClient.prompt()
                .user(u -> u.text("Summarize this announcement in exactly 2 concise sentences. Start with 'Summary:'.\n\nTitle: {title}\nContent: {content}")
                        .param("title", announcement.getTitle())
                        .param("content", content))
                .call()
                .content();
    }

    public String recommendEvents(String institutionId, String studentId) throws ExecutionException, InterruptedException {
        User student = userService.getUserById(institutionId, studentId);
        if (student == null) return "Student not found.";

        List<Event> events = eventService.getEventsForAudience(institutionId, student.getRole(), student.getDepartmentId(), student.getProgramme());

        String eventContext = events.stream()
                .limit(10)
                .map(e -> "- " + e.getTitle() + " (" + e.getCategory() + "): " + e.getDescription())
                .collect(Collectors.joining("\n"));

        return chatClient.prompt()
                .user(u -> u.text("Based on the student's profile, recommend the top 2-3 most relevant upcoming events. Explain why they are relevant.\n\nStudent Profile: {profile}\n\nUpcoming Events:\n{events}")
                        .param("profile", student.getProgramme() + ", Sem " + student.getSem())
                        .param("events", eventContext))
                .call()
                .content();
    }

    public String getEventRecommendation(String institutionId, String studentId, String eventId) throws ExecutionException, InterruptedException {
        User student = userService.getUserById(institutionId, studentId);
        Event event = eventService.getEventById(institutionId, eventId);
        
        if (student == null || event == null) return "Data not found.";

        return chatClient.prompt()
                .user(u -> u.text("Explain why this specific event is relevant to this student in 1-2 personalized sentences. Focus on their academic program and the event category.\n\nStudent Profile: {profile}\nEvent: {title} ({category})\nDescription: {description}")
                        .param("profile", student.getProgramme() + ", Sem " + student.getSem())
                        .param("title", event.getTitle())
                        .param("category", event.getCategory())
                        .param("description", event.getDescription()))
                .call()
                .content();
    }
}
