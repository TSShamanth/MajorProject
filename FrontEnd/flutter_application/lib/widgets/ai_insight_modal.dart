import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class AiInsightModal extends StatefulWidget {
  final String? studentId; // If null, fetches for current student

  const AiInsightModal({super.key, this.studentId});

  @override
  State<AiInsightModal> createState() => _AiInsightModalState();
}

class _AiInsightModalState extends State<AiInsightModal> {
  final ApiService _apiService = ApiService();
  String? _insights;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    try {
      final institutionId = await SessionManager.getInstitutionId();
      if (institutionId == null) throw Exception('Institution ID not found');

      String data;
      if (widget.studentId == null) {
        data = await _apiService.getMyAiInsights(institutionId);
      } else {
        data = await _apiService.getMenteeAiInsights(institutionId, widget.studentId!);
      }

      if (mounted) {
        setState(() {
          _insights = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: size.width > 600 ? 500 : size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.75,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Data-driven analysis',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: _isLoading
                  ? _buildLoadingState(isDarkMode)
                  : _error != null
                      ? _buildErrorState(isDarkMode)
                      : _buildMarkdownContent(isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        SizedBox(
          height: 120,
          child: Lottie.asset(
            'assets/animations/green_tick.json', // We'll use this if it exists, else use a simple indicator
            errorBuilder: (context, error, stackTrace) => const CircularProgressIndicator(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Analyzing patterns...',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          'Oops! Something went wrong',
          style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          'We encountered an issue while analyzing your data. Please try again in a moment.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isLoading = true;
              _error = null;
            });
            _fetchInsights();
          },
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildMarkdownContent(bool isDarkMode) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: MarkdownBody(
        data: _insights!,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: isDarkMode ? Colors.grey[300] : const Color(0xFF4B5563),
            height: 1.5,
            fontSize: 15,
          ),
          h1: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF1F2937), fontWeight: FontWeight.bold),
          h2: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 18),
          h3: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 16),
          listBullet: TextStyle(color: const Color(0xFF4F46E5), fontSize: 20),
        ),
      ),
    );
  }
}
