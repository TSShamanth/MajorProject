import 'package:flutter/material.dart';
import '../widgets/admin_layout.dart';

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
  // ── Mock Data ─────────────────────────────────────────────────────────────
  final List<Alumnus> _alumni = [
    Alumnus(name: 'Rohan Sharma', program: 'B.Tech CSE', graduationYear: 2020, company: 'Google', role: 'Software Engineer'),
    Alumnus(name: 'Priya Singh', program: 'B.B.A.', graduationYear: 2021, company: 'Deloitte', role: 'Business Analyst'),
    Alumnus(name: 'Amit Patel', program: 'B.Tech Mech', graduationYear: 2020, company: 'Tata Motors', role: 'Mechanical Engineer'),
    Alumnus(name: 'Sunita Williams', program: 'B.Tech CSE', graduationYear: 2022, company: 'Microsoft', role: 'Product Manager'),
  ];

  bool _isDarkMode = false;
  int? _selectedYear;
  String _searchQuery = '';

  // ── Theme helpers ──────────────────────────────────────────────────────────
  Color get _bgColor =>
      _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _cardColor =>
      _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary =>
      _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary =>
      _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  static const _accent  = Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
  }

  List<Alumnus> get _filteredAlumni {
    return _alumni.where((alumnus) {
      final matchesSearch = _searchQuery.isEmpty ||
          alumnus.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          alumnus.company.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesYear = _selectedYear == null || alumnus.graduationYear == _selectedYear;
      return matchesSearch && matchesYear;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return AdminLayout(
      title: 'Alumni Directory',
      breadcrumbs: [
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: _textSecondary),
        const SizedBox(width: 8),
        Text('Directory', style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
      child: _buildBody(isMobile: isMobile),
    );
  }

  Widget _buildBody({required bool isMobile}) {
    final filtered = _filteredAlumni;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchAndFilters(isMobile),
          const SizedBox(height: 24),
          Text(
            '${filtered.length} ${filtered.length == 1 ? 'Alumnus' : 'Alumni'} Found',
            style: TextStyle(fontSize: 14, color: _textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          _buildAlumniGrid(filtered, isMobile),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: isMobile
          ? Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildYearFilter(),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 16),
                _buildYearFilter(),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: _textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name or company...',
                hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(color: _textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearFilter() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF111827) : _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButton<int>(
        value: _selectedYear,
        hint: Text('Graduation Year', style: TextStyle(color: _textSecondary, fontSize: 14)),
        underline: const SizedBox(),
        dropdownColor: _cardColor,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
        items: [null, 2018, 2019, 2020, 2021, 2022].map((year) {
          return DropdownMenuItem(
            value: year,
            child: Text(year == null ? 'All Years' : year.toString(),
                style: TextStyle(color: _textPrimary, fontSize: 14)),
          );
        }).toList(),
        onChanged: (v) => setState(() => _selectedYear = v),
      ),
    );
  }

  Widget _buildAlumniGrid(List<Alumnus> alumni, bool isMobile) {
    if (alumni.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.group_off_rounded, size: 64, color: _textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('No Alumni Found', style: TextStyle(fontSize: 16, color: _textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (MediaQuery.of(context).size.width > 1100 ? 3 : 2),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 140,
      ),
      itemCount: alumni.length,
      itemBuilder: (context, index) => _buildAlumniCard(alumni[index]),
    );
  }

  Widget _buildAlumniCard(Alumnus alumnus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _accent.withOpacity(0.1),
            child: Text(alumnus.name[0], style: const TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(alumnus.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                const SizedBox(height: 4),
                Text('${alumnus.program} • Class of ${alumnus.graduationYear}',
                    style: TextStyle(fontSize: 12, color: _textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business_center_outlined, size: 14, color: _accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${alumnus.role} at ${alumnus.company}',
                          style: TextStyle(fontSize: 12, color: _textPrimary, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
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
}
