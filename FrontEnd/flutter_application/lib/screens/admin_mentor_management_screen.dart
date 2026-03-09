import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../services/session_manager.dart';
import '../services/api_service.dart';
import '../services/mentorship_service.dart';
import '../widgets/admin_layout.dart';

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
  bool _isDarkMode = false;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAssignment() async {
    if (_selectedMentorId == null || _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a mentor and at least one student'), behavior: SnackBarBehavior.floating));
      return;
    }

    if (!mounted) return;
    setState(() => _isAssigning = true);
    try {
      await _mentorshipService.assignMentor(_institutionId!, _selectedMentorId!, _selectedStudentIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students assigned successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        setState(() {
          _selectedStudentIds.clear();
          _isAssigning = false;
        });
        _fetchStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
        setState(() => _isAssigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    if (_isLoading && _departments.isEmpty) {
      return const AdminLayout(title: 'Mentor Management', child: Center(child: CircularProgressIndicator()));
    }

    return AdminLayout(
      title: 'Mentor Management',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Mentor Management', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mentorship Oversight',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connect students with faculty for structured guidance and support.',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _initData,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Meetings', _stats['totalMeetings'].toString(), Icons.event_available_rounded, const Color(0xFF4F46E5))),
                const SizedBox(width: 24),
                Expanded(child: _buildStatCard('Active Concerns', _stats['activeConcerns'].toString(), Icons.warning_amber_rounded, const Color(0xFFEF4444))),
                if (MediaQuery.of(context).size.width > 1200) ...[
                  const SizedBox(width: 24),
                  Expanded(child: _buildStatCard('Faculty Mentors', _professors.length.toString(), Icons.supervisor_account_rounded, const Color(0xFF10B981))),
                  const SizedBox(width: 24),
                  Expanded(child: _buildStatCard('Total Students', '...', Icons.school_rounded, const Color(0xFFF59E0B))),
                ],
              ],
            ),
            
            const SizedBox(height: 32),
            
            _buildAssignmentSection(textPrimary, textSecondary),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentSection(Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bulk Mentor Assignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                      Text('Select a group of students and assign them to a faculty mentor', style: TextStyle(fontSize: 13, color: textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Step 1: Filter Student Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(child: _buildDepartmentDropdown()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSemesterDropdown()),
                        ],
                      )
                    else ...[
                      _buildDepartmentDropdown(),
                      const SizedBox(height: 16),
                      _buildSemesterDropdown(),
                    ],
                    
                    const SizedBox(height: 32),
                    Text('Step 2: Select Faculty Mentor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                    const SizedBox(height: 16),
                    _buildMentorDropdown(),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Step 3: Select Students (${_students.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                        if (_students.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedStudentIds.length == _students.length) {
                                  _selectedStudentIds.clear();
                                } else {
                                  _selectedStudentIds.clear();
                                  _selectedStudentIds.addAll(_students.map((s) => s.uid));
                                }
                              });
                            },
                            child: Text(_selectedStudentIds.length == _students.length ? 'Deselect All' : 'Select All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : (_students.isEmpty 
                          ? Center(child: Text('No students match current filters', style: TextStyle(color: textSecondary)))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _students.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: borderColor.withOpacity(0.5)),
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final isSelected = _selectedStudentIds.contains(student.uid);
                                return CheckboxListTile(
                                  title: Text(student.displayName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                                  subtitle: Text(student.usn ?? student.email ?? '', style: TextStyle(fontSize: 12, color: textSecondary)),
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
                            )),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Department', Icons.business_rounded),
      value: _selectedDepartmentId,
      dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1F2937), fontSize: 14),
      items: _departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
      onChanged: (val) {
        setState(() => _selectedDepartmentId = val);
        _fetchStudents();
      },
    );
  }

  Widget _buildSemesterDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Semester', Icons.format_list_numbered_rounded),
      value: _selectedSemester,
      dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1F2937), fontSize: 14),
      items: List.generate(8, (i) => (i + 1).toString()).map((s) => DropdownMenuItem(value: s, child: Text('Semester $s'))).toList(),
      onChanged: (val) {
        setState(() => _selectedSemester = val);
        _fetchStudents();
      },
    );
  }

  Widget _buildMentorDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Faculty Mentor', Icons.person_search_rounded),
      value: _selectedMentorId,
      dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1F2937), fontSize: 14),
      items: _professors.map((p) => DropdownMenuItem(value: p.uid, child: Text(p.displayName))).toList(),
      onChanged: (val) => setState(() => _selectedMentorId = val),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5).withOpacity(0.7), size: 20),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
