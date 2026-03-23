package com.example.backend.service;

import com.example.backend.models.*;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class AiFeedbackService {

    private final ChatClient chatClient;
    private final FormService formService;

    public AiFeedbackService(ChatClient.Builder builder, FormService formService) {
        this.chatClient = builder
                .defaultSystem("You are an Expert Feedback Analyst and UX Designer. Your goal is to analyze form responses for sentiment and insights, and to design smart forms based on user requirements.\n\n" +
                        "CORE TASKS:\n" +
                        "1. Sentiment Analysis: Identify the overall mood (Positive/Negative/Neutral).\n" +
                        "2. Actionable Insights: Provide 3-5 specific recommendations based on feedback.\n" +
                        "3. Smart Form Builder: Generate a list of form fields in JSON format based on a topic.")
                .build();
        this.formService = formService;
    }

    public String analyzeFormResponses(String institutionId, String formId) throws ExecutionException, InterruptedException {
        CustomForm form = formService.getFormById(institutionId, formId);
        List<FormResponse> responses = formService.getResponsesForForm(institutionId, formId);

        if (form == null || responses.isEmpty()) {
            return "No data available for analysis. At least one response is required.";
        }

        StringBuilder data = new StringBuilder();
        data.append("Form Title: ").append(form.getTitle()).append("\n")
            .append("Description: ").append(form.getDescription()).append("\n\n");

        data.append("Recent Responses (up to 20):\n");
        for (int i = 0; i < Math.min(responses.size(), 20); i++) {
            data.append("- Response ").append(i + 1).append(": ").append(responses.get(i).getAnswers()).append("\n");
        }

        return chatClient.prompt()
                .user(u -> u.text("Analyze the following form responses. Provide:\n" +
                                 "1.  **Overall Sentiment**: A single score (e.g., 85% Positive) with a brief justification.\n" +
                                 "2.  **Key Themes**: Identify 2-3 recurring topics or keywords from the open-ended answers.\n" +
                                 "3.  **Actionable Insights**: Suggest 3 specific, concrete actions the administrator can take based on the feedback.\n" +
                                 "Use Markdown for clear formatting.\n\n" +
                                 "Data:\n{data}")
                        .param("data", data.toString()))
                .call()
                .content();
    }

    public String proposeFormFields(String topic) {
        return chatClient.prompt()
                .user(u -> u.text("Propose a list of relevant fields for a form about the topic: '{topic}'.\n" +
                                 "Focus ONLY on the question fields, not metadata like 'title' or 'deadline'.\n" +
                                 "Return the response in JSON format as a list of objects with fields: " +
                                 "'label' (String), " +
                                 "'type' (String, one of: TEXT, MULTIPLE_CHOICE, CHECKBOXES, DROPDOWN, DATE), " +
                                 "'options' (List of Strings, for choice-based types), and " +
                                 "'required' (Boolean). " +
                                 "Only return the raw JSON array. No markdown blocks.")
                        .param("topic", topic))
                .call()
                .content();
    }
}
