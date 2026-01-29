import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../services/image_service.dart'; // Import the new image service
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
  bool _isLoading = false;
  Uint8List? _pickedImageBytes;
  String? _photoUrl;
  String? _institutionId;
  int _studentCount = 0;
  int _facultyCount = 0;
  int _adminCount = 0;

  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _fetchInstitutionId().then((_) {
      if (_institutionId != null) {
        _fetchUsersAndCounts();
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
      debugPrint('Fetched users count: ${users.length}'); // Debug print
      int studentCount = 0;
      int facultyCount = 0;
      int adminCount = 0; // New admin counter
      for (var user in users) {
        debugPrint('User role: ${user.role}'); // Debug print
        if (user.role == 'student') {
          studentCount++;
        } else if (user.role == 'faculty') {
          facultyCount++;
        } else if (user.role == 'admin') { // Count admins
          adminCount++;
        }
      }
      setState(() {
        _studentCount = studentCount;
        _facultyCount = facultyCount;
        _adminCount = adminCount; // Update admin count
      });
    } catch (e) {
      // Handle error
      debugPrint('Error fetching users and counts: $e'); // Debug print
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
              backgroundColor: const Color(0xFFF8F9FA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF1E293B)),
                  SizedBox(width: 8),
                  Text('Create New User', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: _pickedImageBytes != null ? MemoryImage(_pickedImageBytes!) : null,
                              child: _pickedImageBytes == null
                                  ? const Icon(Icons.person_outline, size: 50, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF1E293B),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await _pickAndUploadImage();
                                    _showAddUserDialog();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: _inputDecoration('Role', Icons.school_outlined),
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
                      const SizedBox(height: 16),

                      _buildTextField(_displayNameController, 'Display Name', Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Email', Icons.email_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscureText: true),
                      
                      if (selectedRole == 'student') ...[
                        const SizedBox(height: 16),
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearForm();
                  },
                ),
                ElevatedButton.icon(
                  onPressed: _handleCreateUser,
                  icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
                      : const Text('Create User', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
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
      prefixIcon: Icon(icon, color: const Color(0xFF1E293B)),
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
        borderSide: const BorderSide(color: Color(0xFF1E293B), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': Icons.business_outlined, 'label': 'Institution', 'description': 'Manage institution settings'},
      {'icon': Icons.person_add_alt_1_outlined, 'label': 'User Management', 'description': 'Create & manage users'},
      {'icon': Icons.bar_chart_outlined, 'label': 'Attendance Reports', 'description': 'View attendance analytics'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Academic Calendar', 'description': 'Manage timetables & holidays'},
      {'icon': Icons.business_center_outlined, 'label': 'Placements', 'description': 'Manage placement drives'},
      {'icon': Icons.celebration_outlined, 'label': 'Events', 'description': 'Oversee all events'},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'description': 'Institution-wide reports'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'description': 'System configuration'}
    ];

    final stats = [
      {'label': 'Total Students', 'value': _studentCount.toString(), 'change': '+12%', 'color': Colors.blue},
      {'label': 'Total Faculty', 'value': _facultyCount.toString(), 'change': '+3%', 'color': Colors.purple},
      {'label': 'Avg Attendance', 'value': '87%', 'change': '+2%', 'color': Colors.green},
      {'label': 'Active Placements', 'value': '15', 'change': '+5', 'color': Colors.orange}
    ];

    final quickActions = [
      {'icon': Icons.person_add_alt_1_outlined, 'label': 'Add User', 'color': Colors.blue, 'action': _showAddUserDialog},
      {'icon': Icons.business_outlined, 'label': 'Institution Setup', 'color': Colors.purple, 'action': () {}},
      {'icon': Icons.business_center_outlined, 'label': 'New Placement', 'color': Colors.green, 'action': () {}},
      {'icon': Icons.calendar_today_outlined, 'label': 'Add Holiday', 'color': Colors.orange, 'action': () {}}
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acadexa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text('Admin Portal', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1E293B)),
            onPressed: () async {
              final router = GoRouter.of(context);
              await SessionManager.clearSession();
              await AuthService.logout();
              router.go('/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1E293B),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            for (var item in menuItems)
              ListTile(
                leading: Icon(item['icon'] as IconData, color: const Color(0xFF1E293B)),
                title: Text(item['label'] as String),
                subtitle: Text(item['description'] as String),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome, Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const Text('VIT Chennai | Administrator', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return _buildStatCard(stat['label'] as String, stat['value'] as String, stat['change'] as String, stat['color'] as Color);
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActionsCard(quickActions),
            const SizedBox(height: 24),

            // User Management
            _buildUserManagementCard(),
            const SizedBox(height: 16),

            _buildAcademicsCard(),
            const SizedBox(height: 16),

            _buildFinancialsCard(),
            const SizedBox(height: 16),

            _buildResourcesCard(),
            const SizedBox(height: 16),

            _buildToolsCard(),
            const SizedBox(height: 16),

            _buildCommunityCard(),
            const SizedBox(height: 16),

            // Attendance Analytics
            _buildAttendanceAnalyticsCard(),
            const SizedBox(height: 16),

            // Placement Drives
            _buildPlacementDrivesCard(),
            const SizedBox(height: 16),
            
            // Academic Management
            _buildAcademicManagementCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.school_outlined),
                SizedBox(width: 8),
                Text('Academics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              'Class & Section Management',
              'Assign students to classes',
              '',
              Colors.teal,
              onTap: () {
                if (_institutionId != null) {
                  context.go('/$_institutionId/admin/class-management');
                }
              },
            ),
            const SizedBox(height: 8),
            _buildInfoTile(
              'Examination Management',
              'Schedule exams and manage grades',
              '',
              Colors.orange,
              onTap: () {
                if (_institutionId != null) {
                  context.go('/$_institutionId/admin/exam-dashboard');
                }
              },
            ),
             const SizedBox(height: 8),
            _buildInfoTile(
              'Report Card Generation',
              'Generate and distribute grade reports',
              '',
              Colors.purple,
              onTap: () {
                if (_institutionId != null) {
                  context.go('/$_institutionId/admin/report-card-dashboard');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.monetization_on_outlined),
                SizedBox(width: 8),
                Text('Financials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              'Student Fee Management', 
              'Manage fee structures and payments', 
              '',
              Colors.green,
              onTap: () {
                if (_institutionId != null) {
                  context.go('/$_institutionId/admin/fee-management');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined),
                SizedBox(width: 8),
                Text('Resource Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              'Inventory Management', 
              'Track and manage campus assets', 
              '',
              Colors.brown,
              onTap: () {
                if (_institutionId != null) {
                  context.go('/$_institutionId/admin/inventory');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.build_outlined),
                SizedBox(width: 8),
                Text('Content & Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              'Form & Survey Builder',
              'Create custom forms and surveys',
              '',
              Colors.blueGrey,
              onTap: () {
                if (_institutionId != null) {
                  context.go('/$_institutionId/admin/form-builder');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.people_alt_outlined),
                SizedBox(width: 8),
                Text('Community', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              'Alumni Network Portal',
              'Engage with the alumni community',
              '',
              Colors.indigo,
              onTap: () {
                if (_institutionId != null) {
                  context.go('/$_institutionId/admin/alumni-dashboard');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(change, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  Widget _buildQuickActionsCard(List<Map<String, Object>> actions) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return ElevatedButton.icon(
                  onPressed: action['action'] as void Function(),
                  icon: Icon(action['icon'] as IconData, color: action['color'] as Color),
                  label: Text(action['label'] as String, style: const TextStyle(color: Color(0xFF1E293B))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (action['color'] as Color).withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.group_outlined),
                    SizedBox(width: 8),
                    Text('User Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(onPressed: _showAddUserDialog, child: const Text('+ Add User')),
              ],
            ),
            const SizedBox(height: 16),
            _buildUserTypeTile(
              'Students', 
              _studentCount.toString(), 
              'Active accounts', 
              Colors.blue,
              onTap: () {
                if (_institutionId != null) {
                  final path = '/$_institutionId/admin/users/student';
                  debugPrint('Navigating to: $path'); // Debug print
                  context.go(path);
                } else {
                  debugPrint('Institution ID is null, cannot navigate.'); // Debug print
                }
              },
            ),
            const SizedBox(height: 8),
            _buildUserTypeTile(
              'Faculty', 
              _facultyCount.toString(), 
              'Active accounts', 
              Colors.purple,
              onTap: () {
                if (_institutionId != null) {
                  final path = '/$_institutionId/admin/users/faculty';
                  debugPrint('Navigating to: $path'); // Debug print
                  context.go(path);
                } else {
                  debugPrint('Institution ID is null, cannot navigate.'); // Debug print
                }
              },
            ),
            const SizedBox(height: 8),
            _buildUserTypeTile(
              'Admins', 
              _adminCount.toString(), 
              'System administrators', 
              Colors.grey,
              onTap: () {
                if (_institutionId != null) {
                  final path = '/$_institutionId/admin/users/admin';
                  debugPrint('Navigating to: $path'); // Debug print
                  context.go(path);
                } else {
                  debugPrint('Institution ID is null, cannot navigate.'); // Debug print
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeTile(String title, String count, String subtitle, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
              ],
            ),
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
  Widget _buildAttendanceAnalyticsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_outlined),
                SizedBox(width: 8),
                Text('Attendance Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressRow('CSE Department', '89%', 0.89, Colors.blue),
            _buildProgressRow('ECE Department', '85%', 0.85, Colors.purple),
            _buildProgressRow('MECH Department', '83%', 0.83, Colors.green),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
              child: const Text('View Detailed Reports'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementDrivesCard() {
    final drives = [
      {'company': 'Google India', 'applicants': '145 students registered', 'status': 'Active', 'color': Colors.green},
      {'company': 'Microsoft', 'applicants': '89 students registered', 'status': 'Shortlisting', 'color': Colors.blue},
      {'company': 'Amazon', 'applicants': '203 students registered', 'status': 'Active', 'color': Colors.green}
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.business_center_outlined),
                    SizedBox(width: 8),
                    Text('Placement Drives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(onPressed: () {}, child: const Text('+ Create Drive')),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: drives.map((drive) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (drive['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (drive['color'] as Color).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(drive['company'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Chip(
                              label: Text(drive['status'] as String),
                              backgroundColor: Colors.white,
                              labelStyle: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(drive['applicants'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicManagementCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today_outlined),
                SizedBox(width: 8),
                Text('Academic Calendar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoTile('Upcoming Holiday', 'Republic Day', 'Jan 26', Colors.orange),
            const SizedBox(height: 8),
            _buildInfoTile('Semester End', 'Spring 2025', 'Apr 30', Colors.purple),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Add Holiday'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Manage Timetable'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle, String trailing, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
              ],
            ),
            Chip(backgroundColor: color.withOpacity(0.3), label: Text(trailing)),
          ],
        ),
      ),
    );
  }
}
