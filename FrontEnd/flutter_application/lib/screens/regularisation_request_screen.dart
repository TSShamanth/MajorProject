import 'package:flutter/material.dart';
import 'package:flutter_application/models/regularisation_request_dto.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:go_router/go_router.dart';

class RegularisationRequestScreen extends StatefulWidget {
  const RegularisationRequestScreen({super.key});

  @override
  State<RegularisationRequestScreen> createState() => _RegularisationRequestScreenState();
}

class _RegularisationRequestScreenState extends State<RegularisationRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _requestType;
  final TextEditingController _reasonController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

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
        targetDate: _selectedDate!,
        targetTime: '${_selectedTime!.hour}:${_selectedTime!.minute}',
        type: _requestType!,
        reason: _reasonController.text,
        attendanceLogId: null, // This screen is for new requests, not modifying existing ones
      );

      await _apiService.createRegularisationRequest(institutionId, requestData.toJson());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regularisation request submitted successfully!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regularisation Request'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              final institutionId = GoRouter.of(context).routerDelegate.currentConfiguration.pathParameters['institutionId'];
              if (institutionId != null) {
                context.push('/$institutionId/faculty/regularisation/status');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Date Picker
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Target Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  _selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  setState(() {});
                },
                controller: TextEditingController(
                  text: _selectedDate == null ? '' : '${_selectedDate!.toLocal()}'.split(' ')[0],
                ),
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              // Time Picker
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Target Time',
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () async {
                  _selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  setState(() {});
                },
                controller: TextEditingController(
                  text: _selectedTime == null ? '' : _selectedTime!.format(context),
                ),
                validator: (value) {
                  if (_selectedTime == null) {
                    return 'Please select a time';
                  }
                  return null;
                },
              ),
              // Request Type
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Request Type'),
                value: _requestType,
                items: ['Clock-in', 'Clock-out']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _requestType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a request type';
                  }
                  return null;
                },
              ),
              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
