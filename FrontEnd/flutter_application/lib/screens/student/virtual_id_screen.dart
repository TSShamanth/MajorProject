import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

    // Fetch user profile (may throw permission errors)
    Map<String, dynamic> userData = {};
    try {
      final userDoc = await _firestore.collection('users').doc(_uid).get();
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

    // Try to fetch college metadata, but do not fail the whole flow if denied
    Map<String, dynamic> collegeData = {};
    try {
      final collegeId = userData['collegeId'] ?? 'default';
      final collegeDoc = await _firestore.collection('colleges').doc(collegeId).get();
      if (collegeDoc.exists) collegeData = collegeDoc.data() ?? {};
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || (e.message?.toLowerCase().contains('permission') ?? false)) {
        // ignore: avoid_print
        print('Firestore: no permission to read college data, continuing without branding');
      } else {
        rethrow;
      }
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
    return Container(
      color: const Color(0xFF0F172A),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            String message = 'Unexpected error';
            if (err is FirebaseException && (err.code == 'permission-denied' || (err.message?.toLowerCase().contains('permission') ?? false))) {
              message = 'Permission denied: you do not have access to view the Virtual ID. Please contact an administrator.';
            } else {
              message = err?.toString() ?? 'Unknown error';
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                  ),
                ],
              ),
            );
          }

          final response = snapshot.data as Map<String, dynamic>? ?? {};
          final data = (response['user'] as Map<String, dynamic>?) ?? {};
          final collegeData = (response['college'] as Map<String, dynamic>?) ?? {};

          // Only the required fields from backend
          final name = data['name'] ?? '';
          final usn = data['usn'] ?? '';
          final programme = data['programme'] ?? data['program'] ?? '';
          final school = data['school'] ?? '';
          final photoUrl = data['photoUrl'] as String?;
          final email = data['email'] ?? '';
          final address = data['address'] ?? '';
          final contact = data['phone'] ?? data['contact'] ?? '';
          final dob = data['dob'] ?? data['dateOfBirth'] ?? '';
          final bloodGroup = data['bloodGroup'] ?? data['blood_grp'] ?? '';
          final emergencyContact = data['emergencyContact'] ?? data['emergency_contact'] ?? '';
          final validUpto = (data['validUpto'] ?? data['valid_till'] ?? data['validTill'] ?? data['validity'] ?? '').toString();
          final collegeName = collegeData['name'] ?? collegeData['collegeName'] ?? '';

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Tap card to flip',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // The ID Card with overlay close button
                    SizedBox(
                      width: 340,
                      height: min(MediaQuery.of(context).size.height * 0.78, 560),
                      child: Stack(
                        children: [
                          // Tappable card (handles flip)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: _toggleCard,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: _showBack ? 1.0 : 0.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOutBack,
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
                                              name: name,
                                              usn: usn,
                                              programme: programme,
                                              school: school,
                                              email: email,
                                              validUpto: validUpto,
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
                                          ),
                                  );
                                },
                              ),
                            ),
                          ),


                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard({
    required String name,
    required String usn,
    required String programme,
    required String school,
    String? photoUrl,
    String? validUpto,
  }) {
    return Card(
      elevation: 12,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D3B66), Color(0xFF1E5A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'RV',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RV UNIVERSITY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Student Identity Card',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    // Left: photo + details (centered vertically)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Photo
                          Container(
                            width: 100,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(name),
                                    )
                                  : _buildPhotoPlaceholder(name),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Details
                          _buildDetailRow('USN', usn),
                          const SizedBox(height: 12),
                          _buildDetailRow('Name', name),
                          const SizedBox(height: 12),
                          _buildDetailRow('Programme', programme),
                          const SizedBox(height: 12),
                          _buildDetailRow('School', school),
                          const SizedBox(height: 12),
                          _buildDetailRow('Valid Upto', validUpto ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (usn.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: usn.isNotEmpty ? usn : 'NO_USN',
                    version: QrVersions.auto,
                    size: 80,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard({
    required String name,
    required String usn,
    required String programme,
    required String school,
    required String email,
    required String validUpto,
    required String address,
    required String contact,
    required String dob,
    required String bloodGroup,
    required String emergencyContact,
    required String collegeName,
  }) {
    return Card(
      elevation: 12,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF334155)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 4),
            // College name + divider
            if (collegeName.isNotEmpty)
              Text(
                collegeName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Container(width: 60, height: 2, color: Colors.amber),

            const SizedBox(height: 18),

// Other details (vertically centered when space allows)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              _buildDetailRowDark('Email', email),
                              const SizedBox(height: 12),
                              _buildDetailRowDark('Address', address),
                              const SizedBox(height: 12),
                              _buildDetailRowDark('Contact', contact),
                              const SizedBox(height: 12),
                              _buildDetailRowDark('DOB', dob),
                              const SizedBox(height: 12),
                              _buildDetailRowDark('Blood Group', bloodGroup),
                              const SizedBox(height: 12),
                              _buildDetailRowDark('Emergency', emergencyContact),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Tap hint
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, color: Colors.white.withOpacity(0.5), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to flip back',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String name) {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // A dark-theme variant used on the back of the card so placeholders remain visible
  Widget _buildDetailRowDark(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Centered label/value helper used on the dark back side
  Widget _buildDetailCentered(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          value.isNotEmpty ? value : '—',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _generateQrData(String usn, String name, String programme, String school, String email) {
    
    final parts = <String>[];
    if (usn.isNotEmpty) parts.add(usn);
    if (name.isNotEmpty) parts.add(name);
    if (programme.isNotEmpty) parts.add(programme);
    if (school.isNotEmpty) parts.add(school);
    if (email.isNotEmpty) parts.add(email);

    return parts.join('|');
  }
}
            