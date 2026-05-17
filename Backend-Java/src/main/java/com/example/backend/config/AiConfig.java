package com.example.backend.config;

import com.example.backend.service.ManualFirestoreVectorStore;
import com.google.cloud.firestore.Firestore;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AiConfig {

    @Value("${spring.ai.vectorstore.firestore.collection-name:ai_knowledge_base}")
    private String collectionName;

    @Bean
    public VectorStore vectorStore(Firestore firestore, EmbeddingModel embeddingModel) {
        // Use our custom, production-grade Firestore implementation
        return new ManualFirestoreVectorStore(firestore, embeddingModel, collectionName);
    }
}
