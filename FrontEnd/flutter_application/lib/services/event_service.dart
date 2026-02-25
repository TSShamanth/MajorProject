import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/event_model.dart';

class EventService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<EventModel>> getEventsForAudience(
    String institutionId, {
    String? role,
    String? departmentId,
    String? programme,
    String? category,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final params = {
      if (role != null) 'userRole': role,
      if (departmentId != null) 'departmentId': departmentId,
      if (programme != null) 'programme': programme,
      if (category != null) 'category': category,
    };

    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/audience')
        .replace(queryParameters: params);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading events: $e');
    }
  }

  Future<List<EventModel>> getManagedEvents(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/manage');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load managed events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading managed events: $e');
    }
  }

  Future<EventModel> getEventById(String institutionId, String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/$eventId');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load event: ${response.statusCode}');
    }
  }

  Future<EventModel> createEvent(String institutionId, EventModel event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(event.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return EventModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create event: ${response.body}');
    }
  }

  Future<EventModel> updateEvent(String institutionId, String eventId, EventModel event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/$eventId');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(event.toJson()),
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update event: ${response.statusCode}');
    }
  }

  Future<void> deleteEvent(String institutionId, String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/$eventId');

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete event: ${response.statusCode}');
    }
  }

  Future<void> registerForEvent(String institutionId, String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/$eventId/register');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to register for event');
    }
  }

  Future<void> updateEventStatus(String institutionId, String eventId, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/$eventId/status')
        .replace(queryParameters: {'status': status});

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update event status: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getParticipants(String institutionId, String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/$eventId/participants');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load participants: ${response.statusCode}');
    }
  }

  Future<List<EventModel>> getMyRegistrations(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/my-registrations');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => EventModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load my registrations: ${response.statusCode}');
    }
  }

  Future<void> markAttendance(String institutionId, String eventId, String studentId, bool present) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/events/$eventId/attendance');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'studentId': studentId,
        'present': present,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark attendance: ${response.statusCode}');
    }
  }
}
