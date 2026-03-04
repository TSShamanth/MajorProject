import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/session_manager.dart';
import '../../widgets/student_layout.dart';

class VirtualIdScreen extends StatefulWidget {
  const VirtualIdScreen({super.key});

  @override
  State<VirtualIdScreen> createState() => _VirtualIdScreenState();
}

class _VirtualIdScreenState extends State<VirtualIdScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  bool _showBack = false;

  Future<Map<String, dynamic>> _fetchData() async {
    if (_uid == null) throw FirebaseException(plugin: 'virtual_id', message: 'Not logged in');

    Map<String, dynamic> userData = {};
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) throw Exception('Institution ID not found');
      final userDoc = await _firestore.collection('Institutions').doc(institutionId).collection('users').doc(_uid).get();
      if (!userDoc.exists) {
        throw FirebaseException(plugin: 'virtual_id', message: 'Profile not found');
      }
      userData = userDoc.data() ?? {};
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || (e.message?.toLowerCase().contains('permission') ?? false)) {
        throw FirebaseException(plugin: 'virtual_id', code: 'permission-denied', message: 'You do not have permission to read user profile');
      }
      rethrow;
    }

    Map<String, dynamic> collegeData = {};
    try {
      final collegeId = userData['collegeId'] ?? 'default';
      final collegeDoc = await _firestore.collection('colleges').doc(collegeId).get();
      if (collegeDoc.exists) collegeData = collegeDoc.data() ?? {};
    } on FirebaseException catch (_) {
      debugPrint('Firestore: no permission to read college data');
    }

    return {
      'user': userData,
      'college': collegeData,
    };
  }

  void _toggleCard() {
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Virtual Identity Card',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Virtual ID', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final response = snapshot.data ?? {};
          final data = (response['user'] as Map<String, dynamic>?) ?? {};
          final collegeData = (response['college'] as Map<String, dynamic>?) ?? {};

          final name = data['name'] ?? '—';
          final usn = data['usn'] ?? '—';
          final programme = data['programme'] ?? data['program'] ?? '—';
          final school = data['school'] ?? '—';
          final photoUrl = data['photoUrl'] as String?;
          final email = data['email'] ?? '—';
          final address = data['address'] ?? '—';
          final contact = data['phone'] ?? data['contact'] ?? '—';
          final dob = data['dob'] ?? data['dateOfBirth'] ?? '—';
          final bloodGroup = data['bloodGroup'] ?? data['blood_grp'] ?? '—';
          final emergencyContact = data['emergencyContact'] ?? data['emergency_contact'] ?? '—';
          final validUpto = (data['validUpto'] ?? data['valid_till'] ?? data['validTill'] ?? data['validity'] ?? '—').toString();
          final collegeName = collegeData['name'] ?? collegeData['collegeName'] ?? 'Acadexa University';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildInstructions(),
                const SizedBox(height: 40),
                Center(
                  child: SizedBox(
                    width: 360,
                    height: 580,
                    child: GestureDetector(
                      onTap: _toggleCard,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: _showBack ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                        builder: (context, value, child) {
                          final angle = value * pi;
                          final isUnder = value > 0.5;

                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isUnder
                                ? Transform(
                                    transform: Matrix4.identity()..rotateY(pi),
                                    alignment: Alignment.center,
                                    child: _buildBackCard(
                                      email: email,
                                      address: address,
                                      contact: contact,
                                      dob: dob,
                                      bloodGroup: bloodGroup,
                                      emergencyContact: emergencyContact,
                                      collegeName: collegeName,
                                    ),
                                  )
                                : _buildFrontCard(
                                    name: name,
                                    usn: usn,
                                    programme: programme,
                                    school: school,
                                    photoUrl: photoUrl,
                                    validUpto: validUpto,
                                    collegeName: collegeName,
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.touch_app_rounded, color: Color(0xFF4F46E5), size: 20),
          SizedBox(width: 12),
          Text(
            'Tap on the card to flip and view additional details.',
            style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard({
    required String name,
    required String usn,
    required String programme,
    required String school,
    required String collegeName,
    String? photoUrl,
    String? validUpto,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          // Elegant Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('A', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w900, fontSize: 24))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(collegeName.toUpperCase(), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5)),
                      const Text('STUDENT IDENTITY CARD', 
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Photo
          Container(
            width: 140,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 4),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (photoUrl != null && photoUrl.isNotEmpty)
                  ? Image.network(photoUrl, fit: BoxFit.cover)
                  : _buildPhotoPlaceholder(name),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Primary Details
          Text(name.toUpperCase(), 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(programme, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
          
          const Spacer(),
          
          // Footer with QR and Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMiniInfo('USN', usn),
                      const SizedBox(height: 12),
                      _buildMiniInfo('SCHOOL', school),
                      const SizedBox(height: 12),
                      _buildMiniInfo('VALID UNTIL', validUpto ?? '—'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: QrImageView(
                    data: usn,
                    version: QrVersions.auto,
                    size: 80,
                    gapless: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard({
    required String email,
    required String address,
    required String contact,
    required String dob,
    required String bloodGroup,
    required String emergencyContact,
    required String collegeName,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.security_rounded, color: Color(0xFF4F46E5), size: 32),
                const SizedBox(height: 12),
                Text('OFFICIAL TERMS', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(width: 40, height: 2, color: const Color(0xFF4F46E5)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildBackDetail('Email Address', email),
          _buildBackDetail('Contact Number', contact),
          _buildBackDetail('Date of Birth', dob),
          _buildBackDetail('Blood Group', bloodGroup),
          _buildBackDetail('Emergency Contact', emergencyContact),
          _buildBackDetail('Home Address', address),
          const Spacer(),
          const Text('1. This card is non-transferable.', style: TextStyle(color: Colors.white54, fontSize: 10)),
          const Text('2. Loss of card must be reported immediately.', style: TextStyle(color: Colors.white54, fontSize: 10)),
          const Text('3. Please return if found to the university office.', style: TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 16),
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Text(collegeName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildBackDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String name) {
    return Center(
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', 
        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Color(0xFFD1D5DB))),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleActionButton(Icons.download_rounded, 'Download'),
        const SizedBox(width: 32),
        _buildCircleActionButton(Icons.share_rounded, 'Share'),
        const SizedBox(width: 32),
        _buildCircleActionButton(Icons.print_rounded, 'Print'),
      ],
    );
  }

  Widget _buildCircleActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
      ],
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
        ],
      ),
    );
  }
}
