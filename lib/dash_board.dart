// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'constants.dart';

/// Comprehensive Dashboard with Gamification & Analytics
class DashboardScreen extends StatelessWidget {
  final int filesUploaded;
  final int aiChatInteractions;
  final int questionsAnswered;
  final int correctAnswers;
  final int loginDays;
  final int totalPoints;
  final int weeklyUploads;
  final int monthlyUploads;
  final Map<String, int> fileTypeStats;
  final Map<String, int> dailyActivity;
  final List<String> unlockedBadges;
  final List<String> recentAchievements;

  const DashboardScreen({
    super.key,
    this.filesUploaded = 0,
    this.aiChatInteractions = 0,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.loginDays = 0,
    this.totalPoints = 0,
    this.weeklyUploads = 0,
    this.monthlyUploads = 0,
    this.fileTypeStats = const {},
    this.dailyActivity = const {},
    this.unlockedBadges = const [],
    this.recentAchievements = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildUserLevelCard(),
            const SizedBox(height: 24),
            _buildMainMetrics(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildBadgeSystem(),
                      const SizedBox(height: 24),
                      _buildActivityGraph(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildStreakCard(),
                      const SizedBox(height: 24),
                      _buildLeaderboard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRecentAchievements(),
            const SizedBox(height: 24),
            _buildDailyQuote(),
            const SizedBox(height: 32),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
          onPressed: () {
            // Navigate back to main pane - this will close the dashboard
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your learning journey at a glance',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kBrand, kBrand.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '$totalPoints XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserLevelCard() {
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
                    valueColor: AlwaysStoppedAnimation<Color>(kBrand),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Files Uploaded',
            filesUploaded.toString(),
            Icons.cloud_upload,
            Colors.blue,
            '+${weeklyUploads} this week',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Questions Answered',
            questionsAnswered.toString(),
            Icons.quiz,
            Colors.green,
            '${correctAnswers > 0 ? ((correctAnswers / questionsAnswered) * 100).toInt() : 0}% accuracy',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'AI Interactions',
            aiChatInteractions.toString(),
            Icons.smart_toy,
            Colors.purple,
            'Explore more!',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Login Streak',
            '$loginDays days',
            Icons.local_fire_department,
            Colors.orange,
            'Keep it up!',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
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

  Widget _buildBadgeSystem() {
    final badges = _getBadgeDefinitions();
    final unlockedCount = badges.where((b) => b['unlocked'] as bool).length;

    return Container(
      padding: const EdgeInsets.all(24),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kBrand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unlockedCount/${badges.length}',
                  style: TextStyle(color: kBrand, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _buildBadgeTile(
                badge['icon'] as IconData,
                badge['label'] as String,
                badge['unlocked'] as bool,
                badge['description'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeTile(
    IconData icon,
    String label,
    bool unlocked,
    String description,
  ) {
    return Tooltip(
      message: description,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  unlocked
                      ? LinearGradient(
                        colors: [kBrand, kBrand.withValues(alpha: 0.7)],
                      )
                      : null,
              color: unlocked ? null : Colors.grey[300],
            ),
            child: Icon(
              icon,
              size: 30,
              color: unlocked ? Colors.white : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: unlocked ? Colors.black87 : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!unlocked) Icon(Icons.lock, size: 12, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildActivityGraph() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Activity Heatmap',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child:
                dailyActivity.isEmpty
                    ? Center(
                      child: Text(
                        'Start uploading files to see your activity!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: dailyActivity.length,
                      itemBuilder: (context, index) {
                        final entry = dailyActivity.entries.elementAt(index);
                        final intensity = (entry.value / 5).clamp(0.1, 1.0);

                        return Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: kBrand.withValues(alpha: intensity),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      entry.value.toString(),
                                      style: TextStyle(
                                        color:
                                            intensity > 0.5
                                                ? Colors.white
                                                : kBrand,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.key.substring(5, 10),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
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

  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Leaderboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildLeaderTile('You', totalPoints, 1, true),
          _buildLeaderTile('Emma', 1450, 2, false),
          _buildLeaderTile('Noah', 1380, 3, false),
          _buildLeaderTile('Sophia', 1250, 4, false),
        ],
      ),
    );
  }

  Widget _buildLeaderTile(String name, int points, int rank, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser ? kBrand.withValues(alpha: 0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border:
            isUser ? Border.all(color: kBrand.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  rank == 1
                      ? Colors.amber
                      : rank == 2
                      ? Colors.grey[400]
                      : Colors.orange[300],
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isUser ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$points XP',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isUser ? kBrand : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionButton('Upload Files', Icons.cloud_upload, kBrand, () {}),
          const SizedBox(height: 12),
          _buildActionButton('Generate Quiz', Icons.quiz, Colors.green, () {}),
          const SizedBox(height: 12),
          _buildActionButton(
            'AI Assistant',
            Icons.smart_toy,
            Colors.purple,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAchievements() {
    if (recentAchievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
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
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No achievements yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start using the app to unlock achievements!',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.new_releases, color: kBrand),
              const SizedBox(width: 8),
              const Text(
                'Recent Achievements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                recentAchievements.map((achievement) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kBrand.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      achievement,
                      style: TextStyle(
                        color: kBrand,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getBadgeDefinitions() {
    return [
      {
        'icon': Icons.upload_file,
        'label': 'First Upload',
        'unlocked': unlockedBadges.contains('first_file') || filesUploaded >= 1,
        'description': 'Upload your first file ($filesUploaded/1)',
      },
      {
        'icon': Icons.folder,
        'label': 'File Master',
        'unlocked':
            unlockedBadges.contains('file_master') || filesUploaded >= 10,
        'description': 'Upload 10 files ($filesUploaded/10)',
      },
      {
        'icon': Icons.workspace_premium,
        'label': 'File Expert',
        'unlocked':
            unlockedBadges.contains('file_expert') || filesUploaded >= 50,
        'description': 'Upload 50 files ($filesUploaded/50)',
      },
      {
        'icon': Icons.emoji_events,
        'label': 'Week Warrior',
        'unlocked': unlockedBadges.contains('week_warrior') || loginDays >= 7,
        'description': 'Login for 7 consecutive days ($loginDays/7)',
      },
      {
        'icon': Icons.stars,
        'label': 'Month Master',
        'unlocked': unlockedBadges.contains('month_master') || loginDays >= 30,
        'description': 'Login for 30 consecutive days ($loginDays/30)',
      },
      {
        'icon': Icons.smart_toy,
        'label': 'AI Explorer',
        'unlocked':
            unlockedBadges.contains('ai_explorer') || aiChatInteractions >= 5,
        'description': 'Use AI chat 5 times ($aiChatInteractions/5)',
      },
      {
        'icon': Icons.quiz,
        'label': 'Quiz Master',
        'unlocked':
            unlockedBadges.contains('quiz_master') || correctAnswers >= 20,
        'description': 'Answer 20 questions correctly ($correctAnswers/20)',
      },
      {
        'icon': Icons.military_tech,
        'label': 'Century Club',
        'unlocked':
            unlockedBadges.contains('century_club') || totalPoints >= 100,
        'description': 'Earn 100 XP ($totalPoints/100)',
      },
      {
        'icon': Icons.diamond,
        'label': 'Point Prodigy',
        'unlocked':
            unlockedBadges.contains('point_prodigy') || totalPoints >= 500,
        'description': 'Earn 500 XP ($totalPoints/500)',
      },
      {
        'icon': Icons.school,
        'label': 'Scholar',
        'unlocked':
            unlockedBadges.contains('scholar') || questionsAnswered >= 100,
        'description': 'Answer 100 questions ($questionsAnswered/100)',
      },
      {
        'icon': Icons.psychology,
        'label': 'Genius',
        'unlocked': unlockedBadges.contains('genius') || correctAnswers >= 50,
        'description': 'Get 50 correct answers ($correctAnswers/50)',
      },
      {
        'icon': Icons.auto_awesome,
        'label': 'Legendary',
        'unlocked': unlockedBadges.contains('legendary') || totalPoints >= 1000,
        'description': 'Reach 1000 XP ($totalPoints/1000)',
      },
    ];
  }

  Widget _buildDailyQuote() {
    // Generate daily quote based on current date
    final quotes = _getDailyQuotes();
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final selectedQuote = quotes[dayOfYear % quotes.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBrand, kBrand.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBrand.withValues(alpha: 0.3),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Daily Inspiration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '"${selectedQuote['quote']}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '— ${selectedQuote['author']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Quick Links Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFooterLink('Privacy Policy', Icons.security, () {
                _showInfoDialog(
                  context,
                  'Privacy Policy',
                  'Your privacy is important to us. FileGenius collects minimal data necessary for app functionality. We never share your personal information with third parties. All uploaded files are stored securely in your personal Firebase storage.',
                );
              }),
              _buildFooterLink('Terms & Conditions', Icons.description, () {
                _showInfoDialog(
                  context,
                  'Terms & Conditions',
                  'By using FileGenius, you agree to our terms. The app is provided "as is" for educational purposes. Users are responsible for their own content. We reserve the right to update these terms as needed.',
                );
              }),
              _buildFooterLink('FAQ', Icons.help_outline, () {
                _showFAQDialog(context);
              }),
              _buildFooterLink('Contact Us', Icons.email, () {
                _showInfoDialog(
                  context,
                  'Contact Us',
                  'Need help? Reach out to us:\n\nEmail: support@filegenius.com\nPhone: +1 (555) 123-4567\nHours: Mon-Fri 9AM-5PM EST\n\nWe\'re here to help you succeed!',
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),
          // Copyright Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2025 FileGenius. All rights reserved.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Row(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 4),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBrand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: kBrand, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBrand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: kBrand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(content, style: const TextStyle(height: 1.5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: kBrand)),
            ),
          ],
        );
      },
    );
  }

  void _showFAQDialog(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I upload files?',
        'answer':
            'Click the "Upload Files" button or drag and drop files directly onto the upload area. Supported formats: PDF, PPTX, DOCX.',
      },
      {
        'question': 'How does the AI chat work?',
        'answer':
            'Our AI assistant can help you understand your documents, generate questions, and provide explanations about your content.',
      },
      {
        'question': 'How are points calculated?',
        'answer':
            'Earn points by: uploading files (10 XP), AI interactions (5 XP), correct answers (15 XP), attempts (2 XP), and daily logins (5 XP).',
      },
      {
        'question': 'Can I delete my data?',
        'answer':
            'Yes! You can delete individual files or clear all data from the sidebar menu. This action cannot be undone.',
      },
      {
        'question': 'Is my data secure?',
        'answer':
            'Absolutely! All files are stored in your personal Firebase storage with enterprise-grade security. We never access your content.',
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kBrand.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, color: kBrand, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: faqs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      return ExpansionTile(
                        title: Text(
                          faq['question']!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              faq['answer']!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, String>> _getDailyQuotes() {
    return [
      {
        'quote': 'The only way to do great work is to love what you do.',
        'author': 'Steve Jobs',
      },
      {
        'quote': 'Learning never exhausts the mind.',
        'author': 'Leonardo da Vinci',
      },
      {
        'quote':
            'Education is the most powerful weapon which you can use to change the world.',
        'author': 'Nelson Mandela',
      },
      {
        'quote':
            'The beautiful thing about learning is that no one can take it away from you.',
        'author': 'B.B. King',
      },
      {
        'quote':
            'Success is not final, failure is not fatal: it is the courage to continue that counts.',
        'author': 'Winston Churchill',
      },
      {
        'quote':
            'The future belongs to those who believe in the beauty of their dreams.',
        'author': 'Eleanor Roosevelt',
      },
      {
        'quote':
            'It does not matter how slowly you go as long as you do not stop.',
        'author': 'Confucius',
      },
      {
        'quote': 'The expert in anything was once a beginner.',
        'author': 'Helen Hayes',
      },
      {
        'quote': 'Don\'t let yesterday take up too much of today.',
        'author': 'Will Rogers',
      },
      {
        'quote': 'You learn something every day if you pay attention.',
        'author': 'Ray LeBlond',
      },
      {
        'quote':
            'The capacity to learn is a gift; the ability to learn is a skill; the willingness to learn is a choice.',
        'author': 'Brian Herbert',
      },
      {
        'quote':
            'Study hard what interests you the most in the most undisciplined, irreverent and original manner possible.',
        'author': 'Richard Feynman',
      },
      {
        'quote': 'The roots of education are bitter, but the fruit is sweet.',
        'author': 'Aristotle',
      },
      {
        'quote':
            'Learning is a treasure that will follow its owner everywhere.',
        'author': 'Chinese Proverb',
      },
      {
        'quote':
            'The more that you read, the more things you will know. The more that you learn, the more places you\'ll go.',
        'author': 'Dr. Seuss',
      },
      {
        'quote':
            'Intelligence plus character—that is the goal of true education.',
        'author': 'Martin Luther King Jr.',
      },
      {
        'quote':
            'Tell me and I forget, teach me and I may remember, involve me and I learn.',
        'author': 'Benjamin Franklin',
      },
      {
        'quote':
            'The best time to plant a tree was 20 years ago. The second best time is now.',
        'author': 'Chinese Proverb',
      },
      {
        'quote': 'What we learn with pleasure we never forget.',
        'author': 'Alfred Mercier',
      },
      {
        'quote':
            'Learning is not attained by chance, it must be sought for with ardor and attended to with diligence.',
        'author': 'Abigail Adams',
      },
      {
        'quote': 'The journey of a thousand miles begins with one step.',
        'author': 'Lao Tzu',
      },
      {
        'quote':
            'Knowledge is power. Information is liberating. Education is the premise of progress.',
        'author': 'Kofi Annan',
      },
      {
        'quote':
            'The mind is not a vessel to be filled, but a fire to be kindled.',
        'author': 'Plutarch',
      },
      {
        'quote': 'In learning you will teach, and in teaching you will learn.',
        'author': 'Phil Collins',
      },
      {
        'quote':
            'Education is not preparation for life; education is life itself.',
        'author': 'John Dewey',
      },
      {
        'quote': 'The best investment you can make is in yourself.',
        'author': 'Warren Buffett',
      },
      {
        'quote':
            'Continuous learning is the minimum requirement for success in any field.',
        'author': 'Brian Tracy',
      },
      {
        'quote': 'The more you know, the more you realize you don\'t know.',
        'author': 'Aristotle',
      },
      {
        'quote': 'Success is where preparation and opportunity meet.',
        'author': 'Bobby Unser',
      },
      {
        'quote': 'Every accomplishment starts with the decision to try.',
        'author': 'John F. Kennedy',
      },
    ];
  }
}
