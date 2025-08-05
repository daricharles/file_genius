// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'constants.dart';
import 'screens/chat_sessions_screen.dart';

/// Comprehensive Dashboard with Gamification & Analytics
class DashboardScreen extends StatefulWidget {
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
  final String userName;

  // New Analytics Properties
  final Map<String, double> studyTimeBySubject;
  final List<Map<String, dynamic>> performanceHistory;
  final Map<String, int> weeklyPerformance;
  final List<String> weakAreas;
  final List<Map<String, dynamic>> aiRecommendations;
  final double totalStudyTime;
  final double averageAccuracy;
  final String preferredStudyTime;

  final VoidCallback? onBackPressed;
  final VoidCallback? onUploadFiles;
  final VoidCallback? onGenerateQuiz;
  final VoidCallback? onAIInteraction;

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
    this.userName = 'User',

    // Analytics Properties
    this.studyTimeBySubject = const {},
    this.performanceHistory = const [],
    this.weeklyPerformance = const {},
    this.weakAreas = const [],
    this.aiRecommendations = const [],
    this.totalStudyTime = 0.0,
    this.averageAccuracy = 0.0,
    this.preferredStudyTime = 'Morning',

    this.onBackPressed,
    this.onUploadFiles,
    this.onGenerateQuiz,
    this.onAIInteraction,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
            // Enhanced Analytics Section
            _buildAnalyticsSection(),
            const SizedBox(height: 24),
            // AI Recommendations Section
            _buildRecommendationsSection(),
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

  Future<List<Map<String, dynamic>>> _fetchLeaderboardData() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return [];

      // For now, we'll create a simple leaderboard with just the current user
      // In a production app, you'd need a separate leaderboard collection
      // that all users can read but only cloud functions can write to

      // Get current user's actual points from the widget
      final currentUserPoints = widget.totalPoints;

