import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/institution.dart';

class ApiService {
  static Future<List<Institution>> getInstitutions() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/institutions'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Institution.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load institutions');
    }
  }

  Future<http.Response> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String institutionId,
    String? name,
    String? usn,
    String? phone,
    String? sem,
    String? mentorName,
    String? photoUrl, // New parameter
    String? programme,
    String? school,
    String? address,
    String? dob,
    String? bloodGroup,
    String? emergencyContact,
    String? validUpto,
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
      'institutionId': institutionId,
      'name': name,
      'usn': usn,
      'phone': phone,
      'sem': sem,
      'mentorName': mentorName,
      'photoUrl': photoUrl, // Add photoUrl to the body
      'programme': programme,
      'school': school,
      'address': address,
      'dob': dob,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'validUpto': validUpto,
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
