import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

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
    setState(() {
      _institutionId = institutionId;
    });

    if (_institutionId != null) {
      await _fetchCurrentUser();
      _fetchAnnouncements();
    }
  }

  Future<void> _fetchCurrentUser() async {
    if (_institutionId == null) return;
    try {
      final user = await _apiService.getMe(_institutionId!);
      setState(() {
        _currentUser = user;
      });
      print('Current user fetched and set: ${_currentUser?.uid}, role: ${_currentUser?.role}');
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  Future<void> _fetchAnnouncements() async {
    if (_institutionId == null) return;
    setState(() {
      _isLoading = true;
    });
    print('Attempting to fetch announcements. Current user role: ${_currentUser?.role}');

    try {
      debugPrint('Student Fetch: Role=${_currentUser?.role}, Dept=${_currentUser?.programme}');
      final fetchedMy = await _announcementService.getMyAnnouncementsFromBackend(_institutionId!);
      final fetchedAll = await _announcementService.getAllAnnouncements(_institutionId!);
      final fetchedAudience = await _announcementService.getAnnouncements(
        _institutionId!,
        role: _currentUser?.role,
        departmentId: _currentUser?.departmentId,
        programme: _currentUser?.programme, // Pass programme as well
      );
      debugPrint('Student Fetch Results: Audience=${fetchedAudience.length}, All=${fetchedAll.length}');

      setState(() {
        _myAnnouncements = fetchedMy;
        _announcements = fetchedAll;
        _audienceAnnouncements = fetchedAudience;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
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
      // Category filter
      if (_selectedCategory != 'all' && announcement.category != _selectedCategory) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        return announcement.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            announcement.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return true;
    }).toList();
  }

  void _navigateToDetail(AnnouncementModel announcement) {
    context.push(
      '/$_institutionId/announcements/${announcement.id}',
      extra: announcement,
    );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isStudent ? 'Announcements' : 'Manage Announcements'),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Bar - Only for non-students
                if (!isStudent)
                  Material(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF1E293B),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF1E293B),
                      onTap: (index) {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                      tabs: [
                        Tab(
                          child: Text('My Feed (${_audienceAnnouncements.length})'),
                        ),
                        Tab(
                          child: Text('My Announcements (${_myAnnouncements.length})'),
                        ),
                        Tab(
                          child: Text('All Announcements (${_announcements.length})'),
                        ),
                      ],
                    ),
                  ),
                // Search and Filter Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search announcements...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filter Dropdowns
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: _categories
                                  .map((category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(_formatCategory(category)),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Announcements List
                Expanded(
                  child: filteredAnnouncements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.announcement_outlined,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No announcements',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredAnnouncements.length,
                          itemBuilder: (context, index) {
                            final announcement = filteredAnnouncements[index];
                            return _buildAnnouncementCard(announcement, isStudent);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: (_currentUser?.role == 'admin' ||
              _currentUser?.role == 'faculty')
          ? FloatingActionButton(
              onPressed: () {
                context.push('/$_institutionId/announcements/create');
              },
              tooltip: 'Create Announcement',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement, bool isStudent) {
    final isCreator = _currentUser?.uid == announcement.createdBy;
    final isAdmin = _currentUser?.role == 'admin';
    final canManage = !isStudent && (isCreator || isAdmin);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _navigateToDetail(announcement),
        title: Text(
          announcement.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              announcement.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCategoryChip(announcement.category),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '👁️ ${announcement.viewCount}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM').format(announcement.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: canManage
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () => _editAnnouncement(announcement),
                  ),
                  PopupMenuItem(
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onTap: () => _deleteAnnouncement(announcement),
                  ),
                ],
              )
            : null,
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
      try {
        await _announcementService.deleteAnnouncement(
          _institutionId!,
          announcement.id,
        );
        _fetchAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting announcement: $e')),
          );
        }
      }
    }
  }

  Widget _buildCategoryChip(String? category) {
    late Color bgColor;
    late Color textColor;

    switch (category) {
      case 'academic':
        bgColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        break;
      case 'event':
        bgColor = Colors.purple.withOpacity(0.2);
        textColor = Colors.purple;
        break;
      case 'urgent':
        bgColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatCategory(category),
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatCategory(String? category) {
    switch (category) {
      case 'academic':
        return 'Academic';
      case 'event':
        return 'Event';
      case 'urgent':
        return 'Urgent';
      case 'general':
        return 'General';
      case 'all':
        return 'All Categories';
      default:
        return 'General';
    }
  }
}
