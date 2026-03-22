package com.example.backend.service;

import com.google.cloud.storage.Blob;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import org.springframework.ai.document.Document;
import org.springframework.ai.reader.tika.TikaDocumentReader;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AiIngestionService {

    private final VectorStore vectorStore;
    private final Storage storage;

    public AiIngestionService(VectorStore vectorStore) {
        this.vectorStore = vectorStore;
        // Initialize standard Google Storage client
        this.storage = StorageOptions.getDefaultInstance().getService();
    }

    public void ingestPdf(Resource pdfResource) {
        // Process a local/uploaded resource
        TikaDocumentReader tikaReader = new TikaDocumentReader(pdfResource);
        List<Document> documents = tikaReader.get();

        TokenTextSplitter splitter = new TokenTextSplitter();
        List<Document> splitDocuments = splitter.apply(documents);

        vectorStore.accept(splitDocuments);
    }

    public void ingestFromStorage(String bucketName, String blobPath) {
        // 1. Download the file from Firebase Storage
        Blob blob = storage.get(bucketName, blobPath);
        if (blob == null) {
            throw new RuntimeException("File not found in Firebase Storage: " + blobPath);
        }

        byte[] content = blob.getContent();
        ByteArrayResource resource = new ByteArrayResource(content);

        // 2. Reuse existing ingestion logic
        this.ingestPdf(resource);
    }
}
