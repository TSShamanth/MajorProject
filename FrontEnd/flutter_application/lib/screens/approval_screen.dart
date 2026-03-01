import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_layout.dart';
import '../services/session_manager.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  String? _institutionId;
  bool _isDarkMode = false;

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

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return AdminLayout(
      title: 'Approvals',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Approvals', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approvals Hub',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and review all pending requests and applications',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildApprovalCard(
                  title: 'Regularisation',
                  subtitle: 'Review attendance correction requests from faculty',
                  icon: Icons.history_rounded,
                  color: const Color(0xFF4F46E5),
                  count: '5 Pending', // Mock count
                  onTap: () {
                    if (_institutionId != null) {
                      context.push('/$_institutionId/admin/regularisation');
                    }
                  },
                ),
                _buildApprovalCard(
                  title: 'Leave Applications',
                  subtitle: 'Approve or reject leave requests from staff and students',
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF10B981),
                  count: '3 Pending', // Mock count
                  onTap: () {
                    // Navigate to leave approvals when implemented
                  },
                ),
                _buildApprovalCard(
                  title: 'Expense Claims',
                  subtitle: 'Review reimbursement and expense requests',
                  icon: Icons.payments_rounded,
                  color: const Color(0xFFF59E0B),
                  count: '0 Pending',
                  onTap: () {
                    // Navigate to expense approvals
                  },
                ),
                _buildApprovalCard(
                  title: 'Other Requests',
                  subtitle: 'Review miscellaneous administrative requests',
                  icon: Icons.more_horiz_rounded,
                  color: const Color(0xFF8B5CF6),
                  count: '2 Pending',
                  onTap: () {
                    // Navigate to other requests
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String count,
    required VoidCallback onTap,
  }) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                if (count != '0 Pending')
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardColor, width: 2),
                      ),
                      child: Text(
                        count.split(' ')[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              count,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: count == '0 Pending' ? Colors.grey[500] : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
