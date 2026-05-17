package com.example.backend.service;

import com.example.backend.models.*;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class AiAdminService {

    private final ChatClient chatClient;
    private final ClockService clockService;

    public AiAdminService(ChatClient.Builder builder, ClockService clockService) {
        this.chatClient = builder
                .defaultSystem("You are an Expert IT Auditor and Systems Engineer. Your goal is to identify anomalies in system access and provide human-readable explanations for technical errors.\n\n" +
                        "CORE TASKS:\n" +
                        "1. Access Anomaly Detection: Analyze login/clock-in logs for suspicious behavior.\n" +
                        "2. Bug Analyzer: Take a technical stack trace and explain it in plain English for a non-technical administrator.")
                .build();
        this.clockService = clockService;
    }

    public String analyzeBug(String stackTrace) {
        return chatClient.prompt()
                .user(u -> u.text("Analyze this technical error and provide a simple, human-readable summary. Explain potential causes and suggests next steps for a developer.\n\nError:\n{trace}")
                        .param("trace", stackTrace))
                .call()
                .content();
    }

    public String detectAccessAnomalies(String institutionId) throws ExecutionException, InterruptedException {
        // Fetch last 50 attendance logs as a proxy for access logs
        List<AttendanceLog> logs = clockService.getRecentLogs(institutionId, 50);

        String logContext = logs.stream()
                .map(l -> "- Faculty: " + l.getFacultyId() + " | Clock-In: " + l.getClockInTime() + " | Status: " + l.getLocationStatus() + " | Location: " + l.getLocationDetail())
                .collect(Collectors.joining("\n"));

        return chatClient.prompt()
                .user(u -> u.text("Analyze these faculty attendance/access logs for any suspicious activity (e.g. impossible travel, weird hours, location anomalies).\n\nLogs:\n{logs}")
                        .param("logs", logContext))
                .call()
                .content();
    }
}
