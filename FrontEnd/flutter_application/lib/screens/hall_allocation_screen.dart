import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/models/seating_entry.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';

class HallAllocationScreen extends StatefulWidget {
  final String examId;

  const HallAllocationScreen({super.key, required this.examId});

  @override
  State<HallAllocationScreen> createState() => _HallAllocationScreenState();
}

class _HallAllocationScreenState extends State<HallAllocationScreen> {
  final ApiService _apiService = ApiService();
  Exam? _exam;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, Room> _roomsMap = {};
  Map<String, UserModel> _usersMap = {};
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
      _fetchExamDetails();
    }
  }

  Future<void> _fetchExamDetails() async {
    if (!mounted || _institutionId == null) return;
    setState(() => _isLoading = true);
    try {
      final exam = await _apiService.getExamById(_institutionId!, widget.examId);
      
      if (exam.seatingArrangement != null && exam.seatingArrangement!.isNotEmpty) {
        final List<Future> futures = [];
        futures.add(_apiService.getRooms(_institutionId!));
        futures.add(_apiService.getUsers(_institutionId!));
        
        final results = await Future.wait(futures);
        _roomsMap = {for (var room in (results[0] as List<Room>)) room.id: room};
        _usersMap = {for (var user in (results[1] as List<UserModel>)) user.uid: user};
      }

      if (mounted) {
        setState(() {
          _exam = exam;
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

  Future<void> _allocateHalls() async {
    if (_institutionId == null) return;
    setState(() => _isLoading = true);
    try {
      await _apiService.allocateHalls(_institutionId!, widget.examId);
      await _fetchExamDetails(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Halls allocated successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      }
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

    Map<String, List<SeatingEntry>> seatingByRoom = {};
    _exam?.seatingArrangement?.forEach((studentId, seatingEntry) {
      if (!seatingByRoom.containsKey(seatingEntry.roomId)) seatingByRoom[seatingEntry.roomId] = [];
      seatingByRoom[seatingEntry.roomId]!.add(seatingEntry);
    });

    return AdminLayout(
      title: 'Hall Allocation',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/exam-management'),
          child: Text('Exams', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Seating', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
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
                          Text(_exam?.name ?? 'Hall Allocation', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('Manage room assignments and seating for candidates', style: TextStyle(fontSize: 14, color: textSecondary)),
                        ],
                      ),
                      if (_exam?.frozenCandidateList != null && _exam!.frozenCandidateList!.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _allocateHalls,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: const Text('Auto-Allocate Halls'),
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
                  
                  if (_errorMessage != null) 
                    Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  else if (_exam?.frozenCandidateList == null || _exam!.frozenCandidateList!.isEmpty)
                    _buildEmptyState('Freeze List Required', 'Please freeze the eligible students list first before allocating halls.', Icons.lock_clock_rounded, const Color(0xFFF59E0B), textSecondary)
                  else if (seatingByRoom.isEmpty)
                    _buildEmptyState('No Allocations Yet', 'Candidate list is frozen. Click "Auto-Allocate" to generate seating.', Icons.chair_alt_rounded, const Color(0xFF4F46E5), textSecondary)
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          mainAxisExtent: 400,
                        ),
                        itemCount: seatingByRoom.length,
                        itemBuilder: (context, index) {
                          final roomId = seatingByRoom.keys.elementAt(index);
                          final room = _roomsMap[roomId];
                          final students = seatingByRoom[roomId]!;
                          return _buildRoomCard(room, students, textPrimary, textSecondary);
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildRoomCard(Room? room, List<SeatingEntry> students, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.meeting_room_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room?.name ?? 'Unknown Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                      Text('Capacity: ${students.length} / ${room?.capacity ?? "?"}', style: TextStyle(fontSize: 12, color: textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = students[index];
                final user = _usersMap[entry.studentId];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                        child: Center(child: Text(entry.seatNumber.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.displayName ?? entry.studentId, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                            Text(user?.usn ?? 'No USN', style: TextStyle(fontSize: 11, color: textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
