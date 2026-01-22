import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> login(String email, String password) async {
    try {
      debugPrint("Attempting to sign in with email: $email");

      // Step 1: Authenticate the user.
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint("✅ Authentication successful for email: $email");
      
      final uid = userCredential.user?.uid;
      if (uid == null) {
        debugPrint("❌ ERROR: UID is null after authentication.");
        return 'none';
      }

      // Step 2: Get the user's role using their UID.
      return await getRole(uid);

    } catch (e) {
      // This is to avoid a web-only TypeError.
      String error = e.toString();
      if (error.contains('firebase_auth')) {
        debugPrint("❌ AUTHENTICATION ERROR: $error");
      } else {
        debugPrint("❌ AN UNEXPECTED ERROR OCCURRED: $error");
      }
      return 'none';
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
    debugPrint("✅ User signed out successfully");
  }

  static Future<String> getRole(String uid) async {
    try {
      debugPrint("Fetching user role from Firestore for UID: $uid");

      final userDoc = await _firestore.collection('Institutions').doc('RVU').collection('users').doc(uid).get();

      if (userDoc.exists) {
        debugPrint("✅ Firestore document found for UID: $uid");

        dynamic data = userDoc.data();
        if (data != null && data.containsKey('role')) {
          String role = data['role'];
          debugPrint("✅ Role found: '$role'");
          return role;
        } else {
          debugPrint("❌ ERROR: Firestore document exists, but the 'role' field is missing.");
          return 'none';
        }
      } else {
        debugPrint("❌ ERROR: No Firestore document found for UID: $uid");
        return 'none';
      }
    } catch (e) {
      debugPrint("❌ AN UNEXPECTED ERROR OCCURRED while fetching role: $e");
      return 'none';
    }
  }
}


