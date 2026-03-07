import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application/services/session_manager.dart';
import '../widgets/admin_layout.dart';

class AlumniDashboardScreen extends StatefulWidget {
  const AlumniDashboardScreen({super.key});

  @override
  State<AlumniDashboardScreen> createState() => _AlumniDashboardScreenState();
}

class _AlumniDashboardScreenState extends State<AlumniDashboardScreen> {
  String? _institutionId;
  bool _isDarkMode = false;

  // ── Theme helpers ──────────────────────────────────────────────────────────
  Color get _cardColor =>
      _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary =>
      _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary =>
      _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  static const _accent  = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _danger  = Color(0xFFEF4444);
  static const _purple  = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _fetchInstitutionId();
  }

  Future<void> _fetchInstitutionId() async {
    final id = await SessionManager.getInstitutionId();
    if (mounted) {
      setState(() {
        _institutionId = id;
      });
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _navigateTo(String route) {
    if (_institutionId != null) {
      context.push('/$_institutionId$route');
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return AdminLayout(
      title: 'Alumni Network',
      child: _buildBody(isMobile: isMobile),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody({required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Overview', style: TextStyle(fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.w800, color: _textPrimary)),
          const SizedBox(height: 20),
          _buildStatsGrid(isMobile),
          const SizedBox(height: 32),
          Text('Alumni Portal Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 16),
          _buildFeatureGrid(isMobile),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 3 : 2.5,
      children: [
        _buildStatCard('Total Alumni', '1,250', Icons.group_rounded, _accent),
        _buildStatCard('Active Jobs', '42', Icons.work_rounded, _warning),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _textPrimary)),
              Text(label, style: TextStyle(fontSize: 13, color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : (MediaQuery.of(context).size.width > 1200 ? 3 : 2),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: [
        _buildFeatureCard(
          icon: Icons.search_rounded,
          title: 'Alumni Directory',
          subtitle: 'Search and filter the entire database.',
          color: _accent,
          onTap: () => _navigateTo('/admin/alumni-directory'),
        ),
        _buildFeatureCard(
          icon: Icons.work_outline_rounded,
          title: 'Job Board',
          subtitle: 'Opportunities from alumni network.',
          color: _success,
          onTap: () => _navigateTo('/admin/alumni-job-board'),
        ),
        _buildFeatureCard(
          icon: Icons.event_rounded,
          title: 'Alumni Events',
          subtitle: 'Manage alumni meetups and events.',
          color: _purple,
          onTap: () => _navigateTo('/events'),
        ),
        _buildFeatureCard(
          icon: Icons.favorite_rounded,
          title: 'Donation Campaigns',
          subtitle: 'Manage fundraising drives.',
          color: _danger,
          onTap: () {}, // Route not yet defined
        ),
        _buildFeatureCard(
          icon: Icons.analytics_outlined,
          title: 'Network Analytics',
          subtitle: 'Track engagement and growth.',
          color: _warning,
          onTap: () {}, // Route not yet defined
        ),
        _buildFeatureCard(
          icon: Icons.settings_outlined,
          title: 'Portal Settings',
          subtitle: 'Configure alumni network options.',
          color: _textSecondary,
          onTap: () {}, // Route not yet defined
        ),
      ],
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: _textSecondary.withOpacity(0.5), size: 14),
          ],
        ),
      ),
    );
  }
}
