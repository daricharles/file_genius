import 'package:flutter/material.dart';

/// Card showing the user's daily study streak and milestone progress.
class StreakCard extends StatelessWidget {
  final int loginDays;

  const StreakCard({
    super.key,
    required this.loginDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_fire_department,
            size: 48,
            color: Colors.orange[600],
          ),
          const SizedBox(height: 12),
          Text(
            '$loginDays Day Streak',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            loginDays >= 7 ? 'Amazing consistency!' : 'Keep going!',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (loginDays % 7) / 7,
            backgroundColor: Colors.orange.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            'Next milestone: ${7 - (loginDays % 7)} days',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
