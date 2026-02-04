import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // To get current user UID
import '../config/api_config.dart';
import '../models/attendance_model.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../models/subject_wise_attendance_model.dart';
import '../services/session_manager.dart';

class AttendanceException implements Exception {
  final String message;
  final String? code;

  AttendanceException({required this.message, this.code});

  @override
  String toString() => message;
}

// Helper class for attendance summary
class AttendanceSummary {
  final String studentId;
  final String studentName;
  final int totalClasses;
  final int classesPresent;
  final double attendancePercentage;

  AttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.totalClasses,
    required this.classesPresent,
    required this.attendancePercentage,
  });
}

class AttendanceService {
  // Helper to get departmentId from courseCode
  static Future<String?> _getDepartmentIdFromCourseCode(
      String institutionId, String courseCode) async {
    final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/$institutionId/api/departments'));
    if (response.statusCode == 200) {
      List<dynamic> departmentsJson = json.decode(response.body);
      for (var deptJson in departmentsJson) {
        // Fetch courses for each department to find the matching courseCode
        final deptId = deptJson['id'];
        final coursesResponse = await http.get(Uri.parse(
            '${ApiConfig.baseUrl}/$institutionId/api/departments/$deptId/courses'));
        if (coursesResponse.statusCode == 200) {
          List<dynamic> coursesJson = json.decode(coursesResponse.body);
          for (var courseJson in coursesJson) {
            if (courseJson['courseCode'] == courseCode) {
              return deptId;
            }
          }
        }
      }
    }
    return null;
  }

  /// Get all subjects (Courses) for the currently logged-in faculty
  static Future<List<Course>> getSubjects() async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      final facultyUid = FirebaseAuth.instance.currentUser?.uid;

      if (institutionId == null || facultyUid == null) {
        throw AttendanceException(message: 'User not logged in or institution ID not found.');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/institutions/$institutionId/faculty/$facultyUid/courses');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> coursesJson = json.decode(response.body);
        return coursesJson.map((json) => Course.fromJson(json)).toList();
      } else {
        throw AttendanceException(
            message: _getHttpErrorMessage(response.statusCode),
            code: response.statusCode.toString());
      }
    } catch (e) {
      throw AttendanceException(message: 'Error fetching subjects: ${e.toString()}');
    }
  }

  /// Get students for a subject (Course)
  static Future<List<UserModel>> getStudentsForSubject(String courseCode) async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        throw AttendanceException(message: 'Institution ID not found.');
      }

      // Need departmentId for the endpoint
      // Resolve departmentId using Course object if possible, or another service.
      // For now, _getDepartmentIdFromCourseCode needs to be updated or a new way to get departmentId needs to be implemented.
      // Since Course model's departmentId is now nullable from backend, we need to handle this.
      // A more robust solution involves storing departmentId in the Course model or fetching it directly from the backend API.
      // For immediate fix, if we cannot get departmentId, we'll throw an error.
      final departmentId = await _getDepartmentIdFromCourseCode(institutionId, courseCode);
      if (departmentId == null) {
        throw AttendanceException(message: 'Department ID not found for course: $courseCode. Cannot fetch students.');
      }

      final url = Uri.parse(
          '${ApiConfig.baseUrl}/institutions/$institutionId/departments/$departmentId/courses/$courseCode/students');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> studentsJson = json.decode(response.body);
        return studentsJson.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw AttendanceException(
            message: _getHttpErrorMessage(response.statusCode),
            code: response.statusCode.toString());
      }
    } catch (e) {
      throw AttendanceException(message: 'Error fetching students for subject: ${e.toString()}');
    }
  }

  /// Mark attendance for students
  static Future<bool> markAttendance({
    required String courseCode,
    required String institutionId,
    required String? departmentId, // Changed to nullable
    required String facultyUid,
    required List<AttendanceModel> attendanceRecords,
  }) async {
    // Add null check for departmentId as it's required for the URL
    if (departmentId == null) {
      throw AttendanceException(message: 'Department ID is missing for marking attendance.');
    }
    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/institutions/$institutionId/departments/$departmentId/courses/$courseCode/attendance');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(attendanceRecords.map((e) => e.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw AttendanceException(
            message: _getHttpErrorMessage(response.statusCode),
            code: response.statusCode.toString());
      }
    } catch (e) {
      throw AttendanceException(message: 'Error marking attendance: ${e.toString()}');
    }
  }

  /// Get attendance history for a subject (course)
  static Future<List<AttendanceModel>> getAttendanceHistory(
      String institutionId, String? departmentId, String courseCode) async {
    // Add null check for departmentId as it's required for the URL
    if (departmentId == null) {
      throw AttendanceException(message: 'Department ID is missing for fetching attendance history.');
    }
    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/institutions/$institutionId/departments/$departmentId/courses/$courseCode/attendance'); 
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> attendanceJson = json.decode(response.body);
        return attendanceJson.map((json) => AttendanceModel.fromJson(json)).toList();

      } else {
        throw AttendanceException(
            message: _getHttpErrorMessage(response.statusCode),
            code: response.statusCode.toString());
      }
    } catch (e) {
      throw AttendanceException(message: 'Error fetching attendance history: ${e.toString()}');
    }
  }

  /// Get attendance for a specific student across all courses
  static Future<List<AttendanceModel>> getStudentAttendance(String studentId) async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        throw AttendanceException(message: 'Institution ID not found.');
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/institutions/$institutionId/students/$studentId/attendance');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> attendanceJson = json.decode(response.body);
        return attendanceJson.map((json) => AttendanceModel.fromJson(json)).toList();
      } else {
        throw AttendanceException(
            message: _getHttpErrorMessage(response.statusCode),
            code: response.statusCode.toString());
      }
    } catch (e) {
      throw AttendanceException(message: 'Error fetching student attendance: ${e.toString()}');
    }
  }

  /// Get attendance for a specific date (for a course)
  static Future<List<AttendanceModel>> getAttendanceForDate(
      String institutionId, String? departmentId, String courseCode, String date) async {
    // Add null check for departmentId as it's required for the URL
    if (departmentId == null) {
      throw AttendanceException(message: 'Department ID is missing for fetching attendance for date.');
    }
    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/institutions/$institutionId/departments/$departmentId/courses/$courseCode/attendance?date=$date');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> attendanceJson = json.decode(response.body);
        return attendanceJson.map((json) => AttendanceModel.fromJson(json)).toList();
      } else {
        throw AttendanceException(
            message: _getHttpErrorMessage(response.statusCode),
            code: response.statusCode.toString());
      }
    } catch (e) {
      throw AttendanceException(message: 'Error fetching attendance for date: ${e.toString()}');
    }
  }

  /// Get subject-wise attendance for a specific student
  static Future<List<dynamic>> getSubjectWiseAttendance(String studentId) async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        throw AttendanceException(message: 'Institution ID not found.');
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/institutions/$institutionId/students/$studentId/subject-wise-attendance');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> attendanceJson = json.decode(response.body);
        return attendanceJson.map((json) => SubjectWiseAttendance.fromJson(json)).toList();
      } else {
        throw AttendanceException(
            message: _getHttpErrorMessage(response.statusCode),
            code: response.statusCode.toString());
      }
    } catch (e) {
      throw AttendanceException(message: 'Error fetching subject-wise attendance: ${e.toString()}');
    }
  }

  /// Map HTTP error codes to user-friendly messages
  static String _getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Authentication required. Please log in.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'An unexpected error occurred (Status: $statusCode).';
    }
  }
}