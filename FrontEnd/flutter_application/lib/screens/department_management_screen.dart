import 'package:flutter/material.dart';

class DepartmentManagementScreen extends StatefulWidget {
  final String departmentName;
  final String assetType; // 'Courses', 'Faculty', or 'Students'

  const DepartmentManagementScreen({
    super.key,
    required this.departmentName,
    required this.assetType,
  });

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  late List<Map<String, String>> _items;

  @override
  void initState() {
    super.initState();
    // Initialize with hardcoded data based on the asset type
    _items = _getHardcodedData();
  }

  List<Map<String, String>> _getHardcodedData() {
    switch (widget.assetType) {
      case 'Courses':
        return [
          {'title': 'CS101: Intro to Programming', 'subtitle': 'Code: CSE01'},
          {'title': 'CS203: Data Structures', 'subtitle': 'Code: CSE09'},
        ];
      case 'Faculty':
        return [
          {'title': 'Dr. Alan Turing', 'subtitle': 'aturing@rvu.edu.in'},
          {'title': 'Dr. Ada Lovelace', 'subtitle': 'alovelace@rvu.edu.in'},
        ];
      case 'Students':
        return [
          {'title': 'John Doe', 'subtitle': 'USN: 1RVU21CSE001'},
          {'title': 'Jane Smith', 'subtitle': 'USN: 1RVU21CSE002'},
        ];
      default:
        return [];
    }
  }

  void _addItem() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New ${widget.assetType.singular}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (titleController.text.isNotEmpty && subtitleController.text.isNotEmpty) {
                  setState(() {
                    _items.add({
                      'title': titleController.text,
                      'subtitle': subtitleController.text,
                    });
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _editItem(int index) {
     final item = _items[index];
    final titleController = TextEditingController(text: item['title']);
    final subtitleController = TextEditingController(text: item['subtitle']);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${widget.assetType.singular}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (titleController.text.isNotEmpty && subtitleController.text.isNotEmpty) {
                  setState(() {
                    _items[index] = {
                      'title': titleController.text,
                      'subtitle': subtitleController.text,
                    };
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${widget.assetType.singular}?'),
          content: Text('Are you sure you want to delete "${_items[index]['title']}"?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  _items.removeAt(index);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.assetType}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _items.isEmpty
          ? Center(
              child: Text(
                'No ${widget.assetType.toLowerCase()} found.\nAdd one to get started!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['subtitle']!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          onPressed: () => _editItem(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

extension on String {
  String get singular {
    if (endsWith('s')) {
      return substring(0, length - 1);
    }
    return this;
  }
}
