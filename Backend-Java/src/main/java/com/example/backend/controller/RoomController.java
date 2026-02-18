package com.example.backend.controller;

import com.example.backend.models.Room;
import com.example.backend.service.RoomService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/institutions/{institutionId}/rooms")
public class RoomController {

    private final RoomService roomService;

    public RoomController(RoomService roomService) {
        this.roomService = roomService;
    }

    @PostMapping
    public ResponseEntity<Room> createRoom(@PathVariable String institutionId, @RequestBody Room room) {
        try {
            Room createdRoom = roomService.createRoom(institutionId, room);
            return ResponseEntity.ok(createdRoom);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Room>> getRooms(@PathVariable String institutionId) {
        try {
            List<Room> rooms = roomService.getRooms(institutionId);
            return ResponseEntity.ok(rooms);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/{roomId}")
    public ResponseEntity<Room> getRoomById(@PathVariable String institutionId, @PathVariable String roomId) {
        try {
            Room room = roomService.getRoomById(institutionId, roomId);
            if (room != null) {
                return ResponseEntity.ok(room);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @PutMapping("/{roomId}")
    public ResponseEntity<Room> updateRoom(@PathVariable String institutionId, @PathVariable String roomId, @RequestBody Room room) {
        try {
            Room updatedRoom = roomService.updateRoom(institutionId, roomId, room);
            return ResponseEntity.ok(updatedRoom);
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }

    @DeleteMapping("/{roomId}")
    public ResponseEntity<Void> deleteRoom(@PathVariable String institutionId, @PathVariable String roomId) {
        try {
            roomService.deleteRoom(institutionId, roomId);
            return ResponseEntity.noContent().build();
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }
}
