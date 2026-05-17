import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/form_builder_model.dart';
import '../services/form_builder_service.dart';
import '../services/session_manager.dart';
import '../services/api_service.dart';
import '../widgets/admin_layout.dart';

class FormEditorScreen extends StatefulWidget {
  final String? formId;
  const FormEditorScreen({super.key, this.formId});

  @override
  State<FormEditorScreen> createState() => _FormEditorScreenState();
}

class _FormEditorScreenState extends State<FormEditorScreen> {
  final FormBuilderService _formService = FormBuilderService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<FormFieldModel> _fields = [];
  List<String> _targetAudience = ['ALL'];
  bool _isOpen = true;
  bool _allowMultipleSubmissions = false;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String? _institutionId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _institutionId = await SessionManager.getInstitutionId();
    if (widget.formId != null && widget.formId != 'new') {
      setState(() => _isLoading = true);
      try {
        final form = await _formService.getFormById(widget.formId!);
        setState(() {
          _titleController.text = form.title;
          _descriptionController.text = form.description;
          _fields = form.fields;
          _targetAudience = form.targetAudience;
          _isOpen = form.isOpen;
          _allowMultipleSubmissions = form.allowMultipleSubmissions;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading form: $e')));
        }
      }
    }
  }

  void _addField() {
    setState(() {
      _fields.add(FormFieldModel(
        id: const Uuid().v4(),
        type: 'TEXT',
        label: 'Untitled Question',
        placeholder: '',
        isRequired: false,
      ));
    });
  }

  void _removeField(int index) {
    setState(() => _fields.removeAt(index));
  }

