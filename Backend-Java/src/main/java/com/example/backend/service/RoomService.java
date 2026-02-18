package com.example.backend.service;

import com.example.backend.models.Room;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class RoomService {

    private final Firestore firestore;

    public RoomService(Firestore firestore) {
        this.firestore = firestore;
    }

    public List<Room> getRooms(String institutionId) throws ExecutionException, InterruptedException {
        List<Room> roomList = new ArrayList<>();
        ApiFuture<QuerySnapshot> future = firestore.collection("Institutions").document(institutionId).collection("rooms").get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
            roomList.add(document.toObject(Room.class));
        }
        return roomList;
    }

    public Room getRoomById(String institutionId, String roomId) throws ExecutionException, InterruptedException {
        DocumentReference docRef = firestore.collection("Institutions").document(institutionId).collection("rooms").document(roomId);
        ApiFuture<com.google.cloud.firestore.DocumentSnapshot> future = docRef.get();
        com.google.cloud.firestore.DocumentSnapshot document = future.get();
        if (document.exists()) {
            return document.toObject(Room.class);
        } else {
            return null;
        }
    }

    public Room createRoom(String institutionId, Room room) throws ExecutionException, InterruptedException {
        String roomId = UUID.randomUUID().toString();
        room.setId(roomId);
        room.setInstitutionId(institutionId);
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("rooms").document(roomId).set(room);
        future.get();
        return room;
    }

    public Room updateRoom(String institutionId, String roomId, Room room) throws ExecutionException, InterruptedException {
        room.setId(roomId);
        room.setInstitutionId(institutionId);
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("rooms").document(roomId).set(room);
        future.get();
        return room;
    }

    public void deleteRoom(String institutionId, String roomId) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> future = firestore.collection("Institutions").document(institutionId).collection("rooms").document(roomId).delete();
        future.get();
    }
}
