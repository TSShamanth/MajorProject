import 'package:flutter/material.dart';
import 'package:flutter_application/models/exam_model.dart';
import 'package:flutter_application/models/exam_schedule_entry.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/admin_layout.dart';

class ExamTimetableViewerScreen extends StatefulWidget {
  final String examId;

  const ExamTimetableViewerScreen({super.key, required this.examId});

  @override
  State<ExamTimetableViewerScreen> createState() => _ExamTimetableViewerScreenState();
}

class _ExamTimetableViewerScreenState extends State<ExamTimetableViewerScreen> {
  late ApiService _apiService;
  Exam? _exam;
  bool _isLoading = true;
  String? _institutionId;
  Map<String, List<MapEntry<String, ExamScheduleEntry>>> _groupedSchedule = {};
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      _fetchExamDetails();
    }
  }

  Future<void> _fetchExamDetails() async {
    try {
      final exam = await _apiService.getExamById(_institutionId!, widget.examId);
      if (mounted) {
        setState(() {
          _exam = exam;
          _groupScheduleByDate(exam.schedule);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _groupScheduleByDate(Map<String, ExamScheduleEntry> schedule) {
    final grouped = <String, List<MapEntry<String, ExamScheduleEntry>>>{};
    schedule.forEach((subject, details) {
      final date = details.date;
      if (grouped[date] == null) grouped[date] = [];
      grouped[date]!.add(MapEntry(subject, details));
    });
    final sortedKeys = grouped.keys.toList()..sort();
    _groupedSchedule = {for (var key in sortedKeys) key: grouped[key]!};
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('EEEE, dd MMM yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  Future<void> _generatePdf() async {
    if (_exam == null) return;
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('OFFICIAL EXAM TIMETABLE', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Text(_exam!.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),
            pw.Table.fromTextArray(
              headers: ['Date', 'Subject Code', 'Time Slot', 'Duration'],
              data: _groupedSchedule.entries.expand((dateEntry) {
                return dateEntry.value.map((scheduleEntry) {
                  return [
                    _formatDate(dateEntry.key),
                    scheduleEntry.key,
                    '${scheduleEntry.value.startTime} - ${scheduleEntry.value.endTime}',
                    scheduleEntry.value.duration,
                  ];
                });
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
              cellPadding: const pw.EdgeInsets.all(8),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Timetable Viewer',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/exam-management'),
          child: Text('Exams', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Timetable', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_exam?.name ?? 'Exam Timetable', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Official examination schedule and timing', style: TextStyle(fontSize: 14, color: textSecondary)),
                      ],
                    ),
                    if (_groupedSchedule.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _generatePdf,
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                
                Expanded(
                  child: _groupedSchedule.isEmpty 
                    ? _buildEmptyState(textSecondary)
                    : ListView.builder(
                        itemCount: _groupedSchedule.length,
                        itemBuilder: (context, index) {
                          final date = _groupedSchedule.keys.elementAt(index);
                          final sessions = _groupedSchedule[date]!;
                          return _buildDateGroup(date, sessions, textPrimary, textSecondary);
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDateGroup(String date, List<MapEntry<String, ExamScheduleEntry>> sessions, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF4F46E5)),
              const SizedBox(width: 12),
              Text(_formatDate(date), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
            ],
          ),
        ),
        ...sessions.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5), size: 24),
            ),
            title: Text(s.key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Text('${s.value.startTime} - ${s.value.endTime}', style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  Icon(Icons.timer_rounded, size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Text(s.value.duration, style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Timetable not yet scheduled', style: TextStyle(fontSize: 16, color: textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
