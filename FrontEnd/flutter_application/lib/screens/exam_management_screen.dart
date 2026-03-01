import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/department_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  late ApiService _apiService;
  List<Exam> _exams = [];
  List<Department> _departments = [];
  bool _isLoading = true;
  String? _institutionId;
  bool _isNavigating = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _initData();
  }

  Future<void> _initData() async {
    final id = await SessionManager.getInstitutionId();
    if (mounted) setState(() => _institutionId = id);
    if (id != null) _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted || _institutionId == null) return;
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _apiService.getExams(_institutionId!),
        _apiService.getDepartments(_institutionId!),
      ]);

      if (mounted) {
        setState(() {
          _exams = futures[0] as List<Exam>;
          _departments = futures[1] as List<Department>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  String _getDepartmentName(String departmentId) {
    return _departments.firstWhere(
      (dept) => dept.id == departmentId,
      orElse: () => Department(id: departmentId, name: 'General/All', shortName: '', institutionId: ''),
    ).name;
  }

  void _navigate(String route) {
    if (_isNavigating || _institutionId == null) return;
    setState(() => _isNavigating = true);
    context.push('/$_institutionId$route').then((_) {
      if (mounted) setState(() => _isNavigating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Examination Controller',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Exams', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: Padding(
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
                    Text('Exam Management Center', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('Oversee schedules, hall allocations, and student eligibility', style: TextStyle(fontSize: 14, color: textSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _navigate('/admin/create-exam'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Schedule New Exam'),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _exams.isEmpty
                      ? _buildEmptyState(textSecondary)
                      : _buildExamsGrid(textPrimary, textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsGrid(Color textPrimary, Color textSecondary) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 3 : (MediaQuery.of(context).size.width > 900 ? 2 : 1),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 280,
      ),
      itemCount: _exams.length,
      itemBuilder: (context, index) => _buildExamCard(_exams[index], textPrimary, textSecondary),
    );
  }

  Widget _buildExamCard(Exam exam, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final isScheduled = exam.schedule.isNotEmpty;

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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.description_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text('${_getDepartmentName(exam.departmentId)} • Sem ${exam.semester}', style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatusChip(isScheduled ? 'Scheduled' : 'Draft', isScheduled ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    if (isScheduled) Text('${exam.schedule.length} Subjects', style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    _buildActionButton('Schedule', Icons.edit_calendar_rounded, () => _navigate('/admin/exams/${exam.id}/schedule-management')),
                    _buildActionButton('Timetable', Icons.visibility_rounded, () => _navigate('/admin/exams/${exam.id}/timetable')),
                    _buildActionButton('Eligibility', Icons.people_alt_rounded, () => _navigate('/admin/exams/${exam.id}/eligibility')),
                    _buildActionButton('Halls', Icons.chair_alt_rounded, () => _navigate('/admin/exams/${exam.id}/hall-allocation')),
                    _buildActionButton('Invigilators', Icons.assignment_ind_rounded, () => _navigate('/admin/exams/${exam.id}/invigilator-assignment')),
                    _buildActionButton('Tickets', Icons.article_rounded, () => _navigate('/admin/exams/${exam.id}/hall-tickets')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildActionButton(String tooltip, IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: _isDarkMode ? Colors.grey[300] : Colors.grey[700]),
              const SizedBox(width: 6),
              Text(tooltip, style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[300] : Colors.grey[700], fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.event_note_rounded, color: Color(0xFF4F46E5), size: 64),
          ),
          const SizedBox(height: 24),
          Text('No Exams Scheduled', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text('Create a new exam to start managing schedules and halls.', style: TextStyle(fontSize: 14, color: textSecondary)),
        ],
      ),
    );
  }
}
