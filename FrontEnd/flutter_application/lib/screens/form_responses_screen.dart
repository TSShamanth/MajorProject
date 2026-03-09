import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/form_builder_model.dart';
import '../services/form_builder_service.dart';
import '../widgets/admin_layout.dart';

class FormResponsesScreen extends StatefulWidget {
  final String formId;
  const FormResponsesScreen({super.key, required this.formId});

  @override
  State<FormResponsesScreen> createState() => _FormResponsesScreenState();
}

class _FormResponsesScreenState extends State<FormResponsesScreen> {
  final FormBuilderService _formService = FormBuilderService();
  CustomForm? _form;
  List<FormResponseModel> _responses = [];
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
          onTap: () => context.pop(),
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
                _buildSummaryHeader(),
                const SizedBox(height: 32),
                Text('All Submissions (${_responses.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_responses.isEmpty)
                  _buildEmptyState(textSecondary)
                else
                  _buildResponsesTable(),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryHeader() {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_form?.title ?? 'Form Responses', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${_responses.length} responses received', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.forum_outlined, size: 64, color: textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No responses received yet.', style: TextStyle(color: textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesTable() {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: DataTable(
        columns: [
          const DataColumn(label: Text('User ID')),
          const DataColumn(label: Text('Submitted At')),
          ...(_form?.fields.take(2).map((f) => DataColumn(label: Text(f.label))) ?? []),
          const DataColumn(label: Text('Actions')),
        ],
        rows: _responses.map((resp) {
          return DataRow(cells: [
            DataCell(Text('${resp.userId.substring(0, 8)}...')),
            DataCell(Text(DateFormat('dd MMM, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(resp.submittedAt)))),
            ...(_form?.fields.take(2).map((field) {
              final answer = resp.answers[field.id];
              return DataCell(Text(answer?.toString() ?? '-'));
            }) ?? []),
            DataCell(IconButton(
              icon: const Icon(Icons.visibility_outlined, color: Color(0xFF4F46E5)),
              onPressed: () => _showResponseDetails(resp),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  void _showResponseDetails(FormResponseModel response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Response Details'),
        content: SizedBox(
          width: 500,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Submitted by: ${response.userId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(),
              ...(_form?.fields.map((field) {
                final answer = response.answers[field.id];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(answer?.toString() ?? 'No answer provided', style: const TextStyle(color: Color(0xFF4F46E5))),
                    ],
                  ),
                );
              }) ?? []),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
