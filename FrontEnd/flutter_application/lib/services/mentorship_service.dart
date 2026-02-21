import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/mentor_meeting_model.dart';
import '../models/mentee_concern_model.dart';

class MentorshipService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  // --- Admin Methods ---

  Future<void> assignMentor(String institutionId, String mentorId, List<String> studentIds) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/assign?institutionId=$institutionId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'mentorId': mentorId,
        'studentIds': studentIds,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to assign mentor: ${response.body}');
    }
  }

  // --- Faculty (Mentor) Methods ---

  Future<List<UserModel>> getMentees(String institutionId) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/mentees?institutionId=$institutionId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load mentees: ${response.body}');
    }
  }

  Future<UserModel> getMenteeDetail(String institutionId, String menteeId) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/mentees/$menteeId?institutionId=$institutionId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load mentee details: ${response.body}');
    }
  }

  // --- Student (Mentee) Methods ---

  Future<UserModel?> getMentor(String institutionId) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/mentor?institutionId=$institutionId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return null;
      return UserModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load mentor: ${response.body}');
    }
  }

  // --- Common (Meetings & Concerns) ---

  Future<List<MentorMeeting>> getMeetings(String institutionId, {String? studentId}) async {
    final token = await _getToken();
    String urlStr = '${ApiConfig.baseUrl}/api/mentorship/meetings?institutionId=$institutionId';
    if (studentId != null) urlStr += '&studentId=$studentId';
    
    final url = Uri.parse(urlStr);
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => MentorMeeting.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load meetings: ${response.body}');
    }
  }

  Future<void> createMeeting(String institutionId, MentorMeeting meeting) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/meetings?institutionId=$institutionId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(meeting.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create meeting: ${response.body}');
    }
  }

  Future<List<MenteeConcern>> getConcerns(String institutionId, {String? studentId}) async {
    final token = await _getToken();
    String urlStr = '${ApiConfig.baseUrl}/api/mentorship/concerns?institutionId=$institutionId';
    if (studentId != null) urlStr += '&studentId=$studentId';

    final url = Uri.parse(urlStr);
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => MenteeConcern.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load concerns: ${response.body}');
    }
  }

  Future<void> raiseConcern(String institutionId, MenteeConcern concern) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/concerns?institutionId=$institutionId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(concern.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to raise concern: ${response.body}');
    }
  }

  Future<void> updateConcernStatus(String institutionId, String concernId, String status, {String? remarks}) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/concerns/$concernId/status?institutionId=$institutionId');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
        if (remarks != null) 'mentorRemarks': remarks,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update concern status: ${response.body}');
    }
  }

  Future<void> updateMeetingStatus(String institutionId, String meetingId, String status) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/meetings/$meetingId/status?institutionId=$institutionId');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update meeting status: ${response.body}');
    }
  }

  Future<void> completeMeeting(String institutionId, String meetingId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/meetings/$meetingId/complete?institutionId=$institutionId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to complete meeting: ${response.body}');
    }
  }

  Future<void> updateActionItems(String institutionId, String meetingId, List<Map<String, dynamic>> actionItems) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/meetings/$meetingId/action-items?institutionId=$institutionId');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(actionItems),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update action items: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getMentorshipStats(String institutionId) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mentorship/stats?institutionId=$institutionId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stats: ${response.body}');
    }
  }
}
