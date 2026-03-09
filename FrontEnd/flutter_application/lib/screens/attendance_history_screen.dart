import 'package:flutter/material.dart';
import 'package:flutter_application/models/attendance_log_model.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:flutter_application/screens/regularisation_dialog.dart';
import 'package:go_router/go_router.dart';
import '../widgets/faculty_layout.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  // ── Data ───────────────────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  String? _institutionId;
  List<AttendanceLog> _history = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDarkMode = false;

  // ── Theme helpers ──────────────────────────────────────────────────────────
  static const _accent   = Color(0xFF4F46E5);
  static const _success  = Color(0xFF10B981);
  static const _warning  = Color(0xFFF59E0B);
  static const _danger   = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Institution ID not found.';
          _isLoading = false;
        });
      }
      return;
    }
    await _fetchAttendanceHistory();
  }

  Future<void> _fetchAttendanceHistory() async {
    if (_institutionId == null) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final history = await _apiService.getAttendanceHistory(_institutionId!);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load history: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showRegularisationDialog(AttendanceLog log) {
    showDialog(
      context: context,
      builder: (context) => RegularisationDialog(log: log),
    );
  }

  // ── Log card colour logic ──────────────────────────────
  Color _cardBgColor(AttendanceLog log) {
    final isRegularised = log.regularisationStatus == 'Regularised';
    final isOnCampus = log.locationStatus == 'On-Campus';
    if (isRegularised) {
      return _isDarkMode ? _warning.withOpacity(0.1) : const Color(0xFFFEF3C7).withOpacity(0.5);
    }
    if (isOnCampus) {
      return _isDarkMode ? _success.withOpacity(0.1) : const Color(0xFFECFDF5).withOpacity(0.5);
    }
    return _isDarkMode ? _danger.withOpacity(0.1) : const Color(0xFFFEF2F2).withOpacity(0.5);
  }

  Color _cardBorderColor(AttendanceLog log) {
    final isRegularised = log.regularisationStatus == 'Regularised';
    final isOnCampus = log.locationStatus == 'On-Campus';
    if (isRegularised) return _warning.withOpacity(0.3);
    if (isOnCampus) return _success.withOpacity(0.3);
    return _danger.withOpacity(0.3);
  }

  Color _cardAccentColor(AttendanceLog log) {
    final isRegularised = log.regularisationStatus == 'Regularised';
    final isOnCampus = log.locationStatus == 'On-Campus';
    if (isRegularised) return _warning;
    if (isOnCampus) return _success;
    return _danger;
  }

  IconData _locationIcon(AttendanceLog log) {
    final isRegularised = log.regularisationStatus == 'Regularised';
    final isOnCampus = log.locationStatus == 'On-Campus';
    if (isRegularised) return Icons.info_rounded;
    if (isOnCampus) return Icons.check_circle_rounded;
    return Icons.warning_rounded;
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: 'Clock-in History',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Attendance History', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading && _history.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return RefreshIndicator(
                  onRefresh: _fetchAttendanceHistory,
                  color: _accent,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attendance Records',
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Review your clock-in/out logs and campus presence',
                                      style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/$_institutionId/faculty/regularisation'),
                                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                                  label: const Text('Regularise'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            if (_errorMessage != null) _buildErrorState(),

                            _buildSummaryStrip(isMobile),
                            const SizedBox(height: 24),

                            if (_history.isEmpty && !_isLoading)
                              _buildEmptyState()
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _history.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) => _buildLogCard(_history[index], isMobile),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSummaryStrip(bool isMobile) {
    final total = _history.length;
    final onCampus = _history.where((l) => l.locationStatus == 'On-Campus').length;
    final offCampus = _history.where((l) => l.locationStatus != 'On-Campus' && l.regularisationStatus != 'Regularised').length;
    final regularised = _history.where((l) => l.regularisationStatus == 'Regularised').length;

    final chips = [
      {'label': 'Total Logs', 'count': total, 'color': _accent, 'icon': Icons.list_alt_rounded},
      {'label': 'On-Campus', 'count': onCampus, 'color': _success, 'icon': Icons.check_circle_rounded},
      {'label': 'Off-Campus', 'count': offCampus, 'color': _danger, 'icon': Icons.warning_rounded},
      {'label': 'Regularised', 'count': regularised, 'color': _warning, 'icon': Icons.info_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: chips.length,
      itemBuilder: (context, index) {
        final c = chips[index];
        return _summaryChip(c['label'] as String, c['count'] as int, c['color'] as Color, c['icon'] as IconData);
      },
    );
  }

  Widget _summaryChip(String label, int count, Color color, IconData icon) {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1.2)),
                Text(label, style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AttendanceLog log, bool isMobile) {
    final bgColor     = _cardBgColor(log);
    final borderColor = _cardBorderColor(log);
    final accentColor = _cardAccentColor(log);
    final locIcon     = _locationIcon(log);
    final isRegularised = log.regularisationStatus == 'Regularised';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRegularisationDialog(log),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.calendar_today_rounded, color: accentColor, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Text(log.formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    if (isRegularised)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _warning.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: _warning, size: 12),
                            SizedBox(width: 4),
                            Text('Regularised', style: TextStyle(color: _warning, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _timeInfo(Icons.login_rounded, 'IN', log.formattedClockInTime, _success)),
                    Container(width: 1, height: 24, color: borderColor),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _timeInfo(Icons.logout_rounded, 'OUT', log.formattedClockOutTime, _danger),
                    )),
                    _durationBadge(log.formattedDuration, accentColor),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(locIcon, color: accentColor, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log.locationDetail ?? 'Location N/A',
                        style: TextStyle(fontSize: 12, color: accentColor, fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: accentColor.withOpacity(0.5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeInfo(IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _durationBadge(String duration, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(duration, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.history_rounded, size: 64, color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No attendance records found.', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: _danger))),
        ],
      ),
    );
  }
}
