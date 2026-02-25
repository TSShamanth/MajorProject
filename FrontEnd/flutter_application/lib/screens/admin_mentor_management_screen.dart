import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../services/session_manager.dart';
import '../services/api_service.dart';
import '../services/mentorship_service.dart';

class AdminMentorManagementScreen extends StatefulWidget {
  const AdminMentorManagementScreen({super.key});

  @override
  State<AdminMentorManagementScreen> createState() => _AdminMentorManagementScreenState();
}

class _AdminMentorManagementScreenState extends State<AdminMentorManagementScreen> {
  final ApiService _apiService = ApiService();
  final MentorshipService _mentorshipService = MentorshipService();

  String? _institutionId;
  
  List<Department> _departments = [];
  List<UserModel> _professors = [];
  List<UserModel> _students = [];
  
  String? _selectedDepartmentId;
  String? _selectedSemester;
  String? _selectedMentorId;
  final List<String> _selectedStudentIds = [];

  bool _isLoading = true;
  bool _isAssigning = false;

  Map<String, dynamic> _stats = {'totalMeetings': 0, 'activeConcerns': 0};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final id = await SessionManager.getInstitutionId();
    if (mounted) {
      setState(() {
        _institutionId = id;
      });
    }
    if (id != null) {
      await _fetchInitialLists();
      await _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _mentorshipService.getMentorshipStats(_institutionId!);
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<void> _fetchInitialLists() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      final allUsers = await _apiService.getUsers(_institutionId!);
      
      if (mounted) {
        setState(() {
          _departments = departments;
          _professors = allUsers.where((u) => u.role == 'faculty').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchStudents() async {
    if (_selectedDepartmentId == null || _selectedSemester == null) return;
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final allUsers = await _apiService.getUsers(_institutionId!);
      if (mounted) {
        setState(() {
          _students = allUsers.where((u) => 
            u.role == 'student' && 
            u.departmentId == _selectedDepartmentId && 
            u.sem == _selectedSemester
          ).toList();
          _selectedStudentIds.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAssignment() async {
    if (_selectedMentorId == null || _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a mentor and at least one student')));
      return;
    }

    if (!mounted) return;
    setState(() => _isAssigning = true);
    try {
      await _mentorshipService.assignMentor(_institutionId!, _selectedMentorId!, _selectedStudentIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students assigned successfully!'), backgroundColor: Colors.green));
        setState(() {
          _selectedStudentIds.clear();
          _isAssigning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        setState(() => _isAssigning = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5), size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _departments.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mentor Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF4F46E5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign Mentors',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect students with faculty for structured guidance.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildMentorshipStats(),
                    const SizedBox(height: 20),
                    _buildAssignmentSection(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorshipStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Total Meetings', _stats['totalMeetings'].toString(), Icons.event_available, Colors.indigo)),
          Container(width: 1, height: 40, color: Colors.grey.shade100),
          Expanded(child: _buildStatItem('Active Concerns', _stats['activeConcerns'].toString(), Icons.warning_amber_rounded, Colors.pink)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _buildAssignmentSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('1', 'Filter Student Group'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildDepartmentDropdown()),
              const SizedBox(width: 16),
              Expanded(child: _buildSemesterDropdown()),
            ],
          ),
          const SizedBox(height: 32),
          _buildStepHeader('2', 'Select Faculty Mentor'),
          const SizedBox(height: 20),
          _buildMentorDropdown(),
          const SizedBox(height: 32),
          _buildStepHeader('3', 'Select Students (${_students.length})'),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: _students.isEmpty 
              ? const Center(child: Text('No students match filters', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  itemCount: _students.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final isSelected = _selectedStudentIds.contains(student.uid);
                    return CheckboxListTile(
                      title: Text(student.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(student.usn ?? '', style: const TextStyle(fontSize: 12)),
                      value: isSelected,
                      activeColor: const Color(0xFF4F46E5),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedStudentIds.add(student.uid);
                          } else {
                            _selectedStudentIds.remove(student.uid);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isAssigning ? null : _handleAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isAssigning 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm Assignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
          child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Department', Icons.business),
      value: _selectedDepartmentId,
      items: _departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (val) {
        setState(() => _selectedDepartmentId = val);
        _fetchStudents();
      },
    );
  }

  Widget _buildSemesterDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Semester', Icons.format_list_numbered),
      value: _selectedSemester,
      items: List.generate(8, (i) => (i + 1).toString()).map((s) => DropdownMenuItem(value: s, child: Text('Sem $s', style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (val) {
        setState(() => _selectedSemester = val);
        _fetchStudents();
      },
    );
  }

  Widget _buildMentorDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Faculty Mentor', Icons.person_search),
      value: _selectedMentorId,
      items: _professors.map((p) => DropdownMenuItem(value: p.uid, child: Text(p.displayName, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (val) => setState(() => _selectedMentorId = val),
    );
  }
}
