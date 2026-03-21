import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application/models/submission_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/student_layout.dart';

class StudentSubmitAssignmentScreen extends StatefulWidget {
  final String assessmentId;
  const StudentSubmitAssignmentScreen({super.key, required this.assessmentId});

  @override
  State<StudentSubmitAssignmentScreen> createState() => _StudentSubmitAssignmentScreenState();
}

class _StudentSubmitAssignmentScreenState extends State<StudentSubmitAssignmentScreen> {
  final ApiService _apiService = ApiService();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _institutionId = await SessionManager.getInstitutionId();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null || _institutionId == null) return;

    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // In a real app, you would upload to Firebase Storage first and get a URL.
      // For this prototype, we'll simulate the file URL.
      const simulatedUrl = "https://firebasestorage.googleapis.com/v0/b/acadexa/o/simulated_upload.pdf";

      final submission = SubmissionModel(
        assessmentId: widget.assessmentId,
        studentId: user!.uid,
        studentName: user.displayName ?? "Student",
        fileUrl: simulatedUrl,
        fileName: _selectedFile!.name,
        submittedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _apiService.submitAssignment(_institutionId!, submission);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment submitted successfully!'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Submit Assignment',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Upload your submission file (PDF, Doc, Image)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickFile,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(_selectedFile?.name ?? 'Tap to select file', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_selectedFile == null || _isUploading) ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              child: _isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Assignment'),
            ),
          ],
        ),
      ),
    );
  }
}
