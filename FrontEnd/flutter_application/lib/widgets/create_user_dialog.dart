import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../services/session_manager.dart';
import '../models/department_model.dart';
import '../models/section_model.dart';

class CreateUserDialog extends StatefulWidget {
  final String? initialRole;
  final VoidCallback? onSuccess;

  const CreateUserDialog({
    super.key,
    this.initialRole,
    this.onSuccess,
  });

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _displayNameController;
  late TextEditingController _nameController;
  late TextEditingController _usnController;
  late TextEditingController _phoneController;
  late TextEditingController _semController;
  late TextEditingController _mentorController;
  late TextEditingController _programmeController;
  late TextEditingController _schoolController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _validUptoController;

  String? _selectedRole;
  String? _institutionId;
  String? _selectedDepartmentForStudent;
  String? _selectedDepartmentForFaculty;
  String? _selectedSectionId;
  String? _photoUrl;
  Uint8List? _pickedImageBytes;
  bool _isLoading = false;
  bool _isLoadingDepartments = false;
  List<Department> _departments = [];
  List<Section> _sections = [];
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'student';
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _displayNameController = TextEditingController();
    _nameController = TextEditingController();
    _usnController = TextEditingController();
    _phoneController = TextEditingController();
    _semController = TextEditingController();
    _mentorController = TextEditingController();
    _programmeController = TextEditingController();
    _schoolController = TextEditingController();
    _addressController = TextEditingController();
    _dobController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _validUptoController = TextEditingController();

    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      _fetchDepartments();
    }
  }

  Future<void> _fetchDepartments() async {
    setState(() => _isLoadingDepartments = true);
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      setState(() => _departments = departments);
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    } finally {
      setState(() => _isLoadingDepartments = false);
    }
  }

  Future<void> _fetchSections(String departmentId) async {
    try {
      final sections = await _apiService.getSections(_institutionId!, departmentId);
      setState(() => _sections = sections);
    } catch (e) {
      debugPrint('Error fetching sections: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _nameController.dispose();
    _usnController.dispose();
    _phoneController.dispose();
    _semController.dispose();
    _mentorController.dispose();
    _programmeController.dispose();
    _schoolController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _bloodGroupController.dispose();
    _emergencyContactController.dispose();
    _validUptoController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final result = await _imageService.pickAndUploadImage();
    if (result != null) {
      setState(() {
        _photoUrl = result['downloadUrl'];
        _pickedImageBytes = result['imageBytes'];
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 14, color: _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5), size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: _inputDecoration(label, icon),
      style: TextStyle(fontSize: 15, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a $label';
        if (label == 'Email' && !value.contains('@')) return 'Please enter a valid email';
        if (label == 'Password' && value.length < 6) return 'Password must be at least 6 characters long';
        return null;
      },
    );
  }

  Future<void> _handleCreateUser() async {
    if (_formKey.currentState!.validate()) {
      if (_institutionId == null) return;
      setState(() => _isLoading = true);

      try {
        final response = await _apiService.createUser(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _displayNameController.text,
          role: _selectedRole!,
          institutionId: _institutionId!,
          name: _nameController.text,
          usn: _usnController.text,
          phone: _phoneController.text,
          sem: _semController.text,
          departmentId: _selectedRole == 'student' ? _selectedDepartmentForStudent : (_selectedRole == 'faculty' ? _selectedDepartmentForFaculty : null),
          sectionId: _selectedRole == 'student' ? _selectedSectionId : null,
          mentorName: _mentorController.text,
          photoUrl: _photoUrl,
          programme: _programmeController.text,
          school: _schoolController.text,
          address: _addressController.text,
          dob: _dobController.text,
          bloodGroup: _bloodGroupController.text,
          emergencyContact: _emergencyContactController.text,
          validUpto: _validUptoController.text,
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User created successfully!'), backgroundColor: Colors.green),
          );
          if (widget.onSuccess != null) widget.onSuccess!();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.body}'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF4F46E5), size: 22),
          ),
          const SizedBox(width: 16),
          Text(
            'Create New User',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFFEEF2FF),
                          backgroundImage: _pickedImageBytes != null ? MemoryImage(_pickedImageBytes!) : null,
                          child: _pickedImageBytes == null
                              ? const Icon(Icons.person_outline_rounded, size: 56, color: Color(0xFF4F46E5))
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF4F46E5),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                            onPressed: _pickAndUploadImage,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: _inputDecoration('Role', Icons.school_rounded),
                  dropdownColor: _isDarkMode ? const Color(0xFF374151) : Colors.white,
                  style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
                  items: [
                    'student',
                    'faculty',
                    'admin',
                    'placements',
                    'exam_admin',
                    'finance_admin',
                    'hr_admin',
                    'admission_admin'
                  ].map((String role) {
                    String label = role.replaceAll('_', ' ');
                    label = label.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedRole = newValue),
                  validator: (value) => value == null ? 'Please select a role' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(_displayNameController, 'Display Name', Icons.badge_rounded),
                const SizedBox(height: 20),
                _buildTextField(_emailController, 'Email', Icons.email_rounded),
                const SizedBox(height: 20),
                _buildTextField(_passwordController, 'Password', Icons.lock_rounded, obscureText: true),
                
                if (['admin', 'placements', 'exam_admin', 'finance_admin', 'hr_admin', 'admission_admin'].contains(_selectedRole)) ...[
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, 'Full Name', Icons.person_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_phoneController, 'Phone Number', Icons.phone_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_schoolController, 'School', Icons.school_rounded),
                ],
                
                if (_selectedRole == 'student') ...[
                  const SizedBox(height: 20),
                  _isLoadingDepartments
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          value: _selectedDepartmentForStudent,
                          decoration: _inputDecoration('Department', Icons.business_rounded),
                          dropdownColor: _isDarkMode ? const Color(0xFF374151) : Colors.white,
                          items: _departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedDepartmentForStudent = val;
                              _selectedSectionId = null;
                              _sections = [];
                            });
                            if (val != null) _fetchSections(val);
                          },
                          validator: (value) => value == null ? 'Please select a department' : null,
                        ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedSectionId,
                    decoration: _inputDecoration('Section', Icons.group_work_rounded),
                    dropdownColor: _isDarkMode ? const Color(0xFF374151) : Colors.white,
                    items: _sections.where((s) => s.id != null).map((s) => DropdownMenuItem(value: s.id!, child: Text(s.name))).toList(),
                    onChanged: (val) => setState(() => _selectedSectionId = val),
                    validator: (value) => value == null ? 'Please select a section' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, 'Full Name', Icons.person_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_usnController, 'USN', Icons.confirmation_number_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_phoneController, 'Phone Number', Icons.phone_rounded),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_semController, 'Semester', Icons.format_list_numbered_rounded)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTextField(_mentorController, 'Mentor Name', Icons.supervisor_account_rounded)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_programmeController, 'Programme', Icons.class_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_schoolController, 'School', Icons.school_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_addressController, 'Address', Icons.home_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_dobController, 'Date of Birth', Icons.cake_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_bloodGroupController, 'Blood Group', Icons.bloodtype_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_emergencyContactController, 'Emergency Contact', Icons.contact_phone_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(_validUptoController, 'Valid Upto', Icons.date_range_rounded),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _handleCreateUser,
          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.check_circle_rounded, size: 20),
          label: _isLoading 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Create User', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 0,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
    );
  }
}
