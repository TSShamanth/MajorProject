import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class CreateEditEventScreen extends StatefulWidget {
  final EventModel? event;

  const CreateEditEventScreen({super.key, this.event});

  @override
  State<CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
  late EventService _eventService;
  UserModel? _currentUser;
  String? _institutionId;
  bool _isLoading = false;

  // Form Fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  
  String _selectedCategory = 'academic';
  DateTime _startDateTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endDateTime = DateTime.now().add(const Duration(hours: 3));
  DateTime _registrationDeadline = DateTime.now().add(const Duration(minutes: 30));
  
  final List<String> _targetAudience = ['STUDENTS'];
  final List<String> _targetDepartments = ['ALL'];
  
  final List<String> _categories = [
    'academic', 'placement', 'cultural', 'administrative', 'workshop', 'sports'
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _eventService = EventService();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _venueController.text = widget.event!.venue;
      _capacityController.text = widget.event!.capacityLimit.toString();
      _selectedCategory = widget.event!.category.toLowerCase();
      _startDateTime = widget.event!.startDateTime;
      _endDateTime = widget.event!.endDateTime;
      _registrationDeadline = widget.event!.registrationDeadline;
    }
    _initializeData();
  }

  Future<void> _initializeData() async {
    final institutionId = await SessionManager.getInstitutionId();
    setState(() {
      _institutionId = institutionId;
    });
    if (_institutionId != null) {
      _fetchCurrentUser();
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

  Future<void> _selectDateTime(BuildContext context, DateTime initial, Function(DateTime) onSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (pickedTime != null) {
        onSelected(DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day, 
          pickedTime.hour, pickedTime.minute
        ));
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final event = EventModel(
          id: widget.event?.id ?? '',
          institutionId: _institutionId!,
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          status: widget.event?.status ?? 'PENDING_APPROVAL',
          startDateTime: _startDateTime,
          endDateTime: _endDateTime,
          venue: _venueController.text,
          organizerId: _currentUser?.uid ?? '',
          organizerName: _currentUser?.name ?? '',
          organizerPhotoUrl: _currentUser?.photoUrl,
          capacityLimit: int.tryParse(_capacityController.text) ?? 0,
          currentParticipants: widget.event?.currentParticipants ?? 0,
          registrationDeadline: _registrationDeadline,
          targetAudience: _targetAudience,
          targetDepartments: _targetDepartments,
          attachmentUrls: widget.event?.attachmentUrls ?? [],
          createdAt: widget.event?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: widget.event?.createdBy ?? (_currentUser?.uid ?? ''),
          isApprovalRequired: true,
        );

        if (widget.event == null) {
          await _eventService.createEvent(_institutionId!, event);
        } else {
          await _eventService.updateEvent(_institutionId!, widget.event!.id, event);
        }

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.event == null ? 'Event submitted for approval!' : 'Event updated successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _submitForm,
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('General Information'),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Description is required' : null,
                  ),
                  
                  const SizedBox(height: 30),
                  _buildSectionTitle('Venue & Capacity'),
                  TextFormField(
                    controller: _venueController,
                    decoration: const InputDecoration(labelText: 'Venue / Online Link', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Venue is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity Limit (0 for unlimited)', border: OutlineInputBorder()),
                  ),
                  
                  const SizedBox(height: 30),
                  _buildSectionTitle('Schedule'),
                  _buildDateTimeTile('Starts', _startDateTime, (dt) => setState(() => _startDateTime = dt)),
                  _buildDateTimeTile('Ends', _endDateTime, (dt) => setState(() => _endDateTime = dt)),
                  _buildDateTimeTile('Registration Deadline', _registrationDeadline, (dt) => setState(() => _registrationDeadline = dt)),
                  
                  const SizedBox(height: 30),
                  _buildSectionTitle('Target Audience'),
                  Wrap(
                    spacing: 8,
                    children: ['STUDENTS', 'FACULTY', 'ALL'].map((role) {
                      final isSelected = _targetAudience.contains(role);
                      return FilterChip(
                        label: Text(role),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _targetAudience.add(role);
                            } else {
                              _targetAudience.remove(role);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.event == null ? 'SUBMIT FOR APPROVAL' : 'UPDATE EVENT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
    );
  }

  Widget _buildDateTimeTile(String label, DateTime dt, Function(DateTime) onSelected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(dt), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () => _selectDateTime(context, dt, onSelected),
    );
  }
}
