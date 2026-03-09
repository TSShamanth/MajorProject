import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';

class ExamHallTicketsScreen extends StatefulWidget {
  final String examId;

  const ExamHallTicketsScreen({super.key, required this.examId});

  @override
  State<ExamHallTicketsScreen> createState() => _ExamHallTicketsScreenState();
}

class _ExamHallTicketsScreenState extends State<ExamHallTicketsScreen> {
  final ApiService _apiService = ApiService();
  Exam? _exam;
  List<UserModel> _students = [];
  bool _isLoading = true;
  String? _errorMessage;
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
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted || _institutionId == null) return;
    setState(() => _isLoading = true);
    try {
      final exam = await _apiService.getExamById(_institutionId!, widget.examId);
      if (exam.frozenCandidateList != null && exam.frozenCandidateList!.isNotEmpty) {
        final allUsers = await _apiService.getUsers(_institutionId!);
        _students = allUsers.where((user) => exam.frozenCandidateList!.contains(user.uid)).toList();
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
          _errorMessage = 'Failed to load: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Hall Ticket Center',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/exam-management'),
          child: Text('Exams', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Hall Tickets', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
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
                          Text(_exam?.name ?? 'Hall Tickets', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('Generate and view official examination hall tickets', style: TextStyle(fontSize: 14, color: textSecondary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _students.isEmpty ? null : () {},
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('Bulk Generate'),
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
                  else if (_students.isEmpty)
                    _buildEmptyState(textSecondary)
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          mainAxisExtent: 140,
                        ),
                        itemCount: _students.length,
                        itemBuilder: (context, index) => _buildStudentTicketCard(_students[index], textPrimary, textSecondary),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentTicketCard(UserModel student, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return InkWell(
      onTap: () => context.push('/$_institutionId/admin/exams/${_exam!.id}/hall-tickets/${student.uid}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
              backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
              child: student.photoUrl == null ? const Icon(Icons.person_rounded, color: Color(0xFF4F46E5)) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(student.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                  Text(student.usn ?? student.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text('ELIGIBLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.badge_rounded, color: const Color(0xFF4F46E5).withOpacity(0.5), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_rounded, size: 64, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Candidate list not yet frozen', style: TextStyle(fontSize: 16, color: textSecondary, fontWeight: FontWeight.w500)),
          Text('Freeze the list in Eligibility section to generate tickets.', style: TextStyle(fontSize: 13, color: textSecondary.withOpacity(0.7))),
        ],
      ),
    );
  }
}
