package com.example.backend.service;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.QuestionAnswerAdvisor;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;

@Service
public class AiChatService {

    private final ChatClient chatClient;

    public AiChatService(ChatClient.Builder builder, VectorStore vectorStore) {
        String systemPrompt = 
            "You are a helpful, professional, and intelligent assistant for the institution.\n\n" +
            "CORE DIRECTIVE: You have the power to take REAL ACTIONS. Do NOT just tell the user you are doing something; you MUST execute the corresponding tool to make it happen in the database.\n\n" +
            "RULES:\n" +
            "1. If a student mentions an ISSUE, COMPLAINT, or PROBLEM, you MUST call 'createMenteeConcern'.\n" +
            "2. If an admin/faculty wants to post an announcement, you MUST call 'createAnnouncement'.\n" +
            "3. If an admin/faculty wants to schedule an event, you MUST call 'createEvent'.\n" +
            "4. MANDATORY: If a tool returns a 'redirection_link', you MUST include that Markdown link EXACTLY as provided at the VERY END of your response. Example: 'I have logged your concern. [View My Concerns](/RVU/student/my-mentors)'.\n" +
            "5. Do NOT hallucinate success. Only say something is logged if the tool was actually called.\n" +
            "6. Keep responses professional and concise.";

        this.chatClient = builder
                .defaultSystem(systemPrompt)
                .defaultAdvisors(new QuestionAnswerAdvisor(vectorStore))
                .defaultTools("createMenteeConcern", "createAnnouncement", "createEvent")
                .build();
    }

    public String generateResponse(String message, String institutionId, String studentId) {
        try {
            return chatClient.prompt()
                    .user(u -> u.text("Current Context:\n" +
                                     "- institutionId: {instId}\n" +
                                     "- studentId/userId: {studId}\n\n" +
                                     "User Message: {msg}")
                                .param("instId", institutionId)
                                .param("studId", studentId)
                                .param("msg", message))
                    .call()
                    .content();
        } catch (Exception e) {
            // Log the error internally but do not expose it to the client
            e.printStackTrace();
            return "I'm having trouble connecting right now, please try again later.";
        }
    }
}
