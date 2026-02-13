import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/institution.dart';
import '../models/user_model.dart';
import '../models/section_model.dart';
import '../models/department_model.dart';
import '../models/attendance_log_model.dart';

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

  Future<List<Department>> getDepartments(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Department.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load departments');
    }
  }

  Future<List<UserModel>> getUsers(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/users?institutionId=$institutionId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
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

  Future<http.Response> updateUser({
    required String uid,
    required String email,
    required String displayName,
    required String role,
    required String institutionId,
    String? name,
    String? usn,
    String? phone,
    String? sem,
    String? mentorName,
    String? photoUrl,
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
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$uid?institutionId=$institutionId');

    final Map<String, dynamic> body = {
      'email': email,
      'displayName': displayName,
      'role': role,
      // 'institutionId': institutionId, // Remove from body
      'name': name,
      'usn': usn,
      'phone': phone,
      'sem': sem,
      'mentorName': mentorName,
      'photoUrl': photoUrl,
      'programme': programme,
      'school': school,
      'address': address,
      'dob': dob,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'validUpto': validUpto,
    };

    body.removeWhere((key, value) => value == null);

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response;
  }

  // Section Methods
  Future<List<Section>> getSections(String institutionId, String departmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments/$departmentId/sections');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Section.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sections');
    }
  }

  Future<Section> createSection(String institutionId, String departmentId, Section section) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments/$departmentId/sections');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(section.toJson()),
    );

    if (response.statusCode == 200) {
      return Section.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create section');
    }
  }

  Future<Section> updateSection(String institutionId, String departmentId, String sectionId, Section section) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments/$departmentId/sections/$sectionId');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(section.toJson()),
    );

    if (response.statusCode == 200) {
      return Section.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update section');
    }
  }

  Future<void> deleteSection(String institutionId, String departmentId, String sectionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments/$departmentId/sections/$sectionId');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete section');
    }
  }

  Future<Section> getSection(String institutionId, String departmentId, String sectionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments/$departmentId/sections/$sectionId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Section.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load section');
    }
  }

  // User-specific methods
  Future<UserModel> getMe(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/users/me');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user data');
    }
  }

  // Clock-in/Clock-out Methods
  Future<UserModel> clockIn(String institutionId, double latitude, double longitude) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/attendance/clock-in');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to clock in: ${response.body}');
    }
  }

  Future<UserModel> clockOut(String institutionId, double latitude, double longitude) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/attendance/clock-out');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to clock out: ${response.body}');
    }
  }

  Future<List<AttendanceLog>> getAttendanceHistory(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/attendance/history');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => AttendanceLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load attendance history: ${response.body}');
    }
  }

  Future<List<AttendanceLog>> getAttendanceHistoryForFaculty(String institutionId, String facultyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$facultyId/attendance-history?institutionId=$institutionId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => AttendanceLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load attendance history for faculty: ${response.body}');
    }
  }
}
