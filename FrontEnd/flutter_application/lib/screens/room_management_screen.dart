import 'package:flutter/material.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  RoomManagementScreenState createState() => RoomManagementScreenState();
}

class RoomManagementScreenState extends State<RoomManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Room> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        // Handle error
        return;
      }
      final rooms = await _apiService.getRooms(institutionId);
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateAndRefresh(BuildContext context) async {
    final router = GoRouter.of(context);
    final institutionId = await SessionManager.getInstitutionId();
    if(institutionId == null) return;
    final result = await router.push('/$institutionId/admin/room-editor');
    if (result == true) {
      _fetchRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _rooms.length,
              itemBuilder: (context, index) {
                final room = _rooms[index];
                return ListTile(
                  title: Text(room.name),
                  subtitle: Text('Capacity: ${room.capacity}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final router = GoRouter.of(context);
                          final institutionId = await SessionManager.getInstitutionId();
                          if(institutionId == null) return;
                          final result = await router.push('/$institutionId/admin/room-editor/${room.id}');
                          if (result == true) {
                            _fetchRooms();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final institutionId = await SessionManager.getInstitutionId();
                          if(institutionId == null) return;
                          await _apiService.deleteRoom(institutionId, room.id);
                          _fetchRooms();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndRefresh(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
