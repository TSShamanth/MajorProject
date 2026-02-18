import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/session_manager.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_uid == null) return;
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) throw Exception('Institution ID not found');
      final doc = await _firestore.collection('Institutions').doc(institutionId).collection('users').doc(_uid).get();
      if (doc.exists) {
        final data = doc.data();
        _nameController.text = data?['name'] ?? '';
        _employeeIdController.text = data?['employeeId'] ?? '';
        _phoneController.text = data?['phone'] ?? '';
        _departmentController.text = data?['department'] ?? '';
      }
    } catch (e) {
      // ignore errors here, we'll show on save if needed
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _uid == null) return;
    setState(() => _saving = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) throw Exception('Institution ID not found');
      final data = {
        'name': _nameController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': _departmentController.text.trim(),
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
      };

      await _firestore.collection('Institutions').doc(institutionId).collection('users').doc(_uid).set(data, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(labelText: 'Employee ID'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(labelText: 'Department'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200),
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF1E293B))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                            child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
