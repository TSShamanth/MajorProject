package com.example.backend.service;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.QuestionAnswerAdvisor;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;

@Service
public class AiChatService {

    private final ChatClient chatClient;

    public AiChatService(ChatClient.Builder builder, VectorStore vectorStore) {
        // The QuestionAnswerAdvisor interceptor handles the RAG flow:
        // 1. User asks question.
        // 2. Advisor searches VectorStore for relevant chunks.
        // 3. Advisor augments the prompt with these chunks.
        this.chatClient = builder
                .defaultAdvisors(new QuestionAnswerAdvisor(vectorStore))
                .build();
    }

    public String generateResponse(String message) {
        return chatClient.prompt()
                .user(message)
                .call()
                .content();
    }
}
