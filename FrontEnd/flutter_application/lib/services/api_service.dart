import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/models/seating_entry.dart';
import '../models/invigilator_assignment.dart';
import '../models/hall_ticket_data.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../config/api_config.dart';
import '../models/institution.dart';
import '../models/leave_application_model.dart';
import '../models/user_model.dart';
import '../models/professor_model.dart';
import '../models/notification_model.dart';
import '../models/section_model.dart';
import '../models/department_model.dart';
import '../models/attendance_log_model.dart';
import '../models/regularisation_request_model.dart';
import '../models/course_model.dart';
import '../models/exam_model.dart';
import '../models/exam_schedule_entry.dart';
import '../models/room_model.dart';
import './session_manager.dart';
import '../models/student_fee_model.dart';
import '../models/saved_payment_method_model.dart';
import '../models/marks_model.dart';
import '../models/assessment_model.dart';

class ApiService {
  /* -------------------- Institutions -------------------- */

  static Future<List<Institution>> getInstitutions() async {
    final response =
        await http.get(Uri.parse('${ApiConfig.baseUrl}/institutions'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Institution.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load institutions');
    }
  }

  static Future<Institution> getInstitutionProfile(String id) async {
    debugPrint('ApiService: GET /institutions/$id');
    final response =
        await http.get(Uri.parse('${ApiConfig.baseUrl}/institutions/$id'));

    if (response.statusCode == 200) {
      debugPrint('ApiService: Profile fetched successfully');
      return Institution.fromJson(json.decode(response.body));
    } else {
      debugPrint('ApiService: Failed to load profile: ${response.statusCode}');
      throw Exception('Failed to load institution profile');
    }
  }

  static Future<void> updateInstitutionProfile(Institution institution) async {
    final url = '${ApiConfig.baseUrl}/institutions/${institution.id}';
    final body = jsonEncode(institution.toJson());
    debugPrint('ApiService: PUT $url');
    debugPrint('ApiService: Body: $body');
    
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      debugPrint('ApiService: Update failed: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to update institution profile: ${response.body}');
    }
    debugPrint('ApiService: Update successful');
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
  /* -------------------- Users -------------------- */

  Future<List<UserModel>> getUsers(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/users?institutionId=$institutionId');

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

  Future<UserModel> getUserDetails(String institutionId, String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/users/$uid?institutionId=$institutionId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user details: ${response.body}');
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
    String? departmentId, // New parameter
    String? sectionId, // New parameter
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
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/institutions/$institutionId/users');

    final body = {
      'email': email,
      'password': password,
      'displayName': displayName,
      'role': role,
      'institutionId': institutionId,
      'name': name,
      'usn': usn,
      'phone': phone,
      'sem': sem,
      'departmentId': departmentId, // Add departmentId to the body
      'sectionId': sectionId, // Add sectionId to the body
      'mentorName': mentorName,
      'photoUrl': photoUrl,
      'programme': programme,
      'school': school,
      'address': address,
      'dob': dob,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'validUpto': validUpto,
    }..removeWhere((key, value) => value == null);

    return http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<List<String>> bulkCreateUsers(
      String institutionId, List<Map<String, dynamic>> userRequests) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/institutions/$institutionId/users/bulk');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userRequests),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return List<String>.from(data);
    } else {
      throw Exception('Failed to bulk create users: ${response.body}');
    }
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
    String? departmentId,
    String? sectionId,
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
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/users/$uid?institutionId=$institutionId');

    final body = {
      'email': email,
      'displayName': displayName,
      'role': role,
      'name': name,
      'usn': usn,
      'phone': phone,
      'sem': sem,
      'departmentId': departmentId,
      'sectionId': sectionId,
      'mentorName': mentorName,
      'photoUrl': photoUrl,
      'programme': programme,
      'school': school,
      'address': address,
      'dob': dob,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'validUpto': validUpto,
    }..removeWhere((key, value) => value == null);

    return http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  /* -------------------- Leave Management -------------------- */

  Future<List<String>> getLeaveTypes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/leaves/types');

    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load leave types: ${response.body}');
    }
  }

  Future<List<ProfessorDto>> getProfessors() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/leaves/professors');

    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((professor) => ProfessorDto.fromJson(professor as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load professors: ${response.body}');
    }
  }

  Future<http.Response> applyLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required String professor,
    PlatformFile? file,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/leaves/apply');

    var request = http.MultipartRequest('POST', url);
    
    request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['leaveType'] = leaveType;
    request.fields['startDate'] = startDate.toIso8601String();
    request.fields['endDate'] = endDate.toIso8601String();
    request.fields['reason'] = reason;
    request.fields['professorId'] = professor;
    
