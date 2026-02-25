import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import '../../services/api_service.dart';
import '../../models/leave_application_model.dart';
import '../../models/professor_model.dart';

class StudentLeaveScreen extends StatefulWidget {
  static const String routeName = '/student/leave';

  const StudentLeaveScreen({super.key});

  @override
  State<StudentLeaveScreen> createState() => _StudentLeaveScreenState();
}

class _StudentLeaveScreenState extends State<StudentLeaveScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String? _selectedLeaveType;
  String? _selectedProfessorUid;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  PlatformFile? _selectedFile; // State for selected file

  Future<List<String>>? _leaveTypesFuture;
  Future<List<ProfessorDto>>? _professorsFuture;
  Future<List<LeaveApplication>>? _leaveHistoryFuture;
  late TabController _tabController;
  String _sortOption = 'Newest';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _tabController = TabController(length: 4, vsync: this);
  }

  Widget _buildLeaveList(List<LeaveApplication> leaves) {
    if (leaves.isEmpty) {
      return const Center(child: Text('No leaves in this category.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leave = leaves[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      leave.leaveType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    Chip(
                      label: Text(
                        leave.status,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(leave.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  '${DateFormat.yMMMd().format(leave.startDate)} - ${DateFormat.yMMMd().format(leave.endDate)}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(leave.reason),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16.0, color: Colors.grey),
                    const SizedBox(width: 4.0),
                    Text('Professor: ${leave.professor}'),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _fetchInitialData() {
    _leaveTypesFuture = _apiService.getLeaveTypes();
    _professorsFuture = _apiService.getProfessors();
    _leaveHistoryFuture = _apiService.getLeaveHistory();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = _startDate; // Ensure end date is not before start date
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate; // Ensure start date is not after end date
          }
        }
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Allow custom file types
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'], // Specify allowed extensions
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    } else {
      // User canceled the picker
      setState(() {
        _selectedFile = null;
      });
    }
  }

  void _submitLeaveApplication() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both start and end dates.')),
        );
        return;
      }
      if (_selectedProfessorUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a professor.')),
        );
        return;
      }

      try {
        final response = await _apiService.applyLeave(
          leaveType: _selectedLeaveType!,
          startDate: _startDate!,
          endDate: _endDate!,
          reason: _reasonController.text,
          professor: _selectedProfessorUid!,
          file: _selectedFile, // Pass the selected file
        );

        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave application submitted successfully!')),
          );
          _clearForm();
          setState(() {
            _leaveHistoryFuture = _apiService.getLeaveHistory(); // Refresh history
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit leave: ${response.body}')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting leave: $e')),
        );
      }
    }
  }

  void _clearForm() {
    setState(() {
      _selectedLeaveType = null;
      _selectedProfessorUid = null;
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
      _selectedFile = null; // Clear selected file
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApplyLeaveSection(),
            const SizedBox(height: 32),
            _buildLeaveHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyLeaveSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16), // Added margin
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply for Leave',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold), // Improved heading style
              ),
              const SizedBox(height: 24), // Increased spacing
              FutureBuilder<List<String>>(
                future: _leaveTypesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error loading leave types: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No leave types available.');
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Leave Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Adjusted padding
                    ),
                    value: _selectedLeaveType,
                    hint: const Text('Select Leave Type'),
                    items: snapshot.data!.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLeaveType = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a leave type' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Adjusted padding
                        ),
                        child: Text(
                          _startDate == null
                              ? 'Select Date'
                              : DateFormat('dd/MM/yyyy').format(_startDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Adjusted padding
                        ),
                        child: Text(
                          _endDate == null
                              ? 'Select Date'
                              : DateFormat('dd/MM/yyyy').format(_endDate!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Adjusted padding
                ),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a reason' : null,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<ProfessorDto>>(
                future: _professorsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error loading professors: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No professors available.');
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Professor to notify',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Adjusted padding
                    ),
                    value: _selectedProfessorUid,
                    hint: const Text('Select Professor'),
                    items: snapshot.data!.map((professor) {
                      return DropdownMenuItem<String>(
                        value: professor.uid,
                        child: Text(professor.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProfessorUid = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a professor' : null,
                  );
                },
              ),
              const SizedBox(height: 16), // Spacing before file picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Attach Document (PDF, Image, Doc)'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40), // Full width button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (_selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Selected file: ${_selectedFile!.name}',
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'No file selected',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24), // Increased spacing before submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitLeaveApplication,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14), // Adjusted padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Leave Application',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Improved text style
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveHistorySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leave History',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Pending'),
                      Tab(text: 'Approved'),
                      Tab(text: 'Rejected'),
                    ],
                    labelColor: const Color(0xFF4F46E5),
                    unselectedLabelColor: const Color(0xFF64748B),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _sortOption,
                  items: const [
                    DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                    DropdownMenuItem(value: 'Leave Type', child: Text('Leave Type')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _sortOption = v;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 400,
              child: FutureBuilder<List<LeaveApplication>>(
                future: _leaveHistoryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No leave history found.'));
                  }

                  final all = List<LeaveApplication>.from(snapshot.data!);
                  final pending = all.where((l) => l.status.toLowerCase() == 'pending').toList();
                  final approved = all.where((l) => l.status.toLowerCase() == 'approved').toList();
                  final rejected = all.where((l) => l.status.toLowerCase() == 'rejected').toList();
                  _applySort(all);
                  _applySort(pending);
                  _applySort(approved);
                  _applySort(rejected);

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLeaveList(all),
                      _buildLeaveList(pending),
                      _buildLeaveList(approved),
                      _buildLeaveList(rejected),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applySort(List<LeaveApplication> leaves) {
    switch (_sortOption) {
      case 'Newest':
        leaves.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      case 'Oldest':
        leaves.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
        break;
      case 'Leave Type':
        leaves.sort((a, b) => a.leaveType.compareTo(b.leaveType));
        break;
      default:
        break;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
