import 'package:flutter/material.dart';

/// Responsive overview card displaying primary metrics (Files, Quiz accuracy, AI, Login streak).
class MainMetricsCard extends StatelessWidget {
  final int filesUploaded;
  final int weeklyUploads;
  final int questionsAnswered;
  final int correctAnswers;
  final int aiChatInteractions;
  final int loginDays;

  const MainMetricsCard({
    super.key,
    required this.filesUploaded,
    required this.weeklyUploads,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.aiChatInteractions,
    required this.loginDays,
  });

  Widget _buildMetricItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = questionsAnswered > 0
        ? ((correctAnswers / questionsAnswered) * 100).toInt()
        : 0;

    final items = <Widget>[
      _buildMetricItem(
        title: 'Files Uploaded',
        value: filesUploaded.toString(),
        icon: Icons.cloud_upload,
        color: Colors.blue,
        subtitle: '+$weeklyUploads this week',
      ),
      _buildMetricItem(
        title: 'Questions Answered',
        value: questionsAnswered.toString(),
        icon: Icons.quiz,
        color: Colors.green,
        subtitle: '$accuracy% accuracy',
      ),
      _buildMetricItem(
        title: 'AI Interactions',
        value: aiChatInteractions.toString(),
        icon: Icons.smart_toy,
        color: Colors.purple,
        subtitle: 'Explore more!',
      ),
      _buildMetricItem(
        title: 'Login Streak',
        value: '$loginDays days',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        subtitle: 'Keep it up!',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1000;
        if (isNarrow) {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: items
                .map(
                  (w) => SizedBox(
                    width: constraints.maxWidth / 2 - 12,
                    child: w,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: 16),
            Expanded(child: items[1]),
            const SizedBox(width: 16),
            Expanded(child: items[2]),
            const SizedBox(width: 16),
            Expanded(child: items[3]),
          ],
        );
      },
    );
  }
}
