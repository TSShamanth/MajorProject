import 'package:flutter/material.dart';

class BulkUserImportScreen extends StatefulWidget {
  const BulkUserImportScreen({super.key});

  @override
  State<BulkUserImportScreen> createState() => _BulkUserImportScreenState();
}

class _BulkUserImportScreenState extends State<BulkUserImportScreen> {
  int _currentStep = 0;
  String? _uploadedFileName;

  // Mock data
  final List<String> _csvHeaders = ['Full Name', 'Email Address', 'Role', 'USN'];
  final List<String> _userModelFields = ['name', 'email', 'role', 'usn', 'phone', 'Not Mapped'];
  late List<String> _mappedFields;

  @override
  void initState() {
    super.initState();
    _mappedFields = List.from(_userModelFields.take(4)); // Pre-fill for demo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk User Import'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            // Final import logic would go here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Import process started (mocked).')),
            );
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        steps: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
        ],
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: const Text('Download Template'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start by downloading the CSV template. This ensures your data is in the correct format for a successful import.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading template... (mocked)')),
                );
              },
              icon: const Icon(Icons.download_for_offline_outlined),
              label: const Text('Download CSV Template'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.grey[200],
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Template Preview:\n"Full Name","Email Address","Role","USN"\n"John Doe","john.d@example.com","student","1RVU21CSE001"',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
      isActive: _currentStep >= 0,
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Upload File'),
      content: Column(
        children: [
          const Text(
            'Upload the CSV file containing the user data you wish to import.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _uploadedFileName = 'users_to_import.csv';
              });
            },
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Choose CSV File'),
          ),
          if (_uploadedFileName != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Chip(
                label: Text(_uploadedFileName!),
                onDeleted: () {
                  setState(() {
                    _uploadedFileName = null;
                  });
                },
              ),
            ),
        ],
      ),
      isActive: _currentStep >= 1,
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('Map Columns'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match the columns from your CSV file to the corresponding fields in the application.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _csvHeaders.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(_csvHeaders[i], style: const TextStyle(fontWeight: FontWeight.bold))),
                  const Icon(Icons.arrow_forward),
                  Expanded(
                    flex: 3,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _mappedFields[i],
                      items: _userModelFields.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _mappedFields[i] = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      isActive: _currentStep >= 2,
    );
  }

  Step _buildStep4() {
    return Step(
      title: const Text('Review & Import'),
      content: Column(
        children: [
          const Text(
            'Review the import summary below. If everything is correct, proceed with the import.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text('25 users will be created.'),
          ),
          const ListTile(
            leading: Icon(Icons.warning_amber_outlined, color: Colors.orange),
            title: Text('3 rows have formatting errors and will be skipped.'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blue),
            title: Text('Estimated time: < 1 minute.'),
          ),
        ],
      ),
      isActive: _currentStep >= 3,
    );
  }
}
