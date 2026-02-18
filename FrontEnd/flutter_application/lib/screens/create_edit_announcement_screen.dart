import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../models/announcement_model.dart';
import '../models/department_model.dart'; // Add Department model import
import '../services/announcement_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class CreateEditAnnouncementScreen extends StatefulWidget {
  final AnnouncementModel? announcement;

  const CreateEditAnnouncementScreen({
    super.key,
    this.announcement,
  });

  @override
  State<CreateEditAnnouncementScreen> createState() =>
      _CreateEditAnnouncementScreenState();
}

class _CreateEditAnnouncementScreenState extends State<CreateEditAnnouncementScreen> {
  late AnnouncementService _announcementService;
  late ApiService _apiService;
  final _formKey = GlobalKey<FormState>();

  String? _institutionId;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isCreating = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _contentController;

  String _selectedCategory = 'general';
  int _selectedPriority = 2;
  List<String> _selectedAudience = ['student', 'faculty', 'admin'];
  List<String> _selectedDepartments = [];
  DateTime? _scheduledFor;

  final List<String> _categories = ['general', 'academic', 'event', 'urgent'];
  final List<int> _priorities = [1, 2, 3];
  final Map<int, String> _priorityNames = {
    1: 'Low',
    2: 'Medium',
    3: 'High',
  };
  final List<String> _audienceOptions = ['admin', 'faculty', 'student', 'alumni'];
  List<Department> _availableDepartments = []; // Store full Department objects

  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService();
    _apiService = ApiService();

    _titleController = TextEditingController(text: widget.announcement?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.announcement?.description ?? '');
    _contentController =
        TextEditingController(text: widget.announcement?.content ?? '');

    if (widget.announcement != null) {
      _selectedCategory = widget.announcement!.category ?? 'general';
      _selectedPriority = widget.announcement!.priority ?? 2;
      _selectedAudience = widget.announcement!.targetAudience;
      _selectedDepartments = widget.announcement!.targetDepartments;
      _scheduledFor = widget.announcement!.scheduledFor;
    }

    _isCreating = widget.announcement == null;
    _initializeData();
  }

  Future<void> _initializeData() async {
    final institutionId = await SessionManager.getInstitutionId();
    setState(() {
      _institutionId = institutionId;
    });

    if (_institutionId != null) {
      _fetchCurrentUser();
      _fetchDepartments();
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

  Future<void> _fetchDepartments() async {
    if (_institutionId == null) return;
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      setState(() {
        _availableDepartments = departments;
      });
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAudience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one audience')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final announcement = AnnouncementModel(
        id: widget.announcement?.id ?? '',
        institutionId: _institutionId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
        createdBy: _currentUser?.uid ?? currentUser.uid,
        createdByName: _currentUser?.displayName ?? currentUser.email ?? 'Unknown',
        createdByRole: _currentUser?.role ?? 'faculty',
        createdAt: widget.announcement?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        scheduledFor: _scheduledFor,
        isActive: true,
        targetAudience: _selectedAudience,
        targetDepartments: _selectedDepartments,
        priority: _selectedPriority,
        category: _selectedCategory,
      );

      if (_isCreating) {
        await _announcementService.createAnnouncement(
          _institutionId!,
          announcement,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement created successfully')),
          );
          context.pop();
        }
      } else {
        await _announcementService.updateAnnouncement(
          _institutionId!,
          widget.announcement!.id,
          announcement,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement updated successfully')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreating ? 'Create Announcement' : 'Edit Announcement'),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    Text('Title', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter announcement title',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Title is required';
                        }
                        if (value.length < 5) {
                          return 'Title must be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description Field
                    Text('Description',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Brief description (shown in list)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description is required';
                        }
                        if (value.length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Content Field
                    Text('Content (Optional)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Full announcement content (shown in detail view)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Selection
                    Text('Category', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(_formatCategory(category)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value ?? 'general';
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Priority Selection
                    Text('Priority', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedPriority,
                      items: _priorities
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(_priorityNames[priority]!),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value ?? 2;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Target Audience Selection
                    Text('Visible To', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    MultiSelectDialogField<String>(
                      items: _audienceOptions
                          .map((audience) => MultiSelectItem(
                                audience,
                                _formatRole(audience),
                              ))
                          .toList(),
                      initialValue: _selectedAudience,
                      onConfirm: (selected) {
                        setState(() {
                          _selectedAudience = selected;
                        });
                      },
                      listType: MultiSelectListType.CHIP,
                      searchable: true,
                      title: const Text('Select Audience'),
                      chipDisplay: MultiSelectChipDisplay(
                        onTap: (index) {
                          setState(() {
                            _selectedAudience.removeAt(index as int);
                          });
                        },
                      ),
                      dialogHeight: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Target Departments (Optional)
                    if (_availableDepartments.isNotEmpty) ...[
                      Text('Target Departments (Optional)',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      MultiSelectDialogField<String>(
                        items: _availableDepartments
                            .map((dept) => MultiSelectItem(dept.id, dept.name))
                            .toList(),
                        initialValue: _selectedDepartments,
                        onConfirm: (selected) {
                          setState(() {
                            _selectedDepartments = selected;
                          });
                        },
                        listType: MultiSelectListType.CHIP,
                        searchable: true,
                        title: const Text('Select Departments'),
                        chipDisplay: MultiSelectChipDisplay(
                          onTap: (index) {
                            setState(() {
                              _selectedDepartments.removeAt(index as int);
                            });
                          },
                        ),
                        dialogHeight: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Schedule Date (Optional)
                    Text('Schedule Publication (Optional)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _scheduledFor ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _scheduledFor = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _scheduledFor == null
                                  ? 'Select date (optional)'
                                  : '${_scheduledFor!.day}/${_scheduledFor!.month}/${_scheduledFor!.year}',
                              style: TextStyle(
                                color: _scheduledFor == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            const Spacer(),
                            if (_scheduledFor != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _scheduledFor = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white)),
                              )
                            : Text(
                                _isCreating
                                    ? 'Create Announcement'
                                    : 'Update Announcement',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatCategory(String category) {
    switch (category) {
      case 'academic':
        return 'Academic';
      case 'event':
        return 'Event';
      case 'urgent':
        return 'Urgent';
      case 'general':
        return 'General';
      default:
        return 'General';
    }
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
}
