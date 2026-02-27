import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/company_model.dart';
import '../models/placement_drive_model.dart';
import '../models/placement_application_model.dart';
import '../models/interview_slot_model.dart';

class PlacementService {
  final String institutionId;

  PlacementService({required this.institutionId});

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- Interviews ---

  Future<List<InterviewSlotModel>> getInterviewSlots() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/placement/interviews'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => InterviewSlotModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load interview slots');
    }
  }

  Future<InterviewSlotModel> createInterviewSlot(InterviewSlotModel slot) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/placement/interviews'),
      headers: _getHeaders(token),
      body: jsonEncode(slot.toJson()),
    );

    if (response.statusCode == 200) {
      return InterviewSlotModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create interview slot');
    }
  }

  // --- Companies ---

  Future<List<CompanyModel>> getCompanies() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/placement/companies'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => CompanyModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load companies');
    }
  }

  Future<CompanyModel> createCompany(CompanyModel company) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/placement/companies'),
      headers: _getHeaders(token),
      body: jsonEncode(company.toJson()),
    );

    if (response.statusCode == 200) {
      return CompanyModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create company');
    }
  }

  // --- Placement Drives ---

  Future<List<PlacementDriveModel>> getPlacementDrives() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/placement/drives'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => PlacementDriveModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load drives');
    }
  }

  Future<PlacementDriveModel> createDrive(PlacementDriveModel drive) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/placement/drives'),
      headers: _getHeaders(token),
      body: jsonEncode(drive.toJson()),
    );

    if (response.statusCode == 200) {
      return PlacementDriveModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create drive');
    }
  }

  // --- Applications & Student Tracking ---

  Future<List<PlacementApplicationModel>> getApplications({String? driveId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    String url = '${ApiConfig.baseUrl}/api/institutions/$institutionId/placement/applications';
    if (driveId != null) url += '?driveId=$driveId';

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => PlacementApplicationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load applications');
    }
  }

  Future<PlacementApplicationModel> updateApplicationStatus(String appId, String status, String round) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/placement/applications/$appId'),
      headers: _getHeaders(token),
      body: jsonEncode({'status': status, 'currentRound': round}),
    );

    if (response.statusCode == 200) {
      return PlacementApplicationModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update application');
    }
  }

  // --- Analytics ---

  Future<Map<String, dynamic>> getPlacementStats() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/placement/stats'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load placement stats');
    }
  }
}
