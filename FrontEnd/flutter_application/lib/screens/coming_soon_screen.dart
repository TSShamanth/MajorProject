import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 64,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$title Coming Soon',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We are working hard to bring this feature to you!',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
