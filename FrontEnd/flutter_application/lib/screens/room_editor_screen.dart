import 'package:flutter/material.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';

class RoomEditorScreen extends StatefulWidget {
  final String? roomId;

  const RoomEditorScreen({super.key, this.roomId});

  @override
  State<RoomEditorScreen> createState() => _RoomEditorScreenState();
}

class _RoomEditorScreenState extends State<RoomEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Room? _editingRoom;
  String? _institutionId;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (widget.roomId != null) {
      _fetchRoomDetails();
    }
  }

  Future<void> _fetchRoomDetails() async {
    setState(() => _isLoading = true);
    try {
      if (_institutionId == null) return;
      final room = await _apiService.getRoomById(_institutionId!, widget.roomId!);
      if (mounted) {
        setState(() {
          _editingRoom = room;
          _nameController.text = room.name;
          _capacityController.text = room.capacity.toString();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading room: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_institutionId == null) return;

        final room = Room(
          id: _editingRoom?.id ?? '',
          name: _nameController.text,
          capacity: int.parse(_capacityController.text),
          institutionId: _institutionId!,
          departmentId: _editingRoom?.departmentId,
        );

        if (_editingRoom == null) {
          await _apiService.createRoom(_institutionId!, room);
        } else {
          await _apiService.updateRoom(_institutionId!, _editingRoom!.id, room);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Room ${_editingRoom == null ? "created" : "updated"} successfully'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green),
          );
          context.pop(true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: _editingRoom == null ? 'Create Room' : 'Edit Room',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/room-management'),
          child: Text('Rooms', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text(_editingRoom == null ? 'Create' : 'Edit', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingRoom == null ? 'Register New Room' : 'Update Room Details',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Text('Define physical spaces and their seating capacities', style: TextStyle(fontSize: 14, color: textSecondary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveRoom,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(_editingRoom == null ? 'Create Room' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.meeting_room_rounded, color: Color(0xFF4F46E5), size: 20),
                              ),
                              const SizedBox(width: 16),
                              Text('Room Particulars', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildTextField(_nameController, 'Room Name / Number', Icons.edit_note_rounded, 'e.g., Room 302, Lab A, Main Hall'),
                          const SizedBox(height: 24),
                          _buildTextField(_capacityController, 'Seating Capacity', Icons.groups_rounded, 'Enter max number of students', keyboardType: TextInputType.number),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 14, color: textSecondary),
                              const SizedBox(width: 8),
                              Expanded(child: Text('This capacity will be used for automated exam hall allocation.', style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 15),
      decoration: _inputDecoration(label, icon, hint),
      validator: (v) => v!.isEmpty ? '$label is required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!),
      hintStyle: TextStyle(color: _isDarkMode ? Colors.grey[600]! : Colors.grey[400]!, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5).withOpacity(0.7), size: 20),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
