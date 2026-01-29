import 'package:flutter/material.dart';

// Hardcoded data models
class Program {
  final String name;
  final List<Section> sections;
  Program({required this.name, required this.sections});
}

class Section {
  final String name;
  final List<Student> students;
  Section({required this.name, required this.students});
}

class Student {
  final String name;
  final String usn;
  Student({required this.name, required this.usn});
}

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  // Hardcoded data for UI demonstration
  final List<Program> _programs = [
    Program(name: 'B.Tech Computer Science - 2025 Batch', sections: [
      Section(name: 'Section A', students: [
        Student(name: 'John Doe', usn: '1RVU21CSE001'),
        Student(name: 'Jane Smith', usn: '1RVU21CSE002'),
      ]),
      Section(name: 'Section B', students: [
        Student(name: 'Peter Jones', usn: '1RVU21CSE050'),
      ]),
    ]),
    Program(name: 'B.B.A. - 2026 Batch', sections: [
      Section(name: 'Section A', students: [
        Student(name: 'Emily White', usn: '1RVU22BBA005'),
      ]),
    ]),
  ];

  Program? _selectedProgram;

  @override
  void initState() {
    super.initState();
    if (_programs.isNotEmpty) {
      _selectedProgram = _programs.first;
    }
  }

  void _addSection(Program program) {
    setState(() {
      program.sections.add(Section(name: 'Section C (New)', students: []));
    });
  }

  void _addStudent(Section section) {
     setState(() {
      section.students.add(Student(name: 'New Student', usn: '1RVUXXYYYZZZ'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class & Section Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          _buildProgramSelector(),
          Expanded(
            child: _selectedProgram == null
                ? const Center(child: Text('No programs available.'))
                : _buildSectionsList(_selectedProgram!),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: DropdownButtonFormField<Program>(
        value: _selectedProgram,
        decoration: const InputDecoration(
          labelText: 'Select Program/Batch',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (Program? newValue) {
          setState(() {
            _selectedProgram = newValue;
          });
        },
        items: _programs.map<DropdownMenuItem<Program>>((Program program) {
          return DropdownMenuItem<Program>(
            value: program,
            child: Text(program.name),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionsList(Program program) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ...program.sections.map((section) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              shape: Border.all(color: Colors.transparent),
              title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('${section.students.length} Students'),
              children: [
                ...section.students.map((student) {
                  return ListTile(
                    title: Text(student.name),
                    subtitle: Text('USN: ${student.usn}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        // TODO: Implement delete student
                      },
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Student'),
                    onPressed: () => _addStudent(section),
                  ),
                )
              ],
            ),
          );
        }),
        ElevatedButton.icon(
          onPressed: () => _addSection(program),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add New Section'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
