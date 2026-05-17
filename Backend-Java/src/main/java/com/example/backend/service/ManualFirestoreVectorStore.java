package com.example.backend.service;

import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.VectorQuery.DistanceMeasure;
import org.springframework.ai.document.Document;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.ai.vectorstore.filter.Filter;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Custom Firestore Vector Store implementation.
 * Handles float[] to double[] conversion for Firestore compatibility.
 */
public class ManualFirestoreVectorStore implements VectorStore {

    private final Firestore firestore;
    private final EmbeddingModel embeddingModel;
    private final String collectionName;

    public ManualFirestoreVectorStore(Firestore firestore, EmbeddingModel embeddingModel, String collectionName) {
        this.firestore = firestore;
        this.embeddingModel = embeddingModel;
        this.collectionName = collectionName;
    }

    private double[] toDoubleArray(float[] floats) {
        if (floats == null) return null;
        double[] doubles = new double[floats.length];
        for (int i = 0; i < floats.length; i++) {
            doubles[i] = floats[i];
        }
        return doubles;
    }

    @Override
    public void add(List<Document> documents) {
        CollectionReference collection = firestore.collection(collectionName);
        for (Document doc : documents) {
            float[] embedding = embeddingModel.embed(doc);
            
            Map<String, Object> data = new HashMap<>();
            data.put("text", doc.getText());
            data.put("metadata", doc.getMetadata());
            data.put("embedding", FieldValue.vector(toDoubleArray(embedding))); 

            collection.document(doc.getId()).set(data);
        }
    }

    @Override
    public void delete(List<String> idList) {
        for (String id : idList) {
            firestore.collection(collectionName).document(id).delete();
        }
    }

    @Override
    public void delete(Filter.Expression filterExpression) {
        // Not implemented
    }

    @Override
    public List<Document> similaritySearch(SearchRequest request) {
        float[] queryEmbedding = embeddingModel.embed(request.getQuery());

        try {
            // resolve the future with .get() then call .getDocuments()
            return firestore.collection(collectionName)
                    .findNearest("embedding", toDoubleArray(queryEmbedding), request.getTopK(), DistanceMeasure.EUCLIDEAN)
                    .get()
                    .get()
                    .getDocuments()
                    .stream()
                    .map(snap -> {
                        String text = snap.getString("text");
                        @SuppressWarnings("unchecked")
                        Map<String, Object> metadata = (Map<String, Object>) snap.get("metadata");
                        return new Document(snap.getId(), text, metadata);
                    })
                    .collect(Collectors.toList());
        } catch (Exception e) {
            throw new RuntimeException("Vector search failed. Ensure your Firestore Vector Index is created!", e);
        }
    }

    @Override
    public void accept(List<Document> documents) {
        this.add(documents);
    }
}
