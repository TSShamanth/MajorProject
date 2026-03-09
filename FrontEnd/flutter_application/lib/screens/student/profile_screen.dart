import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/session_manager.dart';
import '../../widgets/student_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchProfile() async {
    if (_uid == null) throw Exception('Not logged in');
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');
    return await _firestore.collection('Institutions').doc(institutionId).collection('users').doc(_uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'My Profile',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Profile', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _fetchProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found'));
          }

          final data = snapshot.data!.data();
          final name = data?['name'] ?? '—';
          final usn = data?['usn'] ?? '—';
          final email = data?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '—';
          final phone = data?['phone'] ?? '—';
          final sem = data?['sem']?.toString() ?? '—';
          final mentor = data?['mentorName'] ?? '—';
          final programme = data?['programme'] ?? '—';
          final department = data?['departmentName'] ?? '—';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(name, usn, programme),
                const SizedBox(height: 32),
                _buildInfoGrid(email, phone, sem, mentor, department),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String usn, String programme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  programme,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    usn,
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Edit Profile'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildInfoGrid(String email, String phone, String sem, String mentor, String department) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 2.5,
          children: [
            _buildInfoCard('Email Address', email, Icons.email_outlined, const Color(0xFF4F46E5)),
            _buildInfoCard('Phone Number', phone, Icons.phone_outlined, const Color(0xFF10B981)),
            _buildInfoCard('Current Semester', 'Semester $sem', Icons.school_outlined, const Color(0xFFF59E0B)),
            _buildInfoCard('Academic Mentor', mentor, Icons.person_outline_rounded, const Color(0xFF8B5CF6)),
            _buildInfoCard('Department', department, Icons.business_rounded, const Color(0xFFEF4444)),
            _buildInfoCard('Account Status', 'Active', Icons.verified_user_outlined, const Color(0xFF06B6D4)),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
