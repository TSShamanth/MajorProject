import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../services/image_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/department_model.dart'; // Import Department model

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _usnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _semController = TextEditingController();
  final _mentorController = TextEditingController();
  final _programmeController = TextEditingController();
  final _schoolController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _validUptoController = TextEditingController();

  String? _selectedRole = 'student';
  String? _selectedDepartmentForStudent; // New field
  bool _isLoading = false;
  Uint8List? _pickedImageBytes;
  String? _photoUrl;
  String? _institutionId;
  int _studentCount = 0;
  int _facultyCount = 0;
  int _adminCount = 0;
  bool _sidebarExpanded = true;
  bool _isDarkMode = false;
  late AnimationController _animationController;

  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();
  List<Department> _departments = []; // New list for departments
  bool _isLoadingDepartments = false; // New loading flag

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchInstitutionId().then((_) {
      if (_institutionId != null) {
        _fetchUsersAndCounts();
        _fetchDepartments(); // Fetch departments when institutionId is available
      }
    });
  }

  Future<void> _fetchInstitutionId() async {
    final institutionId = await SessionManager.getInstitutionId();
    setState(() {
      _institutionId = institutionId;
    });
  }

  Future<void> _fetchUsersAndCounts() async {
    if (_institutionId == null) return;
    try {
      final users = await _apiService.getUsers(_institutionId!);
      debugPrint('Fetched users count: ${users.length}');
      int studentCount = 0;
      int facultyCount = 0;
      int adminCount = 0;
      for (var user in users) {
        debugPrint('User role: ${user.role}');
        if (user.role == 'student') {
          studentCount++;
        } else if (user.role == 'faculty') {
          facultyCount++;
        } else if (user.role == 'admin') {
          adminCount++;
        }
      }
      setState(() {
        _studentCount = studentCount;
        _facultyCount = facultyCount;
        _adminCount = adminCount;
      });
    } catch (e) {
      debugPrint('Error fetching users and counts: $e');
    }
  }

  Future<void> _fetchDepartments() async {
    if (_institutionId == null) return;
    setState(() {
      _isLoadingDepartments = true;
    });
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      setState(() {
        _departments = departments;
      });
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    } finally {
      setState(() {
        _isLoadingDepartments = false;
      });
    }
  }
  @override
  void dispose() {
    _animationController.dispose();
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

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedRole = _selectedRole;
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF4F46E5),
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await _pickAndUploadImage();
                                        _showAddUserDialog();
                                      },
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: _inputDecoration('Role', Icons.school_rounded),
                          dropdownColor: _isDarkMode ? const Color(0xFF374151) : Colors.white,
                          style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
                          items: ['student', 'faculty', 'admin'].map((String role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role.substring(0, 1).toUpperCase() + role.substring(1)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setDialogState(() {
                              selectedRole = newValue;
                              _selectedRole = newValue;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a role' : null,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(_displayNameController, 'Display Name', Icons.badge_rounded),
                        const SizedBox(height: 20),
                        _buildTextField(_emailController, 'Email', Icons.email_rounded),
                        const SizedBox(height: 20),
                        _buildTextField(_passwordController, 'Password', Icons.lock_rounded, obscureText: true),
                        
                        if (selectedRole == 'student') ...[
                          const SizedBox(height: 20),
                          _isLoadingDepartments
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  value: _selectedDepartmentForStudent,
                                  decoration: _inputDecoration('Department', Icons.business_rounded),
                                  dropdownColor: _isDarkMode ? const Color(0xFF374151) : Colors.white,
                                  style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
                                  items: _departments.map((department) {
                                    return DropdownMenuItem<String>(
                                      value: department.id,
                                      child: Text(department.name),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setDialogState(() {
                                      _selectedDepartmentForStudent = newValue;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Please select a department' : null,
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
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearForm();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _handleCreateUser,
                  icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.check_circle_rounded, size: 20),
                  label: _isLoading 
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
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
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: _inputDecoration(label, icon),
      style: TextStyle(fontSize: 15, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937)),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a $label';
        }
        if (label == 'Email' && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        if (label == 'Password' && value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
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

  Future<void> _handleCreateUser() async {
    if (_formKey.currentState!.validate()) {
      if (_institutionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine institution. Please log in again.'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });

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
          departmentId: _selectedRole == 'student' ? _selectedDepartmentForStudent : null, // Pass departmentId
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
          Navigator.of(context).pop();
          _clearForm();
          _fetchUsersAndCounts();
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

  void _clearForm() {
    _displayNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _usnController.clear();
    _phoneController.clear();
    _semController.clear();
    _mentorController.clear();
    _programmeController.clear();
    _schoolController.clear();
    _addressController.clear();
    _dobController.clear();
    _bloodGroupController.clear();
    _emergencyContactController.clear();
    _validUptoController.clear();
    setState(() {
      _selectedRole = 'student';
      _pickedImageBytes = null;
      _photoUrl = null;
    });
  }

  Color get _bgColor => _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary => _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary => _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  // Color get _sidebarColor => const Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine screen breakpoints
        final isMobile = constraints.maxWidth < 768;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final isDesktop = constraints.maxWidth >= 1024;

        return Scaffold(
          backgroundColor: _bgColor,
          drawer: isMobile ? _buildMobileDrawer() : null,
          body: isMobile 
              ? _buildMobileLayout()
              : Row(
                  children: [
                    if (!isMobile) _buildModernSidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          _buildModernTopBar(isMobile: isMobile),
                          if (!isMobile) _buildBreadcrumb(),
                          Expanded(
                            child: _buildDashboardContent(
                              isMobile: isMobile,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileTopBar(),
        Expanded(
          child: _buildDashboardContent(
            isMobile: true,
            isTablet: false,
            isDesktop: false,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDrawer() {
    final menuItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': true, 'route': null},
      {'icon': Icons.people_rounded, 'label': 'User Management', 'active': false, 'route': null},
      {'icon': Icons.settings_applications_rounded, 'label': 'Institution Setup', 'active': false, 'route': '/$_institutionId/admin/institution-setup'},
      {'icon': Icons.school_rounded, 'label': 'Academic Operations', 'active': false, 'route': null},
      {'icon': Icons.business_center_rounded, 'label': 'Workforce & Placement', 'active': false, 'route': null},
      {'icon': Icons.event_rounded, 'label': 'Event Management', 'active': false, 'route': null},
      {'icon': Icons.bar_chart_rounded, 'label': 'Analytics & Reports', 'active': false, 'route': null},
      {'icon': Icons.article_rounded, 'label': 'Content Management', 'active': false, 'route': null},
      {'icon': Icons.settings_rounded, 'label': 'System Settings', 'active': false, 'route': null},
    ];

    return Drawer(
      backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode 
                    ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                    : [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF4F46E5),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'AcadWorkHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuItems.map((item) {
                final isActive = item['active'] == true;
                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isActive ? const Color(0xFF4F46E5) : _textSecondary,
                  ),
                  title: Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isActive ? const Color(0xFF4F46E5) : _textPrimary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  selected: isActive,
                  selectedTileColor: const Color(0xFF4F46E5).withOpacity(0.1),
                  onTap: () {
                    Navigator.pop(context);
                    final route = item['route'];
                    if (route != null && _institutionId != null) {
                      context.go(route as String);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_rounded, color: _textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AcadWorkHub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: _isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF4F46E5),
            ),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_rounded, color: _textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildModernSidebar() {
    final menuItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'active': true, 'route': null},
      {'icon': Icons.people_rounded, 'label': 'User Management', 'active': false, 'route': null},
      {'icon': Icons.settings_applications_rounded, 'label': 'Institution Setup', 'active': false, 'route': '/admin/institution-settings'},
      {'icon': Icons.school_rounded, 'label': 'Academic Operations', 'active': false, 'route': null},
      {'icon': Icons.approval, 'label': 'Approval', 'active': false, 'route': '/admin/approval'},
      {'icon': Icons.business_center_rounded, 'label': 'Workforce & Placement', 'active': false, 'route': null},
      {'icon': Icons.event_rounded, 'label': 'Event Management', 'active': false, 'route': null},
      {'icon': Icons.bar_chart_rounded, 'label': 'Analytics & Reports', 'active': false, 'route': null},
      {'icon': Icons.article_rounded, 'label': 'Content Management', 'active': false, 'route': null},
      {'icon': Icons.settings_rounded, 'label': 'System Settings', 'active': false, 'route': null},
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? 270 : 0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode 
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: _sidebarExpanded ? [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ] : [],
      ),
      child: _sidebarExpanded ? Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF4F46E5),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'AcadWorkHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _sidebarExpanded = false;
                      });
                    },
                    tooltip: 'Collapse sidebar',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              children: menuItems.map((item) {
                final isActive = item['active'] == true;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (item['route'] != null && _institutionId != null) {
                          context.go('/$_institutionId${item['route']}');
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? Colors.white.withOpacity(_isDarkMode ? 0.1 : 0.15) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isActive 
                              ? Border.all(
                                  color: Colors.white.withOpacity(_isDarkMode ? 0.2 : 0.3),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(isActive ? 1.0 : 0.8),
                                  fontSize: 15,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Help & Support',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Documentation',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildModernTopBar({bool isMobile = false}) {
    if (isMobile) return const SizedBox.shrink(); // Use mobile top bar instead
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
          bottom: BorderSide(color: _borderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu Toggle Button (appears when sidebar is collapsed)
          if (!_sidebarExpanded)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (_isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF4F46E5)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _sidebarExpanded = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Icon(Icons.search_rounded, color: _textSecondary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search students, courses, companies...',
                        hintStyle: TextStyle(
                          color: _textSecondary,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(color: _textPrimary, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Dark Mode Toggle
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: IconButton(
              icon: Icon(
                _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: _isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF4F46E5),
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
              tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
          ),
          const SizedBox(width: 16),

          Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications_rounded, color: _textPrimary, size: 24),
                  onPressed: () {},
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          Container(
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: _borderColor),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Center(
                    child: Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Administrator',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                PopupMenuButton(
                  icon: Icon(Icons.arrow_drop_down_rounded, color: _textSecondary, size: 26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: _cardColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.settings_rounded, size: 20, color: _textPrimary),
                          const SizedBox(width: 14),
                          Text('Settings', style: TextStyle(fontSize: 15, color: _textPrimary)),
                        ],
                      ),
                      onTap: () {},
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                          SizedBox(width: 14),
                          Text('Logout', style: TextStyle(color: Color(0xFFEF4444), fontSize: 15)),
                        ],
                      ),
                      onTap: () async {
                        final router = GoRouter.of(context);
                        await SessionManager.clearSession();
                        await AuthService.logout();
                        router.go('/login');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Home',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, size: 18, color: _textSecondary),
          const SizedBox(width: 10),
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF4F46E5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent({
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final padding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'System Overview',
              style: TextStyle(
                fontSize: isMobile ? 22 : (isTablet ? 24 : 26),
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete academic workforce and placement management',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: _textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Stats Row - Fully Responsive
            _buildResponsiveStatsRow(isMobile, isTablet),
            SizedBox(height: isMobile ? 16 : 20),

            // Main Content - Fully Responsive
            _buildResponsiveMainContent(isMobile, isTablet, isDesktop),
            SizedBox(height: isMobile ? 16 : 20),

            // Management Cards - Fully Responsive
            _buildResponsiveManagementSection(isMobile, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveStatsRow(bool isMobile, bool isTablet) {
    if (isMobile) {
      // Mobile - Responsive Grid (2 columns on wider phones)
      return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate how many columns fit (minimum card width 150px)
          final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(1, 2);
          
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _buildStatCard('Active Students', _studentCount.toString(), '298 Final Year', Icons.people_rounded, const Color(0xFF4F46E5)),
              _buildStatCard('Faculty', _facultyCount.toString(), '12 Departments', Icons.school_rounded, const Color(0xFF10B981)),
              _buildStatCard('Placement', '82%', 'Current Season', Icons.business_center_rounded, const Color(0xFF8B5CF6)),
              _buildStatCard('Actions', '12', '8 Pending', Icons.warning_rounded, const Color(0xFFF59E0B)),
            ],
          );
        },
      );
    } else if (isTablet) {
      // Tablet - 2 columns
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard('Active Students', _studentCount.toString(), '298 Final Year', Icons.people_rounded, const Color(0xFF4F46E5)),
          _buildStatCard('Faculty', _facultyCount.toString(), '12 Departments', Icons.school_rounded, const Color(0xFF10B981)),
          _buildStatCard('Placement', '82%', 'Current Season', Icons.business_center_rounded, const Color(0xFF8B5CF6)),
          _buildStatCard('Actions', '12', '8 Pending', Icons.warning_rounded, const Color(0xFFF59E0B)),
        ],
      );
    } else {
      // Desktop - 4 columns
      return Row(
        children: [
          Expanded(child: _buildStatCard('Active Students', _studentCount.toString(), '298 Final Year', Icons.people_rounded, const Color(0xFF4F46E5))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Faculty', _facultyCount.toString(), '12 Departments', Icons.school_rounded, const Color(0xFF10B981))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Placement', '82%', 'Current Season', Icons.business_center_rounded, const Color(0xFF8B5CF6))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Actions', '12', '8 Pending', Icons.warning_rounded, const Color(0xFFF59E0B))),
        ],
      );
    }
  }

  Widget _buildResponsiveMainContent(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile || isTablet) {
      // Mobile/Tablet - Single column
      return Column(
        children: [
          _buildUserManagementCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
          const SizedBox(height: 16),
          _buildSystemOverviewCard(),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
        ],
      );
    } else {
      // Desktop - Two columns
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildUserManagementCard(),
                const SizedBox(height: 16),
                _buildRecentActivityCard(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildQuickActionsCard(),
                const SizedBox(height: 16),
                _buildSystemOverviewCard(),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildResponsiveManagementSection(bool isMobile, bool isTablet) {
    if (isMobile) {
      // Mobile - Single column
      return Column(
        children: [
          _buildAcademicsCard(),
          const SizedBox(height: 12),
          _buildFinancialsCard(),
          const SizedBox(height: 12),
          _buildResourcesCard(),
          const SizedBox(height: 12),
          _buildToolsCard(),
          const SizedBox(height: 12),
          _buildCommunityCard(),
        ],
      );
    } else {
      // Tablet/Desktop - Two columns
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAcademicsCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildFinancialsCard()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildResourcesCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildToolsCard()),
            ],
          ),
          const SizedBox(height: 16),
          _buildCommunityCard(),
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String value, String subtext, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Container(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: isMobile ? 20 : 22),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 30,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: _textSecondary.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserManagementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUserTypeTile('Students', _studentCount.toString(), 'Active accounts', const Color(0xFF4F46E5), Icons.school_rounded, onTap: () {
            if (_institutionId != null) {
              context.go('/$_institutionId/admin/users/student');
            }
          }),
          const SizedBox(height: 10),
          _buildUserTypeTile('Faculty', _facultyCount.toString(), 'Active accounts', const Color(0xFF10B981), Icons.people_rounded, onTap: () {
            if (_institutionId != null) {
              context.go('/$_institutionId/admin/users/faculty');
            }
          }),
          const SizedBox(height: 10),
          _buildUserTypeTile('Admins', _adminCount.toString(), 'System administrators', const Color(0xFF8B5CF6), Icons.admin_panel_settings_rounded, onTap: () {
            if (_institutionId != null) {
              context.go('/$_institutionId/admin/users/admin');
            }
          }),
        ],
      ),
    );
  }

  Widget _buildUserTypeTile(String title, String count, String subtitle, Color color, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(_isDarkMode ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final activities = [
      {'title': 'New Company Registration - Wipro', 'time': '1 hour ago', 'icon': Icons.info_rounded, 'color': const Color(0xFF4F46E5)},
      {'title': 'Semester Results Published', 'time': '3 hours ago', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF10B981)},
      {'title': 'Faculty Leave Approval', 'time': '5 pending', 'icon': Icons.access_time_rounded, 'color': const Color(0xFFF59E0B)},
      {'title': 'Placement Drive - Microsoft', 'time': 'Jan 18', 'icon': Icons.event_rounded, 'color': const Color(0xFF8B5CF6)},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.filter_list_rounded, size: 18, color: _textSecondary),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: activity['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity['time'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      activity['icon'] as IconData,
                      size: 16,
                      color: activity['color'] as Color,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    final actions = [
      {'label': 'Manage Users', 'color': const Color(0xFF4F46E5), 'icon': Icons.people_rounded, 'route': null},
      {'label': 'Schedule Drive', 'color': const Color(0xFF10B981), 'icon': Icons.event_rounded, 'route': null},
      {'label': 'System Reports', 'color': const Color(0xFF8B5CF6), 'icon': Icons.bar_chart_rounded, 'route': null},
      {'label': 'Publish Results', 'color': const Color(0xFFF59E0B), 'icon': Icons.publish_rounded, 'route': null},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: () {
                  if (action['label'] == 'Manage Users') {
                    _showAddUserDialog();
                  } else if (action['route'] != null) {
                    final route = action['route'] as String;
                    if (_institutionId != null) {
                      context.go(route);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(_isDarkMode ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          action['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: action['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildOverviewItem('₹6.8L', 'Avg Package'),
              _buildOverviewItem('45', 'Recruiters'),
              _buildOverviewItem('1,248', 'Applications'),
              _buildOverviewItem('342', 'Active Users'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicsCard() {
    return _buildManagementCard(
      'Academics',
      const Color(0xFF10B981),
      Icons.school_rounded,
      [
        {'title': 'Class Management', 'route': '/$_institutionId/admin/class-management'},
        {'title': 'Examinations', 'route': '/$_institutionId/admin/exam-management'},
        {'title': 'Report Cards', 'route': '/$_institutionId/admin/report-card-dashboard'},
      ],
    );
  }

  Widget _buildFinancialsCard() {
    return _buildManagementCard(
      'Financials',
      const Color(0xFFF59E0B),
      Icons.monetization_on_rounded,
      [
        {'title': 'Fee Management', 'route': '/$_institutionId/admin/fee-management'},
      ],
    );
  }

  Widget _buildResourcesCard() {
    return _buildManagementCard(
      'Resources',
      const Color(0xFF8B5CF6),
      Icons.inventory_2_rounded,
      [
        {'title': 'Inventory', 'route': '/$_institutionId/admin/inventory'},
      ],
    );
  }

  Widget _buildToolsCard() {
    return _buildManagementCard(
      'Tools',
      const Color(0xFF14B8A6),
      Icons.build_rounded,
      [
        {'title': 'Form Builder', 'route': '/$_institutionId/admin/form-builder'},
      ],
    );
  }

  Widget _buildCommunityCard() {
    return _buildManagementCard(
      'Community',
      const Color(0xFF4F46E5),
      Icons.groups_rounded,
      [
        {'title': 'Alumni Network', 'route': '/$_institutionId/admin/alumni-dashboard'},
      ],
    );
  }

  Widget _buildManagementCard(String title, Color color, IconData icon, List<Map<String, String>> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  final route = item['route'];
                  if (route != null && _institutionId != null) {
                    context.go(route);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(_isDarkMode ? 0.3 : 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}