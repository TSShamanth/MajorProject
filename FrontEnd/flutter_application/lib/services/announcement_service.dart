import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/announcement_model.dart';
import 'package:flutter/foundation.dart';

class AnnouncementService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<AnnouncementModel>> getAnnouncements(
    String institutionId, {
    String? role,
    String? departmentId,
    String? programme, // Added programme
    bool? active,
    String? category,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final token = await user.getIdToken();
    
    // Build query parameters
    final params = {
      if (role != null) 'userRole': role,
      if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
      if (programme != null && programme.isNotEmpty) 'programme': programme, // Add programme
      if (active != null) 'active': active.toString(),
      if (category != null) 'category': category,
    };

    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/announcements/audience').replace( // Changed endpoint
      queryParameters: params,
    );
    debugPrint('Fetching announcements from URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('Announcements API Response Status: ${response.statusCode}');
      debugPrint('Announcements API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => AnnouncementModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load announcements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading announcements: $e');
    }
  }

  Future<AnnouncementModel> getAnnouncementById(String institutionId, String announcementId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/announcements/$announcementId');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return AnnouncementModel.fromJson(data);
      } else {
        throw Exception('Failed to load announcement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading announcement: $e');
    }
  }

  Future<AnnouncementModel> createAnnouncement(
    String institutionId,
    AnnouncementModel announcement,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/announcements');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(announcement.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return AnnouncementModel.fromJson(data);
      } else {
        throw Exception('Failed to create announcement: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating announcement: $e');
    }
  }

  Future<AnnouncementModel> updateAnnouncement(
    String institutionId,
    String announcementId,
    AnnouncementModel announcement,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/announcements/$announcementId');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(announcement.toJson()),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return AnnouncementModel.fromJson(data);
      } else {
        throw Exception('Failed to update announcement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating announcement: $e');
    }
  }

  Future<void> deleteAnnouncement(String institutionId, String announcementId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/announcements/$announcementId');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete announcement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting announcement: $e');
    }
  }

  Future<void> markAnnouncementAsViewed(String institutionId, String announcementId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/announcements/$announcementId/view');

    try {
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Silently fail for view tracking
      debugPrint('Error marking announcement as viewed: $e');
    }
  }

  Future<List<AnnouncementModel>> searchAnnouncements(
    String institutionId,
    String query,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/announcements/search')
        .replace(queryParameters: {'q': query});

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
        return data.map((json) => AnnouncementModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching announcements: $e');
    }
  }

  // New method to get all published announcements (for "All Announcements" tab)
  Future<List<AnnouncementModel>> getAllAnnouncements(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/announcements/all');

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
        return data.map((json) => AnnouncementModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load all announcements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading all announcements: $e');
    }
  }

  // New method to get announcements created by the current user (for "My Announcements" tab)
  Future<List<AnnouncementModel>> getMyAnnouncementsFromBackend(String institutionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/api/institutions/$institutionId/announcements/manage/my-announcements');

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
        return data.map((json) => AnnouncementModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load my announcements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading my announcements: $e');
    }
  }
}