      // Get the current user's display name
      String displayName = 'You';
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .get();
        if (userDoc.exists) {
          displayName = userDoc.data()?['displayName'] ?? 'You';
        }
      } catch (e) {
        debugPrint('Error getting user display name: $e');
      }

      List<Map<String, dynamic>> leaderboardData = [
        {
          'userId': currentUserId,
          'displayName': displayName,
          'points': currentUserPoints,
          'isCurrentUser': true,
        },
      ];

      // Add some placeholder competitors to motivate user learning
      // Create engaging competitors that can have higher points to encourage usage
      List<Map<String, String>> competitors = [
        {'name': 'Alex', 'adjective': 'Studious'},
        {'name': 'Taylor', 'adjective': 'Dedicated'},
        {'name': 'Jordan', 'adjective': 'Focused'},
        {'name': 'Casey', 'adjective': 'Persistent'},
      ];

      // Base points calculation to ensure positive values and motivation
      int baseMultiplier = currentUserPoints > 0 ? currentUserPoints : 50;

      for (int i = 0; i < competitors.length && i < 3; i++) {
        // Varied point distribution - some higher, some lower than user
        int competitorPoints;
        if (i == 0) {
          // First competitor often has more points (motivation)
          competitorPoints = (baseMultiplier * 1.3).round() + (25 + (i * 10));
        } else if (i == 1) {
          // Second competitor close to user points
          competitorPoints = (baseMultiplier * 0.9).round() + (15 + (i * 8));
        } else {
          // Third competitor slightly below
          competitorPoints = (baseMultiplier * 0.7).round() + (10 + (i * 5));
        }

        // Ensure minimum positive points
        competitorPoints =
            competitorPoints < 20 ? 20 + (i * 15) : competitorPoints;

        leaderboardData.add({
          'userId': 'competitor_$i',
          'displayName': competitors[i]['name']!,
          'points': competitorPoints,
          'isCurrentUser': false,
        });
      }

      // Sort by points descending
      leaderboardData.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );

      return leaderboardData;
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  Widget _buildHeader(BuildContext context) {
    // Get current date and day
    final now = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final currentDay = dayNames[now.weekday - 1];
    final currentDate =
        '${_getOrdinalSuffix(now.day)} ${monthNames[now.month - 1]} ${now.year}';

    return Column(
      children: [
        // Dashboard title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Dashboard title
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                    size: 28,
                  ),
                  onPressed: () {
                    widget.onBackPressed?.call();
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Welcome message, date and XP row
        Row(
          children: [
            const SizedBox(width: 56), // Space for alignment with back button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome! ${widget.userName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
            // Date and day info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentDay,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  currentDate,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 16),
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
                    '${widget.totalPoints} XP',
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
        ),
      ],
    );
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  Widget _buildUserLevelCard() {
    final currentLevel = (widget.totalPoints / 100).floor() + 1;
    final nextLevelPoints = currentLevel * 100;
    final progressToNext = (widget.totalPoints % 100) / 100;

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
                  '${nextLevelPoints - widget.totalPoints} XP to Level ${currentLevel + 1}',
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
            widget.filesUploaded.toString(),
            Icons.cloud_upload,
            Colors.blue,
            '+${widget.weeklyUploads} this week',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Questions Answered',
            widget.questionsAnswered.toString(),
            Icons.quiz,
            Colors.green,
            '${widget.correctAnswers > 0 ? ((widget.correctAnswers / widget.questionsAnswered) * 100).toInt() : 0}% accuracy',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'AI Interactions',
            widget.aiChatInteractions.toString(),
            Icons.smart_toy,
            Colors.purple,
            'Explore more!',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Login Streak',
            '${widget.loginDays} days',
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
          const SizedBox(height: 16), // Reduced from 20
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6, // Increased from 4 to 6
              crossAxisSpacing: 12, // Reduced from 16
              mainAxisSpacing: 12, // Reduced from 16
              childAspectRatio: 0.9, // Increased from 0.8 for more compact look
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
            width: 50, // Reduced from 60
            height: 50, // Reduced from 60
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
              size: 24, // Reduced from 30
              color: unlocked ? Colors.white : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6), // Reduced from 8
          Text(
            label,
            style: TextStyle(
              fontSize: 10, // Reduced from 11
              fontWeight: FontWeight.w600,
              color: unlocked ? Colors.black87 : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!unlocked)
            Icon(
              Icons.lock,
              size: 10,
              color: Colors.grey[400],
            ), // Reduced from 12
        ],
      ),
    );
  }

  Widget _buildActivityGraph() {
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
          const Text(
            'Activity Heatmap',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child:
                widget.dailyActivity.isEmpty
                    ? Center(
                      child: Text(
                        'Start uploading files to see your activity!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.dailyActivity.length,
                      itemBuilder: (context, index) {
                        final entry = widget.dailyActivity.entries.elementAt(
                          index,
                        );
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
            '${widget.loginDays} Day Streak',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.loginDays >= 7 ? 'Amazing consistency!' : 'Keep going!',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (widget.loginDays % 7) / 7,
            backgroundColor: Colors.orange.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            'Next milestone: ${7 - (widget.loginDays % 7)} days',
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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchLeaderboardData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unable to load leaderboard',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              final leaderboardData = snapshot.data ?? [];

              if (leaderboardData.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first on the leaderboard!',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start earning points to see your ranking',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children:
                    leaderboardData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final userData = entry.value;
                      final isCurrentUser = userData['isCurrentUser'] ?? false;

                      return _buildLeaderTile(
                        userData['displayName'] ?? 'User ${index + 1}',
                        userData['points'] ?? 0,
                        index + 1,
                        isCurrentUser,
                      );
                    }).toList(),
              );
            },
          ),
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
            flex: 3,
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isUser ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$points XP',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isUser ? kBrand : Colors.grey[700],
                fontSize: 11,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
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
          _buildActionButton('Upload Files', Icons.cloud_upload, kBrand, () {
            widget.onUploadFiles?.call();
          }),
          const SizedBox(height: 12),
          _buildActionButton(
            'Chat Sessions',
            Icons.chat_bubble,
            Colors.blue,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatSessionsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton('Generate Quiz', Icons.quiz, Colors.green, () {
            widget.onGenerateQuiz?.call();
          }),
          const SizedBox(height: 12),
          _buildActionButton(
            'AI Assistant',
            Icons.smart_toy,
            Colors.purple,
            () {
              widget.onAIInteraction?.call();
            },
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
    if (widget.recentAchievements.isEmpty) {
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
                widget.recentAchievements.map((achievement) {
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

  // ===== ENHANCED ANALYTICS SECTION =====
  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Learning Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Analytics Cards Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Study Time Analytics
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildStudyTimeChart(),
                  const SizedBox(height: 24),
                  _buildPerformanceMetrics(),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Learning Patterns & Insights
            Expanded(
              child: Column(
                children: [
                  _buildLearningPatterns(),
                  const SizedBox(height: 24),
                  _buildWeakAreasCard(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudyTimeChart() {
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
              const Icon(Icons.schedule, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Study Time by Subject',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.totalStudyTime.toStringAsFixed(1)}h total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Bar Chart for Study Time
          if (widget.studyTimeBySubject.isNotEmpty)
            SizedBox(height: 200, child: _buildCustomBarChart())
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No study time recorded yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start studying to see your time distribution',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomBarChart() {
    final maxValue = widget.studyTimeBySubject.values.reduce(math.max);
    final subjects = widget.studyTimeBySubject.keys.toList();

    return Column(
      children:
          subjects.map((subject) {
            final value = widget.studyTimeBySubject[subject]!;
            final percentage = maxValue > 0 ? value / maxValue : 0.0;
            final color = _getSubjectColor(subject);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${value.toStringAsFixed(1)}h',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Color _getSubjectColor(String subject) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[subject.hashCode % colors.length];
  }

  Widget _buildPerformanceMetrics() {
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
              const Icon(Icons.trending_up, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Performance Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Average Accuracy',
                  '${widget.averageAccuracy.toStringAsFixed(1)}%',
                  Icons.gps_fixed,
                  Colors.green,
                  widget.averageAccuracy >= 80
                      ? 'Excellent!'
                      : widget.averageAccuracy >= 60
                      ? 'Good'
                      : 'Needs improvement',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  'Study Streak',
                  '$widget.loginDays days',
                  Icons.local_fire_department,
                  Colors.orange,
                  widget.loginDays >= 7 ? 'Amazing!' : 'Keep going!',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Weekly Performance Trend
          if (widget.weeklyPerformance.isNotEmpty) ...[
            const Text(
              'Weekly Performance',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    widget.weeklyPerformance.entries.map((entry) {
                      final day = entry.key;
                      final score = entry.value;
                      final height = (score / 100) * 50; // Max height 50

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 20,
                            height: height,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.substring(0, 1),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPatterns() {
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
              const Icon(Icons.psychology, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Learning Patterns',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildPatternItem(
            'Best Study Time',
            widget.preferredStudyTime,
            Icons.schedule,
            Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildPatternItem(
            'Most Active Subject',
            widget.studyTimeBySubject.isNotEmpty
                ? widget.studyTimeBySubject.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key
                : 'No data yet',
            Icons.book,
            Colors.green,
          ),
          const SizedBox(height: 16),

          _buildPatternItem(
            'Study Sessions',
            '${widget.studyTimeBySubject.length} subjects tracked',
            Icons.timeline,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeakAreasCard() {
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
              const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Areas for Improvement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (widget.weakAreas.isNotEmpty)
            ...widget.weakAreas
                .take(3)
                .map(
                  (area) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_down,
                            color: Colors.amber[700],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              area,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Great job! No weak areas detected.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===== AI-POWERED RECOMMENDATIONS SECTION =====
  Widget _buildRecommendationsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI-Powered Recommendations',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _generateAIRecommendations(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recommendations Grid
          if (widget.aiRecommendations.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: math.min(widget.aiRecommendations.length, 4),
              itemBuilder: (context, index) {
                final recommendation = widget.aiRecommendations[index];
                return _buildRecommendationCard(recommendation);
              },
            )
          else
            _buildEmptyRecommendations(),

          const SizedBox(height: 20),

          // Export Options
          _buildExportOptions(),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final type = recommendation['type'] as String;
    final title = recommendation['title'] as String;
    final description = recommendation['description'] as String;
    final priority = recommendation['priority'] as String;

    final color = _getRecommendationColor(type);
    final icon = _getRecommendationIcon(type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(priority),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRecommendationColor(String type) {
    switch (type) {
      case 'study_schedule':
        return Colors.blue;
      case 'weak_area':
        return Colors.orange;
      case 'content':
        return Colors.green;
      case 'review':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRecommendationIcon(String type) {
    switch (type) {
      case 'study_schedule':
        return Icons.schedule;
      case 'weak_area':
        return Icons.trending_up;
      case 'content':
        return Icons.library_books;
      case 'review':
        return Icons.refresh;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyRecommendations() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: Colors.purple[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Recommendations Loading...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI is analyzing your learning patterns to provide personalized recommendations.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _generateAIRecommendations(),
            icon: const Icon(Icons.smart_toy, size: 16),
            label: const Text('Generate Recommendations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export & Share Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  'PDF Report',
                  Icons.picture_as_pdf,
                  Colors.red,
                  () => _exportToPDF(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(
                  'CSV Data',
                  Icons.table_chart,
                  Colors.green,
                  () => _exportToCSV(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(
                  'Share Achievement',
                  Icons.share,
                  Colors.blue,
                  () => _shareAchievement(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===== AI RECOMMENDATION METHODS =====
  void _generateAIRecommendations() {
    // Simulate AI recommendation generation
    // In a real app, this would call an AI service
    debugPrint('Generating AI recommendations...');

    // In a stateful widget, you would call setState here
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI recommendations updated!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _exportToPDF() {
    // Generate PDF report
    debugPrint('Exporting to PDF...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF report generation started. Check downloads folder.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _exportToCSV() {
    // Export data to CSV
    debugPrint('Exporting to CSV...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV data exported successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareAchievement() {
    // Share achievement on social media
    debugPrint('Sharing achievement...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Achievement shared! 🎉'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  List<Map<String, dynamic>> _getBadgeDefinitions() {
    return [
      {
        'icon': Icons.upload_file,
        'label': 'First Upload',
        'unlocked':
            widget.unlockedBadges.contains('first_file') ||
            widget.filesUploaded >= 1,
        'description': 'Upload your first file ($widget.filesUploaded/1)',
      },
      {
        'icon': Icons.folder,
        'label': 'File Master',
        'unlocked':
            widget.unlockedBadges.contains('file_master') ||
            widget.filesUploaded >= 10,
        'description': 'Upload 10 files ($widget.filesUploaded/10)',
      },
      {
        'icon': Icons.workspace_premium,
        'label': 'File Expert',
        'unlocked':
            widget.unlockedBadges.contains('file_expert') ||
            widget.filesUploaded >= 50,
        'description': 'Upload 50 files ($widget.filesUploaded/50)',
      },
      {
        'icon': Icons.emoji_events,
        'label': 'Week Warrior',
        'unlocked':
            widget.unlockedBadges.contains('week_warrior') ||
            widget.loginDays >= 7,
        'description': 'Login for 7 consecutive days ($widget.loginDays/7)',
      },
      {
        'icon': Icons.stars,
        'label': 'Month Master',
        'unlocked':
            widget.unlockedBadges.contains('month_master') ||
            widget.loginDays >= 30,
        'description': 'Login for 30 consecutive days ($widget.loginDays/30)',
      },
      {
        'icon': Icons.smart_toy,
        'label': 'AI Explorer',
        'unlocked':
            widget.unlockedBadges.contains('ai_explorer') ||
            widget.aiChatInteractions >= 5,
        'description': 'Use AI chat 5 times ($widget.aiChatInteractions/5)',
      },
      {
        'icon': Icons.quiz,
        'label': 'Quiz Master',
        'unlocked':
            widget.unlockedBadges.contains('quiz_master') ||
            widget.correctAnswers >= 20,
        'description':
            'Answer 20 questions correctly ($widget.correctAnswers/20)',
      },
      {
        'icon': Icons.military_tech,
        'label': 'Century Club',
        'unlocked':
            widget.unlockedBadges.contains('century_club') ||
            widget.totalPoints >= 100,
        'description': 'Earn 100 XP ($widget.totalPoints/100)',
      },
      {
        'icon': Icons.diamond,
        'label': 'Point Prodigy',
        'unlocked':
            widget.unlockedBadges.contains('point_prodigy') ||
            widget.totalPoints >= 500,
        'description': 'Earn 500 XP ($widget.totalPoints/500)',
      },
      {
        'icon': Icons.school,
        'label': 'Scholar',
        'unlocked':
            widget.unlockedBadges.contains('scholar') ||
            widget.questionsAnswered >= 100,
        'description': 'Answer 100 questions ($widget.questionsAnswered/100)',
      },
      {
        'icon': Icons.psychology,
        'label': 'Genius',
        'unlocked':
            widget.unlockedBadges.contains('genius') ||
            widget.correctAnswers >= 50,
        'description': 'Get 50 correct answers ($widget.correctAnswers/50)',
      },
      {
        'icon': Icons.auto_awesome,
        'label': 'Legendary',
        'unlocked':
            widget.unlockedBadges.contains('legendary') ||
            widget.totalPoints >= 1000,
        'description': 'Reach 1000 XP ($widget.totalPoints/1000)',
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
