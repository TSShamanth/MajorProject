import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'session_manager.dart';

import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final googleSignIn = GoogleSignIn();

  static Future<String> signInWithGoogleForExistingUser(String institutionId) async {
    try {
      // 1. Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn.standard().signIn();

      if (googleUser == null) {
        // User cancelled the sign-in flow
        debugPrint("Google Sign-In was cancelled by the user.");
        return 'none';
      }

      // 2. Proceed with Firebase sign-in
      debugPrint("Proceeding with Firebase authentication.");
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user?.uid;

      if (uid != null) {
        // Store institutionId in session
        await SessionManager.setInstitutionId(institutionId);
        // Role will be fetched by the redirect/wrapper logic
        return 'success';
      }

      return 'none';
    } catch (e) {
      debugPrint("❌ AN UNEXPECTED ERROR OCCURRED during Google Sign-In: $e");
      return 'none';
    }
  }

  static Future<String> login(String email, String password, String institutionId) async {
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

      // Store institutionId in session
      await SessionManager.setInstitutionId(institutionId);

      // Step 2: Get the user's role using their UID and institutionId.
      return await getRole(uid, institutionId);

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

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint("✅ Password reset email sent successfully to $email");
    } catch (e) {
      debugPrint("❌ ERROR sending password reset email: $e");
      // Re-throw the exception to be handled by the UI.
      rethrow;
    }
  }

  static Future<String> getRole(String uid, String institutionId) async {
    try {
      debugPrint("Fetching user role from Firestore for UID: $uid in institution: $institutionId");

      final userDoc = await _firestore.collection('Institutions').doc(institutionId).collection('users').doc(uid).get();

      if (userDoc.exists) {
        debugPrint("✅ Firestore document found for UID: $uid");

        dynamic data = userDoc.data();
        if (data != null && data.containsKey('role')) {
          String role = data['role'];
          debugPrint("✅ Role found: '$role'");
          return role.trim().toLowerCase();
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

