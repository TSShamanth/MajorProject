import 'package:flutter/material.dart';

// --- Data Models ---
enum QuestionType { shortText, paragraph, multipleChoice, checkbox, dropdown }

class FormQuestion {
  String questionText;
  QuestionType type;
  List<String> options;
  bool isRequired;

  FormQuestion({
    required this.questionText,
    this.type = QuestionType.shortText,
    this.isRequired = false,
    List<String>? options,
  }) : options = options ?? [];
}

// --- Main Screen ---
class FormEditorScreen extends StatefulWidget {
  const FormEditorScreen({super.key});

  @override
  State<FormEditorScreen> createState() => _FormEditorScreenState();
}

class _FormEditorScreenState extends State<FormEditorScreen> {
  final _titleController = TextEditingController(text: 'Student Satisfaction Survey 2024');
  final _descriptionController = TextEditingController(text: 'Please provide your honest feedback.');

  final List<FormQuestion> _questions = [
    FormQuestion(questionText: 'What is your name?', isRequired: true),
    FormQuestion(questionText: 'How would you rate the library services?', type: QuestionType.multipleChoice, options: ['Excellent', 'Good', 'Average', 'Poor']),
    FormQuestion(questionText: 'Any suggestions for the sports facilities?', type: QuestionType.paragraph),
  ];

  void _addQuestion() {
    setState(() {
      _questions.add(FormQuestion(questionText: 'New Question'));
    });
  }
  
  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'Preview',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Form',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFormHeader(),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return QuestionEditor(
                  key: ValueKey(_questions[index]), // Important for stateful list items
                  question: _questions[index],
                  onRemove: () => _removeQuestion(index),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Form Title',),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Form Description',),
            ),
          ],
        ),
      ),
    );
  }
}


// --- Question Editor Widget ---
class QuestionEditor extends StatefulWidget {
  final FormQuestion question;
  final VoidCallback onRemove;

  const QuestionEditor({super.key, required this.question, required this.onRemove});

  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  late TextEditingController _questionTextController;

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController(text: widget.question.questionText);
  }
  
  @override
  void dispose() {
    _questionTextController.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      widget.question.options.add('New Option');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
       elevation: 2,
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           children: [
             Row(
               children: [
                 Expanded(
                   child: TextFormField(
                     controller: _questionTextController,
                     decoration: const InputDecoration(labelText: 'Question'),
                     onChanged: (value) => widget.question.questionText = value,
                   ),
                 ),
                 const SizedBox(width: 8),
                 DropdownButton<QuestionType>(
                   value: widget.question.type,
                   onChanged: (QuestionType? newValue) {
                     setState(() {
                       widget.question.type = newValue!;
                     });
                   },
                   items: QuestionType.values.map((QuestionType type) {
                     return DropdownMenuItem<QuestionType>(
                       value: type,
                       child: Text(type.name.replaceAll('_', ' ')),
                     );
                   }).toList(),
                 )
               ],
             ),
             const SizedBox(height: 8),
             if (widget.question.type == QuestionType.multipleChoice || 
                 widget.question.type == QuestionType.checkbox ||
                 widget.question.type == QuestionType.dropdown)
              _buildOptionsEditor(),
            const Divider(),
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 const Text('Required'),
                 Switch(value: widget.question.isRequired, onChanged: (val) { setState(() { widget.question.isRequired = val; });}),
                 IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: widget.onRemove),
               ],
             )
           ],
         ),
       ),
    );
  }

  Widget _buildOptionsEditor() {
    return Column(
      children: [
        for(int i = 0; i < widget.question.options.length; i++)
          Row(
            children: [
              const Icon(Icons.radio_button_off, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: widget.question.options[i],
                  onChanged: (value) => widget.question.options[i] = value,
                ),
              ),
              IconButton(icon: const Icon(Icons.clear), onPressed: () { setState(() { widget.question.options.removeAt(i); });})
            ],
          ),
        TextButton.icon(
          onPressed: _addOption,
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
        )
      ],
    );
  }
}
