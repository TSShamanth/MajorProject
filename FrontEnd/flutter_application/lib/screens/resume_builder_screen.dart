import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/placement_registration_model.dart';
import '../services/api_service.dart';
import '../services/placement_service.dart';
import 'package:go_router/go_router.dart';

class ResumeBuilderScreen extends StatefulWidget {
  final String institutionId;
  const ResumeBuilderScreen({super.key, required this.institutionId});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  bool _isLoading = true;
  UserModel? _currentUser;
  PlacementRegistrationModel? _registration;
  
  late PlacementService _placementService;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _placementService = PlacementService(institutionId: widget.institutionId);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await _apiService.getMe(widget.institutionId);
      if (_currentUser != null) {
        _registration = await _placementService.getRegistration(_currentUser!.uid);
      }
    } catch (e) {
      debugPrint('Error loading resume data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_currentUser!.displayName, style: pw.TextStyle(font: boldFont, fontSize: 24)),
                      pw.Text(_currentUser!.email ?? '', style: pw.TextStyle(font: font, fontSize: 12)),
                      pw.Text(_currentUser!.phone ?? '', style: pw.TextStyle(font: font, fontSize: 12)),
                      pw.Text('USN: ${_currentUser!.usn ?? "N/A"}', style: pw.TextStyle(font: font, fontSize: 12)),
                    ],
                  ),
                  if (_currentUser!.photoUrl != null) 
                    pw.Container(
                      width: 80,
                      height: 80,
                      decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle),
                      // child: pw.Image(pw.MemoryImage(someBytes)), // Image loading is tricky in sync
                    ),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.indigo),
              pw.SizedBox(height: 20),

              // Education
              _buildPdfSectionTitle('EDUCATION', boldFont),
              pw.SizedBox(height: 10),
              _buildPdfEducationItem(
                'Bachelor of Engineering in ${_currentUser!.programme ?? "Computer Science"}',
                'RV University, Bangalore',
                'CGPA: ${_registration?.cgpa ?? _currentUser!.currentGPA ?? "N/A"} / 10.0',
                '2022 - 2026',
                font, boldFont
              ),
              pw.SizedBox(height: 20),

              // Skills
              _buildPdfSectionTitle('SKILLS', boldFont),
              pw.SizedBox(height: 10),
              pw.Text(
                _registration?.skills.join(' • ') ?? 'Skills not listed yet.',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 20),

              // Projects (Mock data since not in user model yet)
              _buildPdfSectionTitle('PROJECTS', boldFont),
              pw.SizedBox(height: 10),
              _buildPdfProjectItem(
                'College Management System',
                'Built a full-stack platform using Flutter and Spring Boot for university operations.',
                'Flutter, Spring Boot, Firebase, Firestore',
                font, boldFont
              ),
              pw.SizedBox(height: 10),
              _buildPdfProjectItem(
                'Automated Attendance Tracker',
                'Developed a real-time attendance tracking app with geofencing capabilities.',
                'Dart, Python, GPS API',
                font, boldFont
              ),
              pw.SizedBox(height: 20),

              // Summary/Objective
              _buildPdfSectionTitle('OBJECTIVE', boldFont),
              pw.SizedBox(height: 10),
              pw.Text(
                'Motivated final-year engineering student with a strong foundation in software development and problem-solving. Seeking to leverage skills in Flutter and Java to contribute to innovative projects at a forward-thinking organization.',
                style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 2),
              ),
              
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Generated on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfSectionTitle(String title, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
      child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.indigo)),
    );
  }

  pw.Widget _buildPdfEducationItem(String degree, String school, String grade, String period, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(degree, style: pw.TextStyle(font: boldFont, fontSize: 13)),
            pw.Text(period, style: pw.TextStyle(font: font, fontSize: 12)),
          ],
        ),
        pw.Text(school, style: pw.TextStyle(font: font, fontSize: 12)),
        pw.Text(grade, style: pw.TextStyle(font: boldFont, fontSize: 12)),
      ],
    );
  }

  pw.Widget _buildPdfProjectItem(String title, String desc, String tech, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 13)),
        pw.Text(desc, style: pw.TextStyle(font: font, fontSize: 12)),
        pw.Text('Technologies: $tech', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_currentUser == null) return const Scaffold(body: Center(child: Text('User not found')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Builder'),
        actions: [
          if (_registration == null)
            TextButton.icon(
              onPressed: () => context.push('/${widget.institutionId}/placement/registration'),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Update Profile', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        maxPageWidth: 700,
        pdfFileName: '${_currentUser!.displayName.replaceAll(" ", "_")}_Resume.pdf',
        actions: const [
          PdfPrintAction(),
        ],
      ),
    );
  }
}
