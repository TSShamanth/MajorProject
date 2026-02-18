import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

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
  bool _isLoading = true;
  String? _institutionId;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      _institutionId = await SessionManager.getInstitutionId();
      if (_institutionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Institution ID not found. Please log in again.')),
          );
          setState(() {
            _isLoading = false;
          });
          debugPrint('UserListScreen: Institution ID is null.'); // Debug print
          return;
        }
      }
      debugPrint('UserListScreen: Fetching users for institutionId: $_institutionId'); // Debug print

      final allUsers = await _apiService.getUsers(_institutionId!);
      debugPrint('UserListScreen: Fetched total users: ${allUsers.length}'); // Debug print

      setState(() {
        _users = allUsers.where((user) => user.role == widget.role).toList();
        _isLoading = false;
      });
      debugPrint('UserListScreen: Filtered users count for role ${widget.role}: ${_users.length}'); // Debug print
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('UserListScreen: Error fetching users: $e'); // Debug print
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role[0].toUpperCase()}${widget.role.substring(1)} List'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Text('No ${widget.role}s found.'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null
                              ? Icon(widget.role == 'student' ? Icons.person : Icons.group_add, color: Colors.white)
                              : null,
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(user.email ?? ''),
                        onTap: () {
                          final institutionId = _institutionId ?? 'unknown'; // Fallback if null
                          context.go('/$institutionId/admin/users/details/${user.uid}'); // This route will be defined later
                        },
                      ),
                    );
                  },
                ),
    );
  }
}