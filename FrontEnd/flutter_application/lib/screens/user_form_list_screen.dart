import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/form_builder_model.dart';
import '../services/form_builder_service.dart';
import '../services/session_manager.dart';

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
  bool _isDarkMode = false;

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
      setState(() {
        _forms = forms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading forms: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Surveys & Forms'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadForms,
            child: _forms.isEmpty 
              ? _buildEmptyState(textSecondary)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _forms.length,
                  itemBuilder: (context, index) => _buildFormCard(_forms[index], textPrimary, textSecondary),
                ),
          ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No active forms or surveys at the moment.', style: TextStyle(color: textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFormCard(CustomForm form, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/$_institutionId/forms/${form.id}/fill'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
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
                    Text(form.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      form.description.isNotEmpty ? form.description : 'Click to fill out this form',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF4F46E5)),
            ],
          ),
        ),
      ),
    );
  }
}
