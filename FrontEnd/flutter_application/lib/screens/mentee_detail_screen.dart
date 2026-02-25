import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/mentor_meeting_model.dart';
import '../models/mentee_concern_model.dart';
import '../services/mentorship_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final mentee = await _mentorshipService.getMenteeDetail(widget.institutionId, widget.menteeId);
      
      // These calls now correctly pass the studentId to the filtered backend logic
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_mentee == null) return const Scaffold(body: Center(child: Text('Mentee not found')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_mentee!.displayName),
        backgroundColor: const Color(0xFF312E81),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Academic'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAcademicTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildContactInfo(),
          const SizedBox(height: 20),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFEEF2FF),
              backgroundImage: _mentee!.photoUrl != null ? NetworkImage(_mentee!.photoUrl!) : null,
              child: _mentee!.photoUrl == null ? const Icon(Icons.person, size: 40, color: Color(0xFF4F46E5)) : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_mentee!.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                Text('USN: ${_mentee!.usn ?? 'N/A'}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                  child: Text('Sem ${_mentee!.sem ?? 'N/A'} | ${_mentee!.programme ?? 'N/A'}', 
                    style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, 'Email Address', _mentee!.email ?? 'N/A'),
          const Divider(height: 32),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', _mentee!.phone ?? 'N/A'),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_outlined, 'Residential Address', _mentee!.address ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMiniStat('Attendance', '${_mentee!.attendancePercentage?.toStringAsFixed(1) ?? '0'}%', Colors.green, _mentee!.attendanceHistory)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStat('Current GPA', _mentee!.currentGPA?.toStringAsFixed(2) ?? '0.0', Colors.blue, _mentee!.gpaHistory)),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, List<double>? history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
              if (history != null && history.isNotEmpty)
                SizedBox(
                  width: 50,
                  height: 25,
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

  Widget _buildAcademicTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Trend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 16),
            if (_mentee!.attendanceHistory != null && _mentee!.attendanceHistory!.isNotEmpty) ...[
              const Text('Overall Attendance (%)', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: CustomPaint(painter: SparklinePainter(data: _mentee!.attendanceHistory!, color: Colors.green, fill: true)),
              ),
            ],
            const SizedBox(height: 32),
            const Center(child: Text('Detailed subject-wise records will appear here.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Mentorship Journey', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(height: 20),
        ..._meetings.map((m) => _buildTimelineItem(m.date, 'Meeting: ${m.notes}', m.status, Icons.event_note_rounded, const Color(0xFF4F46E5))),
        const SizedBox(height: 8),
        ..._concerns.map((c) => _buildTimelineItem(c.createdAt, 'Concern: ${c.concernType}', c.status, Icons.report_problem_outlined, Colors.orange)),
      ],
    );
  }

  Widget _buildTimelineItem(DateTime date, String title, String status, IconData icon, Color color) {
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
              Expanded(child: Container(width: 2, color: const Color(0xFFE5E7EB))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
                  const SizedBox(height: 2),
                  Text('Status: $status', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
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
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double dx = size.width / (data.length - 1);
    
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double minVal = data.reduce((a, b) => a < b ? a : b);
    
    // Ensure some padding and avoid div by zero
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
