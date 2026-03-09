import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/placement_service.dart';
import '../models/placement_registration_model.dart';

class PlacementRegistrationScreen extends StatefulWidget {
  final String institutionId;
  const PlacementRegistrationScreen({super.key, required this.institutionId});

  @override
  State<PlacementRegistrationScreen> createState() => _PlacementRegistrationScreenState();
}

class _PlacementRegistrationScreenState extends State<PlacementRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cgpaController = TextEditingController();
  final _skillsController = TextEditingController();
  final _backlogsController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUploading = false;
  String? _resumeUrl;
  String? _photoUrl;
  String? _resumeFileName;
  String? _photoFileName;
  
  UserModel? _currentUser;
  late PlacementService _placementService;
  final ApiService _apiService = ApiService();

  final List<String> _departments = ['CS', 'IS', 'EC', 'ME', 'CV', 'BT'];
  final List<String> _selectedDepartments = [];

  @override
  void initState() {
    super.initState();
    _placementService = PlacementService(institutionId: widget.institutionId);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await _apiService.getMe(widget.institutionId);
      if (_currentUser != null) {
        final registration = await _placementService.getRegistration(_currentUser!.uid);
        if (registration != null) {
          _cgpaController.text = registration.cgpa.toString();
          _skillsController.text = registration.skills.join(', ');
          _backlogsController.text = registration.backlogCount.toString();
          _resumeUrl = registration.resumeUrl;
          _photoUrl = registration.photoUrl;
          _selectedDepartments.addAll(registration.interestedDepartments);
        } else {
          _cgpaController.text = _currentUser!.currentGPA?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile(bool isResume) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isResume ? FileType.custom : FileType.image,
      allowedExtensions: isResume ? ['pdf'] : null,
      withData: true, // Crucial for Web
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.single.bytes;
      String fileName = result.files.single.name;
      
      setState(() {
        if (isResume) {
          _resumeFileName = fileName;
        } else {
          _photoFileName = fileName;
        }
        _isUploading = true;
      });

      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('institutions')
            .child(widget.institutionId)
            .child('placements')
            .child(_currentUser!.uid)
            .child(isResume ? 'resume.pdf' : 'photo.${fileName.split('.').last}');

        if (kIsWeb) {
          if (fileBytes == null) throw Exception('No file data available');
          await ref.putData(fileBytes);
        } else {
          File file = File(result.files.single.path!);
          await ref.putFile(file);
        }
        String downloadUrl = await ref.getDownloadURL();

        setState(() {
          if (isResume) {
            _resumeUrl = downloadUrl;
          } else {
            _photoUrl = downloadUrl;
          }
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resumeUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your resume')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final registration = PlacementRegistrationModel(
        uid: _currentUser!.uid,
        resumeUrl: _resumeUrl!,
        photoUrl: _photoUrl ?? '',
        cgpa: double.parse(_cgpaController.text),
        skills: _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        backlogCount: int.parse(_backlogsController.text),
        interestedDepartments: _selectedDepartments,
      );

      await _placementService.registerStudent(registration);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placement registration successful!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Registration'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Academic Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cgpaController,
                decoration: const InputDecoration(
                  labelText: 'Current CGPA',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grade),
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backlogsController,
                decoration: const InputDecoration(
                  labelText: 'Active Backlogs',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Skills & Preferences'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                  hintText: 'e.g. Java, Flutter, Python, SQL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Target Departments', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _departments.map((dept) {
                  final isSelected = _selectedDepartments.contains(dept);
                  return FilterChip(
                    label: Text(dept),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDepartments.add(dept);
                        } else {
                          _selectedDepartments.remove(dept);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Documents'),
              const SizedBox(height: 16),
              _buildFileUploadTile(
                'Resume (PDF)', 
                _resumeFileName ?? (_resumeUrl != null ? 'Resume Uploaded' : 'Not Selected'),
                Icons.description,
                () => _pickFile(true),
              ),
              const SizedBox(height: 16),
              _buildFileUploadTile(
                'Professional Photo', 
                _photoFileName ?? (_photoUrl != null ? 'Photo Uploaded' : 'Not Selected'),
                Icons.image,
                () => _pickFile(false),
              ),
              const SizedBox(height: 48),

              if (_isUploading)
                const Center(child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Uploading file...'),
                  ],
                ))
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
    );
  }

  Widget _buildFileUploadTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: Icon(icon, color: Colors.indigo),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: subtitle.contains('Uploaded') ? Colors.green : Colors.grey)),
        trailing: const Icon(Icons.upload_file),
      ),
    );
  }
}
