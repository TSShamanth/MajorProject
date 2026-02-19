import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications found.'));
          }

          final notifications = snapshot.data!;
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                tileColor: n.read ? null : Colors.grey.shade200,
                title: Text(n.title),
                subtitle: Text(n.message),
                trailing: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(n.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () async {
                  if (!n.read) {
                    await _markRead(n.id);
                  }
                  if (!mounted) return;
                  // follow optional route embedded in notification
                  if (n.route != null && n.route!.isNotEmpty) {
                    final inst = _getInstitutionId();
                    context.push('/$inst${n.route}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
