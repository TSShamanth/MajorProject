import 'package:flutter/material.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';

class RoomEditorScreen extends StatefulWidget {
  final String? roomId;

  const RoomEditorScreen({super.key, this.roomId});

  @override
  RoomEditorScreenState createState() => RoomEditorScreenState();
}

class RoomEditorScreenState extends State<RoomEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Room? _editingRoom;

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      _fetchRoomDetails();
    }
  }

  Future<void> _fetchRoomDetails() async {
    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) return;
      final room = await _apiService.getRoomById(institutionId, widget.roomId!);
      if (mounted) {
        setState(() {
          _editingRoom = room;
          _nameController.text = room.name;
          _capacityController.text = room.capacity.toString();
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final institutionId = await SessionManager.getInstitutionId();
        if (institutionId == null) return;

        final room = Room(
          id: _editingRoom?.id ?? '',
          name: _nameController.text,
          capacity: int.parse(_capacityController.text),
          institutionId: institutionId,
          departmentId: _editingRoom?.departmentId,
        );

        if (_editingRoom == null) {
          await _apiService.createRoom(institutionId, room);
        } else {
          await _apiService.updateRoom(institutionId, _editingRoom!.id, room);
        }
        
        if (mounted) {
          context.pop(true);
        }
      } catch (e) {
        // Handle error
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingRoom == null ? 'Create Room' : 'Edit Room'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Room Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a room name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null) {
                          return 'Please enter a valid capacity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveRoom,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
