import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/faculty_layout.dart';
import '../widgets/admin_layout.dart';
import '../widgets/student_layout.dart';

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
  bool _isDarkMode = false;

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
    if (mounted) {
      setState(() => _institutionId = institutionId);
    }

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
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  Future<void> _fetchLatestAnnouncement() async {
    if (_institutionId == null) return;
    try {
      final announcement = await _announcementService.getAnnouncementById(_institutionId!, _announcement.id);
      if (mounted) {
        setState(() => _announcement = announcement);
      }
    } catch (e) {
      debugPrint('Error fetching latest announcement: $e');
    }
  }

  Future<void> _markAsViewed() async {
    if (_institutionId == null || _hasViewedMarked) return;
    try {
      await _announcementService.markAnnouncementAsViewed(_institutionId!, _announcement.id);
      if (mounted) {
        setState(() => _hasViewedMarked = true);
      }
    } catch (e) {
      debugPrint('Error marking as viewed: $e');
    }
  }

  Future<void> _deleteAnnouncement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        title: Text('Delete Announcement', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
        content: Text('Are you sure you want to delete this announcement?', style: TextStyle(color: _isDarkMode ? Colors.grey[300] : Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _institutionId != null) {
      setState(() => _isLoading = true);
      try {
        await _announcementService.deleteAnnouncement(_institutionId!, _announcement.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement deleted'), behavior: SnackBarBehavior.floating));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
        }
      }
    }
  }

  void _downloadFile(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open attachment: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    
    final isCreator = _currentUser?.uid == _announcement.createdBy;
    final isAdmin = _currentUser?.role == 'admin';
    final canManage = isCreator || isAdmin;

    Widget content = _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(textPrimary, textSecondary, canManage),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildMainContent(textPrimary, textSecondary)),
                          const SizedBox(width: 32),
                          Expanded(flex: 1, child: _buildSidePanel(textPrimary, textSecondary)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildMainContent(textPrimary, textSecondary),
                          const SizedBox(height: 32),
                          _buildSidePanel(textPrimary, textSecondary),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );

    final role = _currentUser?.role?.toLowerCase();
    if (role == 'admin') {
      return AdminLayout(title: 'Announcement Details', child: content);
    } else if (role == 'faculty') {
      return FacultyLayout(title: 'Announcement Details', child: content);
    } else {
      return StudentLayout(title: 'Announcement Details', child: content);
    }
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary, bool canManage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCategoryChip(_announcement.category),
                  const SizedBox(width: 12),
                  _buildPriorityBadge(_announcement.priority),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _announcement.title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        if (canManage)
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _deleteAnnouncement,
                icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/$_institutionId/announcements/${_announcement.id}/edit', extra: _announcement),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMainContent(Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              _announcement.description,
              style: TextStyle(fontSize: 16, color: textSecondary, height: 1.6),
            ),
            if (_announcement.content != null && _announcement.content!.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              Text(
                'Full Content',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF111827) : Colors.grey[50]!,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  _announcement.content!,
                  style: TextStyle(fontSize: 15, color: textPrimary, height: 1.7),
                ),
              ),
            ],
            if (_announcement.attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              Text(
                'Attachments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 16),
              ..._announcement.attachmentUrls.map((url) => _buildAttachmentItem(url, textPrimary, textSecondary, borderColor)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(String url, Color textPrimary, Color textSecondary, Color borderColor) {
    final fileName = url.split('/').last.split('?').first;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF4F46E5), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(fileName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 14))),
          IconButton(
            onPressed: () => _downloadFile(url),
            icon: const Icon(Icons.download_rounded, color: Color(0xFF4F46E5)),
            tooltip: 'Download',
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel(Color textPrimary, Color textSecondary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(Icons.person_rounded, 'Posted By', _announcement.createdByName, textPrimary, textSecondary),
              const SizedBox(height: 24),
              _buildInfoItem(Icons.calendar_today_rounded, 'Posted On', DateFormat('dd MMM, yyyy').format(_announcement.createdAt), textPrimary, textSecondary),
              const SizedBox(height: 24),
              _buildInfoItem(Icons.remove_red_eye_rounded, 'Total Views', _announcement.viewCount.toString(), textPrimary, textSecondary),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              Text('Visible To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _announcement.targetAudience.map((role) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(role.toUpperCase(), style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String? category) {
    late Color color;
    switch (category) {
      case 'academic': color = const Color(0xFF3B82F6); break;
      case 'event': color = const Color(0xFFA855F7); break;
      case 'urgent': color = const Color(0xFFEF4444); break;
      default: color = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(category?.toUpperCase() ?? 'GENERAL', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildPriorityBadge(int? priority) {
    Color color;
    String label;
    switch (priority) {
      case 1: color = const Color(0xFF10B981); label = 'LOW'; break;
      case 3: color = const Color(0xFFEF4444); label = 'HIGH'; break;
      default: color = const Color(0xFFF59E0B); label = 'MEDIUM';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Text('$label PRIORITY', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}
