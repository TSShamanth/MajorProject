import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/session_manager.dart';
import '../../widgets/faculty_layout.dart';

class VirtualIdScreen extends StatefulWidget {
  const VirtualIdScreen({super.key});

  @override
  State<VirtualIdScreen> createState() => _VirtualIdScreenState();
}

class _VirtualIdScreenState extends State<VirtualIdScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  bool _showBack = false;
  bool _isDarkMode = false;

  Future<Map<String, dynamic>> _fetchData() async {
    if (_uid == null) throw FirebaseException(plugin: 'virtual_id', message: 'Not logged in');

    Map<String, dynamic> userData = {};
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) throw Exception('Institution ID not found');
      final userDoc = await _firestore.collection('Institutions').doc(institutionId).collection('users').doc(_uid).get();
      if (!userDoc.exists) throw FirebaseException(plugin: 'virtual_id', message: 'Profile not found');
      userData = userDoc.data() ?? {};
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || (e.message?.toLowerCase().contains('permission') ?? false)) {
        throw FirebaseException(plugin: 'virtual_id', code: 'permission-denied', message: 'Permission denied: Contact administrator.');
      }
      rethrow;
    }

    Map<String, dynamic> collegeData = {};
    try {
      final collegeId = userData['collegeId'] ?? 'default';
      final collegeDoc = await _firestore.collection('colleges').doc(collegeId).get();
      if (collegeDoc.exists) collegeData = collegeDoc.data() ?? {};
    } catch (e) {
      debugPrint('Firestore branding error: $e');
    }

    return {'user': userData, 'college': collegeData};
  }

  void _toggleCard() => setState(() => _showBack = !_showBack);

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: 'Digital ID',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Virtual ID', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());

          final data = (snapshot.data?['user'] as Map<String, dynamic>?) ?? {};
          final collegeData = (snapshot.data?['college'] as Map<String, dynamic>?) ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Virtual ID',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the card to view reverse side details',
                  style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                Center(
                  child: SizedBox(
                    width: 340,
                    height: 520,
                    child: GestureDetector(
                      onTap: _toggleCard,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: _showBack ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          final angle = value * pi;
                          return Transform(
                            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
                            alignment: Alignment.center,
                            child: value > 0.5
                                ? Transform(
                                    transform: Matrix4.identity()..rotateY(pi),
                                    alignment: Alignment.center,
                                    child: _buildBackCard(data, collegeData),
                                  )
                                : _buildFrontCard(data),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard(Map<String, dynamic> data) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0D3B66), Color(0xFF1E5A8A)]),
              ),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.amber, radius: 20, child: Text('RV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RV UNIVERSITY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                        Text('Faculty Identity Card', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  children: [
                    Container(
                      width: 130,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: data['photoUrl'] != null 
                          ? Image.network(data['photoUrl'], fit: BoxFit.cover) 
                          : const Icon(Icons.person, size: 80, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _detailRow('Employee ID', data['employeeId'] ?? 'N/A'),
                    _detailRow('Name', data['name'] ?? 'N/A'),
                    _detailRow('Program', data['programme'] ?? data['program'] ?? 'N/A'),
                    _detailRow('Department', data['departmentId'] ?? 'N/A'),
                    _detailRow('Valid Upto', data['validUpto'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Map<String, dynamic> data, Map<String, dynamic> collegeData) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
        ),
        child: Column(
          children: [
            Text((collegeData['name'] ?? 'RV UNIVERSITY').toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Container(width: 40, height: 2, color: Colors.amber),
            const SizedBox(height: 40),
            _detailRowDark('Email', data['email'] ?? 'N/A'),
            _detailRowDark('Phone', data['phone'] ?? 'N/A'),
            _detailRowDark('Address', data['address'] ?? 'N/A'),
            _detailRowDark('Blood Group', data['bloodGroup'] ?? 'N/A'),
            _detailRowDark('Emergency', data['emergencyContact'] ?? 'N/A'),
            const Spacer(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, color: Colors.white24, size: 16),
                SizedBox(width: 8),
                Text('Tap to flip back', style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500))),
          const Text(': ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _detailRowDark(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12))),
          const Text(': ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 20),
          const Text('Unable to load ID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
        ],
      ),
    );
  }
}
