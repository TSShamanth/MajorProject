import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/time_slot_model.dart';
import '../models/working_day_model.dart';
import '../models/timetable_entry_model.dart';

class TimetableService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  // Time Slot APIs
  Future<List<TimeSlot>> getTimeSlots(String institutionId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$institutionId/api/timeslots'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TimeSlot.fromJson(json)).toList();
    }
    throw Exception('Failed to load time slots');
  }

  Future<TimeSlot> createTimeSlot(String institutionId, TimeSlot timeSlot) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/$institutionId/api/timeslots'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(timeSlot.toJson()),
    );
    if (response.statusCode == 200) {
      return TimeSlot.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create time slot');
  }

  Future<void> deleteTimeSlot(String institutionId, String timeSlotId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$institutionId/api/timeslots/$timeSlotId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete time slot');
    }
  }

  // Working Day APIs
  Future<List<WorkingDay>> getWorkingDays(String institutionId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$institutionId/api/working-days'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => WorkingDay.fromJson(json)).toList();
    }
    throw Exception('Failed to load working days');
  }

  Future<WorkingDay> createWorkingDay(String institutionId, WorkingDay workingDay) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/$institutionId/api/working-days'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(workingDay.toJson()),
    );
    if (response.statusCode == 200) {
      return WorkingDay.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create working day');
  }

  Future<void> updateWorkingDay(String institutionId, WorkingDay workingDay) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/$institutionId/api/working-days'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(workingDay.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update working day');
    }
  }

  // Timetable APIs
  Future<TimetableEntry> assignTimetable(String institutionId, TimetableEntry entry) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/$institutionId/api/timetable/assign'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(entry.toJson()),
    );
    if (response.statusCode == 200) {
      return TimetableEntry.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to assign timetable');
  }

  Future<List<TimetableEntry>> getTimetableForClass(
    String institutionId,
    String departmentId,
    String program,
    String semester,
    String sectionId,
  ) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$institutionId/api/timetable/class/$departmentId/$program/$semester/$sectionId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TimetableEntry.fromJson(json)).toList();
    }
    throw Exception('Failed to load timetable for class');
  }

  Future<List<TimetableEntry>> getTimetableForFaculty(String institutionId, String facultyUid) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$institutionId/api/timetable/faculty/$facultyUid'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TimetableEntry.fromJson(json)).toList();
    }
    throw Exception('Failed to load timetable for faculty');
  }

  Future<void> updateTimetable(String institutionId, TimetableEntry entry) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/$institutionId/api/timetable/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(entry.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update timetable');
    }
  }

  Future<void> deleteTimetable(String institutionId, String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$institutionId/api/timetable/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete timetable');
    }
  }
}
