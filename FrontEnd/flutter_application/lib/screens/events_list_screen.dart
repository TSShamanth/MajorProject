import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

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
    setState(() {
      _institutionId = institutionId;
    });

    if (_institutionId != null) {
      await _fetchCurrentUser();
      await _fetchEvents();
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await _apiService.getMe(_institutionId!);
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  Future<void> _fetchEvents() async {
    if (_institutionId == null) return;
    setState(() {
      _isLoading = true;
    });

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
      
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Explorer'),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                      _fetchEvents();
                    },
                    tabs: [
                      const Tab(text: 'Upcoming Events'),
                      Tab(text: isStudent ? 'My Registrations' : 'Management'),
                    ],
                  ),
                ),
                // Search & Category Filter
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
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
                                selectedColor: const Color(0xFF1E293B),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Events List
                Expanded(
                  child: filteredEvents.isEmpty
                      ? const Center(child: Text('No events found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];
                            return _buildEventCard(event);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: !isStudent
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/$_institutionId/events/create'),
              backgroundColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Event', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/$_institutionId/events/${event.id}', extra: event),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for Poster Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: _getCategoryColor(event.category).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(event.category),
                  size: 48,
                  color: _getCategoryColor(event.category),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCategoryChip(event.category),
                      _buildStatusChip(event.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${event.formattedDate} • ${event.formattedTime}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        event.venue,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '${event.currentParticipants} / ${event.capacityLimit == 0 ? "∞" : event.capacityLimit} Registered',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (event.isFull)
                        const Text(
                          'FULL',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                        )
                      else if (event.isEventOver)
                        const Text(
                          'CLOSED',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                        )
                      else
                        const Text(
                          'OPEN',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatCategory(category).toUpperCase(),
        style: TextStyle(
          color: _getCategoryColor(category),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    if (status == 'PUBLISHED') color = Colors.green;
    if (status == 'PENDING_APPROVAL') color = Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatCategory(String category) {
    if (category.isEmpty) return '';
    return category[0].toUpperCase() + category.substring(1);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic': return Colors.blue;
      case 'placement': return Colors.indigo;
      case 'cultural': return Colors.purple;
      case 'administrative': return Colors.teal;
      case 'workshop': return Colors.orange;
      case 'sports': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'academic': return Icons.school;
      case 'placement': return Icons.work;
      case 'cultural': return Icons.music_note;
      case 'workshop': return Icons.handyman;
      case 'sports': return Icons.sports_basketball;
      default: return Icons.event;
    }
  }
}
