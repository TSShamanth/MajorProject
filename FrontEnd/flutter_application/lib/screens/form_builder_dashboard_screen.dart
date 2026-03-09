import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/services/form_builder_service.dart';
import 'package:flutter_application/models/form_builder_model.dart';
import '../widgets/admin_layout.dart';
import 'package:intl/intl.dart';

class FormBuilderDashboardScreen extends StatefulWidget {
  const FormBuilderDashboardScreen({super.key});

  @override
  State<FormBuilderDashboardScreen> createState() =>
      _FormBuilderDashboardScreenState();
}

class _FormBuilderDashboardScreenState
    extends State<FormBuilderDashboardScreen> {
  final FormBuilderService _formService = FormBuilderService();
  List<CustomForm> _forms = [];
  Map<String, int> _responseCounts = {};
  bool _isLoading = true;
  String? _institutionId;
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
      final forms = await _formService.getForms();
      
      // Fetch counts for each form
      final counts = <String, int>{};
      for (var form in forms) {
        counts[form.id] = await _formService.getResponseCount(form.id);
      }

      setState(() {
        _forms = forms;
        _responseCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading forms: $e')),
        );
      }
    }
  }

  Future<void> _deleteForm(String formId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Form'),
        content: const Text('Are you sure you want to delete this form and all its responses?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _formService.deleteForm(formId);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Form Builder',
      breadcrumbs: [
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Text('Form Builder', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(textPrimary, textSecondary),
                  const SizedBox(height: 32),
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  Text('All Forms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 16),
                  if (_forms.isEmpty)
                    _buildEmptyState(textSecondary)
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _forms.length,
                      itemBuilder: (context, index) => _buildFormCard(_forms[index]),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Form & Survey Builder', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Create and manage custom forms for your institution', style: TextStyle(fontSize: 14, color: textSecondary)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => context.push('/$_institutionId/admin/form-builder/new'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create New Form'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.description_outlined, size: 64, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No forms found. Create your first form!', style: TextStyle(color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalSubmissions = _responseCounts.values.fold(0, (sum, count) => sum + count);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 2.5,
          children: [
            _buildStatCard('Total Forms', '${_forms.length}', Icons.description_rounded, const Color(0xFF4F46E5)),
            _buildStatCard('Active Forms', '${_forms.where((f) => f.isOpen).length}', Icons.bolt_rounded, const Color(0xFF10B981)),
            _buildStatCard('Total Submissions', '$totalSubmissions', Icons.forum_rounded, const Color(0xFF8B5CF6)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
                Text(title, style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(CustomForm form) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final statusColor = form.isOpen ? const Color(0xFF10B981) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.assignment_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(form.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text('Last updated ${DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(form.updatedAt))}',
                          style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: statusColor.withOpacity(0.3))),
                  child: Text(form.isOpen ? 'OPEN' : 'CLOSED', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              children: [
                _buildCardDetail(Icons.people_rounded, form.targetAudience.isEmpty ? 'All' : form.targetAudience.join(', ')),
                _buildCardDetail(Icons.list_alt_rounded, '${form.fields.length} Fields'),
                _buildCardDetail(Icons.forum_rounded, '${_responseCounts[form.id] ?? 0} Responses'),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _deleteForm(form.id),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: 'Delete Form',
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    final baseUrl = kIsWeb ? Uri.base.origin : 'https://acadexa.app';
                    final link = '$baseUrl/#/$_institutionId/forms/${form.id}/fill';
                    Clipboard.setData(ClipboardData(text: link)).then((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Form link copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4F46E5), side: const BorderSide(color: Color(0xFF4F46E5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/$_institutionId/admin/form-builder/${form.id}/responses'),
                  icon: const Icon(Icons.analytics_rounded, size: 16),
                  label: const Text('Responses'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4F46E5), side: const BorderSide(color: Color(0xFF4F46E5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => context.push('/$_institutionId/admin/form-builder/${form.id}/edit'),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit Form'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetail(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
      ],
    );
  }
}
