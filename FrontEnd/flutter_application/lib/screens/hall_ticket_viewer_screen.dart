import 'package:flutter/material.dart';
import 'package:flutter_application/models/hall_ticket_data.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/student_layout.dart';

class HallTicketViewerScreen extends StatefulWidget {
  final String examId;
  final String studentId;

  const HallTicketViewerScreen({super.key, required this.examId, required this.studentId});

  @override
  HallTicketViewerScreenState createState() => HallTicketViewerScreenState();
}

class HallTicketViewerScreenState extends State<HallTicketViewerScreen> {
  final ApiService _apiService = ApiService();
  HallTicketData? _hallTicketData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHallTicketData();
  }

  Future<void> _fetchHallTicketData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        if (mounted) setState(() => _isLoading = false);
        _errorMessage = 'Institution ID not found.';
        return;
      }
      final data = await _apiService.getHallTicketData(institutionId, widget.examId, widget.studentId);
      if (mounted) {
        setState(() {
          _hallTicketData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load hall ticket data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generatePdf(HallTicketData data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(data.examName.toUpperCase(), 
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                ),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text('OFFICIAL HALL TICKET', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700))),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NAME: ${data.studentName.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text('USN: ${data.studentUsn ?? 'N/A'}'),
                        pw.SizedBox(height: 5),
                        pw.Text('DEPARTMENT: ${data.studentDepartment ?? 'N/A'}'),
                        pw.SizedBox(height: 5),
                        pw.Text('SEMESTER: ${data.studentSemester ?? 'N/A'}'),
                      ],
                    ),
                    pw.Container(
                      height: 80,
                      width: 80,
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'Student ID: ${data.studentId}, Exam ID: ${data.examId}',
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Text('EXAMINATION SCHEDULE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['SUBJECT', 'DATE', 'TIME', 'ROOM', 'SEAT'],
                  data: data.subjects.map((subject) {
                    final schedule = data.schedule[subject];
                    final seating = data.studentSeatingEntry;
                    return [
                      subject,
                      schedule?.date ?? 'N/A',
                      '${schedule?.startTime ?? ''} - ${schedule?.endTime ?? ''}',
                      data.studentRoomDetails.name,
                      seating.seatNumber,
                    ];
                  }).toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
                  cellAlignment: pw.Alignment.center,
                  cellPadding: const pw.EdgeInsets.all(8),
                ),
                pw.SizedBox(height: 40),
                pw.Text('CANDIDATE INSTRUCTIONS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Bullet(text: 'Please bring a valid University ID card along with this hall ticket.'),
                pw.Bullet(text: 'Electronic devices, smartwatches, and programmable calculators are strictly prohibited.'),
                pw.Bullet(text: 'Reach the examination hall at least 20 minutes before the scheduled commencement.'),
                pw.Bullet(text: 'Verify all details on the hall ticket and report discrepancies to the registrar immediately.'),
                pw.SizedBox(height: 60),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('Candidate Signature', style: const pw.TextStyle(fontSize: 10)),
                    ]),
                    pw.Column(children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('Controller of Exams', style: const pw.TextStyle(fontSize: 10)),
                    ]),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: 'Hall Ticket Viewer',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Hall Tickets', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('View', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(_errorMessage!)
              : _hallTicketData == null
                  ? const Center(child: Text('Hall ticket data not available.'))
                  : _buildTicketContent(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildTicketContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _generatePdf(_hallTicketData!),
                icon: const Icon(Icons.print_rounded),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Paper-style Document
          Center(
            child: Container(
              width: 800,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _hallTicketData!.examName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('OFFICIAL HALL TICKET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('NAME', _hallTicketData!.studentName.toUpperCase(), isBold: true),
                          _buildDetailRow('USN', _hallTicketData!.studentUsn ?? 'N/A'),
                          _buildDetailRow('DEPT', _hallTicketData!.studentDepartment ?? 'N/A'),
                          _buildDetailRow('SEM', _hallTicketData!.studentSemester ?? 'N/A'),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: 'Student ID: ${_hallTicketData!.studentId}, Exam ID: ${_hallTicketData!.examId}',
                          version: QrVersions.auto,
                          size: 100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text('EXAMINATION SCHEDULE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                        children: ['SUBJECT', 'DATE', 'TIME', 'ROOM', 'SEAT'].map((h) => Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(h, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                        )).toList(),
                      ),
                      ..._hallTicketData!.subjects.map((subject) {
                        final schedule = _hallTicketData!.schedule[subject];
                        final seating = _hallTicketData!.studentSeatingEntry;
                        return TableRow(
                          children: [
                            subject,
                            schedule?.date ?? 'N/A',
                            '${schedule?.startTime ?? ''} - ${schedule?.endTime ?? ''}',
                            _hallTicketData!.studentRoomDetails.name,
                            seating.seatNumber,
                          ].map((t) => Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                          )).toList(),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text('INSTRUCTIONS TO THE CANDIDATE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  const Text('1. Please bring a valid University ID card along with this hall ticket.', style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.6)),
                  const Text('2. Electronic devices, smartwatches, and programmable calculators are strictly prohibited.', style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.6)),
                  const Text('3. Reach the examination hall at least 20 minutes before the scheduled commencement.', style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.6)),
                  const Text('4. Verify all details on the hall ticket and report discrepancies to the registrar immediately.', style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.6)),
                  const SizedBox(height: 80),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSignatureLine('Candidate Signature'),
                      _buildSignatureLine('Controller of Examinations'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildSignatureLine(String label) {
    return Column(
      children: [
        Container(width: 180, height: 1, color: Colors.black),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
      ],
    );
  }
}
