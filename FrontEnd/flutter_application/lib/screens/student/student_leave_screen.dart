import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../models/leave_application_model.dart';
import '../../models/professor_model.dart';
import '../../widgets/student_layout.dart';

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
  PlatformFile? _selectedFile;

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
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
          file: _selectedFile,
        );

        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave application submitted successfully!'), backgroundColor: Colors.green),
          );
          _clearForm();
          setState(() {
            _leaveHistoryFuture = _apiService.getLeaveHistory();
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
      _selectedFile = null;
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
    return StudentLayout(
      title: 'Leave Management',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Leave', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1024) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildApplyLeaveSection()),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: _buildLeaveHistorySection()),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildApplyLeaveSection(),
                    const SizedBox(height: 32),
                    _buildLeaveHistorySection(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leave Requests',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Apply for new leave and track your previous requests',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildApplyLeaveSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Application', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            const SizedBox(height: 24),
            _buildDropdownField('Leave Type', _leaveTypesFuture),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDatePicker('Start Date', true)),
                const SizedBox(width: 16),
                Expanded(child: _buildDatePicker('End Date', false)),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfessorDropdown(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for Leave',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
              ),
              validator: (v) => v!.isEmpty ? 'Please enter a reason' : null,
            ),
            const SizedBox(height: 16),
            _buildFilePicker(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitLeaveApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Submit Application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, Future<List<String>>? future) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (context, snapshot) {
        return DropdownButtonFormField<String>(
          value: _selectedLeaveType,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          ),
          items: snapshot.data?.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList() ?? [],
          onChanged: (v) => setState(() => _selectedLeaveType = v),
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildProfessorDropdown() {
    return FutureBuilder<List<ProfessorDto>>(
      future: _professorsFuture,
      builder: (context, snapshot) {
        return DropdownButtonFormField<String>(
          value: _selectedProfessorUid,
          decoration: InputDecoration(
            labelText: 'Notifying Professor',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          ),
          items: snapshot.data?.map((p) => DropdownMenuItem(value: p.uid, child: Text(p.displayName))).toList() ?? [],
          onChanged: (v) => setState(() => _selectedProfessorUid = v),
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildDatePicker(String label, bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date == null ? 'Select' : DateFormat('dd MMM yyyy').format(date), 
              style: TextStyle(fontSize: 13, color: date == null ? Colors.grey[600] : const Color(0xFF1F2937))),
            Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedFile?.name ?? 'Attach supporting document',
                style: TextStyle(color: _selectedFile == null ? Colors.grey[600] : const Color(0xFF1F2937), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedFile != null)
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _selectedFile = null)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Leave History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                _buildSortDropdown(),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF4F46E5),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF4F46E5),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.grey.shade100,
            tabs: const [
              Tab(text: 'All Requests'),
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
          SizedBox(
            height: 600,
            child: FutureBuilder<List<LeaveApplication>>(
              future: _leaveHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                if (all.isEmpty) return _buildEmptyHistory();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaveList(all),
                    _buildLeaveList(all.where((l) => l.status.toLowerCase() == 'pending').toList()),
                    _buildLeaveList(all.where((l) => l.status.toLowerCase() == 'approved').toList()),
                    _buildLeaveList(all.where((l) => l.status.toLowerCase() == 'rejected').toList()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _sortOption,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
        items: ['Newest', 'Oldest', 'Leave Type'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _sortOption = v!),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No leave requests found', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLeaveList(List<LeaveApplication> leaves) {
    if (leaves.isEmpty) return _buildEmptyHistory();
    _applySort(leaves);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leave = leaves[index];
        final statusColor = _getStatusColor(leave.status);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(leave.leaveType, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1F2937))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(leave.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Text(leave.reason, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4)),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(radius: 10, backgroundColor: const Color(0xFFE5E7EB), child: Icon(Icons.person, size: 12, color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  Text('Mentor: ${leave.professor}', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
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
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF10B981);
      case 'pending': return const Color(0xFFF59E0B);
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }
}
