import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/user_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';

class StudentEligibilityScreen extends StatefulWidget {
  final String examId;
  const StudentEligibilityScreen({super.key, required this.examId});

  @override
  State<StudentEligibilityScreen> createState() => _StudentEligibilityScreenState();
}

class _StudentEligibilityScreenState extends State<StudentEligibilityScreen> {
  late ApiService _apiService;
  Exam? _exam;
  List<UserModel> _eligibleStudents = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _institutionId;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      _fetchEligibilityData();
    }
  }

  Future<void> _fetchEligibilityData() async {
    if (!mounted || _institutionId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final futures = await Future.wait([
        _apiService.getExamById(_institutionId!, widget.examId),
        _apiService.getEligibleStudentsForExam(_institutionId!, widget.examId),
      ]);

      if (mounted) {
        setState(() {
          _exam = futures[0] as Exam;
          _eligibleStudents = futures[1] as List<UserModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: $e';
        });
      }
    }
  }

  Future<void> _freezeCandidateList() async {
    if (_institutionId == null) return;
    setState(() => _isLoading = true);

    try {
      final nonDetainedStudentUids = _eligibleStudents
          .where((student) => !(student.isDetained ?? false))
          .map((student) => student.uid)
          .toList();

      await _apiService.freezeEligibleStudentsForExam(_institutionId!, widget.examId, nonDetainedStudentUids);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate list frozen successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStudentStatus(int index, bool isDetained) async {
    final student = _eligibleStudents[index];
    final originalStatus = student.isDetained;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _eligibleStudents[index] = student.copyWith(isDetained: isDetained);
    });

    try {
      await _apiService.updateStudentDetainedStatus(_institutionId!, student.uid, isDetained);
      messenger.showSnackBar(SnackBar(content: Text('${student.displayName} marked as ${isDetained ? "Detained" : "Eligible"}'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) {
        setState(() {
          _eligibleStudents[index] = student.copyWith(isDetained: originalStatus);
        });
        messenger.showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Eligibility Control',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/exam-management'),
          child: Text('Exams', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Eligibility', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
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
                          Text(_exam?.name ?? 'Student Eligibility', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('Review and finalize the list of candidates for this examination', style: TextStyle(fontSize: 14, color: textSecondary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _eligibleStudents.isEmpty ? null : _freezeCandidateList,
                        icon: const Icon(Icons.lock_person_rounded, size: 18),
                        label: const Text('Freeze Candidate List'),
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
                  
                  if (_errorMessage.isNotEmpty) 
                    Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                  else
                    Expanded(
                      child: _eligibleStudents.isEmpty
                          ? _buildEmptyState(textSecondary)
                          : GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                mainAxisExtent: 140,
                              ),
                              itemCount: _eligibleStudents.length,
                              itemBuilder: (context, index) => _buildStudentCard(index, textPrimary, textSecondary),
                            ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentCard(int index, Color textPrimary, Color textSecondary) {
    final student = _eligibleStudents[index];
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final isDetained = student.isDetained ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDetained ? Colors.redAccent.withOpacity(0.5) : borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: (isDetained ? Colors.redAccent : const Color(0xFF4F46E5)).withOpacity(0.1),
            backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
            child: student.photoUrl == null ? Icon(Icons.person_rounded, color: isDetained ? Colors.redAccent : const Color(0xFF4F46E5)) : null,
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
                Text(isDetained ? 'DETAINED' : 'ELIGIBLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDetained ? Colors.redAccent : const Color(0xFF10B981), letterSpacing: 1)),
              ],
            ),
          ),
          Switch(
            value: !isDetained,
            activeColor: const Color(0xFF10B981),
            inactiveThumbColor: Colors.redAccent,
            inactiveTrackColor: Colors.redAccent.withOpacity(0.2),
            onChanged: (val) => _updateStudentStatus(index, !val),
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
          Icon(Icons.people_outline_rounded, size: 64, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No students found for this department/semester', style: TextStyle(fontSize: 16, color: textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
