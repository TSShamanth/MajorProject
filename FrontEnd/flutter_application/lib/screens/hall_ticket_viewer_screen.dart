import 'package:flutter/material.dart';
import 'package:flutter_application/models/hall_ticket_data.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

    // You can also load a font to use in the PDF
    // final font = await PdfGoogleFonts.robotoRegular();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(data.examName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Name: ${data.studentName}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('USN: ${data.studentUsn ?? 'N/A'}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('Department: ${data.studentDepartment ?? 'N/A'}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('Semester: ${data.studentSemester ?? 'N/A'}', style: const pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                  pw.Container(
                    height: 100,
                    width: 100,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'Student ID: ${data.studentId}, Exam ID: ${data.examId}',
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Exam Schedule & Seating:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                headers: ['Subject', 'Date', 'Time', 'Room', 'Seat'],
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
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.center,
              ),
              pw.SizedBox(height: 20),
              pw.Text('Instructions:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('1. Please bring a valid ID card along with this hall ticket.'),
              pw.Text('2. Electronic devices are not allowed inside the examination hall.'),
              pw.Text('3. Reach the examination hall 15 minutes before the scheduled time.'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hall Ticket'),
        actions: [
          if (_hallTicketData != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _generatePdf(_hallTicketData!),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _hallTicketData == null
                  ? const Center(child: Text('Hall ticket data not available.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              _hallTicketData!.examName,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Name: ${_hallTicketData!.studentName}'),
                                  Text('USN: ${_hallTicketData!.studentUsn ?? 'N/A'}'),
                                  Text('Department: ${_hallTicketData!.studentDepartment ?? 'N/A'}'),
                                  Text('Semester: ${_hallTicketData!.studentSemester ?? 'N/A'}'),
                                ],
                              ),
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: QrImageView(
                                  data: 'Student ID: ${_hallTicketData!.studentId}, Exam ID: ${_hallTicketData!.examId}',
                                  version: QrVersions.auto,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Exam Schedule & Seating:', style: Theme.of(context).textTheme.titleLarge),
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Subject')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Time')),
                              DataColumn(label: Text('Room')),
                              DataColumn(label: Text('Seat')),
                            ],
                            rows: _hallTicketData!.subjects.map((subject) {
                              final schedule = _hallTicketData!.schedule[subject];
                              final seating = _hallTicketData!.studentSeatingEntry;
                              return DataRow(
                                cells: [
                                  DataCell(Text(subject)),
                                  DataCell(Text(schedule?.date ?? 'N/A')),
                                  DataCell(Text('${schedule?.startTime ?? ''} - ${schedule?.endTime ?? ''}')),
                                  DataCell(Text(_hallTicketData!.studentRoomDetails.name)),
                                  DataCell(Text(seating.seatNumber)),
                                ],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Text('Instructions:', style: Theme.of(context).textTheme.titleLarge),
                          const Text('''1. Please bring a valid ID card along with this hall ticket.
2. Electronic devices are not allowed inside the examination hall.
3. Reach the examination hall 15 minutes before the scheduled time.'''),
                        ],
                      ),
                    ),
    );
  }
}
