import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/admin_layout.dart';

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
  bool _isDarkMode = false;

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
    if (mounted) {
      setState(() {
        _institutionId = institutionId;
      });
    }
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
      builder: (context, child) {
        return Theme(
          data: _isDarkMode ? ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              surface: Color(0xFF1F2937),
              onSurface: Colors.white,
            ),
          ) : ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
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
            SnackBar(
              content: Text(widget.event == null ? 'Event submitted for approval!' : 'Event updated successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'), 
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: widget.event == null ? 'Create Event' : 'Edit Event',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/events'),
          child: Text('Events', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text(widget.event == null ? 'Create' : 'Edit', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
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
                            widget.event == null ? 'Create New Event' : 'Edit Event Details',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Provide detailed information about your institutional event',
                            style: TextStyle(fontSize: 14, color: textSecondary),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(widget.event == null ? 'Submit Event' : 'Update Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  _buildFormSection(
                    'General Information',
                    'Basic event details and categorization',
                    Icons.info_outline_rounded,
                    const Color(0xFF3B82F6),
                    [
                      _buildTextField(_titleController, 'Event Title', Icons.title_rounded, 'Enter a clear and concise title'),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        style: TextStyle(color: textPrimary, fontSize: 15),
                        dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                        decoration: _inputDecoration('Category', Icons.category_rounded),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(_descriptionController, 'Event Description', Icons.description_rounded, 'Describe what the event is about...', maxLines: 5),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildFormSection(
                    'Venue & Capacity',
                    'Where and how many people can attend',
                    Icons.place_rounded,
                    const Color(0xFF10B981),
                    [
                      _buildTextField(_venueController, 'Venue / Online Link', Icons.location_on_rounded, 'Physical room name or virtual meeting link'),
                      const SizedBox(height: 20),
                      _buildTextField(_capacityController, 'Capacity Limit', Icons.group_rounded, 'Enter 0 for unlimited capacity', keyboardType: TextInputType.number),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildFormSection(
                    'Schedule',
                    'Timing and registration deadlines',
                    Icons.access_time_filled_rounded,
                    const Color(0xFFF59E0B),
                    [
                      _buildDateTimeTile('Event Start Time', _startDateTime, (dt) => setState(() => _startDateTime = dt)),
                      const Divider(),
                      _buildDateTimeTile('Event End Time', _endDateTime, (dt) => setState(() => _endDateTime = dt)),
                      const Divider(),
                      _buildDateTimeTile('Registration Deadline', _registrationDeadline, (dt) => setState(() => _registrationDeadline = dt)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildFormSection(
                    'Target Audience',
                    'Who is invited to this event',
                    Icons.people_alt_rounded,
                    const Color(0xFF8B5CF6),
                    [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ['STUDENTS', 'FACULTY', 'ALUMNI', 'ALL'].map((role) {
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
                            selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF8B5CF6),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF8B5CF6) : textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFormSection(String title, String subtitle, IconData icon, Color color, List<Widget> children) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1F2937))),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 15),
      decoration: _inputDecoration(label, icon, hint: hint),
      validator: (v) => v!.isEmpty ? '$label is required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!),
      hintStyle: TextStyle(color: _isDarkMode ? Colors.grey[600]! : Colors.grey[400]!, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5).withOpacity(0.7), size: 20),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDateTimeTile(String label, DateTime dt, Function(DateTime) onSelected) {
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return InkWell(
      onTap: () => _selectDateTime(context, dt, onSelected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(dt),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_calendar_rounded, size: 20, color: textSecondary),
          ],
        ),
      ),
    );
  }
}
