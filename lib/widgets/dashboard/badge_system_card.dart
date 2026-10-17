import 'package:flutter/material.dart';
import '../../constants.dart';

/// Achievement badge definition model.
class BadgeItemData {
  final IconData icon;
  final String label;
  final bool unlocked;
  final String description;

  const BadgeItemData({
    required this.icon,
    required this.label,
    required this.unlocked,
    required this.description,
  });
}

/// Grid card rendering gamified user badges with tooltips and unlock status.
class BadgeSystemCard extends StatelessWidget {
  final List<String> unlockedBadges;
  final int filesUploaded;
  final int loginDays;
  final int aiChatInteractions;
  final int correctAnswers;
  final int totalPoints;
  final int questionsAnswered;

  const BadgeSystemCard({
    super.key,
    required this.unlockedBadges,
    required this.filesUploaded,
    required this.loginDays,
    required this.aiChatInteractions,
    required this.correctAnswers,
    required this.totalPoints,
    required this.questionsAnswered,
  });

  List<BadgeItemData> _getBadgeDefinitions() {
    return [
      BadgeItemData(
        icon: Icons.upload_file,
        label: 'First Upload',
        unlocked: unlockedBadges.contains('first_file'),
        description: 'Upload your first file ($filesUploaded/1)',
      ),
      BadgeItemData(
        icon: Icons.folder,
        label: 'File Master',
        unlocked: unlockedBadges.contains('file_master'),
        description: 'Upload 10 files ($filesUploaded/10)',
      ),
      BadgeItemData(
        icon: Icons.workspace_premium,
        label: 'File Expert',
        unlocked: unlockedBadges.contains('file_expert'),
        description: 'Upload 50 files ($filesUploaded/50)',
      ),
      BadgeItemData(
        icon: Icons.emoji_events,
        label: 'Week Warrior',
        unlocked: unlockedBadges.contains('week_warrior'),
        description: 'Login for 7 consecutive days ($loginDays/7)',
      ),
      BadgeItemData(
        icon: Icons.stars,
        label: 'Month Master',
        unlocked: unlockedBadges.contains('month_master'),
        description: 'Login for 30 consecutive days ($loginDays/30)',
      ),
      BadgeItemData(
        icon: Icons.smart_toy,
        label: 'AI Explorer',
        unlocked: unlockedBadges.contains('ai_explorer'),
        description: 'Use AI chat 5 times ($aiChatInteractions/5)',
      ),
      BadgeItemData(
        icon: Icons.quiz,
        label: 'Quiz Master',
        unlocked: unlockedBadges.contains('quiz_master'),
        description: 'Answer 20 questions correctly ($correctAnswers/20)',
      ),
      BadgeItemData(
        icon: Icons.military_tech,
        label: 'Century Club',
        unlocked: unlockedBadges.contains('century_club'),
        description: 'Earn 100 XP ($totalPoints/100)',
      ),
      BadgeItemData(
        icon: Icons.diamond,
        label: 'Point Prodigy',
        unlocked: unlockedBadges.contains('point_prodigy'),
        description: 'Earn 500 XP ($totalPoints/500)',
      ),
      BadgeItemData(
        icon: Icons.school,
        label: 'Scholar',
        unlocked: unlockedBadges.contains('scholar'),
        description: 'Answer 100 questions ($questionsAnswered/100)',
      ),
      BadgeItemData(
        icon: Icons.psychology,
        label: 'Genius',
        unlocked: unlockedBadges.contains('genius'),
        description: 'Get 50 correct answers ($correctAnswers/50)',
      ),
      BadgeItemData(
        icon: Icons.auto_awesome,
        label: 'Legendary',
        unlocked: unlockedBadges.contains('legendary'),
        description: 'Reach 1000 XP ($totalPoints/1000)',
      ),
    ];
  }

  Widget _buildBadgeItem(BadgeItemData badge) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: badge.unlocked
                ? LinearGradient(
                    colors: [kBrand, kBrand.withValues(alpha: 0.7)],
                  )
                : null,
            color: badge.unlocked ? null : Colors.grey[300],
          ),
          child: Icon(
            badge.icon,
            size: 20,
            color: badge.unlocked ? Colors.white : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          badge.label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: badge.unlocked ? Colors.black87 : Colors.grey[500],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (!badge.unlocked)
          Icon(Icons.lock, size: 8, color: Colors.grey[400]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final badges = _getBadgeDefinitions();
    final unlockedCount = badges.where((b) => b.unlocked).length;
    final crossAxisCount = MediaQuery.of(context).size.width < 1100 ? 4 : 6;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Text(
                'Achievement Badges',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kBrand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$unlockedCount / ${badges.length}',
                  style: const TextStyle(
                    color: kBrand,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Tooltip(
                message: badge.description,
                child: _buildBadgeItem(badge),
              );
            },
          ),
        ],
      ),
    );
  }
}
