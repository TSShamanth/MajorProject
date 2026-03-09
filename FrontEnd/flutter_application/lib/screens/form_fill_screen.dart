import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/form_builder_model.dart';
import '../services/form_builder_service.dart';
import '../services/session_manager.dart';
import '../services/api_service.dart';

class FormFillScreen extends StatefulWidget {
  final String formId;
  const FormFillScreen({super.key, required this.formId});

  @override
  State<FormFillScreen> createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<FormFillScreen> {
  final FormBuilderService _formService = FormBuilderService();
  final ApiService _apiService = ApiService();
  CustomForm? _form;
  FormResponseModel? _existingResponse;
  final Map<String, dynamic> _answers = {};
  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _isAlreadySubmitted = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() => _isLoading = true);
    try {
      final institutionId = await SessionManager.getInstitutionId();
      final form = await _formService.getFormById(widget.formId);
      final userResponse = await _formService.getUserResponse(widget.formId);
      final currentUser = await _apiService.getMe(institutionId!);

      setState(() {
        _form = form;
        _existingResponse = userResponse;
        _isAlreadySubmitted = userResponse != null && !form.allowMultipleSubmissions;
        
        // Initialize answers with existing response if editing
        if (userResponse != null) {
          _answers.addAll(userResponse.answers);
        } else {
          // Autofill logic
          for (var field in form.fields) {
            final label = field.label.toLowerCase();
            if (label.contains('name')) {
              _answers[field.id] = currentUser.displayName;
            } else if (label.contains('email')) {
              _answers[field.id] = currentUser.email;
            } else if (label.contains('phone')) {
              _answers[field.id] = currentUser.phone;
            }

            if (field.type == 'CHECKBOXES' && _answers[field.id] == null) {
              _answers[field.id] = <String>[];
            } else if (field.type == 'SCALE' && _answers[field.id] == null) {
              _answers[field.id] = field.minScale ?? 1;
            }
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading form: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _formService.submitResponse(
        widget.formId, 
        _answers, 
        responseId: _existingResponse?.id
      );
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            content: Text(
              _existingResponse != null 
                ? 'Your response has been updated successfully.'
                : 'Your response has been recorded successfully.', 
              textAlign: TextAlign.center
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) Navigator.pop(context);
                }, 
                child: const Text('OK')
              ),
            ],
          ),
        ).then((_) {
          if (mounted) context.pop();
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting response: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF3F4F6);

    if (_isLoading && _form == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_form == null) {
      return const Scaffold(body: Center(child: Text('Form not found')));
    }

    if (_isAlreadySubmitted && _existingResponse != null) {
      return _buildAlreadySubmittedView(bgColor);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(_form!.title),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildFormInfo(),
              const SizedBox(height: 16),
              if (_existingResponse != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 12),
                      Text('You are editing your previous response', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ..._form!.fields.map((field) => _buildFieldCard(field)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(
                    _existingResponse != null ? 'Update Response' : 'Submit Response', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormInfo() {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border(top: const BorderSide(color: Color(0xFF4F46E5), width: 8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_form!.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          if (_form!.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_form!.description, style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.grey[400] : Colors.grey[700])),
          ],
          const Divider(height: 32),
          const Text('* Required', style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFieldCard(FormFieldModel field) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(field.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              if (field.isRequired) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          _buildFieldInput(field),
        ],
      ),
    );
  }

  Widget _buildAlreadySubmittedView(Color bgColor) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text(_form!.title), backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.task_alt_rounded, color: Colors.green, size: 64),
              const SizedBox(height: 24),
              const Text('Already Submitted', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('You have already filled out this form. You can only submit one response.', textAlign: TextAlign.center, style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isAlreadySubmitted = false),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Edit Your Response'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Back to Dashboard')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldInput(FormFieldModel field) {
    switch (field.type) {
      case 'TEXT':
        return TextFormField(
          initialValue: _answers[field.id]?.toString(),
          onChanged: (val) => _answers[field.id] = val,
          validator: (val) => field.isRequired && (val == null || val.isEmpty) ? 'This is a required question' : null,
          decoration: InputDecoration(hintText: field.placeholder, border: const OutlineInputBorder()),
        );
      case 'PARAGRAPH':
        return TextFormField(
          initialValue: _answers[field.id]?.toString(),
          onChanged: (val) => _answers[field.id] = val,
          validator: (val) => field.isRequired && (val == null || val.isEmpty) ? 'This is a required question' : null,
          maxLines: 4,
          decoration: InputDecoration(hintText: field.placeholder, border: const OutlineInputBorder()),
        );
      case 'MULTIPLE_CHOICE':
        return Column(
          children: field.options.map((opt) => RadioListTile<String>(
            title: Text(opt),
            value: opt,
            groupValue: _answers[field.id],
            onChanged: (val) => setState(() => _answers[field.id] = val),
            activeColor: const Color(0xFF4F46E5),
          )).toList(),
        );
      case 'CHECKBOXES':
        final selected = (_answers[field.id] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        return Column(
          children: field.options.map((opt) => CheckboxListTile(
            title: Text(opt),
            value: selected.contains(opt),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selected.add(opt);
                } else {
                  selected.remove(opt);
                }
                _answers[field.id] = selected;
              });
            },
            activeColor: const Color(0xFF4F46E5),
          )).toList(),
        );
      case 'DROPDOWN':
        return DropdownButtonFormField<String>(
          value: _answers[field.id],
          items: field.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: (val) => _answers[field.id] = val,
          validator: (val) => field.isRequired && val == null ? 'Please select an option' : null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        );
      case 'SCALE':
        final min = (field.minScale ?? 1).toDouble();
        final max = (field.maxScale ?? 5).toDouble();
        return Column(
          children: [
            Slider(
              value: (_answers[field.id] as num? ?? min).toDouble(),
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              label: _answers[field.id].toString(),
              onChanged: (val) => setState(() => _answers[field.id] = val.toInt()),
              activeColor: const Color(0xFF4F46E5),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(min.toInt().toString()), Text(max.toInt().toString())],
              ),
            ),
          ],
        );
      default:
        return const Text('Unsupported field type');
    }
  }
}
