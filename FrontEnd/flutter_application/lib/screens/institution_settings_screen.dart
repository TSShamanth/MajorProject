import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/institution.dart';
import '../models/department_model.dart';
import '../widgets/admin_layout.dart';
import '../providers/institution_provider.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/session_manager.dart';
import 'dart:convert';

class InstitutionSettingsScreen extends StatefulWidget {
  const InstitutionSettingsScreen({super.key});

  @override
  State<InstitutionSettingsScreen> createState() =>
      _InstitutionSettingsScreenState();
}

class _InstitutionSettingsScreenState extends State<InstitutionSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _academicYearStartController = TextEditingController(text: '2023-08-01');
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

  bool _isDarkMode = false;
  String? _institutionId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _departmentsFuture = _fetchDepartments();
    _fetchId();
  }

  Future<void> _fetchId() async {
    final id = await SessionManager.getInstitutionId();
    setState(() {
      _institutionId = id;
    });
  }

  void _initFields(Institution? institution) {
    if (institution != null && !_initialized) {
      _nameController.text = institution.name;
      _addressController.text = institution.address ?? '';
      _emailController.text = institution.email ?? '';
      _phoneController.text = institution.phone ?? '';
      _initialized = true;
    }
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

  Future<void> _saveSettings() async {
    debugPrint('Save Settings button clicked');
    final provider = Provider.of<InstitutionProvider>(context, listen: false);
    final currentInst = provider.institution;
    
    if (currentInst == null) {
      debugPrint('Error: currentInst is null in provider');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Institution data not loaded.')),
      );
      return;
    }

    final hexColor = '#${provider.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}';
    debugPrint('Updating institution: ${currentInst.id} with color: $hexColor');
    
    final updatedInst = Institution(
      id: currentInst.id,
      name: _nameController.text,
      address: _addressController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      primaryColor: hexColor,
      logoUrl: currentInst.logoUrl,
    );

    try {
      await provider.updateInstitutionProfile(updatedInst);
      debugPrint('Update successful');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Institution profile updated successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  void _showColorPicker(InstitutionProvider provider) {
    final colors = [
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFFEF4444), // Red
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme Color'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                provider.setPrimaryColor(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: provider.primaryColor == color ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _addDepartment() {
    final nameController = TextEditingController();
    final shortNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          title: Text('Add New Department', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Department Name',
                  labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!)),
                ),
              ),
              TextField(
                controller: shortNameController,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Short Name (e.g., CSE)',
                  labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!)),
                ),
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
            backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            title: Text('Confirm Deletion', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
            content: Text('Are you sure you want to delete this department?', style: TextStyle(color: _isDarkMode ? Colors.grey[300]! : Colors.black54)),
            actions: [
               TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Consumer<InstitutionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !_initialized) {
          return const AdminLayout(child: Center(child: CircularProgressIndicator()));
        }

        _initFields(provider.institution);
        final primaryColor = provider.primaryColor;

        return AdminLayout(
          title: 'Institution Setup',
          breadcrumbs: [
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
            const SizedBox(width: 8),
            Text('Institution Setup', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
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
                          'Institution Setup',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your institution profile, academic structure, and policies',
                          style: TextStyle(fontSize: 14, color: textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _saveSettings,
                      icon: provider.isLoading 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                      label: Text(provider.isLoading ? 'Saving...' : 'Save Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                _buildModernSection(
                  'Core Institution Profile',
                  'Details about your institution and branding',
                  Icons.business_rounded,
                  primaryColor,
                  Column(
                    children: [
                      _buildModernTextField(_nameController, 'Institution Name', Icons.corporate_fare_rounded, primaryColor),
                      const SizedBox(height: 20),
                      _buildModernTextField(_addressController, 'Address', Icons.location_on_rounded, primaryColor),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildModernTextField(_emailController, 'Contact Email', Icons.email_rounded, primaryColor)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildModernTextField(_phoneController, 'Phone Number', Icons.phone_rounded, primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildAssetPicker('Primary Theme Color', Icons.color_lens_rounded, Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                          ), onTap: () => _showColorPicker(provider)),
                          const SizedBox(width: 24),
                          _buildAssetPicker('Institution Logo', Icons.image_rounded, const Icon(Icons.upload_file_rounded, size: 20), onTap: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logo upload functionality can be implemented with image_picker')),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildModernSection(
                  'Academic Structure',
                  'Define departments and academic periods',
                  Icons.school_rounded,
                  const Color(0xFF10B981),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildModernTextField(_academicYearStartController, 'Academic Year Start', Icons.calendar_month_rounded, primaryColor, readOnly: true)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildModernTextField(_academicYearEndController, 'Academic Year End', Icons.event_available_rounded, primaryColor, readOnly: true)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FutureBuilder<List<Department>>(
                        future: _departmentsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final departments = snapshot.data ?? [];
                          return _buildModernChipList(
                            'Departments',
                            departments,
                            Icons.school_outlined,
                            primaryColor,
                            onAdd: _addDepartment,
                            onDelete: (id) => _deleteDepartment(id),
                            isDepartment: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildModernSection(
                  'User & Attendance Policy',
                  'Configure working days and institutional holidays',
                  Icons.policy_rounded,
                  const Color(0xFF8B5CF6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Working Days', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 15)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: _workingDays.keys.map((day) {
                          final isSelected = _workingDays[day]!;
                          return ChoiceChip(
                            label: Text(day.substring(0, 3)),
                            selected: isSelected,
                            onSelected: (selected) => setState(() => _workingDays[day] = selected),
                            selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF8B5CF6),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF8B5CF6) : textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildModernChipList(
                        'Holidays',
                        _holidays,
                        Icons.calendar_today_rounded,
                        primaryColor,
                        onAdd: () {},
                        onDelete: (item) => setState(() => _holidays.remove(item)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildModernSection(String title, String subtitle, IconData icon, Color color, Widget content) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
          Padding(
            padding: const EdgeInsets.all(24),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon, Color primaryColor, {bool readOnly = false}) {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!, fontSize: 14),
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildAssetPicker(String label, IconData icon, Widget trailing, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(color: _isDarkMode ? Colors.grey[300]! : Colors.grey[700]!, fontSize: 14))),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernChipList(
    String title,
    List<dynamic> items,
    IconData icon,
    Color primaryColor, {
    required VoidCallback onAdd,
    required void Function(String) onDelete,
    bool isDepartment = false,
  }) {
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 15)),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor),
              onPressed: onAdd,
              tooltip: 'Add ${title.substring(0, title.length - 1)}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: items.map((item) {
            final String name = isDepartment ? (item as Department).name : item as String;
            final String id = isDepartment ? (item as Department).id : item as String;
            
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDepartment ? () async {
                  if (_institutionId != null) {
                    // context.go('/$_institutionId/admin/institution-settings/$name');
                  }
                } : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(name, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => onDelete(id),
                        child: Icon(Icons.close_rounded, size: 16, color: primaryColor.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            );
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
