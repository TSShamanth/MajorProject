import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_dto.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/session_manager.dart';
import 'package:go_router/go_router.dart';
import '../widgets/faculty_layout.dart';

class RegularisationRequestScreen extends StatefulWidget {
  const RegularisationRequestScreen({super.key});

  @override
  State<RegularisationRequestScreen> createState() =>
      _RegularisationRequestScreenState();
}

class _RegularisationRequestScreenState
    extends State<RegularisationRequestScreen> {
  // ── Form state ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _requestType;
  final TextEditingController _reasonController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isDarkMode = false;
  String? _institutionId;

  // ── Theme helpers ──────────────────────────────────────────────────────────
  static const _accent = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);
  static const _danger = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_institutionId == null) throw Exception('Institution ID not found');

      final requestData = RegularisationRequestDTO(
        targetDate: _selectedDate!,
        targetTime: '${_selectedTime!.hour}:${_selectedTime!.minute}',
        type: _requestType!,
        reason: _reasonController.text,
        attendanceLogId: null,
      );

      await _apiService.createRegularisationRequest(_institutionId!, requestData.toJson());

      if (!mounted) return;
      _showSnackbar('Regularisation request submitted successfully!', isError: false);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Failed to submit request: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _danger : _success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return FacultyLayout(
      title: 'Regularisation',
      breadcrumbs: [
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('Attendance History', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text('New Request', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
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
                          'Regularisation Request',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Correct your attendance record for a specific date/time',
                          style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/$_institutionId/faculty/regularisation/status'),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('View Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: _accent, size: 20),
                const SizedBox(width: 12),
                const Text('Request Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel('TARGET DATE & TIME'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDateField()),
                const SizedBox(width: 16),
                Expanded(child: _buildTimeField()),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel('REQUEST TYPE'),
            const SizedBox(height: 12),
            _buildRequestTypeField(),
            const SizedBox(height: 24),

            _sectionLabel('REASON FOR REQUEST'),
            const SizedBox(height: 12),
            _buildReasonField(),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitRequest,
                icon: _isLoading 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isLoading ? 'SUBMITTING...' : 'SUBMIT REQUEST', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.grey[500] : Colors.grey[500], letterSpacing: 1.0));
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Select Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
        ),
        child: Text(_selectedDate == null ? 'Target Date' : '${_selectedDate!.toLocal()}'.split(' ')[0]),
      ),
    );
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: _pickTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Select Time',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.access_time_rounded, size: 20),
        ),
        child: Text(_selectedTime == null ? 'Target Time' : _selectedTime!.format(context)),
      ),
    );
  }

  Widget _buildRequestTypeField() {
    return DropdownButtonFormField<String>(
      value: _requestType,
      dropdownColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      decoration: InputDecoration(
        labelText: 'Correction Type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.swap_horiz_rounded, size: 20),
      ),
      items: ['Clock-in', 'Clock-out'].map((type) => DropdownMenuItem(
        value: type,
        child: Text(type),
      )).toList(),
      onChanged: (val) => setState(() => _requestType = val),
      validator: (val) => val == null ? 'Please select a type' : null,
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Provide a detailed reason for this correction...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        alignLabelWithHint: true,
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Reason is required' : (val.length < 10 ? 'Please provide more detail' : null),
    );
  }
}
