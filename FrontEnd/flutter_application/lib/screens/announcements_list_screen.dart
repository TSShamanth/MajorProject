import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/student_layout.dart';

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
    final isStudent = _currentUser?.role == 'student';
    final filteredAnnouncements = _getFilteredAnnouncements();

    return StudentLayout(
      title: 'Announcements Feed',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Announcements', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isStudent),
                  const SizedBox(height: 24),

                  // Modern Tab Bar - Only show if not student or if we want multiple student tabs
                  if (!isStudent)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF4F46E5),
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: const Color(0xFF4F46E5),
                        indicatorWeight: 3,
                        tabAlignment: TabAlignment.start,
                        isScrollable: true,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: const InputDecoration(
                              hintText: 'Search news and announcements...',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            icon: const Icon(Icons.filter_list_rounded, size: 20, color: Color(0xFF6B7280)),
                            items: _categories.map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(_formatCategory(category), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedCategory = value),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Announcements Grid
                  filteredAnnouncements.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            mainAxisExtent: 240,
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

  Widget _buildHeader(bool isStudent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Institutional Feed',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Stay updated with the latest news from your department and university',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        if (!isStudent)
          ElevatedButton.icon(
            onPressed: () => context.push('/$_institutionId/announcements/create'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_off_rounded, color: Color(0xFF4F46E5), size: 64),
            ),
            const SizedBox(height: 24),
            const Text('No announcements yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text('Check back later for important updates and information.', 
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement, bool isStudent) {
    final isCreator = _currentUser?.uid == announcement.createdBy;
    final isAdmin = _currentUser?.role == 'admin';
    final canManage = !isStudent && (isCreator || isAdmin);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/$_institutionId/announcements/${announcement.id}', extra: announcement),
          borderRadius: BorderRadius.circular(24),
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
                      _buildManageMenu(announcement),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  announcement.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.3, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
                ),
                const Spacer(),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.remove_red_eye_rounded, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text('${announcement.viewCount}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                    const Spacer(),
                    Text(
                      DateFormat('MMM dd, yyyy').format(announcement.createdAt),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
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

  Widget _buildManageMenu(AnnouncementModel announcement) {
    return PopupMenuButton(
      icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[400], size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 12), Text('Edit Post')]),
          onTap: () => Future.delayed(Duration.zero, () => _editAnnouncement(announcement)),
        ),
        PopupMenuItem(
          child: const Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))]),
          onTap: () => Future.delayed(Duration.zero, () => _deleteAnnouncement(announcement)),
        ),
      ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post?'),
        content: const Text('This announcement will be permanently removed from the feed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement deleted'), behavior: SnackBarBehavior.floating));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        _formatCategory(category).toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  String _formatCategory(String? category) {
    switch (category) {
      case 'academic': return 'Academic';
      case 'event': return 'Event';
      case 'urgent': return 'Urgent';
      case 'general': return 'General';
      case 'all': return 'All News';
      default: return 'General';
    }
  }
}
