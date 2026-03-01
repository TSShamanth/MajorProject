import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/models/invigilator_assignment.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';

class InvigilatorAssignmentScreen extends StatefulWidget {
  final String examId;

  const InvigilatorAssignmentScreen({super.key, required this.examId});

  @override
  State<InvigilatorAssignmentScreen> createState() => _InvigilatorAssignmentScreenState();
}

class _InvigilatorAssignmentScreenState extends State<InvigilatorAssignmentScreen> {
  final ApiService _apiService = ApiService();
  Exam? _exam;
  bool _isLoading = true;
  String? _errorMessage;
  List<Room> _rooms = [];
  List<UserModel> _faculty = [];
  List<InvigilatorAssignment> _assignments = [];
  String? _institutionId;
  bool _isDarkMode = false;

  final Map<String, String?> _selectedFacultyForRoom = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted || _institutionId == null) return;
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.getExamById(_institutionId!, widget.examId),
        _apiService.getRooms(_institutionId!),
        _apiService.getUsers(_institutionId!),
        _apiService.getInvigilatorAssignments(_institutionId!, widget.examId),
      ]);

      if (mounted) {
        setState(() {
          _exam = futures[0] as Exam;
          _rooms = futures[1] as List<Room>;
          _faculty = (futures[2] as List<UserModel>).where((u) => u.role == 'faculty').toList();
          _assignments = futures[3] as List<InvigilatorAssignment>;

          _selectedFacultyForRoom.clear();
          for (var assignment in _assignments) {
            _selectedFacultyForRoom[assignment.roomId] = assignment.facultyId;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _assignInvigilator(String roomId, String? facultyId) async {
    if (_institutionId == null) return;
    if (facultyId == null) return;

    setState(() => _isLoading = true);
    try {
      final existingAssignment = _assignments.firstWhere(
        (a) => a.roomId == roomId,
        orElse: () => InvigilatorAssignment(id: '', examId: widget.examId, roomId: '', facultyId: '', institutionId: _institutionId!),
      );

      final newAssignment = InvigilatorAssignment(
        id: existingAssignment.id,
        examId: widget.examId,
        roomId: roomId,
        facultyId: facultyId,
        institutionId: _institutionId!,
        session: 'Default',
      );

      await _apiService.assignInvigilator(_institutionId!, widget.examId, newAssignment);
      await _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invigilator assigned successfully'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    if (_institutionId == null) return;
    setState(() => _isLoading = true);
    try {
      await _apiService.deleteInvigilatorAssignment(_institutionId!, widget.examId, assignmentId);
      await _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment removed'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Invigilator Management',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/exam-management'),
          child: Text('Exams', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Invigilators', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading && _exam == null
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
                          Text(_exam?.name ?? 'Invigilator Assignment', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('Assign faculty members to rooms for examination duty', style: TextStyle(fontSize: 14, color: textSecondary)),
                        ],
                      ),
                      IconButton(
                        onPressed: _fetchData,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh Assignments',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  if (_errorMessage != null) 
                    Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  else if (_rooms.isEmpty)
                    _buildEmptyState('No Rooms Configured', 'Please register examination halls in Room Management first.', Icons.meeting_room_rounded, const Color(0xFFF59E0B), textSecondary)
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          mainAxisExtent: 220,
                        ),
                        itemCount: _rooms.length,
                        itemBuilder: (context, index) => _buildRoomAssignmentCard(_rooms[index], textPrimary, textSecondary),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildRoomAssignmentCard(Room room, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    
    final assignment = _assignments.firstWhere((a) => a.roomId == room.id, orElse: () => InvigilatorAssignment(id: '', examId: '', roomId: '', facultyId: '', institutionId: ''));
    final currentSelection = _selectedFacultyForRoom[room.id];
    final isAssigned = assignment.id.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAssigned ? const Color(0xFF4F46E5).withOpacity(0.5) : borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chair_rounded, color: Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                      Text('Capacity: ${room.capacity} students', style: TextStyle(fontSize: 12, color: textSecondary)),
                    ],
                  ),
                ),
                if (isAssigned)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteAssignment(assignment.id),
                    tooltip: 'Remove Assignment',
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: DropdownButtonFormField<String>(
              value: currentSelection,
              dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: _inputDecoration('Assign Invigilator', Icons.person_pin_rounded),
              items: [
                const DropdownMenuItem(value: null, child: Text('No Invigilator Assigned')),
                ..._faculty.map((f) => DropdownMenuItem(value: f.uid, child: Text(f.displayName))),
              ],
              onChanged: (val) => _assignInvigilator(room.id, val),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!, fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5).withOpacity(0.7), size: 18),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color, Color textSecondary) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 64),
            ),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: textSecondary)),
          ],
        ),
      ),
    );
  }
}
