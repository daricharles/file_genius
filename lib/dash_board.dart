// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
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
  void dispose() {
    // Cancel any timers, subscriptions, etc.
    // Example:
    // _timer?.cancel();
    // _subscription?.cancel();
    super.dispose();
  }

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
            // AI Recommendations Section removed
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
                    'Welcome, ${widget.userName}!',
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
                  colors: [kBrand, kBrand.withOpacity(0.8)],
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
          colors: [kBrand.withOpacity(0.1), kBrand.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBrand.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kBrand, kBrand.withOpacity(0.7)],
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
            color: Colors.black.withOpacity(0.05),
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
                  color: color.withOpacity(0.1),
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
    final unlockedCount =
        badges.where((badge) => badge['unlocked'] as bool).length;

    return Container(
      padding: const EdgeInsets.all(20), // Reduced from 24
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ), // Reduced from 20
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, // Reduced from 12
                  vertical: 4, // Reduced from 6
                ),
                decoration: BoxDecoration(
                  color: kBrand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16), // Reduced from 20
                ),
                child: Text(
                  '$unlockedCount / ${badges.length}',
                  style: TextStyle(
                    color: kBrand,
                    fontWeight: FontWeight.w600,
                    fontSize: 12, // Added smaller font size
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 16
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  6, // Increased from 4 to fit more badges in less height
              crossAxisSpacing: 8, // Reduced from 12
              mainAxisSpacing: 8, // Reduced from 12
              childAspectRatio: 0.9, // Slightly increased from 0.8
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Tooltip(
                message: badge['description'],
                child: _buildBadgeItem(
                  badge['icon'] as IconData,
                  badge['label'] as String,
                  badge['unlocked'] as bool,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(IconData icon, String label, bool unlocked) {
    return Column(
      children: [
        Container(
          width: 40, // Reduced from 50
          height: 40, // Reduced from 50
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
            size: 20, // Reduced from 24
            color: unlocked ? Colors.white : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4), // Reduced from 6
        Text(
          label,
          style: TextStyle(
            fontSize: 9, // Reduced from 10
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
            size: 8, // Reduced from 10
            color: Colors.grey[400],
          ),
      ],
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
            color: Colors.black.withOpacity(0.05),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start uploading files to see your activity!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.dailyActivity.length,
                      itemBuilder: (context, index) {
                        final entry = widget.dailyActivity.entries.elementAt(
                          index,
                        );
                        final date = entry.key;
                        final activity = entry.value;
                        final maxActivity =
                            widget.dailyActivity.values.isNotEmpty
                                ? widget.dailyActivity.values.reduce(
                                  (a, b) => a > b ? a : b,
                                )
                                : 1;
                        final intensity = (activity / maxActivity).clamp(
                          0.1,
                          1.0,
                        );

                        return Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kBrand.withOpacity(intensity),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      activity.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            intensity > 0.5
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(date, style: const TextStyle(fontSize: 10)),
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
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
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
            backgroundColor: Colors.orange.withOpacity(0.2),
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

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
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
              color: Colors.black.withOpacity(0.05),
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
          colors: [kBrand.withOpacity(0.1), kBrand.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBrand.withOpacity(0.2)),
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
              const Spacer(),
              Text(
                '${widget.recentAchievements.length} new',
                style: TextStyle(color: kBrand, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.recentAchievements.take(10).map((achievement) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kBrand.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 16, color: kBrand),
                        const SizedBox(width: 4),
                        Text(
                          achievement,
                          style: TextStyle(
                            color: kBrand,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Study time breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Study time chart
              Expanded(flex: 2, child: _buildStudyTimeChart()),
              const SizedBox(width: 24),
              // Right: Weekly performance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCustomBarChart(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],
      ),
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
            color: Colors.black.withOpacity(0.05),
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
                  color: Colors.blue.withOpacity(0.1),
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
    // Check if studyTimeBySubject is empty or has no values
    if (widget.studyTimeBySubject.isEmpty ||
        widget.studyTimeBySubject.values.isEmpty) {
      return Container(
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
      );
    }

    // Safe reduce with null check
    final values =
        widget.studyTimeBySubject.values.where((v) => v > 0).toList();
    if (values.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No study time data available',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
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


  List<Map<String, dynamic>> _getBadgeDefinitions() {
    return [
      {
        'icon': Icons.upload_file,
        'label': 'First Upload',
        'unlocked':
            widget.unlockedBadges.contains('first_file') ||
            widget.filesUploaded >= 1,
        'description': 'Upload your first file (${widget.filesUploaded}/1)',
      },
      {
        'icon': Icons.folder,
        'label': 'File Master',
        'unlocked':
            widget.unlockedBadges.contains('file_master') ||
            widget.filesUploaded >= 10,
        'description': 'Upload 10 files (${widget.filesUploaded}/10)',
      },
      {
        'icon': Icons.workspace_premium,
        'label': 'File Expert',
        'unlocked':
            widget.unlockedBadges.contains('file_expert') ||
            widget.filesUploaded >= 50,
        'description': 'Upload 50 files (${widget.filesUploaded}/50)',
      },
      {
        'icon': Icons.emoji_events,
        'label': 'Week Warrior',
        'unlocked':
            widget.unlockedBadges.contains('week_warrior') ||
            widget.loginDays >= 7,
        'description':
            'Login for 7 consecutive days (${widget.filesUploaded}/7)',
      },
      {
        'icon': Icons.stars,
        'label': 'Month Master',
        'unlocked':
            widget.unlockedBadges.contains('month_master') ||
            widget.loginDays >= 30,
        'description':
            'Login for 30 consecutive days (${widget.filesUploaded}/30)',
      },
      {
        'icon': Icons.smart_toy,
        'label': 'AI Explorer',
        'unlocked':
            widget.unlockedBadges.contains('ai_explorer') ||
            widget.aiChatInteractions >= 5,
        'description': 'Use AI chat 5 times (${widget.aiChatInteractions}/5)',
      },
      {
        'icon': Icons.quiz,
        'label': 'Quiz Master',
        'unlocked':
            widget.unlockedBadges.contains('quiz_master') ||
            widget.correctAnswers >= 20,
        'description':
            'Answer 20 questions correctly (${widget.correctAnswers}/20)',
      },
      {
        'icon': Icons.military_tech,
        'label': 'Century Club',
        'unlocked':
            widget.unlockedBadges.contains('century_club') ||
            widget.totalPoints >= 100,
        'description': 'Earn 100 XP (${widget.totalPoints}/100)',
      },
      {
        'icon': Icons.diamond,
        'label': 'Point Prodigy',
        'unlocked':
            widget.unlockedBadges.contains('point_prodigy') ||
            widget.totalPoints >= 500,
        'description': 'Earn 500 XP (${widget.totalPoints}/500)',
      },
      {
        'icon': Icons.school,
        'label': 'Scholar',
        'unlocked':
            widget.unlockedBadges.contains('scholar') ||
            widget.questionsAnswered >= 100,
        'description': 'Answer 100 questions (${widget.questionsAnswered}/100)',
      },
      {
        'icon': Icons.psychology,
        'label': 'Genius',
        'unlocked':
            widget.unlockedBadges.contains('genius') ||
            widget.correctAnswers >= 50,
        'description': 'Get 50 correct answers (${widget.correctAnswers}/50)',
      },
      {
        'icon': Icons.auto_awesome,
        'label': 'Legendary',
        'unlocked':
            widget.unlockedBadges.contains('legendary') ||
            widget.totalPoints >= 1000,
        'description': 'Reach 1000 XP (${widget.totalPoints}/1000)',
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
          const Text(
            'FileGenius Learning Platform',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFooterItem(Icons.info_outline, 'About'),
              _buildFooterItem(Icons.help_outline, 'Help'),
              _buildFooterItem(Icons.privacy_tip, 'Privacy'),
              _buildFooterItem(Icons.contact_support, 'Contact'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Version 1.0.0 • © ${DateTime.now().year} FileGenius',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kBrand.withOpacity(0.1),
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
    );
  }

  List<Map<String, String>> _getDailyQuotes() {
    return [
      {
        'quote': 'The only way to do great work is to love what you do.',
        'author': 'Steve Jobs',
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
