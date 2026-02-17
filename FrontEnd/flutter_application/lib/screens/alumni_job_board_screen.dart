import 'package:flutter/material.dart';

// Mock Data
class JobPosting {
  final String title;
  final String company;
  final String location;
  final String postedBy;

  JobPosting({
    required this.title,
    required this.company,
    required this.location,
    required this.postedBy,
  });
}

class AlumniJobBoardScreen extends StatefulWidget {
  const AlumniJobBoardScreen({super.key});

  @override
  State<AlumniJobBoardScreen> createState() => _AlumniJobBoardScreenState();
}

class _AlumniJobBoardScreenState extends State<AlumniJobBoardScreen> {
  // Mock Data
  final List<JobPosting> _jobs = [
    JobPosting(title: 'Senior Flutter Developer', company: 'Google', location: 'Bengaluru (Remote)', postedBy: 'Rohan Sharma \'20'),
    JobPosting(title: 'Data Analyst (Fresher)', company: 'Deloitte', location: 'Hyderabad', postedBy: 'Priya Singh \'21'),
    JobPosting(title: 'Mechanical Design Engineer', company: 'Tata Motors', location: 'Pune', postedBy: 'Amit Patel \'20'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Job Board'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _jobs.length,
        itemBuilder: (context, index) {
          final job = _jobs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(job.company),
                    ],
                  ),
                   const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(job.location),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text('Posted by: ${job.postedBy}', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                       ElevatedButton(onPressed: (){}, child: const Text('View Details')),
                    ],
                  )

                ],
              ),
            ),
          );
        },
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open a dialog or screen to post a new job
        },
        tooltip: 'Post a New Job',
        child: const Icon(Icons.add),
      ),
    );
  }
}
