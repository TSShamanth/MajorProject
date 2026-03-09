import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../widgets/admin_layout.dart';

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
  Department? _department;
  bool _isLoading = true;
  String? _institutionId;
  final ApiService _apiService = ApiService();
  bool _isDarkMode = false;

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
            const SnackBar(content: Text('Institution ID not found. Please log in again.'), behavior: SnackBarBehavior.floating),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final allUsers = await _apiService.getUsers(_institutionId!);
      final user = allUsers.firstWhere((u) => u.uid == widget.uid);
      
      Department? department;
      if (user.departmentId != null) {
        try {
          final departments = await _apiService.getDepartments(_institutionId!);
          department = departments.firstWhere((d) => d.id == user.departmentId);
        } catch (e) {
          debugPrint('Error fetching department: $e');
        }
      }

      if (mounted) {
        setState(() {
          _user = user;
          _department = department;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user details: $e'), behavior: SnackBarBehavior.floating),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final roleName = _user?.role != null ? _user!.role![0].toUpperCase() + _user!.role!.substring(1) : 'User';

    return AdminLayout(
      title: 'User Profile',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/user-management'),
          child: Text('User Management', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        if (_user?.role != null) ...[
          Icon(Icons.chevron_right, size: 16, color: textSecondary),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => context.push('/$_institutionId/admin/users/${_user!.role}'),
            child: Text(roleName, style: TextStyle(color: textSecondary, fontSize: 13)),
          ),
        ],
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Profile Details', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _user == null
          ? const Center(child: Text('User not found.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(textPrimary, textSecondary),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 1000) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: _buildPersonalCard(textPrimary, textSecondary)),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: _buildAcademicCard(textPrimary, textSecondary)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildPersonalCard(textPrimary, textSecondary),
                            const SizedBox(height: 24),
                            _buildAcademicCard(textPrimary, textSecondary),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
              backgroundImage: _user!.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
              child: _user!.photoUrl == null 
                ? Icon(_user!.role == 'student' ? Icons.school_rounded : Icons.person_rounded, size: 40, color: const Color(0xFF4F46E5))
                : null,
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.displayName,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _user!.role?.toUpperCase() ?? 'USER',
                        style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_user!.email ?? '', style: TextStyle(fontSize: 14, color: textSecondary)),
                  ],
                ),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () async {
            if (_institutionId != null) {
              final result = await context.push(
                '/$_institutionId/admin/users/edit/${_user!.uid}',
                extra: _user,
              );
              if (result == true) _fetchUserDetails();
            }
          },
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Edit Profile'),
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

  Widget _buildPersonalCard(Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 24),
          _buildInfoItem(Icons.badge_rounded, 'Full Name', _user!.name ?? _user!.displayName, textPrimary, textSecondary),
          const SizedBox(height: 20),
          _buildInfoItem(Icons.email_rounded, 'Email Address', _user!.email ?? 'N/A', textPrimary, textSecondary),
          const SizedBox(height: 20),
          _buildInfoItem(Icons.phone_rounded, 'Phone Number', _user!.phone ?? 'N/A', textPrimary, textSecondary),
          const SizedBox(height: 20),
          _buildInfoItem(Icons.cake_rounded, 'Date of Birth', _user!.dob ?? 'N/A', textPrimary, textSecondary),
          const SizedBox(height: 20),
          _buildInfoItem(Icons.bloodtype_rounded, 'Blood Group', _user!.bloodGroup ?? 'N/A', textPrimary, textSecondary),
          const SizedBox(height: 20),
          _buildInfoItem(Icons.location_on_rounded, 'Current Address', _user!.address ?? 'N/A', textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildAcademicCard(Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Academic & Institutional Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 24,
            childAspectRatio: 4,
            children: [
              _buildInfoItem(Icons.business_rounded, 'Department', _department?.name ?? 'General', textPrimary, textSecondary),
              if (_user!.role == 'student') ...[
                _buildInfoItem(Icons.tag_rounded, 'USN / ID', _user!.usn ?? 'N/A', textPrimary, textSecondary),
                _buildInfoItem(Icons.format_list_numbered_rounded, 'Current Semester', _user!.sem ?? 'N/A', textPrimary, textSecondary),
                _buildInfoItem(Icons.school_rounded, 'Programme', _user!.programme ?? 'N/A', textPrimary, textSecondary),
                _buildInfoItem(Icons.account_balance_rounded, 'School', _user!.school ?? 'N/A', textPrimary, textSecondary),
                _buildInfoItem(Icons.person_pin_rounded, 'Faculty Mentor', _user!.mentorName ?? 'Not Assigned', textPrimary, textSecondary),
                _buildInfoItem(Icons.contact_phone_rounded, 'Emergency Contact', _user!.emergencyContact ?? 'N/A', textPrimary, textSecondary),
                _buildInfoItem(Icons.calendar_today_rounded, 'Valid Upto', _user!.validUpto ?? 'N/A', textPrimary, textSecondary),
              ] else if (_user!.role == 'faculty') ...[
                _buildInfoItem(Icons.work_rounded, 'Designation', _user!.programme ?? 'Faculty', textPrimary, textSecondary),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 2),
              Text(
                value, 
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
