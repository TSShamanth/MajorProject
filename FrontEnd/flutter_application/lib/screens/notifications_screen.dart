import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<NotificationModel>> _notificationsFuture;

  String _getInstitutionId() {
    return GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'] ?? '';
  }

  @override
  void initState() {
    super.initState();
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
      // ignore errors for now
    }
  }

  IconData _getNotificationIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('attendance') || t.contains('clock')) return Icons.access_time_rounded;
    if (t.contains('leave')) return Icons.event_busy_rounded;
    if (t.contains('exam')) return Icons.assignment_rounded;
    if (t.contains('announcement')) return Icons.campaign_rounded;
    if (t.contains('regularisation')) return Icons.edit_calendar_rounded;
    return Icons.notifications_none_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  TextButton(onPressed: _fetchNotifications, child: const Text('Retry')),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('All caught up!', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return InkWell(
                onTap: () async {
                  if (!n.read) {
                    await _markRead(n.id);
                  }
                  if (!mounted) return;
                  if (n.route != null && n.route!.isNotEmpty) {
                    final inst = _getInstitutionId();
                    context.push('/$inst${n.route}');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: n.read ? Colors.transparent : theme.primaryColor.withOpacity(0.04),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: n.read ? Colors.grey[100] : theme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getNotificationIcon(n.title),
                              color: n.read ? Colors.grey[600] : theme.primaryColor,
                              size: 24,
                            ),
                          ),
                          if (!n.read)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.read ? FontWeight.w500 : FontWeight.bold,
                                      fontSize: 15,
                                      color: n.read ? Colors.black87 : Colors.black,
                                    ),
                                  ),
                                ),
                                Text(
                                  timeago.format(n.createdAt),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: n.read ? Colors.grey[600] : Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
