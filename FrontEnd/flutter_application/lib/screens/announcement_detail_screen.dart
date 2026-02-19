import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late AnnouncementService _announcementService;
  late ApiService _apiService;
  String? _institutionId;
  UserModel? _currentUser;
  late AnnouncementModel _announcement;
  bool _isLoading = false;
  bool _hasViewedMarked = false;

  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService();
    _apiService = ApiService();
    _announcement = widget.announcement;
    _initializeData();
  }

  Future<void> _initializeData() async {
    final institutionId = await SessionManager.getInstitutionId();
    setState(() {
      _institutionId = institutionId;
    });

    if (_institutionId != null) {
      _fetchCurrentUser();
      _markAsViewed();
      _fetchLatestAnnouncement();
    }
  }

  Future<void> _fetchCurrentUser() async {
    if (_institutionId == null) return;
    try {
      final user = await _apiService.getMe(_institutionId!);
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  Future<void> _fetchLatestAnnouncement() async {
    if (_institutionId == null) return;
    try {
      final announcement = await _announcementService.getAnnouncementById(
        _institutionId!,
        _announcement.id,
      );
      setState(() {
        _announcement = announcement;
      });
    } catch (e) {
      debugPrint('Error fetching latest announcement: $e');
    }
  }

  Future<void> _markAsViewed() async {
    if (_institutionId == null || _hasViewedMarked) return;
    try {
      await _announcementService.markAnnouncementAsViewed(
        _institutionId!,
        _announcement.id,
      );
      setState(() {
        _hasViewedMarked = true;
      });
    } catch (e) {
      debugPrint('Error marking as viewed: $e');
    }
  }

  Future<void> _editAnnouncement() async {
    if (_currentUser?.uid == _announcement.createdBy ||
        _currentUser?.role == 'admin') {
      context.push(
        // ignore: unnecessary_brace_in_string_interps
        '/${_institutionId}/announcements/${_announcement.id}/edit',
        extra: _announcement,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only edit your own announcements')),
      );
    }
  }

  Future<void> _deleteAnnouncement() async {
    if (_currentUser?.uid != _announcement.createdBy &&
        _currentUser?.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own announcements')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && _institutionId != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _announcementService.deleteAnnouncement(
          _institutionId!,
          _announcement.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted successfully')),
          );
          context.pop();
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting announcement: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _currentUser?.uid == _announcement.createdBy ||
        _currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: canEdit
            ? [
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: _editAnnouncement,
                      child: const Text('Edit'),
                    ),
                    PopupMenuItem(
                      onTap: _deleteAnnouncement,
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ]
            : [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    color: const Color(0xFF1E293B).withOpacity(0.05),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Priority and Category Badges
                        Row(
                          children: [
                            _buildPriorityBadge(_announcement.priority),
                            const SizedBox(width: 8),
                            _buildCategoryChip(_announcement.category),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '👁️ ${_announcement.viewCount} views',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          _announcement.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Meta Information
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              child: const Icon(Icons.person, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _announcement.createdByName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${_announcement.createdByRole.toUpperCase()} • ${DateFormat('dd MMM yyyy, hh:mm a').format(_announcement.createdAt)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Main Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Text(
                          _announcement.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey,
                          ),
                        ),

                        if (_announcement.content != null &&
                            _announcement.content!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          Text(
                            'Details',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              _announcement.content!,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],

                        // Target Audience
                        const SizedBox(height: 24),
                        Text(
                          'Visible To',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _announcement.targetAudience
                              .map((audience) => Chip(
                                    label: Text(_formatRole(audience)),
                                    backgroundColor: Colors.blue.withOpacity(0.2),
                                    labelStyle: const TextStyle(color: Colors.blue),
                                  ))
                              .toList(),
                        ),

                        // Attachments
                        if (_announcement.attachmentUrls.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Attachments',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._announcement.attachmentUrls.asMap().entries.map(
                            (entry) {
                              final url = entry.value;
                              final fileName =
                                  url.split('/').last.split('?').first;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.attach_file),
                                  title: Text(fileName),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () => _downloadFile(url),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],

                        // Last Updated
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Created',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(_announcement.createdAt),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Updated',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(_announcement.updatedAt),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPriorityBadge(int? priority) {
    late Color color;
    late String label;

    switch (priority) {
      case 1:
        color = Colors.green;
        label = 'Low Priority';
        break;
      case 3:
        color = Colors.red;
        label = 'High Priority';
        break;
      default:
        color = Colors.orange;
        label = 'Medium Priority';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String? category) {
    late Color bgColor;
    late Color textColor;
    late String label;

    switch (category) {
      case 'academic':
        bgColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        label = 'Academic';
        break;
      case 'event':
        bgColor = Colors.purple.withOpacity(0.2);
        textColor = Colors.purple;
        label = 'Event';
        break;
      case 'urgent':
        bgColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        label = 'Urgent';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey[700]!;
        label = 'General';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'faculty':
        return 'Faculty';
      case 'student':
        return 'Student';
      case 'alumni':
        return 'Alumni';
      default:
        return role.toUpperCase();
    }
  }

  void _downloadFile(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open attachment: $e')),
        );
      }
    }
  }
}
