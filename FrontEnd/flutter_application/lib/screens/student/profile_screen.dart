import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/session_manager.dart';

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
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF1E293B),
                  child: Text(
                    (name?.isNotEmpty == true) ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.badge_outlined, color: Color(0xFF1E293B)),
                          title: const Text('USN'),
                          subtitle: Text(usn),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.email_outlined, color: Color(0xFF1E293B)),
                          title: const Text('Email'),
                          subtitle: Text(email),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined, color: Color(0xFF1E293B)),
                          title: const Text('Phone'),
                          subtitle: Text(phone),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.school_outlined, color: Color(0xFF1E293B)),
                          title: const Text('Semester'),
                          subtitle: Text(sem),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person_outlined, color: Color(0xFF1E293B)),
                          title: const Text('Mentor'),
                          subtitle: Text(mentor),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
  }
}
