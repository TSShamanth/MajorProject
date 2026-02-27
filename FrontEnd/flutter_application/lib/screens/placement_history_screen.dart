import 'package:flutter/material.dart';
import '../services/placement_service.dart';
import '../models/placement_application_model.dart';

class PlacementHistoryScreen extends StatefulWidget {
  final String institutionId;
  const PlacementHistoryScreen({super.key, required this.institutionId});

  @override
  State<PlacementHistoryScreen> createState() => _PlacementHistoryScreenState();
}

class _PlacementHistoryScreenState extends State<PlacementHistoryScreen> {
  bool _isLoading = true;
  List<PlacementApplicationModel> _history = [];
  late PlacementService _placementService;

  @override
  void initState() {
    super.initState();
    _placementService = PlacementService(institutionId: widget.institutionId);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      _history = await _placementService.getPlacementHistory();
    } catch (e) {
      debugPrint('Error loading placement history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Placement Records'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _history.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) => _buildHistoryCard(_history[index]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No placement records found yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const Text('Be the first to get placed this season!', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(PlacementApplicationModel app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.indigo.withOpacity(0.1),
            child: Text(app.studentName[0].toUpperCase(), style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${app.companyName} • ${app.jobRole}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Text('Year: 2026', style: TextStyle(color: Colors.grey[500], fontSize: 11)), // Hardcoded for now
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text('Placed', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
