import 'package:flutter/material.dart';

// Mock Data Models
class GradeInfo {
  final String subjectCode;
  final String subjectName;
  final int credits;
  final String grade;

  GradeInfo({required this.subjectCode, required this.subjectName, required this.credits, required this.grade});
}

class ReportCardViewerScreen extends StatelessWidget {
  const ReportCardViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    const studentName = 'John Doe';
    const usn = '1RVU21CSE001';
    const program = 'B.Tech Computer Science';
    const semester = '3rd Semester';
    final grades = [
      GradeInfo(subjectCode: 'CS301', subjectName: 'Operating Systems', credits: 4, grade: 'A+'),
      GradeInfo(subjectCode: 'CS302', subjectName: 'Database Systems', credits: 4, grade: 'A'),
      GradeInfo(subjectCode: 'MA301', subjectName: 'Eng. Mathematics III', credits: 3, grade: 'B+'),
      GradeInfo(subjectCode: 'EC305', subjectName: 'Digital Electronics', credits: 3, grade: 'A'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Report Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting as PDF... (mocked)')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
           decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const Divider(height: 30),
              _buildStudentInfo(studentName, usn, program, semester),
              const SizedBox(height: 24),
              _buildGradesTable(context, grades),
              const SizedBox(height: 24),
              _buildSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Placeholder for institution logo
        const CircleAvatar(radius: 30, child: Icon(Icons.school, size: 30)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RV University', // Hardcoded
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text('Official Grade Report - Fall 2024'),
          ],
        )
      ],
    );
  }

  Widget _buildStudentInfo(String name, String usn, String program, String semester) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Student Name:', name),
        _infoRow('USN:', usn),
        _infoRow('Program:', program),
        _infoRow('Semester:', semester),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildGradesTable(BuildContext context, List<GradeInfo> grades) {
    final columns = ['Code', 'Subject', 'Credits', 'Grade'];
    return DataTable(
      columnSpacing: 20,
      columns: columns.map((col) => DataColumn(label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
      rows: grades.map((grade) => DataRow(
        cells: [
          DataCell(Text(grade.subjectCode)),
          DataCell(Text(grade.subjectName)),
          DataCell(Text(grade.credits.toString())),
          DataCell(Text(grade.grade, style: const TextStyle(fontWeight: FontWeight.bold))),
        ]
      )).toList(),
    );
  }

  Widget _buildSummary() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem('SGPA', '8.91'),
            _summaryItem('CGPA', '9.12'),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
