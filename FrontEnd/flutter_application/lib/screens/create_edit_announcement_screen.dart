import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../models/announcement_model.dart';
import '../models/department_model.dart';
import '../services/announcement_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/admin_layout.dart';

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
  bool _isDarkMode = false;

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
  List<Department> _availableDepartments = [];

  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService();
    _apiService = ApiService();

    _titleController = TextEditingController(text: widget.announcement?.title ?? '');
    _descriptionController = TextEditingController(text: widget.announcement?.description ?? '');
    _contentController = TextEditingController(text: widget.announcement?.content ?? '');

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
    if (mounted) {
      setState(() {
        _institutionId = institutionId;
      });
    }

    if (_institutionId != null) {
      _fetchCurrentUser();
      _fetchDepartments();
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

  Future<void> _fetchDepartments() async {
    if (_institutionId == null) return;
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      if (mounted) {
        setState(() {
          _availableDepartments = departments;
        });
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAudience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one audience'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      final announcement = AnnouncementModel(
        id: widget.announcement?.id ?? '',
        institutionId: _institutionId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
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
        await _announcementService.createAnnouncement(_institutionId!, announcement);
      } else {
        await _announcementService.updateAnnouncement(_institutionId!, widget.announcement!.id, announcement);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Announcement ${_isCreating ? 'created' : 'updated'} successfully'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AdminLayout(
      title: _isCreating ? 'Create Announcement' : 'Edit Announcement',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/announcements'),
          child: Text('Announcements', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text(_isCreating ? 'Create' : 'Edit', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
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
                            _isCreating ? 'New Announcement' : 'Edit Announcement Details',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Broadcasting information to your institution community',
                            style: TextStyle(fontSize: 14, color: textSecondary),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isCreating ? 'Post Announcement' : 'Update Post'),
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
                    'Basic Information',
                    'Main content of your announcement',
                    Icons.article_rounded,
                    const Color(0xFF3B82F6),
                    [
                      _buildTextField(_titleController, 'Title', Icons.title_rounded, 'Give your post a clear title'),
                      const SizedBox(height: 20),
                      _buildTextField(_descriptionController, 'Short Description', Icons.notes_rounded, 'A brief summary shown in the feed', maxLines: 2),
                      const SizedBox(height: 20),
                      _buildTextField(_contentController, 'Full Content (Optional)', Icons.description_rounded, 'Detailed information, links, etc.', maxLines: 6, isRequired: false),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildFormSection(
                    'Categorization',
                    'How your post is indexed and prioritized',
                    Icons.label_rounded,
                    const Color(0xFFF59E0B),
                    [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                              style: TextStyle(color: textPrimary, fontSize: 15),
                              decoration: _inputDecoration('Category', Icons.category_rounded),
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(_formatCategory(c)))).toList(),
                              onChanged: (v) => setState(() => _selectedCategory = v!),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedPriority,
                              dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                              style: TextStyle(color: textPrimary, fontSize: 15),
                              decoration: _inputDecoration('Priority', Icons.priority_high_rounded),
                              items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(_priorityNames[p]!))).toList(),
                              onChanged: (v) => setState(() => _selectedPriority = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildFormSection(
                    'Visibility & Scheduling',
                    'Control who sees this and when',
                    Icons.visibility_rounded,
                    const Color(0xFF10B981),
                    [
                      Text('Visible To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                      const SizedBox(height: 12),
                      MultiSelectDialogField<String>(
                        items: _audienceOptions.map((role) => MultiSelectItem(role, _formatRole(role))).toList(),
                        initialValue: _selectedAudience,
                        onConfirm: (selected) => setState(() => _selectedAudience = selected),
                        buttonIcon: Icon(Icons.people_rounded, color: textSecondary),
                        buttonText: Text('Select Roles', style: TextStyle(color: textPrimary)),
                        decoration: BoxDecoration(
                          color: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                        ),
                        backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                        selectedColor: const Color(0xFF4F46E5),
                        unselectedColor: textPrimary,
                        itemsTextStyle: TextStyle(color: textPrimary),
                        selectedItemsTextStyle: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      if (_availableDepartments.isNotEmpty) ...[
                        Text('Target Departments (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                        const SizedBox(height: 12),
                        MultiSelectDialogField<String>(
                          items: _availableDepartments.map((dept) => MultiSelectItem(dept.id, dept.name)).toList(),
                          initialValue: _selectedDepartments,
                          onConfirm: (selected) => setState(() => _selectedDepartments = selected),
                          buttonIcon: Icon(Icons.business_rounded, color: textSecondary),
                          buttonText: Text('Select Departments', style: TextStyle(color: textPrimary)),
                          decoration: BoxDecoration(
                            color: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                          ),
                          backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                          selectedColor: const Color(0xFF4F46E5),
                          unselectedColor: textPrimary,
                          itemsTextStyle: TextStyle(color: textPrimary),
                          selectedItemsTextStyle: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text('Publication Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _scheduledFor ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _scheduledFor = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isDarkMode ? const Color(0xFF111827).withOpacity(0.5) : Colors.grey[50]!,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 20, color: textSecondary),
                              const SizedBox(width: 12),
                              Text(_scheduledFor == null ? 'Publish Immediately' : DateFormat('dd MMM, yyyy').format(_scheduledFor!),
                                  style: TextStyle(color: textPrimary, fontSize: 15)),
                              const Spacer(),
                              if (_scheduledFor != null) 
                                IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _scheduledFor = null)),
                            ],
                          ),
                        ),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {int maxLines = 1, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 15),
      decoration: _inputDecoration(label, icon, hint: hint),
      validator: isRequired ? (v) => v!.isEmpty ? '$label is required' : null : null,
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

  String _formatCategory(String category) {
    switch (category) {
      case 'academic': return 'Academic';
      case 'event': return 'Event';
      case 'urgent': return 'Urgent';
      case 'general': return 'General';
      default: return 'General';
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'admin': return 'Admin';
      case 'faculty': return 'Faculty';
      case 'student': return 'Student';
      case 'alumni': return 'Alumni';
      default: return role.toUpperCase();
    }
  }
}
