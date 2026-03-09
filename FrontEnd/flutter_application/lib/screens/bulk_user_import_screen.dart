import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../widgets/admin_layout.dart';
import 'package:go_router/go_router.dart';

class BulkUserImportScreen extends StatefulWidget {
  const BulkUserImportScreen({super.key});

  @override
  State<BulkUserImportScreen> createState() => _BulkUserImportScreenState();
}

class _BulkUserImportScreenState extends State<BulkUserImportScreen> {
  int _currentStep = 0;
  String? _uploadedFileName;
  List<List<dynamic>> _csvData = [];
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();
  String? _institutionId;
  bool _isDarkMode = false;

  // Mapping state
  final List<String> _userModelFields = [
    'displayName',
    'email',
    'password',
    'role',
    'name',
    'usn',
    'phone',
    'sem',
    'departmentId',
    'sectionId',
    'mentorName',
    'programme',
    'school',
    'address',
    'dob',
    'bloodGroup',
    'emergencyContact',
    'validUpto',
    'photoUrl',
    'Not Mapped'
  ];
  List<String> _mappedFields = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (mounted) setState(() {});
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.first;
      final bytes = file.bytes!;
      final csvString = utf8.decode(bytes);
      final rows = const CsvDecoder().convert(csvString);

      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The selected CSV file is empty.')),
          );
        }
        return;
      }

      setState(() {
        _uploadedFileName = file.name;
        _csvData = rows;
        // Initialize mapping with "Not Mapped" or best guess
        final headersRow = rows[0];
        _mappedFields = List.generate(headersRow.length, (index) {
          String header = headersRow[index].toString().toLowerCase();
          if (header.contains('email')) return 'email';
          if (header.contains('display') || (header.contains('name') && !header.contains('full'))) return 'displayName';
          if (header.contains('full name')) return 'name';
          if (header.contains('role')) return 'role';
          if (header.contains('pass')) return 'password';
          if (header.contains('usn') || header.contains('id')) return 'usn';
          if (header.contains('phone') || header.contains('mobile')) return 'phone';
          if (header.contains('sem')) return 'sem';
          if (header.contains('dept') || header.contains('department')) return 'departmentId';
          if (header.contains('section')) return 'sectionId';
          if (header.contains('mentor')) return 'mentorName';
          if (header.contains('prog')) return 'programme';
          if (header.contains('school')) return 'school';
          if (header.contains('addr')) return 'address';
          if (header.contains('dob') || header.contains('birth')) return 'dob';
          if (header.contains('blood')) return 'bloodGroup';
          if (header.contains('emergency') || header.contains('contact')) return 'emergencyContact';
          if (header.contains('valid')) return 'validUpto';
          if (header.contains('photo') || header.contains('image')) return 'photoUrl';
          return 'Not Mapped';
        });
      });
    }
  }

  Future<void> _processImport() async {
    setState(() => _isProcessing = true);
    try {
      if (_institutionId == null) throw Exception('Institution ID not found');

      final List<Map<String, dynamic>> importRequests = [];

      // Start from index 1 to skip header row
      for (int i = 1; i < _csvData.length; i++) {
        final row = _csvData[i];
        final Map<String, dynamic> userData = {};
        
        for (int j = 0; j < row.length; j++) {
          final fieldName = _mappedFields[j];
          if (fieldName != 'Not Mapped') {
            userData[fieldName] = row[j].toString();
          }
        }

        // Add defaults if missing
        if (!userData.containsKey('password')) {
          userData['password'] = 'Welcome@123'; // Default password
        }
        if (!userData.containsKey('role')) {
          userData['role'] = 'student'; // Default role
        }
        if (!userData.containsKey('displayName') && userData.containsKey('name')) {
          userData['displayName'] = userData['name'];
        }

        userData['institutionId'] = _institutionId;
        importRequests.add(userData);
      }

      final results = await _apiService.bulkCreateUsers(_institutionId!, importRequests);
      
      if (mounted) {
        int successCount = results.where((r) => r.startsWith('SUCCESS')).length;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            title: const Text('Import Results'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, i) => Text(results[i], style: TextStyle(
                  color: results[i].startsWith('SUCCESS') ? Colors.green : Colors.red,
                  fontSize: 12,
                )),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
            ],
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import completed! Success: $successCount, Total: ${results.length}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during import: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Bulk User Import',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/user-management'),
          child: Text('User Management', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Bulk Import', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isProcessing 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing users, please wait...'),
            ],
          ))
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload CSV Data',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rapidly create multiple accounts by uploading a structured file',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                    ),
                    child: Stepper(
                      type: StepperType.horizontal,
                      currentStep: _currentStep,
                      onStepContinue: () {
                        if (_currentStep == 1 && _csvData.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a CSV file first.')));
                          return;
                        }
                        if (_currentStep < 3) {
                          setState(() => _currentStep += 1);
                        } else {
                          _processImport();
                        }
                      },
                      onStepCancel: () {
                        if (_currentStep > 0) setState(() => _currentStep -= 1);
                      },
                      steps: [
                        _buildStep1(textPrimary, textSecondary),
                        _buildStep2(textPrimary, textSecondary),
                        _buildStep3(textPrimary, textSecondary),
                        _buildStep4(textPrimary, textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Step _buildStep1(Color textPrimary, Color textSecondary) {
    return Step(
      title: const Text('Setup'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prepare CSV File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),
          Text('Ensure your CSV includes columns like Name, Email, and Role.', style: TextStyle(color: textSecondary)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF4F46E5)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Required columns (mapped later):\ndisplayName, email, password, role, usn',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      isActive: _currentStep >= 0,
    );
  }

  Step _buildStep2(Color textPrimary, Color textSecondary) {
    return Step(
      title: const Text('Upload'),
      content: Column(
        children: [
          const Icon(Icons.upload_file_rounded, size: 64, color: Color(0xFF4F46E5)),
          const SizedBox(height: 16),
          Text('Select CSV File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          Text('Choose the file from your local storage', style: TextStyle(color: textSecondary)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: Text(_uploadedFileName ?? 'Browse Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
          if (_csvData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_csvData.length - 1} users found in file',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      isActive: _currentStep >= 1,
    );
  }

  Step _buildStep3(Color textPrimary, Color textSecondary) {
    final headers = _csvData.isNotEmpty ? _csvData[0] : [];
    return Step(
      title: const Text('Map'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Map Columns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          Text('Match CSV headers to application fields.', style: TextStyle(color: textSecondary)),
          const SizedBox(height: 24),
          if (_csvData.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: headers.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isDarkMode ? Colors.black26 : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _isDarkMode ? Colors.white10 : Colors.grey[200]!),
                          ),
                          child: Text(headers[i].toString(), style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF4F46E5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _mappedFields[i],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: _isDarkMode ? const Color(0xFF111827) : Colors.white,
                          ),
                          dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                          items: _userModelFields.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) => setState(() => _mappedFields[i] = val!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      isActive: _currentStep >= 2,
    );
  }

  Step _buildStep4(Color textPrimary, Color textSecondary) {
    return Step(
      title: const Text('Review'),
      content: Column(
        children: [
          const Icon(Icons.verified_user_rounded, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text('Ready to Import', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),
          Text('You are about to create ${_csvData.isNotEmpty ? _csvData.length - 1 : 0} users.', style: TextStyle(color: textSecondary)),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.security_rounded, color: Color(0xFF4F46E5)),
            title: Text('Default passwords will be set if not provided.', style: TextStyle(fontSize: 13, color: textPrimary)),
            tileColor: const Color(0xFF4F46E5).withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
      isActive: _currentStep >= 3,
    );
  }
}
