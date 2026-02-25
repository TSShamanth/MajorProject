import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../services/session_manager.dart';

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
    setState(() {
      _institutionId = institutionId;
    });
    if (_institutionId != null) {
      _fetchDepartments();
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      setState(() {
        _availableDepartments = departments;
      });
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
        const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Colors.green),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed or was cancelled.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleUpdateUser() async {
    if (_formKey.currentState!.validate()) {
      if (_institutionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not determine institution. Please log in again.'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      setState(() {
        _isLoading = true;
      });

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

        if (!mounted) return;

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully!'), backgroundColor: Colors.green),
          );
          // Go back to the user details screen and refresh (if possible)
          context.pop(true); // Pop with a result to indicate success
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _pickedImageBytes != null
                          ? MemoryImage(_pickedImageBytes!)
                          : (_photoUrl != null ? NetworkImage(_photoUrl!) : null) as ImageProvider?,
                      child: _pickedImageBytes == null && _photoUrl == null
                          ? const Icon(Icons.person_outline, size: 50, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                          onPressed: _pickAndUploadImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: _inputDecoration('Role', Icons.school_outlined),
                items: ['student', 'faculty', 'admin', 'placements'].map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role.substring(0, 1).toUpperCase() + role.substring(1)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a role' : null,
              ),
              const SizedBox(height: 16),
              if (_availableDepartments.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedDepartmentId,
                  decoration: _inputDecoration('Department', Icons.business_outlined),
                  items: _availableDepartments.map((dept) {
                    return DropdownMenuItem<String>(
                      value: dept.id,
                      child: Text(dept.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedDepartmentId = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              _buildTextField(_displayNameController, 'Display Name', Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', Icons.email_outlined, readOnly: true), // Email usually not editable
              const SizedBox(height: 16),
              if (_selectedRole == 'student') ...[
                _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_usnController, 'USN', Icons.confirmation_number_outlined),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_semController, 'Semester', Icons.format_list_numbered_outlined)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_mentorController, 'Mentor Name', Icons.supervisor_account_outlined)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(_programmeController, 'Programme', Icons.class_outlined),
                const SizedBox(height: 16),
                _buildTextField(_schoolController, 'School', Icons.school_outlined),
                const SizedBox(height: 16),
                _buildTextField(_addressController, 'Address', Icons.home_outlined),
                const SizedBox(height: 16),
                _buildTextField(_dobController, 'Date of Birth', Icons.cake_outlined),
                const SizedBox(height: 16),
                _buildTextField(_bloodGroupController, 'Blood Group', Icons.bloodtype_outlined),
                const SizedBox(height: 16),
                _buildTextField(_emergencyContactController, 'Emergency Contact', Icons.contact_phone_outlined),
                const SizedBox(height: 16),
                _buildTextField(_validUptoController, 'Valid Upto', Icons.date_range_outlined),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleUpdateUser,
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.save_outlined, color: Colors.white),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: _inputDecoration(label, icon),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a $label';
        }
        if (label == 'Email' && !value.contains('@') && !readOnly) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}