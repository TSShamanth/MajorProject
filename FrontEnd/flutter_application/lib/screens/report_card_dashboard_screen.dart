import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';

// Mock Data Models
class Student {
  final String id;
  final String name;
  final String usn;
  bool isReportGenerated;

  Student({required this.id, required this.name, required this.usn, this.isReportGenerated = false});
}

class ReportCardDashboardScreen extends StatefulWidget {
  const ReportCardDashboardScreen({super.key});

  @override
  State<ReportCardDashboardScreen> createState() => _ReportCardDashboardScreenState();
}

class _ReportCardDashboardScreenState extends State<ReportCardDashboardScreen> {
  String? _selectedProgram = 'B.Tech Computer Science - 2025 Batch';
  String? _selectedSemester = 'Semester 3';

  final List<Student> _students = [
    Student(id: 's01', name: 'John Doe', usn: '1RVU21CSE001', isReportGenerated: true),
    Student(id: 's02', name: 'Jane Smith', usn: '1RVU21CSE002', isReportGenerated: true),
    Student(id: 's03', name: 'Peter Jones', usn: '1RVU21CSE050'),
  ];

  void _navigateToViewer() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (!mounted) return;
    if (institutionId != null) {
      context.go('/$institutionId/admin/report-card-viewer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card Generation'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  for (var student in _students) {
                    student.isReportGenerated = true;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating reports for all students... (mocked)')),
                );
              },
              icon: const Icon(Icons.bolt_outlined),
              label: const Text('Generate for All Students in this Semester'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedProgram,
              decoration: const InputDecoration(labelText: 'Program/Batch', border: OutlineInputBorder()),
              onChanged: (value) => setState(() => _selectedProgram = value),
              items: const [
                DropdownMenuItem(value: 'B.Tech Computer Science - 2025 Batch', child: Text('B.Tech CS - 2025')),
                DropdownMenuItem(value: 'B.B.A. - 2026 Batch', child: Text('B.B.A. - 2026')),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSemester,
              decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
              onChanged: (value) => setState(() => _selectedSemester = value),
              items: const [
                DropdownMenuItem(value: 'Semester 1', child: Text('Sem 1')),
                DropdownMenuItem(value: 'Semester 2', child: Text('Sem 2')),
                DropdownMenuItem(value: 'Semester 3', child: Text('Sem 3')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text(student.name.substring(0, 1))),
            title: Text(student.name),
            subtitle: Text(student.usn),
            trailing: student.isReportGenerated
                ? TextButton.icon(
                    icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                    label: const Text('View'),
                    onPressed: _navigateToViewer,
                  )
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        student.isReportGenerated = true;
                      });
                      _navigateToViewer();
                    },
                    child: const Text('Generate'),
                  ),
          ),
        );
      },
    );
  }
}
