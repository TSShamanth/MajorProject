import 'package:flutter/material.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Room> _rooms = [];
  bool _isLoading = true;
  String? _institutionId;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      _fetchRooms();
    }
  }

  Future<void> _fetchRooms() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      final rooms = await _apiService.getRooms(_institutionId!);
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAndRefresh(BuildContext context, {String? roomId}) async {
    final route = roomId != null 
      ? '/$_institutionId/admin/room-editor/$roomId' 
      : '/$_institutionId/admin/room-editor';
    
    final result = await context.push(route);
    if (result == true) _fetchRooms();
  }

  Future<void> _deleteRoom(String roomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        title: Text('Delete Room', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
        content: Text('Are you sure you want to delete this room? This cannot be undone.', style: TextStyle(color: _isDarkMode ? Colors.grey[300] : Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _institutionId != null) {
      try {
        await _apiService.deleteRoom(_institutionId!, roomId);
        _fetchRooms();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room deleted successfully'), behavior: SnackBarBehavior.floating));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Infrastructure',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Rooms & Venues', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Room Management', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Manage classrooms, labs, and examination halls', style: TextStyle(fontSize: 14, color: textSecondary)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _navigateAndRefresh(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Room'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                Expanded(
                  child: _rooms.isEmpty 
                    ? _buildEmptyState(textSecondary)
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          mainAxisExtent: 160,
                        ),
                        itemCount: _rooms.length,
                        itemBuilder: (context, index) => _buildRoomCard(_rooms[index], textPrimary, textSecondary),
                      ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildRoomCard(Room room, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.meeting_room_rounded, color: Color(0xFF4F46E5), size: 20),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit_rounded, size: 18), color: textSecondary, onPressed: () => _navigateAndRefresh(context, roomId: room.id)),
                  IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18), color: Colors.redAccent, onPressed: () => _deleteRoom(room.id)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(room.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.groups_rounded, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text('Capacity: ${room.capacity}', style: TextStyle(fontSize: 13, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.room_preferences_rounded, size: 64, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No rooms registered yet', style: TextStyle(fontSize: 16, color: textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
