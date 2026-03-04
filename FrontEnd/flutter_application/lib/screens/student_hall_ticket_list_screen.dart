import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/student_layout.dart';

class StudentHallTicketListScreen extends StatefulWidget {
  const StudentHallTicketListScreen({super.key});

  @override
  StudentHallTicketListScreenState createState() =>
      StudentHallTicketListScreenState();
}

class StudentHallTicketListScreenState
    extends State<StudentHallTicketListScreen> {
  final ApiService _apiService = ApiService();
  List<Exam> _exams = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      final studentId = FirebaseAuth.instance.currentUser?.uid;
      if (institutionId == null || studentId == null) {
        if (mounted) setState(() => _isLoading = false);
        _errorMessage = 'User or Institution ID not found.';
        return;
      }

      final allExams = await _apiService.getExams(institutionId);
      final studentExams = allExams.where((exam) {
        return exam.frozenCandidateList != null && exam.frozenCandidateList!.contains(studentId);
      }).toList();

      if (mounted) {
        setState(() {
          _exams = studentExams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load exams: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Hall Tickets',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Hall Tickets', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(_errorMessage!)
              : _exams.isEmpty
                  ? _buildEmptyState()
                  : _buildExamsList(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.confirmation_number_outlined, size: 64, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Hall Tickets Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your hall tickets will appear here once exams are scheduled.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final router = GoRouter.of(context);
                final institutionId = await SessionManager.getInstitutionId();
                if (institutionId == null) return;
                
                router.go('/$institutionId/student/hall-tickets/${exam.id}');
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_rounded, color: Color(0xFF4F46E5), size: 24),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Click to view and print your hall ticket',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
