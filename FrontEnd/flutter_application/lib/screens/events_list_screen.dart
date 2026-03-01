import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/admin_layout.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> with TickerProviderStateMixin {
  late ApiService _apiService;
  late EventService _eventService;
  late TabController _tabController;
  String? _institutionId;
  UserModel? _currentUser;
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isDarkMode = false;

  final List<String> _categories = [
    'all',
    'academic',
    'placement',
    'cultural',
    'administrative',
    'workshop',
    'sports'
  ];

  List<EventModel> _events = [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _eventService = EventService();
    _selectedCategory = 'all';
    _tabController = TabController(length: 2, vsync: this);
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
      await _fetchEvents();
    }
  }

  Future<void> _fetchCurrentUser() async {
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

  Future<void> _fetchEvents() async {
    if (_institutionId == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      List<EventModel> events;
      if (_selectedTabIndex == 1 && _currentUser?.role == 'student') {
        events = await _eventService.getMyRegistrations(_institutionId!);
      } else if (_selectedTabIndex == 1 && _currentUser?.role != 'student') {
        events = await _eventService.getManagedEvents(_institutionId!); 
      } else {
        events = await _eventService.getEventsForAudience(
          _institutionId!,
          role: _currentUser?.role,
          departmentId: _currentUser?.departmentId,
          programme: _currentUser?.programme,
        );
      }
      
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  List<EventModel> _getFilteredEvents() {
    return _events.where((event) {
      if (_selectedCategory != 'all' && event.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event.description.toLowerCase().contains(_searchQuery.toLowerCase());
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
    final filteredEvents = _getFilteredEvents();

    return AdminLayout(
      title: 'Events',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text('Events', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
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
                            'Event Explorer',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Discover and manage institutional events',
                            style: TextStyle(fontSize: 14, color: textSecondary),
                          ),
                        ],
                      ),
                      if (!isStudent)
                        ElevatedButton.icon(
                          onPressed: () => context.push('/$_institutionId/events/create'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create Event'),
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
                        _fetchEvents();
                      },
                      tabs: [
                        const Tab(text: 'Upcoming Events'),
                        Tab(text: isStudent ? 'My Registrations' : 'Management'),
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
                              hintText: 'Search events...',
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
                        flex: 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(_formatCategory(cat)),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() => _selectedCategory = cat);
                                  },
                                  selectedColor: const Color(0xFF4F46E5).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFF4F46E5),
                                  labelStyle: TextStyle(
                                    color: isSelected ? const Color(0xFF4F46E5) : textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF4F46E5) : (_isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Events Grid/List
                  filteredEvents.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            mainAxisExtent: 420,
                          ),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            return _buildEventCard(filteredEvents[index]);
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
              child: const Icon(Icons.event_busy_rounded, color: Color(0xFF4F46E5), size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters to find what you\'re looking for.',
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

  Widget _buildEventCard(EventModel event) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final categoryColor = _getCategoryColor(event.category);

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.push('/$_institutionId/events/${event.id}', extra: event),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header/Image Placeholder
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [categoryColor.withOpacity(0.8), categoryColor.withOpacity(0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getCategoryIcon(event.category),
                        size: 64,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildCategoryChip(event.category),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildStatusChip(event.status),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          '${event.formattedDate} • ${event.formattedTime}',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 16, color: textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.venue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textSecondary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people_rounded, size: 18, color: Color(0xFF4F46E5)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${event.currentParticipants} / ${event.capacityLimit == 0 ? "∞" : event.capacityLimit}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14),
                            ),
                            Text('Registered', style: TextStyle(color: textSecondary, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        _buildAvailabilityIndicator(event),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityIndicator(EventModel event) {
    if (event.isFull) {
      return _indicator('FULL', Colors.red);
    } else if (event.isEventOver) {
      return _indicator('CLOSED', Colors.grey);
    } else {
      return _indicator('OPEN', Colors.green);
    }
  }

  Widget _indicator(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Text(
        _formatCategory(category).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    String label = status.replaceAll('_', ' ');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatCategory(String category) {
    if (category.isEmpty) return '';
    return category[0].toUpperCase() + category.substring(1);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic': return const Color(0xFF3B82F6);
      case 'placement': return const Color(0xFF6366F1);
      case 'cultural': return const Color(0xFFA855F7);
      case 'administrative': return const Color(0xFF14B8A6);
      case 'workshop': return const Color(0xFFF59E0B);
      case 'sports': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'academic': return Icons.school_rounded;
      case 'placement': return Icons.work_rounded;
      case 'cultural': return Icons.music_note_rounded;
      case 'workshop': return Icons.handyman_rounded;
      case 'sports': return Icons.sports_basketball_rounded;
      default: return Icons.event_rounded;
    }
  }
}
