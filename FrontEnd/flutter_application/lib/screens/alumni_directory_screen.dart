import 'package:flutter/material.dart';

// Mock Data
class Alumnus {
  final String name;
  final String program;
  final int graduationYear;
  final String company;
  final String role;

  Alumnus({
    required this.name,
    required this.program,
    required this.graduationYear,
    required this.company,
    required this.role,
  });
}

class AlumniDirectoryScreen extends StatefulWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  State<AlumniDirectoryScreen> createState() => _AlumniDirectoryScreenState();
}

class _AlumniDirectoryScreenState extends State<AlumniDirectoryScreen> {
  // Mock Data
  final List<Alumnus> _alumni = [
    Alumnus(name: 'Rohan Sharma', program: 'B.Tech CSE', graduationYear: 2020, company: 'Google', role: 'Software Engineer'),
    Alumnus(name: 'Priya Singh', program: 'B.B.A.', graduationYear: 2021, company: 'Deloitte', role: 'Business Analyst'),
    Alumnus(name: 'Amit Patel', program: 'B.Tech Mech', graduationYear: 2020, company: 'Tata Motors', role: 'Mechanical Engineer'),
     Alumnus(name: 'Sunita Williams', program: 'B.Tech CSE', graduationYear: 2022, company: 'Microsoft', role: 'Product Manager'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Directory'),
      ),
      body: Column(
        children: [
          _buildFilterControls(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _alumni.length,
              itemBuilder: (context, index) {
                final alumnus = _alumni[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alumnus.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${alumnus.program} - Class of ${alumnus.graduationYear}', style: TextStyle(color: Colors.grey[600])),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Icon(Icons.work_outline, size: 16, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${alumnus.role} at ${alumnus.company}')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('View Profile'),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Expanded(
            child: TextField(
              decoration: InputDecoration(hintText: 'Search by name, company...', prefixIcon: Icon(Icons.search)),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            hint: const Text('Year'),
            items: [2020, 2021, 2022].map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))).toList(),
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}
