import 'package:flutter/material.dart';

// Mock Data Models
class ExamSubject {
  String name;
  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;

  ExamSubject({
    required this.name,
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}

class ExamScheduleEditorScreen extends StatefulWidget {
  const ExamScheduleEditorScreen({super.key});

  @override
  State<ExamScheduleEditorScreen> createState() => _ExamScheduleEditorScreenState();
}

class _ExamScheduleEditorScreenState extends State<ExamScheduleEditorScreen> {
  final _titleController = TextEditingController(text: 'Mid-Term Examinations - Fall 2024');
  final _startDateController = TextEditingController(text: '2024-10-15');
  final _endDateController = TextEditingController(text: '2024-10-25');

  final List<ExamSubject> _subjects = [
    ExamSubject(name: 'CS301 - Operating Systems', date: DateTime(2024, 10, 15), startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 12, minute: 0)),
    ExamSubject(name: 'CS302 - Database Systems', date: DateTime(2024, 10, 17), startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 12, minute: 0)),
    ExamSubject(name: 'MA301 - Engineering Mathematics III', date: DateTime(2024, 10, 19), startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 12, minute: 0)),
  ];

  void _addSubject() {
    setState(() {
      _subjects.add(ExamSubject(
        name: 'New Subject',
        date: DateTime.now(),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Schedule Editor'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.save)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Exam Title', border: OutlineInputBorder()),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _startDateController, decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder()))),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _endDateController, decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 24),
            Text('Subjects & Timetable', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            ..._subjects.map((subject) => _buildSubjectCard(subject)),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addSubject,
                icon: const Icon(Icons.add),
                label: const Text('Add Subject to Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(ExamSubject subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(Icons.calendar_today, '${subject.date.year}-${subject.date.month}-${subject.date.day}'),
                _buildInfoChip(Icons.access_time, '${subject.startTime.format(context)} - ${subject.endTime.format(context)}'),
              ],
            ),
             const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                 TextButton(onPressed: () {}, child: const Text('Assign Rooms')),
                 const SizedBox(width: 8),
                 TextButton(onPressed: () {}, child: const Text('Manage Grades')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Colors.grey[200],
    );
  }
}
