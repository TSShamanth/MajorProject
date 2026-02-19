import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../config/api_config.dart';
import '../models/fee_category_model.dart';
import '../models/fee_structure_model.dart';
import '../models/student_fee_model.dart';
import '../models/payment_model.dart';

class FeeService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ... (existing methods)

  Future<void> downloadReceipt(String institutionId, String paymentId, String receiptNumber) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.get(
      Uri.parse('$baseUrl/$institutionId/api/fees/payments/$paymentId/receipt'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Uint8List pdfBytes = response.bodyBytes;
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Receipt_$receiptNumber',
      );
    } else {
      throw Exception('Failed to download receipt: ${response.statusCode}');
    }
  }

  // Fee Categories
  Future<List<FeeCategory>> getFeeCategories(String institutionId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.get(
      Uri.parse('$baseUrl/$institutionId/api/fees/categories'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FeeCategory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load fee categories');
    }
  }

  Future<FeeCategory> createFeeCategory(String institutionId, String name) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.post(
      Uri.parse('$baseUrl/$institutionId/api/fees/categories'),
      headers: _getHeaders(token),
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200) {
      return FeeCategory.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create fee category');
    }
  }

  Future<void> deleteFeeCategory(String institutionId, String categoryId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.delete(
      Uri.parse('$baseUrl/$institutionId/api/fees/categories/$categoryId'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete fee category');
    }
  }

  // Fee Structures
  Future<List<FeeStructure>> getFeeStructures(String institutionId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.get(
      Uri.parse('$baseUrl/$institutionId/api/fees/structures'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FeeStructure.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load fee structures');
    }
  }

  Future<FeeStructure> createFeeStructure(String institutionId, FeeStructure structure) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.post(
      Uri.parse('$baseUrl/$institutionId/api/fees/structures'),
      headers: _getHeaders(token),
      body: json.encode(structure.toJson()),
    );

    if (response.statusCode == 200) {
      return FeeStructure.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create fee structure: ${response.body}');
    }
  }

  Future<FeeStructure> updateFeeStructure(String institutionId, FeeStructure structure) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.put(
      Uri.parse('$baseUrl/$institutionId/api/fees/structures/${structure.id}'),
      headers: _getHeaders(token),
      body: json.encode(structure.toJson()),
    );

    if (response.statusCode == 200) {
      return FeeStructure.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update fee structure');
    }
  }

  Future<void> deleteFeeStructure(String institutionId, String structureId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.delete(
      Uri.parse('$baseUrl/$institutionId/api/fees/structures/$structureId'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete fee structure');
    }
  }

  // Student Fees
  Future<void> generateFees(String institutionId, String feeStructureId, DateTime dueDate) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.post(
      Uri.parse('$baseUrl/$institutionId/api/fees/generate'),
      headers: _getHeaders(token),
      body: json.encode({
        'feeStructureId': feeStructureId,
        'dueDate': dueDate.toIso8601String(), // Use ISO8601String for consistency
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate fees: ${response.body}');
    }
  }

  Future<List<StudentFee>> getStudentFees(String institutionId, {String? studentId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    String url = '$baseUrl/$institutionId/api/fees/student-fees';
    if (studentId != null) {
      url += '?studentId=$studentId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => StudentFee.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load student fees');
    }
  }

  Future<Map<String, dynamic>> getFeeStats(String institutionId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.get(
      Uri.parse('$baseUrl/$institutionId/api/fees/stats'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load fee stats');
    }
  }

  Future<Payment> recordPayment(String institutionId, String studentFeeId, double amount, String method, {String? transactionId, String? notes}) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.post(
      Uri.parse('$baseUrl/$institutionId/api/fees/student-fees/$studentFeeId/payments'),
      headers: _getHeaders(token),
      body: json.encode({
        'amountPaid': amount,
        'paymentMethod': method,
        'transactionId': transactionId,
        'notes': notes,
        'paymentDate': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return Payment.fromJson(json.decode(response.body));
    } else if (response.statusCode == 400) {
      throw Exception('Payment failed: ${response.body}');
    } else {
      throw Exception('Failed to record payment: ${response.statusCode}');
    }
  }

  Future<List<Payment>> getPaymentHistory(String institutionId, String studentFeeId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No user logged in');

    final response = await http.get(
      Uri.parse('$baseUrl/$institutionId/api/fees/student-fees/$studentFeeId/payments'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Payment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payment history');
    }
  }
}