  Future<void> _saveForm() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a form title')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final form = CustomForm(
        id: (widget.formId == 'new' || widget.formId == null) ? '' : widget.formId!,
        institutionId: _institutionId ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        createdBy: '', // Set by backend
        createdAt: now,
        updatedAt: now,
        expiryDate: 0,
        isOpen: _isOpen,
        allowMultipleSubmissions: _allowMultipleSubmissions,
        targetAudience: _targetAudience,
        fields: _fields,
      );

      await _formService.saveForm(form);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form saved successfully!')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving form: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final textPrimary = _isDarkMode ? Colors.white : Colors.black87;

    return AdminLayout(
      title: widget.formId == 'new' ? 'New Form' : 'Edit Form',
      breadcrumbs: [
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.pop(),
          child: Text('Form Builder', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Text('Editor', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormHeader(textPrimary),
                    const SizedBox(height: 24),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _fields.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _fields.removeAt(oldIndex);
                          _fields.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) => _buildFieldEditor(_fields[index], index),
                    ),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _magicGenerateFields() async {
    final topicController = TextEditingController();
    final topic = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Form Builder'),
        content: TextField(
          controller: topicController,
          decoration: const InputDecoration(
            hintText: 'e.g., Student Feedback for CSE Department',
            labelText: 'What is this form about?',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, topicController.text),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (topic != null && topic.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final apiService = ApiService();
        final proposalJson = await apiService.proposeFormFields(topic);
        final List<dynamic> proposedFields = jsonDecode(proposalJson);
        
        setState(() {
          _fields.clear(); // Clear existing fields
          for (var field in proposedFields) {
            String rawType = field['type'].toString().toUpperCase();
            String mappedType = 'TEXT';
            
            // Map AI suggestions to supported frontend types
            if (rawType.contains('TEXT')) {
              mappedType = 'TEXT';
            } else if (rawType.contains('PARA')) {
              mappedType = 'PARAGRAPH';
            } else if (rawType.contains('CHOICE')) {
              mappedType = 'MULTIPLE_CHOICE';
            } else if (rawType.contains('CHECK')) {
              mappedType = 'CHECKBOXES';
            } else if (rawType.contains('DROP')) {
              mappedType = 'DROPDOWN';
            } else if (rawType.contains('SCALE')) {
              mappedType = 'SCALE';
            } else if (rawType.contains('DATE')) {
              mappedType = 'DATE';
            } else if (rawType.contains('NUM')) {
              mappedType = 'TEXT';
            }
            
            _fields.add(FormFieldModel(
              id: const Uuid().v4(),
              type: mappedType,
              label: field['label'],
              placeholder: '',
              isRequired: field['required'] ?? false,
              options: field['options'] != null ? List<String>.from(field['options']) : [],
            ));
          }
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating fields: $e')));
        }
      }
    }
  }

  Widget _buildFormHeader(Color textPrimary) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFD1D5DB);

    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Container(
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Form Title',
                    labelStyle: TextStyle(color: const Color(0xFF4F46E5).withOpacity(0.8)),
                    hintText: 'Enter a descriptive title...',
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF4F46E5), width: 2)),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: null,
                  style: TextStyle(fontSize: 16, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Form Description',
                    labelStyle: TextStyle(color: textPrimary.withOpacity(0.6)),
                    hintText: 'Add instructions or details for respondents...',
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF4F46E5), width: 2)),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Target Audience', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
                          const SizedBox(height: 12),
                          _buildAudienceSelector(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildSettingsToggle('Allow Multiple Submissions', _allowMultipleSubmissions, (val) => setState(() => _allowMultipleSubmissions = val)),
                        const SizedBox(height: 8),
                        _buildSettingsToggle('Accepting Responses', _isOpen, (val) => setState(() => _isOpen = val)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF4F46E5),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildAudienceSelector() {
    final options = ['ALL', 'STUDENT', 'FACULTY', 'ADMIN', 'ALUMNI'];
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final isSelected = _targetAudience.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (option == 'ALL') {
                _targetAudience = ['ALL'];
              } else {
                _targetAudience.remove('ALL');
                if (selected) {
                  _targetAudience.add(option);
                } else {
                  _targetAudience.remove(option);
                  if (_targetAudience.isEmpty) _targetAudience = ['ALL'];
                }
              }
            });
          },
          selectedColor: const Color(0xFF4F46E5).withOpacity(0.2),
          checkmarkColor: const Color(0xFF4F46E5),
        );
      }).toList(),
    );
  }

  Widget _buildFieldEditor(FormFieldModel field, int index) {
    final cardColor = _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      key: ValueKey(field.id),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) => _updateField(index, label: val),
                  controller: TextEditingController(text: field.label)..selection = TextSelection.collapsed(offset: field.label.length),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(hintText: 'Question', filled: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: field.type,
                  decoration: const InputDecoration(filled: true),
                  items: const [
                    DropdownMenuItem(value: 'TEXT', child: Text('Short Answer')),
                    DropdownMenuItem(value: 'PARAGRAPH', child: Text('Paragraph')),
                    DropdownMenuItem(value: 'MULTIPLE_CHOICE', child: Text('Multiple Choice')),
                    DropdownMenuItem(value: 'CHECKBOXES', child: Text('Checkboxes')),
                    DropdownMenuItem(value: 'DROPDOWN', child: Text('Dropdown')),
                    DropdownMenuItem(value: 'SCALE', child: Text('Linear Scale')),
                    DropdownMenuItem(value: 'DATE', child: Text('Date')),
                  ],
                  onChanged: (val) => _updateField(index, type: val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (['MULTIPLE_CHOICE', 'CHECKBOXES', 'DROPDOWN'].contains(field.type)) 
            _buildOptionsEditor(field, index),
          if (field.type == 'SCALE')
            _buildScaleEditor(field, index),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(onPressed: () => _removeField(index), icon: const Icon(Icons.delete_outline, color: Colors.red)),
              const VerticalDivider(),
              const Text('Required'),
              Switch(
                value: field.isRequired, 
                onChanged: (val) => _updateField(index, isRequired: val),
                activeColor: const Color(0xFF4F46E5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsEditor(FormFieldModel field, int index) {
    return Column(
      children: [
        ...field.options.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(field.type == 'CHECKBOXES' ? Icons.check_box_outline_blank : Icons.radio_button_off, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    final newOptions = List<String>.from(field.options);
                    newOptions[entry.key] = val;
                    _updateField(index, options: newOptions);
                  },
                  controller: TextEditingController(text: entry.value)..selection = TextSelection.collapsed(offset: entry.value.length),
                  decoration: const InputDecoration(hintText: 'Option'),
                ),
              ),
              IconButton(
                onPressed: () {
                  final newOptions = List<String>.from(field.options)..removeAt(entry.key);
                  _updateField(index, options: newOptions);
                }, 
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        )),
        TextButton.icon(
          onPressed: () {
            final newOptions = List<String>.from(field.options)..add('Option ${field.options.length + 1}');
            _updateField(index, options: newOptions);
          }, 
          icon: const Icon(Icons.add), 
          label: const Text('Add Option'),
        ),
      ],
    );
  }

  Widget _buildScaleEditor(FormFieldModel field, int index) {
    return Row(
      children: [
        const Text('Range: '),
        DropdownButton<int>(
          value: field.minScale ?? 1,
          items: const [DropdownMenuItem(value: 0, child: Text('0')), DropdownMenuItem(value: 1, child: Text('1'))],
          onChanged: (val) => _updateField(index, minScale: val),
        ),
        const Text(' to '),
        DropdownButton<int>(
          value: field.maxScale ?? 5,
          items: List.generate(9, (i) => i + 2).map((i) => DropdownMenuItem(value: i, child: Text('$i'))).toList(),
          onChanged: (val) => _updateField(index, maxScale: val),
        ),
      ],
    );
  }

  void _updateField(int index, {String? label, String? type, bool? isRequired, List<String>? options, int? minScale, int? maxScale}) {
    setState(() {
      final old = _fields[index];
      _fields[index] = FormFieldModel(
        id: old.id,
        type: type ?? old.type,
        label: label ?? old.label,
        placeholder: old.placeholder,
        isRequired: isRequired ?? old.isRequired,
        options: options ?? old.options,
        minScale: minScale ?? old.minScale,
        maxScale: maxScale ?? old.maxScale,
      );
    });
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _magicGenerateFields,
          icon: const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
          label: const Text('Magic AI Build'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[50],
            foregroundColor: Colors.amber[900],
            side: BorderSide(color: Colors.amber[200]!),
          ),
        ),
        const SizedBox(width: 24),
        ElevatedButton.icon(
          onPressed: _addField,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Question'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5), side: const BorderSide(color: Color(0xFF4F46E5))),
        ),
        const SizedBox(width: 24),
        ElevatedButton.icon(
          onPressed: _saveForm,
          icon: const Icon(Icons.save),
          label: const Text('Save Form'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
