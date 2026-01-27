import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../models/institution.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingInstitutions = true;
  List<Institution> _institutions = [];
  Institution? _selectedInstitution;

  @override
  void initState() {
    super.initState();
    _fetchInstitutions();
  }

  Future<void> _fetchInstitutions() async {
    try {
      final institutions = await ApiService.getInstitutions();
      setState(() {
        _institutions = institutions;
        _isLoadingInstitutions = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load institutions: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingInstitutions = false;
        });
      }
    }
  }

  Future<void> _login() async {
    debugPrint('Login button pressed');
    if (_selectedInstitution == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an institution.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final role = await AuthService.login(
      _emailController.text,
      _passwordController.text,
      _selectedInstitution!.id,
    );
    debugPrint('Login role: $role');

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (role != 'none') {
      final path = switch (role) {
        'admin' => '/${_selectedInstitution!.id}/admin/dashboard',
        'faculty' => '/${_selectedInstitution!.id}/faculty/dashboard',
        'student' => '/${_selectedInstitution!.id}/student/dashboard',
        _ => null,
      };

      if (path != null) {
        debugPrint('Login successful. Navigating to: $path');
        context.go(path);
      } else {
        debugPrint('Login failed: Role was valid but no path could be determined.');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not determine user dashboard. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      debugPrint('Login failed, role is "none"');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 48),
                _buildLoginForm(),
                const SizedBox(height: 24),
                _buildSocialLogins(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Welcome to Acadexa',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Text(
          'Your integrated academic portal.',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _isLoadingInstitutions
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<Institution>(
                value: _selectedInstitution,
                hint: const Text('Select Institution'),
                items: _institutions.map((institution) {
                  return DropdownMenuItem<Institution>(
                    value: institution,
                    child: Text(institution.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedInstitution = value;
                  });
                },
                decoration: _inputDecoration('Institution', Icons.school_outlined),
              ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: _inputDecoration('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!_isLoading) _login();
          },
          decoration: _inputDecoration('Password', Icons.lock_outline),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // TODO: Implement forgot password functionality
            },
            child: const Text(
              'Forgot Password?',
              style: TextStyle(color: Color(0xFF1E293B)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildSocialLogins() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Or continue with', style: TextStyle(color: Colors.grey.shade600)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Implement Google Sign-in
          },
          icon: SvgPicture.asset(
            'assets/images/google_logo.svg',
            height: 20,
          ),
          label: const Text(
            'Sign in with Google',
            style: TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

