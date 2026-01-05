import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> login(String email, String password) async {
    try {
      debugPrint("Attempting to sign in with email: $email");

      // Step 1: Authenticate the user to verify their password is correct.
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint("✅ Authentication successful for email: $email");
      debugPrint("Fetching user role from Firestore by querying email...");

      // Step 2: Query the 'users' collection to find the document with the matching email.
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        debugPrint("✅ Firestore document found for email: $email");
        
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
        debugPrint("❌ ERROR: No Firestore document found for email: $email");
        return 'none';
      }
    } catch (e) {
      // Final workaround: Convert error to String and check for substring.
      // This is to avoid the strange web-only TypeError.
      String error = e.toString();
      if (error.contains('firebase_auth')) {
        debugPrint("❌ AUTHENTICATION ERROR: $error");
      } else {
        debugPrint("❌ AN UNEXPECTED ERROR OCCURRED: $error");
      }
      return 'none';
    }
  }
}


