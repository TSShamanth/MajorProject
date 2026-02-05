import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/department_model.dart';
import '../config/api_config.dart';

class InstitutionSettingsScreen extends StatefulWidget {
  const InstitutionSettingsScreen({super.key});

  @override
  State<InstitutionSettingsScreen> createState() =>
      _InstitutionSettingsScreenState();
}

class _InstitutionSettingsScreenState extends State<InstitutionSettingsScreen> {
  final _nameController = TextEditingController(text: 'RV University');
  final _addressController =
      TextEditingController(text: 'Mysuru Road, Bengaluru');
  final _emailController = TextEditingController(text: 'contact@rvu.edu.in');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _academicYearStartController =
      TextEditingController(text: '2023-08-01');
  final _academicYearEndController = TextEditingController(text: '2024-05-31');

  late Future<List<Department>> _departmentsFuture;
  final List<String> _holidays = [
    '2024-01-26: Republic Day',
    '2024-08-15: Independence Day',
    '2024-10-02: Gandhi Jayanti'
  ];
  final Map<String, bool> _workingDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };

  @override
  void initState() {
    super.initState();
    _departmentsFuture = _fetchDepartments();
  }

  Future<List<Department>> _fetchDepartments() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) {
      throw Exception('Institution ID not found');
    }
    final response =
        await http.get(Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((dept) => Department.fromJson(dept)).toList();
    } else {
      throw Exception('Failed to load departments');
    }
  }

  void _addDepartment() {
    final nameController = TextEditingController();
    final shortNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Department Name'),
              ),
              TextField(
                controller: shortNameController,
                decoration: const InputDecoration(labelText: 'Short Name (e.g., CSE)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    shortNameController.text.isNotEmpty) {
                  
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    final institutionId = await SessionManager.getInstitutionId();
                    if (institutionId == null) {
                      messenger.showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Error: Could not determine institution ID.')),
                      );
                      return;
                    }

                    final response = await http.post(
                      Uri.parse(
                          '${ApiConfig.baseUrl}/$institutionId/api/departments'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'name': nameController.text,
                        'shortName': shortNameController.text,
                      }),
                    );

                    if (response.statusCode == 200) {
                      navigator.pop();
                      setState(() {
                        _departmentsFuture = _fetchDepartments();
                      });
                      messenger.showSnackBar(
                        const SnackBar(
                            content: Text('Department added successfully!')),
                      );
                    } else {
                      throw Exception('Failed to add department');
                    }
                  } catch (e) {
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteDepartment(String departmentId) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this department?'),
            actions: [
               TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                child: const Text('Delete'),
                onPressed: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final institutionId = await SessionManager.getInstitutionId();
                     if (institutionId == null) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Error: Could not determine institution ID.')),
                        );
                        return;
                      }
                    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments/$departmentId'));
                    if (response.statusCode == 200) {
                      navigator.pop();
                      setState(() {
                        _departmentsFuture = _fetchDepartments();
                      });
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Department deleted successfully!')),
                      );
                    } else {
                      throw Exception('Failed to delete department');
                    }
                  } catch (e) {
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
              )
            ],
          );
        });
  }

  void _addHoliday() {
    // Placeholder for adding a holiday
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Institution Setup'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'Core Institution Profile'),
          _buildProfileCard(),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Academic Structure'),
          _buildAcademicStructureCard(),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'User & Attendance Policy'),
          _buildPolicyCard(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings Saved (Hardcoded)')),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Institution Name')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Contact Email')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Primary Theme Color'),
              trailing: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 15,
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Institution Logo'),
              trailing: const Icon(Icons.upload_file),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicStructureCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _academicYearStartController,
              decoration: const InputDecoration(labelText: 'Academic Year Start'),
              readOnly: true,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _academicYearEndController,
              decoration: const InputDecoration(labelText: 'Academic Year End'),
              readOnly: true,
              onTap: () {},
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Department>>(
              future: _departmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildChipList(
                    'Departments',
                    [],
                    Icons.school_outlined,
                    onAdd: _addDepartment,
                    onDelete: (id) => _deleteDepartment(id),
                    isDepartment: true,
                  );
                }

                final departments = snapshot.data!;
                return _buildChipList(
                  'Departments',
                  departments,
                  Icons.school_outlined,
                  onAdd: _addDepartment,
                  onDelete: (id) => _deleteDepartment(id),
                  isDepartment: true,
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Working Days', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _workingDays.keys.map((day) {
                return ChoiceChip(
                  label: Text(day.substring(0, 3)),
                  selected: _workingDays[day]!,
                  onSelected: (isSelected) {
                    setState(() {
                      _workingDays[day] = isSelected;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _buildChipList(
              'Holidays',
              _holidays,
              Icons.calendar_today,
              onAdd: _addHoliday,
              onDelete: (item) => setState(() => _holidays.remove(item)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipList(
    String title,
    List<dynamic> items,
    IconData icon, {
    required VoidCallback onAdd,
    required void Function(String) onDelete,
    bool isDepartment = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: items.map((item) {
            final String name = isDepartment ? (item as Department).name : item as String;
            final String id = isDepartment ? (item as Department).id : item as String;
            final chip = Chip(
              avatar: CircleAvatar(child: Icon(icon, size: 16)),
              label: Text(name),
              onDeleted: () => onDelete(id),
              deleteIcon: const Icon(Icons.cancel, size: 18),
            );

            if (isDepartment) {
              return InkWell(
                onTap: () async {
                  final institutionId = await SessionManager.getInstitutionId();
                  if (!mounted) return;
                  if (institutionId != null) {
                    context.go('/$institutionId/admin/institution-settings/$name');
                  }
                },
                child: chip,
              );
            }
            return chip;
          }).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _academicYearStartController.dispose();
    _academicYearEndController.dispose();
    super.dispose();
  }
}