    if (file != null && file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );
    }
    
    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  Future<List<LeaveApplication>> getLeaveHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/leaves/history/me');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => LeaveApplication.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load leave history: ${response.body}');
    }
  }

  /* -------------------- Notifications -------------------- */

  Future<List<NotificationModel>> getNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/notifications/me');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load notifications: ${response.body}');
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/notifications/me/$notificationId/read');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification read: ${response.body}');
    }
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
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/users/me');

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

  Future<void> createRegularisationRequest(String institutionId, Map<String, dynamic> requestData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/regularisation/request?institutionId=$institutionId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create regularisation request: ${response.body}');
    }
  }

  Future<List<RegularisationRequest>> getMyRegularisationRequests(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/regularisation/requests/me?institutionId=$institutionId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => RegularisationRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load regularisation requests: ${response.body}');
    }
  }

  Future<List<RegularisationRequest>> getPendingRegularisationRequests(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/regularisation/admin/requests?institutionId=$institutionId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => RegularisationRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending requests: ${response.body}');
    }
  }

  Future<void> approveRegularisationRequest(String institutionId, String requestId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/regularisation/admin/requests/$requestId/approve?institutionId=$institutionId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to approve request: ${response.body}');
    }
  }

  Future<void> denyRegularisationRequest(String institutionId, String requestId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/regularisation/admin/requests/$requestId/deny?institutionId=$institutionId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to deny request: ${response.body}');
    }
  }

  Future<List<Course>> getCourses(String institutionId, String departmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments/$departmentId/courses');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }

  // --- New Faculty Leave Management Methods ---

  Future<List<LeaveApplication>> getPendingLeaveApplicationsForFaculty() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/leaves/faculty/me/pending');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => LeaveApplication.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending leave applications: ${response.body}');
    }
  }

  Future<http.Response> createExam(String institutionId, Map<String, dynamic> examData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(examData),
    );

    return response;
  }

  Future<void> approveLeaveApplication(String leaveId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/leaves/$leaveId/approve');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to approve leave application: ${response.body}');
    }
  }

  Future<void> rejectLeaveApplication(String leaveId, {String? reason}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/leaves/$leaveId/reject');

    final body = {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject leave application: ${response.body}');
    }
  }

  Future<List<LeaveApplication>> getFacultyLeaveHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/leaves/faculty/me/history');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => LeaveApplication.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load faculty leave history: ${response.body}');
    }
  }

  Future<List<Exam>> getExams(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Exam.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exams');
    }
  }

  Future<Exam> getExamById(String institutionId, String examId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Exam.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Exam not found');
    } else {
      throw Exception('Failed to load exam: ${response.body}');
    }
  }

  Future<List<UserModel>> getEligibleStudentsForExam(String institutionId, String examId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/eligible-students');

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
    } else if (response.statusCode == 404) {
      throw Exception('Exam not found or no eligible students');
    } else {
      throw Exception('Failed to load eligible students: ${response.body}');
    }
  }

  Future<void> freezeEligibleStudentsForExam(
      String institutionId, String examId, List<String> studentUids) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/freeze-eligible-students');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(studentUids),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to freeze eligible students: ${response.body}');
    }
  }

  Future<void> updateStudentDetainedStatus(
      String institutionId, String studentUid, bool isDetained) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/users/$studentUid/detained-status');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isDetained': isDetained}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update student detained status: ${response.body}');
    }
  }

  Future<void> updateExamSchedule(
      String institutionId, String examId, Map<String, ExamScheduleEntry> schedule) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/schedule');

    // Convert Map<String, ExamScheduleEntry> to Map<String, dynamic> for JSON encoding
    Map<String, dynamic> serializableSchedule = schedule.map(
      (key, value) => MapEntry(key, value.toJson()),
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(serializableSchedule),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update exam schedule: ${response.body}');
    }
  }

  // Room Management Methods
  Future<List<Room>> getRooms(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/rooms');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Room.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load rooms');
    }
  }

  Future<Room> getRoomById(String institutionId, String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/rooms/$roomId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Room.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Room not found');
    } else {
      throw Exception('Failed to load room');
    }
  }

  Future<Room> createRoom(String institutionId, Room room) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/rooms');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(room.toJson()),
    );

    if (response.statusCode == 200) {
      return Room.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create room');
    }
  }

  Future<Room> updateRoom(String institutionId, String roomId, Room room) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/rooms/$roomId');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(room.toJson()),
    );

    if (response.statusCode == 200) {
      return Room.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update room');
    }
  }

  Future<void> deleteRoom(String institutionId, String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/rooms/$roomId');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete room');
    }
  }

  // Hall Allocation Methods
  Future<Map<String, SeatingEntry>> allocateHalls(String institutionId, String examId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/allocate-halls');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data.map((key, value) => MapEntry(key, SeatingEntry.fromJson(value)));
    } else {
      throw Exception('Failed to allocate halls: ${response.body}');
    }
  }

  Future<Map<String, SeatingEntry>> getSeatingArrangement(String institutionId, String examId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/seating-arrangement');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data.map((key, value) => MapEntry(key, SeatingEntry.fromJson(value)));
    } else if (response.statusCode == 404) {
      return {}; // Return empty map if no arrangement found
    } else {
      throw Exception('Failed to load seating arrangement: ${response.body}');
    }
  }

  // Invigilator Assignment Methods
  Future<InvigilatorAssignment> assignInvigilator(String institutionId, String examId, InvigilatorAssignment assignment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/invigilator-assignments');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(assignment.toJson()),
    );

    if (response.statusCode == 200) {
      return InvigilatorAssignment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to assign invigilator: ${response.body}');
    }
  }

  Future<List<InvigilatorAssignment>> getInvigilatorAssignments(String institutionId, String examId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/invigilator-assignments');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => InvigilatorAssignment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load invigilator assignments: ${response.body}');
    }
  }

  Future<List<InvigilatorAssignment>> getInvigilatorAssignmentsByRoom(String institutionId, String examId, String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/invigilator-assignments/room/$roomId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => InvigilatorAssignment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load invigilator assignments by room: ${response.body}');
    }
  }

  Future<void> deleteInvigilatorAssignment(String institutionId, String examId, String assignmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/invigilator-assignments/$assignmentId');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete invigilator assignment: ${response.body}');
    }
  }

  // Hall Ticket Data Method
  Future<HallTicketData> getHallTicketData(String institutionId, String examId, String studentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/exams/$examId/students/$studentId/hall-ticket-data');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return HallTicketData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load hall ticket data: ${response.body}');
    }
  }

  // New method for faculty to get their students' fee status
  Future<List<StudentFee>> getStudentFeesForFaculty(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/fees/faculty/student-fees'); // Updated endpoint

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => StudentFee.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load student fees for faculty: ${response.body}');
    }
  }

  Future<StudentFee> updateStudentFeeRemarks(String institutionId, String studentFeeId, String remarks) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/fees/student-fees/$studentFeeId/remarks');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'remarks': remarks}),
    );

    if (response.statusCode == 200) {
      return StudentFee.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update student fee remarks: ${response.body}');
    }
  }

  // --- Saved Payment Methods ---

  Future<List<SavedPaymentMethod>> getMyPaymentMethods(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/me/payment-methods');

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => SavedPaymentMethod.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load saved payment methods: ${response.body}');
    }
  }

  Future<SavedPaymentMethod> saveMyPaymentMethod(String institutionId, SavedPaymentMethod method) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/me/payment-methods');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(method.toJson()),
    );

    if (response.statusCode == 200) {
      return SavedPaymentMethod.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to save payment method: ${response.body}');
    }
  }

  Future<void> deleteMyPaymentMethod(String institutionId, String methodId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/me/payment-methods/$methodId');

    final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode != 204) {
      throw Exception('Failed to delete payment method: ${response.statusCode}');
    }
  }

  /* -------------------- Marks & Academic Progress -------------------- */

  Future<MarksModel> saveMarks(String institutionId, MarksModel marks) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/marks');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(marks.toJson()),
    );

    if (response.statusCode == 200) {
      return MarksModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to save marks: ${response.body}');
    }
  }

  Future<List<MarksModel>> getMarksByStudent(String institutionId, String studentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/marks/student/$studentId');

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => MarksModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load marks: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getAcademicSummary(String institutionId, String studentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/marks/student/$studentId/summary');

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load academic summary: ${response.body}');
    }
  }

  /* -------------------- Course Assessments -------------------- */

  Future<AssessmentModel> createAssessment(String institutionId, AssessmentModel assessment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/assessments');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(assessment.toJson()),
    );

    if (response.statusCode == 200) {
      return AssessmentModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create assessment: ${response.body}');
    }
  }

  Future<List<AssessmentModel>> getAssessmentsByCourse(String institutionId, String courseCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/assessments/course/$courseCode');

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => AssessmentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load assessments: ${response.body}');
    }
  }

  Future<void> deleteAssessment(String institutionId, String assessmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/assessments/$assessmentId');

    final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode != 200) {
      throw Exception('Failed to delete assessment: ${response.body}');
    }
  }
}
