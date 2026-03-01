import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../widgets/admin_layout.dart';

class UserListScreen extends StatefulWidget {
  final String role;

  const UserListScreen({
    super.key,
    required this.role,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  List<Department> _departments = [];
  bool _isLoading = true;
  String? _institutionId;
  final ApiService _apiService = ApiService();
  
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDepartmentId;
  String? _selectedSemester;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (_institutionId != null) {
      await Future.wait([
        _fetchUsers(),
        _fetchDepartments(),
      ]);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.'), behavior: SnackBarBehavior.floating),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final departments = await _apiService.getDepartments(_institutionId!);
      if (mounted) setState(() => _departments = departments);
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
  }

  Future<void> _fetchUsers() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      final allUsers = await _apiService.getUsers(_institutionId!);
      if (mounted) {
        setState(() {
          _users = allUsers.where((user) => user.role == widget.role).toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e'), behavior: SnackBarBehavior.floating),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final query = _searchController.text.toLowerCase();
        final matchesQuery = user.displayName.toLowerCase().contains(query) || 
                            (user.email?.toLowerCase().contains(query) ?? false) ||
                            (user.usn?.toLowerCase().contains(query) ?? false);
        
        final matchesDept = _selectedDepartmentId == null || user.departmentId == _selectedDepartmentId;
        final matchesSem = _selectedSemester == null || user.sem == _selectedSemester;
        
        return matchesQuery && matchesDept && matchesSem;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final roleName = widget.role[0].toUpperCase() + widget.role.substring(1);

    return AdminLayout(
      title: '$roleName Management',
      breadcrumbs: [
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.push('/$_institutionId/admin/user-management'),
          child: Text('User Management', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text(roleName, style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(textPrimary, textSecondary, roleName),
                const SizedBox(height: 32),
                _buildFilterBar(textPrimary, textSecondary),
                const SizedBox(height: 24),
                Expanded(
                  child: _filteredUsers.isEmpty 
                    ? _buildEmptyState(textSecondary)
                    : _buildUserGrid(),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary, String roleName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$roleName Directory',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'View and manage all registered ${widget.role}s in the system',
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            if (widget.role == 'student')
              OutlinedButton.icon(
                onPressed: () => context.push('/$_institutionId/admin/bulk-user-import'),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Bulk Import'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Future: Navigation to individual user creation
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add $roleName'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar(Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name, USN or email...',
                hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const VerticalDivider(width: 32),
          if (widget.role != 'admin') ...[
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDepartmentId,
                  isExpanded: true,
                  hint: Text('Department', style: TextStyle(color: textSecondary, fontSize: 14)),
                  dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Departments')),
                    ..._departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedDepartmentId = val);
                    _applyFilters();
                  },
                ),
              ),
            ),
            const VerticalDivider(width: 32),
          ],
          if (widget.role == 'student') ...[
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSemester,
                  isExpanded: true,
                  hint: Text('Semester', style: TextStyle(color: textSecondary, fontSize: 14)),
                  dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Semesters')),
                    ...List.generate(8, (i) => (i + 1).toString()).map((s) => DropdownMenuItem(value: s, child: Text('Semester $s'))),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedSemester = val);
                    _applyFilters();
                  },
                ),
              ),
            ),
            const VerticalDivider(width: 32),
          ],
          IconButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedDepartmentId = null;
                _selectedSemester = null;
                _applyFilters();
              });
            },
            icon: Icon(Icons.refresh_rounded, color: textSecondary),
            tooltip: 'Reset Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 4 : (MediaQuery.of(context).size.width > 1000 ? 3 : (MediaQuery.of(context).size.width > 700 ? 2 : 1)),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 180,
      ),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textPrimary = _isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return InkWell(
      onTap: () => context.go('/$_institutionId/admin/users/details/${user.uid}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null 
                ? Icon(widget.role == 'student' ? Icons.school_rounded : Icons.person_rounded, color: const Color(0xFF4F46E5))
                : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'No email',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  const Spacer(),
                  if (widget.role == 'student') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sem ${user.sem ?? "?"}',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else if (widget.role == 'faculty') ...[
                    Text(
                      user.programme ?? 'Faculty',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8B5CF6)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    user.departmentId != null 
                      ? _departments.firstWhere((d) => d.id == user.departmentId, orElse: () => Department(id: '', name: 'General', shortName: '', institutionId: '')).name
                      : 'General',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, color: Color(0xFF4F46E5), size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            'No matches found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query or filters.',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    );
  }
}
