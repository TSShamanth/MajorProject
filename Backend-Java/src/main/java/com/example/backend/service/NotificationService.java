package com.example.backend.service;

import com.example.backend.models.Notification;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class NotificationService {

    private final Firestore firestore;
    private static final Logger logger = LoggerFactory.getLogger(NotificationService.class);

    public NotificationService(Firestore firestore) {
        this.firestore = firestore;
    }

    private CollectionReference getUserNotificationsCollection(String institutionId, String userId) {
        return firestore.collection("Institutions")
                .document(institutionId)
                .collection("users")
                .document(userId)
                .collection("notifications");
    }

    public Notification createNotification(String institutionId, String userId, Notification notification)
            throws ExecutionException, InterruptedException {
        String id = UUID.randomUUID().toString();
        notification.setId(id);
        notification.setUserId(userId);
        notification.setCreatedAt(System.currentTimeMillis());
        notification.setRead(false);

        getUserNotificationsCollection(institutionId, userId)
                .document(id)
                .set(notification)
                .get();
        logger.info("Notification created for user {}: {}", userId, notification.getTitle());
        return notification;
    }

    public List<Notification> getNotifications(String institutionId, String userId)
            throws ExecutionException, InterruptedException {
        List<Notification> notifications = new ArrayList<>();
        Query query = getUserNotificationsCollection(institutionId, userId)
                .orderBy("createdAt", Query.Direction.DESCENDING);
        QuerySnapshot snapshot = query.get().get();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            if (doc.exists()) {
                Notification n = doc.toObject(Notification.class);
                notifications.add(n);
            }
        }
        return notifications;
    }

    public void markAsRead(String institutionId, String userId, String notificationId)
            throws ExecutionException, InterruptedException {
        getUserNotificationsCollection(institutionId, userId)
                .document(notificationId)
                .update("read", true)
                .get();
    }
}
