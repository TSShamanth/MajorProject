import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/form_builder_model.dart';
import '../services/form_builder_service.dart';
import '../services/session_manager.dart';
import '../widgets/student_layout.dart';

class UserFormListScreen extends StatefulWidget {
  final String role; // 'STUDENT' or 'FACULTY'
  const UserFormListScreen({super.key, required this.role});

  @override
  State<UserFormListScreen> createState() => _UserFormListScreenState();
}

class _UserFormListScreenState extends State<UserFormListScreen> {
  final FormBuilderService _formService = FormBuilderService();
  List<CustomForm> _forms = [];
  bool _isLoading = true;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  Future<void> _loadForms() async {
    setState(() => _isLoading = true);
    try {
      _institutionId = await SessionManager.getInstitutionId();
      final forms = await _formService.getFormsForAudience(widget.role);
      if (mounted) {
        setState(() {
          _forms = forms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading forms: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If it's a student, wrap in StudentLayout. If faculty, we might need a FacultyLayout later.
    // For now, focusing on Student UI as per user instruction.
    if (widget.role == 'STUDENT') {
      return StudentLayout(
        title: 'Surveys & Feedback',
        breadcrumbs: [
          Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('Forms', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
        child: _buildBody(),
      );
    }

    // Fallback for Faculty/other roles
    return Scaffold(
      appBar: AppBar(title: const Text('Forms & Surveys')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _loadForms,
          color: const Color(0xFF4F46E5),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _forms.isEmpty 
                  ? _buildEmptyState()
                  : Column(
                      children: _forms.map((form) => _buildFormCard(form)).toList(),
                    ),
              ],
            ),
          ),
        );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Forms',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Please complete the surveys and feedback forms below',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF4F46E5), size: 64),
            ),
            const SizedBox(height: 24),
            const Text('No active forms', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text('You have no pending surveys or feedback forms at this time.', 
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(CustomForm form) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/$_institutionId/forms/${form.id}/fill'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.description_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(form.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text(
                        form.description.isNotEmpty ? form.description : 'Click to open and submit this form',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
