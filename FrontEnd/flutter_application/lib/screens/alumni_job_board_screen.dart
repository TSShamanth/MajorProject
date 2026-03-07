import 'package:flutter/material.dart';
import '../widgets/admin_layout.dart';

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
  // ── Mock Data ─────────────────────────────────────────────────────────────
  final List<JobPosting> _jobs = [
    JobPosting(title: 'Senior Flutter Developer', company: 'Google', location: 'Bengaluru (Remote)', postedBy: 'Rohan Sharma \'20'),
    JobPosting(title: 'Data Analyst (Fresher)', company: 'Deloitte', location: 'Hyderabad', postedBy: 'Priya Singh \'21'),
    JobPosting(title: 'Mechanical Design Engineer', company: 'Tata Motors', location: 'Pune', postedBy: 'Amit Patel \'20'),
  ];

  bool _isDarkMode = false;
  String _searchQuery = '';

  // ── Theme helpers ──────────────────────────────────────────────────────────
  Color get _cardColor =>
      _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary =>
      _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary =>
      _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  static const _accent  = Color(0xFF4F46E5);
  static const _success = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
  }

  List<JobPosting> get _filteredJobs {
    if (_searchQuery.isEmpty) return _jobs;
    return _jobs.where((job) {
      return job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.location.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return AdminLayout(
      title: 'Alumni Job Board',
      breadcrumbs: [
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: _textSecondary),
        const SizedBox(width: 8),
        Text('Job Board', style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let AdminLayout handle background
        body: _buildBody(isMobile: isMobile),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: _accent,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Post a Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildBody({required bool isMobile}) {
    final jobs = _filteredJobs;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(isMobile),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${jobs.length} Opportunities Available',
                style: TextStyle(fontSize: 14, color: _textSecondary, fontWeight: FontWeight.w500),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.filter_list_rounded, size: 18, color: _accent),
                label: Text('Filters', style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildJobGrid(jobs, isMobile),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: _textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search jobs by title, company, or location...',
                hintStyle: TextStyle(color: _textSecondary, fontSize: 15),
                border: InputBorder.none,
              ),
              style: TextStyle(color: _textPrimary, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobGrid(List<JobPosting> jobs, bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (MediaQuery.of(context).size.width > 1200 ? 2 : 1),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 160,
      ),
      itemCount: jobs.length,
      itemBuilder: (context, index) => _buildJobCard(jobs[index]),
    );
  }

  Widget _buildJobCard(JobPosting job) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                    const SizedBox(height: 4),
                    Text(job.company, style: TextStyle(fontSize: 15, color: _accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Full-time', style: TextStyle(color: _success, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: _textSecondary),
              const SizedBox(width: 4),
              Text(job.location, style: TextStyle(color: _textSecondary, fontSize: 13)),
              const SizedBox(width: 24),
              Icon(Icons.person_outline_rounded, size: 16, color: _textSecondary),
              const SizedBox(width: 4),
              Text('Posted by ${job.postedBy}', style: TextStyle(color: _textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent.withOpacity(0.1),
              foregroundColor: _accent,
              elevation: 0,
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
