import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../widgets/admin_layout.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<NotificationModel>> _notificationsFuture;
  String? _institutionId;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final id = await SessionManager.getInstitutionId();
    if (mounted) {
      setState(() => _institutionId = id);
    }
    _fetchNotifications();
  }

  void _fetchNotifications() {
    setState(() {
      _notificationsFuture = _apiService.getNotifications();
    });
  }

  Future<void> _markRead(String id) async {
    try {
      await _apiService.markNotificationRead(id);
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllRead() async {
    try {
      final notifications = await _notificationsFuture;
      for (var n in notifications) {
        if (!n.read) {
          await _apiService.markNotificationRead(n.id);
        }
      }
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  IconData _getNotificationIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('attendance') || t.contains('clock')) return Icons.access_time_rounded;
    if (t.contains('leave')) return Icons.event_busy_rounded;
    if (t.contains('exam')) return Icons.assignment_rounded;
    if (t.contains('announcement')) return Icons.campaign_rounded;
    if (t.contains('regularisation')) return Icons.edit_calendar_rounded;
    return Icons.notifications_rounded;
  }

  Color _getNotificationColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('leave') || t.contains('regularisation')) return const Color(0xFFF59E0B);
    if (t.contains('exam')) return const Color(0xFFEF4444);
    if (t.contains('announcement')) return const Color(0xFF10B981);
    return const Color(0xFF4F46E5);
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: 'Notifications Center',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Notifications', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: Padding(
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
                    Text(
                      'Your Notifications',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text('Stay updated with the latest alerts and activities', style: TextStyle(fontSize: 14, color: textSecondary)),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _markAllRead,
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Mark All Read'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _fetchNotifications,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh Notifications',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: FutureBuilder<List<NotificationModel>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString(), textPrimary, textSecondary);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(textSecondary);
                  }

                  final notifications = snapshot.data!;
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(notifications[index], textPrimary, textSecondary);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n, Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final iconColor = _getNotificationColor(n.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: !n.read ? (_isDarkMode ? const Color(0xFF374151).withOpacity(0.3) : const Color(0xFF4F46E5).withOpacity(0.03)) : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: !n.read ? const Color(0xFF4F46E5).withOpacity(0.3) : borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!n.read) await _markRead(n.id);
            if (!mounted || _institutionId == null) return;
            if (n.route != null && n.route!.isNotEmpty) {
              context.push('/$_institutionId${n.route}');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getNotificationIcon(n.title), color: iconColor, size: 24),
                    ),
                    if (!n.read)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                            border: Border.all(color: cardColor, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: !n.read ? FontWeight.bold : FontWeight.w600,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            timeago.format(n.createdAt),
                            style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: !n.read ? FontWeight.w600 : FontWeight.normal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        n.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: !n.read ? textPrimary.withOpacity(0.9) : textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, size: 64, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text('You have no new notifications right now.', style: TextStyle(fontSize: 14, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          Text('Failed to load notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: textSecondary, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchNotifications,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
