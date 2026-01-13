import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  Future<http.Response> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? name,
    String? usn,
    String? phone,
    String? sem,
    String? mentorName,
    String? photoUrl, // New parameter
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/users');

    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'displayName': displayName,
      'role': role,
      'name': name,
      'usn': usn,
      'phone': phone,
      'sem': sem,
      'mentorName': mentorName,
      'photoUrl': photoUrl, // Add photoUrl to the body
    };

    // Remove null values from the body
    body.removeWhere((key, value) => value == null);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response;
  }
}
