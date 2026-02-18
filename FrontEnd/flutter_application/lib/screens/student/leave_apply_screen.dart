import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/models/professor_model.dart';
import 'package:intl/intl.dart';

class LeaveApplyScreen extends StatefulWidget {
  const LeaveApplyScreen({super.key});

  @override
  State<LeaveApplyScreen> createState() => _LeaveApplyScreenState();
}

class _LeaveApplyScreenState extends State<LeaveApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _leaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedProfessorUid;
  PlatformFile? _pickedFile;
  bool _isLoading = false;

  final ApiService _apiService = ApiService();
  late Future<List<String>> _leaveTypesFuture;
  late Future<List<ProfessorDto>> _professorsFuture;

  @override
  void initState() {
    super.initState();
    _leaveTypesFuture = _apiService.getLeaveTypes();
    _professorsFuture = _apiService.getProfessors();
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
       builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc'],
    );
    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start and end date.')),
        );
        return;
      }
      if (_selectedProfessorUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a professor.')),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      try {
        final response = await _apiService.applyLeave(
          leaveType: _leaveType!,
          startDate: _startDate!,
          endDate: _endDate!,
          reason: _reasonController.text,
          professor: _selectedProfessorUid!,
          file: _pickedFile,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave application submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit leave application: ${response.body}')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'New Leave Application',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B)
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Fill out the form below to request time off.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 24.0),
                          _buildDropdown(_leaveTypesFuture, 'Leave Type', _leaveType, (val) => setState(() => _leaveType = val)),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(true),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: _buildDateField(false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _reasonController,
                            decoration: _inputDecoration('Reason for Leave'),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a reason for your leave';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          _buildFileUpload(),
                          const SizedBox(height: 16.0),
                          _buildProfessorDropdown(),
                          const SizedBox(height: 32.0),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              backgroundColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)
                              )
                            ),
                            child: _isLoading 
                            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white),)
                            : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(Future<List<String>> future, String label, String? currentValue, ValueChanged<String?> onChanged) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AbsorbPointer(
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration(label, suffixIcon: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2,))),
              hint: const Text('Loading...'),
              items: const [],
              onChanged: (value) {},
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No data available');
        } else {
          return DropdownButtonFormField<String>(
            value: currentValue,
            decoration: _inputDecoration(label),
            items: snapshot.data!.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) => value == null ? 'Please select an option' : null,
          );
        }
      },
    );
  }

  Widget _buildDateField(bool isStartDate) {
    DateTime? date = isStartDate ? _startDate : _endDate;
    String label = isStartDate ? 'Start Date' : 'End Date';
    return InkWell(
      onTap: () => _selectDate(context, isStartDate: isStartDate),
      child: InputDecorator(
        decoration: _inputDecoration(
          label,
          suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF94A3B8)),
          errorText: (!isStartDate && _endDate != null && _startDate != null && _endDate!.isBefore(_startDate!))
              ? 'Invalid date'
              : null,
        ),
        child: Text(
          date != null
              ? DateFormat.yMMMd().format(date)
              : 'Select Date',
          style: TextStyle(
            color: date != null ? const Color(0xFF1E293B) : const Color(0xFF64748B)
          ),
        ),
      ),
    );
  }

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file, color: Color(0xFF4F46E5),),
          label: const Text('Upload Document', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            )
          ),
        ),
        if (_pickedFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20,),
                const SizedBox(width: 8),
                Expanded(child: Text('Selected: ${_pickedFile!.name}', style: const TextStyle(color: Color(0xFF475569)),)),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.red,),
                  onPressed: () => setState(() => _pickedFile = null),
                )
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String labelText, {Widget? suffixIcon, String? errorText}) {
    return InputDecoration(
      labelText: labelText,
      errorText: errorText,
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
      suffixIcon: suffixIcon
    );
  }

  Widget _buildProfessorDropdown() {
    return FutureBuilder<List<ProfessorDto>>(
      future: _professorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AbsorbPointer(
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration('Notify Professor', 
                suffixIcon: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              hint: const Text('Loading...'),
              items: const [],
              onChanged: (value) {},
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error loading professors: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No professors available');
        } else {
          final professors = snapshot.data!;
          return DropdownButtonFormField<String>(
            value: _selectedProfessorUid,
            decoration: _inputDecoration('Notify Professor'),
            hint: const Text('Select a Professor'),
            items: professors.map((ProfessorDto prof) {
              return DropdownMenuItem<String>(
                value: prof.uid,
                child: Text(prof.displayName),
                onTap: () {
                  setState(() {
                    _selectedProfessorUid = prof.uid;
                  });
                },
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProfessorUid = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a professor';
              }
              return null;
            },
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}