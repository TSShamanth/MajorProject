import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../services/session_manager.dart';
import '../widgets/admin_layout.dart';

class EditUserDetailsScreen extends StatefulWidget {
  final UserModel user;

  const EditUserDetailsScreen({super.key, required this.user});

  @override
  State<EditUserDetailsScreen> createState() => _EditUserDetailsScreenState();
}

class _EditUserDetailsScreenState extends State<EditUserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
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
  String? _selectedDepartmentId;
  List<Department> _availableDepartments = [];
  bool _isLoading = false;
  Uint8List? _pickedImageBytes;
  String? _photoUrl;
  String? _institutionId;
  bool _isDarkMode = false;

  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _fetchInstitutionId();
    _initializeControllers();
    _selectedRole = widget.user.role;
    _selectedDepartmentId = widget.user.departmentId;
    _photoUrl = widget.user.photoUrl;
  }

  void _initializeControllers() {
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
    _nameController = TextEditingController(text: widget.user.name);
    _usnController = TextEditingController(text: widget.user.usn);
    _phoneController = TextEditingController(text: widget.user.phone);
    _semController = TextEditingController(text: widget.user.sem);
    _mentorController = TextEditingController(text: widget.user.mentorName);
    _programmeController = TextEditingController(text: widget.user.programme);
    _schoolController = TextEditingController(text: widget.user.school);
    _addressController = TextEditingController(text: widget.user.address);
    _dobController = TextEditingController(text: widget.user.dob);
    _bloodGroupController = TextEditingController(text: widget.user.bloodGroup);
    _emergencyContactController = TextEditingController(text: widget.user.emergencyContact);
    _validUptoController = TextEditingController(text: widget.user.validUpto);
  }

  Future<void> _fetchInstitutionId() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (mounted) setState(() => _institutionId = institutionId);
    if (institutionId != null) _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      if (mounted) setState(() => _availableDepartments = departments);
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _handleUpdateUser() async {
    if (_formKey.currentState!.validate()) {
      if (_institutionId == null) return;
      setState(() => _isLoading = true);

      try {
        final response = await _apiService.updateUser(
          uid: widget.user.uid,
          email: _emailController.text,
          displayName: _displayNameController.text,
          role: _selectedRole!,
          institutionId: _institutionId!,
          name: _nameController.text,
          usn: _usnController.text,
          phone: _phoneController.text,
          sem: _semController.text,
          mentorName: _mentorController.text,
          photoUrl: _photoUrl,
          programme: _programmeController.text,
          school: _schoolController.text,
          address: _addressController.text,
          dob: _dobController.text,
          bloodGroup: _bloodGroupController.text,
          emergencyContact: _emergencyContactController.text,
          validUpto: _validUptoController.text,
          departmentId: _selectedDepartmentId,
        );

        if (mounted) {
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User updated successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
            );
            context.pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${response.body}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Edit User',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/user-management'),
          child: Text('User Management', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/users/details/${widget.user.uid}'),
          child: Text('Profile', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Edit', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textPrimary, textSecondary),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide) ...[
                        Expanded(flex: 1, child: _buildPhotoSection(textPrimary, textSecondary)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildFormSections(textPrimary, textSecondary)),
                      ] else ...[
                        Expanded(
                          child: Column(
                            children: [
                              _buildPhotoSection(textPrimary, textSecondary),
                              const SizedBox(height: 24),
                              _buildFormSections(textPrimary, textSecondary),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit User Profile',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text('Modify account details and institutional assignments', style: TextStyle(fontSize: 14, color: textSecondary)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleUpdateUser,
          icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                backgroundImage: _pickedImageBytes != null
                    ? MemoryImage(_pickedImageBytes!)
                    : (_photoUrl != null ? NetworkImage(_photoUrl!) : null) as ImageProvider?,
                child: _pickedImageBytes == null && _photoUrl == null
                    ? Icon(widget.user.role == 'student' ? Icons.school_rounded : Icons.person_rounded, size: 60, color: const Color(0xFF4F46E5))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: const Color(0xFF4F46E5),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    onPressed: _pickAndUploadImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 4),
          Text('Allowed: JPG, PNG (Max 5MB)', style: TextStyle(fontSize: 12, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFormSections(Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        _buildSectionCard(
          'Account Role & Department',
          Icons.admin_panel_settings_rounded,
          const Color(0xFF4F46E5),
          [
            DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              style: TextStyle(color: textPrimary, fontSize: 15),
              decoration: _inputDecoration('Role', Icons.badge_rounded),
              items: ['student', 'faculty', 'admin', 'placements'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => _selectedRole = val),
            ),
            const SizedBox(height: 20),
            if (_availableDepartments.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedDepartmentId,
                dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                style: TextStyle(color: textPrimary, fontSize: 15),
                decoration: _inputDecoration('Department', Icons.business_rounded),
                items: _availableDepartments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                onChanged: (val) => setState(() => _selectedDepartmentId = val),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          'Personal Details',
          Icons.person_rounded,
          const Color(0xFF10B981),
          [
            _buildTextField(_displayNameController, 'Display Name', Icons.account_circle_rounded),
            const SizedBox(height: 20),
            _buildTextField(_emailController, 'Email Address', Icons.email_rounded, readOnly: true),
            const SizedBox(height: 20),
            _buildTextField(_phoneController, 'Phone Number', Icons.phone_rounded),
          ],
        ),
        if (_selectedRole == 'student') ...[
          const SizedBox(height: 24),
          _buildSectionCard(
            'Academic Records',
            Icons.school_rounded,
            const Color(0xFFF59E0B),
            [
              Row(
                children: [
                  Expanded(child: _buildTextField(_usnController, 'USN / ID', Icons.tag_rounded)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildTextField(_semController, 'Semester', Icons.format_list_numbered_rounded)),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(_programmeController, 'Programme', Icons.book_rounded),
              const SizedBox(height: 20),
              _buildTextField(_mentorController, 'Mentor Name', Icons.person_pin_rounded),
            ],
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
                const SizedBox(width: 16),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 15),
      decoration: _inputDecoration(label, icon),
      validator: (v) => v!.isEmpty ? '$label is required' : null,
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
