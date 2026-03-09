import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';
import '../services/session_manager.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  String? _institutionId;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _fetchInstitutionId();
  }

  Future<void> _fetchInstitutionId() async {
    final id = await SessionManager.getInstitutionId();
    if (mounted) {
      setState(() {
        _institutionId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AdminLayout(
      title: 'User Management',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your institution users',
              style: TextStyle(
                fontSize: 16,
                color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildManagementCard(
                  title: 'Student Management',
                  subtitle: 'View, add, and edit students',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF4F46E5),
                  onTap: () {
                    if (_institutionId != null) {
                      context.push('/$_institutionId/admin/users/student');
                    }
                  },
                ),
                _buildManagementCard(
                  title: 'Faculty Management',
                  subtitle: 'View, add, and edit faculty members',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () {
                    if (_institutionId != null) {
                      context.push('/$_institutionId/admin/users/faculty');
                    }
                  },
                ),
                _buildManagementCard(
                  title: 'Admin Management',
                  subtitle: 'System administrators and staff',
                  icon: Icons.admin_panel_settings_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    if (_institutionId != null) {
                      context.push('/$_institutionId/admin/users/admin');
                    }
                  },
                ),
                _buildManagementCard(
                  title: 'Bulk User Import',
                  subtitle: 'Upload multiple users via CSV',
                  icon: Icons.upload_file_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    if (_institutionId != null) {
                      context.push('/$_institutionId/admin/bulk-user-import');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
