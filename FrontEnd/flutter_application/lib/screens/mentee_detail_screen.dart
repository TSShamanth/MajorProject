import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/mentor_meeting_model.dart';
import '../models/mentee_concern_model.dart';
import '../services/mentorship_service.dart';
import '../widgets/faculty_layout.dart';
import '../widgets/ai_insight_modal.dart';

class MenteeDetailScreen extends StatefulWidget {
  final String menteeId;
  final String institutionId;

  const MenteeDetailScreen({
    super.key,
    required this.menteeId,
    required this.institutionId,
  });

  @override
  State<MenteeDetailScreen> createState() => _MenteeDetailScreenState();
}

class _MenteeDetailScreenState extends State<MenteeDetailScreen> with SingleTickerProviderStateMixin {
  final MentorshipService _mentorshipService = MentorshipService();
  
  UserModel? _mentee;
  List<MentorMeeting> _meetings = [];
  List<MenteeConcern> _concerns = [];
  bool _isLoading = true;
  late TabController _tabController;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final mentee = await _mentorshipService.getMenteeDetail(widget.institutionId, widget.menteeId);
      final meetings = await _mentorshipService.getMeetings(widget.institutionId, studentId: widget.menteeId);
      final concerns = await _mentorshipService.getConcerns(widget.institutionId, studentId: widget.menteeId);

      if (mounted) {
        setState(() {
          _mentee = mentee;
          _meetings = meetings;
          _concerns = concerns;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: _mentee?.displayName ?? 'Mentee Detail',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Mentees', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Detail', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mentee == null
              ? const Center(child: Text('Mentee not found'))
              : Column(
                  children: [
                    Container(
                      color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF4F46E5),
                        unselectedLabelColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        indicatorColor: const Color(0xFF4F46E5),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Academic'),
                          Tab(text: 'History'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(textPrimary),
                          _buildAcademicTab(textPrimary),
                          _buildHistoryTab(textPrimary),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab(Color textPrimary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileCard(textPrimary),
          const SizedBox(height: 24),
          _buildContactInfo(textPrimary),
          const SizedBox(height: 24),
          _buildQuickStats(textPrimary),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Color textPrimary) {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _mentee!.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(_mentee!.photoUrl!, fit: BoxFit.cover, width: 100, height: 100),
                    )
                  : Text(
                      _mentee!.displayName.isNotEmpty ? _mentee!.displayName[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mentee!.displayName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                ),
                Text(
                  'USN: ${_mentee!.usn ?? 'N/A'}',
                  style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 15),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Sem ${_mentee!.sem ?? 'N/A'} | ${_mentee!.programme ?? 'N/A'}',
                        style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AiInsightModal(studentId: widget.menteeId),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'AI Insights',
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Color textPrimary) {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, 'Email Address', _mentee!.email ?? 'N/A', textPrimary),
          const Divider(height: 32),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', _mentee!.phone ?? 'N/A', textPrimary),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_outlined, 'Residential Address', _mentee!.address ?? 'N/A', textPrimary),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Color textPrimary) {
    return Row(
      children: [
        Expanded(child: _buildMiniStat('Attendance', '${_mentee!.attendancePercentage?.toStringAsFixed(1) ?? '0'}%', Colors.green, _mentee!.attendanceHistory)),
        const SizedBox(width: 16),
        Expanded(child: _buildMiniStat('Current GPA', _mentee!.currentGPA?.toStringAsFixed(2) ?? '0.0', Colors.blue, _mentee!.gpaHistory)),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, List<double>? history) {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              if (history != null && history.isNotEmpty)
                SizedBox(
                  width: 60,
                  height: 30,
                  child: CustomPaint(
                    painter: SparklinePainter(data: history, color: color),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicTab(Color textPrimary) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 24),
            if (_mentee!.attendanceHistory != null && _mentee!.attendanceHistory!.isNotEmpty) ...[
              Text('Overall Attendance (%)', style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
                child: CustomPaint(painter: SparklinePainter(data: _mentee!.attendanceHistory!, color: Colors.green, fill: true)),
              ),
            ],
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.analytics_outlined, size: 48, color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Detailed subject-wise records will appear here.', style: TextStyle(color: _isDarkMode ? Colors.grey[500] : Colors.grey[500], fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(Color textPrimary) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Mentorship Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 24),
        if (_meetings.isEmpty && _concerns.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(Icons.history_rounded, size: 48, color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No mentorship history yet.', style: TextStyle(color: _isDarkMode ? Colors.grey[500] : Colors.grey[500])),
                ],
              ),
            ),
          )
        else ...[
          ..._meetings.map((m) => _buildTimelineItem(m.date, 'Meeting: ${m.notes}', m.status, Icons.event_note_rounded, const Color(0xFF4F46E5), textPrimary)),
          const SizedBox(height: 8),
          ..._concerns.map((c) => _buildTimelineItem(c.createdAt, 'Concern: ${c.concernType}', c.status, Icons.report_problem_outlined, Colors.orange, textPrimary)),
        ],
      ],
    );
  }

  Widget _buildTimelineItem(DateTime date, String title, String status, IconData icon, Color color, Color textPrimary) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color)
              ),
              Expanded(child: Container(width: 2, color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${date.day}/${date.month}/${date.year}', style: TextStyle(color: _isDarkMode ? Colors.grey[500] : Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textPrimary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10)
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
        ]),
      ],
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool fill;

  SparklinePainter({required this.data, required this.color, this.fill = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double dx = size.width / (data.length - 1);
    
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double minVal = data.reduce((a, b) => a < b ? a : b);
    
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }
    
    final double range = maxVal - minVal;

    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    if (fill) {
      final fillPath = Path.from(path);
      fillPath.lineTo((data.length - 1) * dx, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
      
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) => true;
}
