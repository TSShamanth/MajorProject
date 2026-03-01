import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/admin_layout.dart';

class AnnouncementsListScreen extends StatefulWidget {
  const AnnouncementsListScreen({
    super.key,
  });

  @override
  State<AnnouncementsListScreen> createState() => _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> with TickerProviderStateMixin {
  late AnnouncementService _announcementService;
  late ApiService _apiService;
  late TabController _tabController;
  String? _institutionId;
  UserModel? _currentUser;
  List<AnnouncementModel> _announcements = [];
  List<AnnouncementModel> _myAnnouncements = [];
  List<AnnouncementModel> _audienceAnnouncements = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isDarkMode = false;

  final List<String> _categories = ['all', 'general', 'academic', 'event', 'urgent'];

  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService();
    _apiService = ApiService();
    _selectedCategory = 'all';
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final institutionId = await SessionManager.getInstitutionId();
    if (mounted) {
      setState(() {
        _institutionId = institutionId;
      });
    }

    if (_institutionId != null) {
      await _fetchCurrentUser();
      _fetchAnnouncements();
    }
  }

  Future<void> _fetchCurrentUser() async {
    if (_institutionId == null) return;
    try {
      final user = await _apiService.getMe(_institutionId!);
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  Future<void> _fetchAnnouncements() async {
    if (_institutionId == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final fetchedMy = await _announcementService.getMyAnnouncementsFromBackend(_institutionId!);
      final fetchedAll = await _announcementService.getAllAnnouncements(_institutionId!);
      final fetchedAudience = await _announcementService.getAnnouncements(
        _institutionId!,
        role: _currentUser?.role,
        departmentId: _currentUser?.departmentId,
        programme: _currentUser?.programme,
      );

      if (mounted) {
        setState(() {
          _myAnnouncements = fetchedMy;
          _announcements = fetchedAll;
          _audienceAnnouncements = fetchedAudience;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading announcements: $e')),
        );
      }
    }
  }

  List<AnnouncementModel> _getFilteredAnnouncements() {
    List<AnnouncementModel> source;
    if (_selectedTabIndex == 0) {
      source = _audienceAnnouncements;
    } else if (_selectedTabIndex == 1) {
      source = _myAnnouncements;
    } else {
      source = _announcements;
    }

    return source.where((announcement) {
      if (_selectedCategory != 'all' && announcement.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return announcement.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            announcement.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final isStudent = _currentUser?.role == 'student';
    final filteredAnnouncements = _getFilteredAnnouncements();

    return AdminLayout(
      title: 'Announcements',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Announcements', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            'Institutional Feed',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stay updated with the latest news and information',
                            style: TextStyle(fontSize: 14, color: textSecondary),
                          ),
                        ],
                      ),
                      if (!isStudent)
                        ElevatedButton.icon(
                          onPressed: () => context.push('/$_institutionId/announcements/create'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('New Announcement'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Modern Tab Bar
                  if (!isStudent)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF4F46E5),
                        unselectedLabelColor: textSecondary,
                        indicatorColor: const Color(0xFF4F46E5),
                        indicatorWeight: 3,
                        onTap: (index) {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        tabs: [
                          Tab(text: 'My Feed (${_audienceAnnouncements.length})'),
                          Tab(text: 'My Posts (${_myAnnouncements.length})'),
                          Tab(text: 'All (${_announcements.length})'),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Search & Category Filter
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: _isDarkMode ? const Color(0xFF111827) : Colors.grey[50]!,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search announcements...',
                              hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Category scroll
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _isDarkMode ? const Color(0xFF111827) : Colors.grey[50]!,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              icon: Icon(Icons.filter_list_rounded, color: textSecondary),
                              dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                              style: TextStyle(color: textPrimary, fontSize: 14),
                              items: _categories.map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(_formatCategory(category)),
                              )).toList(),
                              onChanged: (value) => setState(() => _selectedCategory = value),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Announcements Grid/List
                  filteredAnnouncements.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            mainAxisExtent: 220,
                          ),
                          itemCount: filteredAnnouncements.length,
                          itemBuilder: (context, index) {
                            return _buildAnnouncementCard(filteredAnnouncements[index], isStudent);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.announcement_rounded, color: Color(0xFF4F46E5), size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'No announcements found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement, bool isStudent) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final isCreator = _currentUser?.uid == announcement.createdBy;
    final isAdmin = _currentUser?.role == 'admin';
    final canManage = !isStudent && (isCreator || isAdmin);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/$_institutionId/announcements/${announcement.id}', extra: announcement),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCategoryChip(announcement.category),
                    if (canManage)
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert_rounded, color: textSecondary, size: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 12), Text('Edit')]),
                            onTap: () => Future.delayed(Duration.zero, () => _editAnnouncement(announcement)),
                          ),
                          PopupMenuItem(
                            child: const Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))]),
                            onTap: () => Future.delayed(Duration.zero, () => _deleteAnnouncement(announcement)),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  announcement.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
                ),
                const Spacer(),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.remove_red_eye_rounded, size: 14, color: textSecondary.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Text(
                      '${announcement.viewCount} views',
                      style: TextStyle(fontSize: 12, color: textSecondary.withOpacity(0.7)),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM, yyyy').format(announcement.createdAt),
                      style: TextStyle(fontSize: 12, color: textSecondary.withOpacity(0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editAnnouncement(AnnouncementModel announcement) {
    context.push(
      '/$_institutionId/announcements/${announcement.id}/edit',
      extra: announcement,
    );
  }

  Future<void> _deleteAnnouncement(AnnouncementModel announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        title: Text('Delete Announcement', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
        content: Text('Are you sure you want to delete this announcement?', style: TextStyle(color: _isDarkMode ? Colors.grey[300] : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _institutionId != null) {
      try {
        await _announcementService.deleteAnnouncement(_institutionId!, announcement.id);
        _fetchAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        _formatCategory(category).toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  String _formatCategory(String? category) {
    switch (category) {
      case 'academic': return 'Academic';
      case 'event': return 'Event';
      case 'urgent': return 'Urgent';
      case 'general': return 'General';
      case 'all': return 'All Categories';
      default: return 'General';
    }
  }
}
