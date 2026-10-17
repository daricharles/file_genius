import 'package:flutter/material.dart';
import '../../constants.dart';

/// Card showing the user's current Scholar Level and progress to the next level.
class UserLevelCard extends StatelessWidget {
  final int totalPoints;

  const UserLevelCard({
    super.key,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    final currentLevel = (totalPoints / 100).floor() + 1;
    final nextLevelPoints = currentLevel * 100;
    final progressToNext = (totalPoints % 100) / 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kBrand.withValues(alpha: 0.1),
            kBrand.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBrand.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kBrand, kBrand.withValues(alpha: 0.7)],
              ),
            ),
            child: Center(
              child: Text(
                'L$currentLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $currentLevel Scholar',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${nextLevelPoints - totalPoints} XP to Level ${currentLevel + 1}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressToNext,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(kBrand),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
