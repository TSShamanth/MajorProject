import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/student_layout.dart';

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
    final isStudent = _currentUser?.role == 'student';
    final filteredEvents = _getFilteredEvents();

    return StudentLayout(
      title: 'Events Explorer',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Events', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
                  
                  // Modern Tab Bar
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
                        _fetchEvents();
                      },
                      tabs: [
                        const Tab(text: 'All Upcoming Events'),
                        Tab(text: isStudent ? 'My Registrations' : 'My Managed Events'),
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
                              hintText: 'Search by title or description...',
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
                                  selectedColor: const Color(0xFF4F46E5).withOpacity(0.1),
                                  checkmarkColor: const Color(0xFF4F46E5),
                                  labelStyle: TextStyle(
                                    color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[600],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
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
                  
                  // Events Grid
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

  Widget _buildHeader(bool isStudent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Events Explorer',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Discover workshops, cultural fests, and placement drives',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
              child: const Icon(Icons.event_busy_rounded, color: Color(0xFF4F46E5), size: 64),
            ),
            const SizedBox(height: 24),
            const Text('No events found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text('Try adjusting your search or filters to discover more events.', 
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final categoryColor = _getCategoryColor(event.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.push('/$_institutionId/events/${event.id}', extra: event),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Banner Placeholder
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
                      child: Icon(_getCategoryIcon(event.category), size: 64, color: Colors.white.withOpacity(0.9)),
                    ),
                    Positioned(top: 16, left: 16, child: _buildCategoryChip(event.category)),
                    Positioned(top: 16, right: 16, child: _buildStatusChip(event.status)),
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    _buildIconText(Icons.calendar_today_rounded, '${event.formattedDate} • ${event.formattedTime}'),
                    const SizedBox(height: 8),
                    _buildIconText(Icons.location_on_rounded, event.venue),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.people_rounded, size: 18, color: Color(0xFF4F46E5)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${event.currentParticipants} / ${event.capacityLimit == 0 ? "∞" : event.capacityLimit}', 
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937), fontSize: 14)),
                            Text('Participating', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)),
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

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, 
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildAvailabilityIndicator(EventModel event) {
    if (event.isFull) return _indicator('FULL', const Color(0xFFEF4444));
    if (event.isEventOver) return _indicator('CLOSED', const Color(0xFF6B7280));
    return _indicator('OPEN', const Color(0xFF10B981));
  }

  Widget _indicator(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
      child: Text(_formatCategory(category).toUpperCase(), 
        style: TextStyle(color: _getCategoryColor(category), fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white.withOpacity(0.2))),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), 
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
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
