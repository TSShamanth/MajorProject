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

  @override
  void initState() {
    super.initState();
    _clockInTime = TimeOfDay.fromDateTime(widget.log.clockInTime.toLocal());
    if (widget.log.clockOutTime != null) {
      _clockOutTime = TimeOfDay.fromDateTime(widget.log.clockOutTime!.toLocal());
    } else {
      _clockOutTime = null;
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
      if (institutionId == null) {
        throw Exception("Institution ID not found");
      }

      final requestData = RegularisationRequestDTO(
        targetDate: widget.log.clockInTime,
        newClockInTime: '${_clockInTime.hour}:${_clockInTime.minute}',
        newClockOutTime: _clockOutTime != null ? '${_clockOutTime!.hour}:${_clockOutTime!.minute}' : null,
        reason: _reasonController.text,
        attendanceLogId: widget.log.id,
      );

      await _apiService.createRegularisationRequest(institutionId, requestData.toJson());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regularisation request submitted successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Regularise Attendance'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Clock-in Time',
                suffixIcon: Icon(Icons.access_time),
              ),
              readOnly: true,
              onTap: () async {
                final newTime = await showTimePicker(
                  context: context,
                  initialTime: _clockInTime,
                );
                if (newTime != null) {
                  setState(() {
                    _clockInTime = newTime;
                  });
                }
              },
              controller: TextEditingController(
                text: _clockInTime.format(context),
              ),
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Clock-out Time',
                suffixIcon: Icon(Icons.access_time),
              ),
              readOnly: true,
              onTap: () async {
                final newTime = await showTimePicker(
                  context: context,
                  initialTime: _clockOutTime ?? TimeOfDay.now(),
                );
                if (newTime != null) {
                  setState(() {
                    _clockOutTime = newTime;
                  });
                }
              },
              controller: TextEditingController(
                text: _clockOutTime?.format(context) ?? '',
              ),
            ),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason (Mandatory)'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a reason';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRequest,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
