import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class UserDetailsScreen extends StatefulWidget {
  final String uid;

  const UserDetailsScreen({
    super.key,
    required this.uid,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String? _institutionId;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      _institutionId = await SessionManager.getInstitutionId();
      if (_institutionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Institution ID not found. Please log in again.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Assuming a get user by UID endpoint exists. If not, this will need adjustment.
      // For now, I'll assume getUsers can be filtered on the client side,
      // or that the API has a specific endpoint like /api/admin/users/{uid}
      final allUsers = await _apiService.getUsers(_institutionId!);
      final user = allUsers.firstWhere((u) => u.uid == widget.uid);

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user details: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.displayName ?? 'User Details'),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                if (_institutionId != null) {
                  final result = await context.push(
                    '/$_institutionId/admin/users/edit/${_user!.uid}',
                    extra: _user,
                  );
                  if (result == true) {
                    // Refresh user details if edit was successful
                    _fetchUserDetails();
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('User not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _user!.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
                          child: _user!.photoUrl == null
                              ? Icon(_user!.role == 'student' ? Icons.person : Icons.group_add, size: 60, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow('Display Name', _user!.displayName),
                      _buildDetailRow('Name', _user!.name ?? 'N/A'),
                      _buildDetailRow('Email', _user!.email ?? 'N/A'),
                      _buildDetailRow('Role', _user!.role ?? 'N/A'),
                      if (_user!.role == 'student') ...[
                        _buildDetailRow('USN', _user!.usn ?? 'N/A'),
                        _buildDetailRow('Phone', _user!.phone ?? 'N/A'),
                        _buildDetailRow('Semester', _user!.sem ?? 'N/A'),
                        _buildDetailRow('Mentor', _user!.mentorName ?? 'N/A'),
                        _buildDetailRow('Programme', _user!.programme ?? 'N/A'),
                        _buildDetailRow('School', _user!.school ?? 'N/A'),
                        _buildDetailRow('Address', _user!.address ?? 'N/A'),
                        _buildDetailRow('Date of Birth', _user!.dob ?? 'N/A'),
                        _buildDetailRow('Blood Group', _user!.bloodGroup ?? 'N/A'),
                        _buildDetailRow('Emergency Contact', _user!.emergencyContact ?? 'N/A'),
                        _buildDetailRow('Valid Upto', _user!.validUpto ?? 'N/A'),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
