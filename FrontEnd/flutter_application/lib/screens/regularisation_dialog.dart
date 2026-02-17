import 'package:flutter/material.dart';
import 'package:flutter_application/models/attendance_log_model.dart';
import 'package:flutter_application/models/regularisation_request_dto.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';

class RegularisationDialog extends StatefulWidget {
  final AttendanceLog log;

  const RegularisationDialog({super.key, required this.log});

  @override
  State<RegularisationDialog> createState() => _RegularisationDialogState();
}

class _RegularisationDialogState extends State<RegularisationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _clockInTime;
  TimeOfDay? _clockOutTime;
  final TextEditingController _reasonController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // ── Theme helpers ──────────────────────────────────────────────────────────
  // Dialogs inherit the app's brightness; we detect it from context.
  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _cardColor =>
      _isDark ? const Color(0xFF1F2937) : Colors.white;
  Color get _bgColor =>
      _isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _textPrimary =>
      _isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary =>
      _isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor =>
      _isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  static const _accent = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);
  static const _danger = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _clockInTime =
        TimeOfDay.fromDateTime(widget.log.clockInTime.toLocal());
    _clockOutTime = widget.log.clockOutTime != null
        ? TimeOfDay.fromDateTime(widget.log.clockOutTime!.toLocal())
        : null;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final institutionId = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .pathParameters['institutionId'];
      if (institutionId == null) throw Exception('Institution ID not found');

      final requestData = RegularisationRequestDTO(
        targetDate: widget.log.clockInTime,
        newClockInTime:
            '${_clockInTime.hour}:${_clockInTime.minute}',
        newClockOutTime: _clockOutTime != null
            ? '${_clockOutTime!.hour}:${_clockOutTime!.minute}'
            : null,
        reason: _reasonController.text,
        attendanceLogId: widget.log.id,
      );

      await _apiService.createRegularisationRequest(
          institutionId, requestData.toJson());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Regularisation request submitted successfully!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Failed to submit request: $e',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Time picker helper ─────────────────────────────────────────────────────
  Future<void> _pickTime({
    required TimeOfDay initial,
    required void Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
              surface: _cardColor,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  // ── Input decoration ───────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(fontSize: 14, color: _textSecondary),
      prefixIcon: Icon(icon, color: _accent, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _danger, width: 2),
      ),
      filled: true,
      fillColor: _bgColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Responsive: use full-screen bottom sheet on narrow screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return _buildBottomSheet(context);
    }
    return _buildDesktopDialog(context);
  }

  // ── Mobile: bottom sheet style ─────────────────────────────────────────────
  Widget _buildBottomSheet(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.bottomCenter,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _buildForm(),
              ),
            ),
            _buildActions(isMobile: true),
          ],
        ),
      ),
    );
  }

  // ── Desktop: centered dialog ───────────────────────────────────────────────
  Widget _buildDesktopDialog(BuildContext context) {
    return Dialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: _buildForm(),
              ),
            ),
            _buildActions(isMobile: false),
          ],
        ),
      ),
    );
  }

  // ── Dialog header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_calendar_rounded,
                color: _accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regularise Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(widget.log.clockInTime.toLocal()),
                  style: TextStyle(
                      fontSize: 13, color: _textSecondary),
                ),
              ],
            ),
          ),
          // Close button
          Container(
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: IconButton(
              icon: Icon(Icons.close_rounded,
                  color: _textSecondary, size: 18),
              onPressed: () => Navigator.of(context).pop(),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form body ──────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Current attendance info chip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accent.withOpacity(_isDark ? 0.15 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _accent.withOpacity(_isDark ? 0.3 : 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: _accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Submitting a correction request for ${_formatDate(widget.log.clockInTime.toLocal())}',
                      style: TextStyle(
                          fontSize: 13,
                          color: _accent,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section label
            Text(
              'Corrected Times',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Clock-in time field
            TextFormField(
              decoration: _inputDecoration(
                  'Clock-in Time', Icons.login_rounded),
              readOnly: true,
              style: TextStyle(
                  fontSize: 15,
                  color: _textPrimary,
                  fontWeight: FontWeight.w500),
              onTap: () => _pickTime(
                initial: _clockInTime,
                onPicked: (t) => _clockInTime = t,
              ),
              controller: TextEditingController(
                  text: _clockInTime.format(context)),
            ),
            const SizedBox(height: 14),

            // Clock-out time field
            TextFormField(
              decoration: _inputDecoration(
                  'Clock-out Time', Icons.logout_rounded),
              readOnly: true,
              style: TextStyle(
                  fontSize: 15,
                  color: _textPrimary,
                  fontWeight: FontWeight.w500),
              onTap: () => _pickTime(
                initial: _clockOutTime ?? TimeOfDay.now(),
                onPicked: (t) => _clockOutTime = t,
              ),
              controller: TextEditingController(
                  text: _clockOutTime?.format(context) ?? ''),
            ),
            const SizedBox(height: 20),

            // Section label
            Text(
              'Reason',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Reason field
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              style: TextStyle(fontSize: 15, color: _textPrimary),
              decoration: _inputDecoration(
                'Reason (Mandatory)',
                Icons.notes_rounded,
              ).copyWith(
                alignLabelWithHint: true,
                prefixIconConstraints: const BoxConstraints(
                    minWidth: 48, minHeight: 48),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a reason for the correction';
                }
                if (value.length < 10) {
                  return 'Please provide a more detailed reason';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActions({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          isMobile ? 20 : 24, 16, isMobile ? 20 : 24, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: isMobile
          // Mobile: full-width stacked buttons
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitRequest,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Icon(
                            Icons.check_circle_rounded,
                            size: 20),
                    label: Text(
                      _isLoading ? 'Submitting...' : 'Submit Request',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _accent.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondary,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: _borderColor),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                ),
              ],
            )
          // Desktop: side-by-side buttons
          : Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondary,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: _borderColor),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitRequest,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Icon(Icons.check_circle_rounded,
                            size: 20),
                    label: Text(
                      _isLoading ? 'Submitting...' : 'Submit Request',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _accent.withOpacity(0.6),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}