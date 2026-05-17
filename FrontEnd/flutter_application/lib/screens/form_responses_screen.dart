import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/form_builder_model.dart';
import '../services/form_builder_service.dart';
import '../services/session_manager.dart';
import '../services/api_service.dart';
import '../widgets/admin_layout.dart';
import '../widgets/ai_analysis_modal.dart';

class FormResponsesScreen extends StatefulWidget {
  final String formId;
  const FormResponsesScreen({super.key, required this.formId});

  @override
  State<FormResponsesScreen> createState() => _FormResponsesScreenState();
}

class _FormResponsesScreenState extends State<FormResponsesScreen> {
  final FormBuilderService _formService = FormBuilderService();
  final ApiService _apiService = ApiService();
  CustomForm? _form;
  List<FormResponseModel> _responses = [];
  String? _institutionId;
  bool _isLoading = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _institutionId = await SessionManager.getInstitutionId();
      if (_institutionId == null) throw Exception('Institution ID not found');
      
      final form = await _formService.getFormById(widget.formId);
      final responses = await _formService.getResponses(widget.formId);
      
      setState(() {
        _form = form;
        _responses = responses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading responses: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Form Responses',
      breadcrumbs: [
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.go('/$_institutionId/admin/form-builder'),
          child: Text('Form Builder', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Text('Responses', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_responses.isEmpty)
                    _buildEmptyState(textSecondary)
                  else
                    _buildResponsesTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_form?.title ?? 'Form Responses', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_responses.length} responses received', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        Row(
          children: [
            if (_responses.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AiAnalysisModal(
                      title: 'Response Analysis',
                      subtitle: 'Sentiment & Actionable Insights',
                      onAnalyze: () => _apiService.analyzeFormResponses(_institutionId!, widget.formId),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.amber),
                label: const Text('AI Analyze', style: TextStyle(color: Colors.amber)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[50],
                  elevation: 0,
                ),
              ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {}, // Placeholder for _exportToCsv
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Export CSV'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No responses received yet.', style: TextStyle(color: textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesTable() {
    // This would be a more complex widget, like a DataTable or a custom grid.
    // For simplicity, we'll just list them.
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _responses.length,
      itemBuilder: (context, index) {
        final response = _responses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text('Submitted on: ${DateFormat.yMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(response.submittedAt))}'),
            subtitle: Text('Answers: ${response.answers}'),
          ),
        );
      },
    );
  }
}
