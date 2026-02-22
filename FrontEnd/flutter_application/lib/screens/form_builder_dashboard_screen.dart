import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';

// Mock Data
class CustomForm {
  final String id;
  final String title;
  final int responseCount;
  final bool isOpen;
  final DateTime createdDate;

  CustomForm({
    required this.id,
    required this.title,
    required this.responseCount,
    required this.isOpen,
    required this.createdDate,
  });
}

class FormBuilderDashboardScreen extends StatefulWidget {
  const FormBuilderDashboardScreen({super.key});

  @override
  State<FormBuilderDashboardScreen> createState() =>
      _FormBuilderDashboardScreenState();
}

class _FormBuilderDashboardScreenState
    extends State<FormBuilderDashboardScreen> {
  // Mock Data
  final List<CustomForm> _forms = [
    CustomForm(id: 'f01', title: 'Student Satisfaction Survey 2024', responseCount: 152, isOpen: false, createdDate: DateTime(2024, 8, 1)),
    CustomForm(id: 'f02', title: 'Registration for Annual Tech Fest', responseCount: 312, isOpen: true, createdDate: DateTime(2024, 9, 5)),
    CustomForm(id: 'f03', title: 'Faculty Feedback on New Curriculum', responseCount: 28, isOpen: true, createdDate: DateTime(2024, 9, 10)),
  ];

  Future<void> _navigateTo(String route) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (!mounted) return;
    if (institutionId != null) {
      context.go('/$institutionId/admin/$route');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form & Survey Builder'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _forms.length,
        itemBuilder: (context, index) {
          final form = _forms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(form.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(form.isOpen ? 'Accepting Responses' : 'Closed', style: const TextStyle(color: Colors.white)),
                        backgroundColor: form.isOpen ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text('${form.responseCount} responses'),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Share')),
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => _navigateTo('form-responses'), child: const Text('View Responses')),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _navigateTo('form-editor'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateTo('form-editor'),
        icon: const Icon(Icons.add),
        label: const Text('Create New Form'),
      ),
    );
  }
}
