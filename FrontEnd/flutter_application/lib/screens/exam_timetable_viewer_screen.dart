import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/exam_schedule_entry.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExamTimetableViewerScreen extends StatefulWidget {
  final String examId;

  const ExamTimetableViewerScreen({super.key, required this.examId});

  @override
  ExamTimetableViewerScreenState createState() => ExamTimetableViewerScreenState();
}

class ExamTimetableViewerScreenState extends State<ExamTimetableViewerScreen> {
  late ApiService _apiService;
  Exam? _exam;
  bool _isLoading = true;
  Map<String, List<MapEntry<String, ExamScheduleEntry>>> _groupedSchedule = {};

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchExamDetails();
  }

  Future<void> _fetchExamDetails() async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      final exam = await _apiService.getExamById(institutionId, widget.examId);
      _groupScheduleByDate(exam.schedule);
      if (mounted) {
        setState(() {
          _exam = exam;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _exam = null;
          _isLoading = false;
        });
      }
    }
  }

  void _groupScheduleByDate(Map<String, ExamScheduleEntry> schedule) {
    final grouped = <String, List<MapEntry<String, ExamScheduleEntry>>>{};
    schedule.forEach((subject, details) {
      final date = details.date;
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(MapEntry(subject, details));
    });
    final sortedKeys = grouped.keys.toList()..sort();
    _groupedSchedule = {for (var key in sortedKeys) key: grouped[key]!};
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('EEEE, MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Exam Timetable - ${_exam?.name ?? ''}',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Date', 'Subject', 'Time'],
              data: _groupedSchedule.entries.expand((dateEntry) {
                return dateEntry.value.map((scheduleEntry) {
                  return [
                    _formatDate(dateEntry.key),
                    scheduleEntry.key,
                    '${scheduleEntry.value.startTime} - ${scheduleEntry.value.endTime}',
                  ];
                });
              }).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(),
              cellAlignment: pw.Alignment.center,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          ];
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
        title: Text(_exam != null ? '${_exam!.name} - Timetable' : 'Timetable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _exam == null ? null : _generatePdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exam == null || _groupedSchedule.isEmpty
              ? const Center(child: Text('Timetable not yet scheduled.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Subject')),
                      DataColumn(label: Text('Time')),
                    ],
                    rows: _groupedSchedule.entries.expand((dateEntry) {
                      return dateEntry.value.map((scheduleEntry) {
                        return DataRow(
                          cells: [
                            DataCell(Text(_formatDate(dateEntry.key))),
                            DataCell(Text(scheduleEntry.key)),
                            DataCell(Text('${scheduleEntry.value.startTime} - ${scheduleEntry.value.endTime}')),
                          ],
                        );
                      });
                    }).toList(),
                  ),
                ),
    );
  }
}

