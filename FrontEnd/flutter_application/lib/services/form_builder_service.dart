import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/form_builder_model.dart';
import 'session_manager.dart';

class FormBuilderService {
  Future<List<CustomForm>> getForms() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => CustomForm.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load forms');
    }
  }

  Future<List<CustomForm>> getFormsForAudience(String role) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();

    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms/audience?role=$role');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => CustomForm.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load forms for audience');
    }
  }

  Future<CustomForm> getFormById(String formId) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms/$formId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return CustomForm.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load form');
    }
  }

  Future<CustomForm> saveForm(CustomForm form) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();

    final isNew = form.id.isEmpty;
    final url = isNew 
      ? Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms')
      : Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms/${form.id}');

    final response = await (isNew 
      ? http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(form.toJson()),
        )
      : http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(form.toJson()),
        ));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CustomForm.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to save form: ${response.body}');
    }
  }

  Future<void> deleteForm(String formId) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();

    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms/$formId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete form');
    }
  }

  Future<int> getResponseCount(String formId) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms/$formId/responses/count');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to load response count');
    }
  }

  Future<FormResponseModel?> getUserResponse(String formId) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken();

    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms/$formId/responses/me');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return FormResponseModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 204) {
      return null;
    } else {
      throw Exception('Failed to load user response');
    }
  }

  Future<void> submitResponse(String formId, Map<String, dynamic> answers, {String? responseId}) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();

    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms/$formId/responses');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': responseId,
        'institutionId': institutionId,
        'formId': formId,
        'userId': user.uid,
        'answers': answers,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to submit response');
    }
  }

  Future<List<FormResponseModel>> getResponses(String formId) async {
    final institutionId = await SessionManager.getInstitutionId();
    if (institutionId == null) throw Exception('Institution ID not found');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final token = await user.getIdToken();

    final url = Uri.parse('${ApiConfig.baseUrl}/api/institutions/$institutionId/forms/$formId/responses');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FormResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load responses');
    }
  }
}
