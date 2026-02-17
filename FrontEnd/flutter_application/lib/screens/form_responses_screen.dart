import 'package:flutter/material.dart';

// Mock Data
class FormResponse {
  final List<String> answers;
  FormResponse(this.answers);
}

class FormResponsesScreen extends StatelessWidget {
  const FormResponsesScreen({super.key});

  // Mock Data
  static const List<String> _questions = [
    'What is your name?',
    'How would you rate the library services?',
    'Any suggestions for the sports facilities?',
  ];

  static final List<FormResponse> _responses = [
    FormResponse(['Alice', 'Excellent', 'More basketball courts, please.']),
    FormResponse(['Bob', 'Good', 'The gym timings could be extended.']),
    FormResponse(['Charlie', 'Excellent', 'No suggestions, everything is great!']),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Form Responses'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export to CSV',
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Individual'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSummaryView(),
            _buildIndividualView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummaryCard(
          question: _questions[1], // "How would you rate the library services?"
          child: Column(
            children: [
              _buildBarChartOption('Excellent', 2),
              _buildBarChartOption('Good', 1),
              _buildBarChartOption('Average', 0),
              _buildBarChartOption('Poor', 0),
            ],
          ),
        ),
        _buildSummaryCard(
          question: _questions[2], // "Any suggestions for the sports facilities?"
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _responses.map((r) => Text('• ${r.answers[2]}')).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard({required String question, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildBarChartOption(String option, int count) {
    // Simple bar chart representation
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(option)),
          Expanded(
            child: Container(
              height: 20,
              color: Colors.blue.withOpacity(0.2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: (count / _responses.length) * 200, // simple scaling
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          SizedBox(width: 10, child: Text('$count')),
        ],
      ),
    );
  }

  Widget _buildIndividualView() {
    return PageView.builder(
      itemCount: _responses.length,
      itemBuilder: (context, index) {
        final response = _responses[index];
        return Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Response ${index + 1} of ${_responses.length}', style: Theme.of(context).textTheme.titleLarge),
                const Divider(height: 24),
                for (int i = 0; i < _questions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_questions[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(response.answers[i], style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
