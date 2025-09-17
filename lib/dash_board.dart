// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'constants.dart';
import 'screens/chat_sessions_screen.dart';
import 'widgets/app_footer.dart';

/// Comprehensive Dashboard with Gamification & Analytics
class DashboardScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onBackPressed;
  final VoidCallback? onUploadFiles;
  final VoidCallback? onGenerateQuiz;
  final VoidCallback? onAIInteraction;
  final GlobalKey<DashboardScreenState>? dashboardKey; // Add this

  const DashboardScreen({
    super.key,
    required this.userId,
    this.onBackPressed,
    this.onUploadFiles,
    this.onGenerateQuiz,
    this.onAIInteraction,
    this.dashboardKey, // Add this
  });

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  // Dashboard state
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // User metrics
  int _filesUploaded = 0;
  int _aiChatInteractions = 0;
  int _questionsAnswered = 0;
  int _correctAnswers = 0;
  int _loginDays = 0;
  int _totalPoints = 0;
  int _weeklyUploads = 0;
  int _monthlyUploads = 0;
  Map<String, int> _fileTypeStats = {};
  Map<String, int> _dailyActivity = {};
  List<String> _unlockedBadges = [];
  List<String> _recentAchievements = [];
  String _userName = 'User';

  // Add Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Analytics data
  Map<String, double> _studyTimeBySubject = {};
  List<Map<String, dynamic>> _performanceHistory = [];
  Map<String, int> _weeklyPerformance = {};
  List<String> _weakAreas = [];
  List<Map<String, dynamic>> _aiRecommendations = [];
  double _totalStudyTime = 0.0;
  double _averageAccuracy = 0.0;
  String _preferredStudyTime = 'Morning';

  // Timer for refresh
  Timer? _refreshTimer;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _dashboardSubscription; // <— add

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _loadDashboardData();

    _dashboardSubscription = _firestore
        .collection('dashboards')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          final data = snapshot.data();
          if (data != null && mounted) {
            // Add null check here
            setState(() {
              _applyDashboardData(
                data,
              ); // Now data is guaranteed to be non-null
            });
          }
        });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _dashboardSubscription?.cancel(); // <— cancel stream
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return; // Add early return check

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Try to load from cache first
      await _loadFromCache();

      // Check mounted before Firestore call
      if (!mounted) return;

      // Then fetch fresh data from Firestore
      await _fetchFromFirestore();

      // Check mounted before saving to cache
      if (!mounted) return;

      // Save the latest data to cache
      await _saveToCache();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFromCache() async {
    if (!mounted) return; // Add check at start

    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return; // Check again after async operation

    setState(() {
      _filesUploaded = prefs.getInt('filesUploaded') ?? 0;
      _aiChatInteractions = prefs.getInt('aiChatInteractions') ?? 0;
      _questionsAnswered = prefs.getInt('questionsAnswered') ?? 0;
      _correctAnswers = prefs.getInt('correctAnswers') ?? 0;
      _loginDays = prefs.getInt('loginDays') ?? 0;
      _totalPoints = prefs.getInt('totalPoints') ?? 0;
      _weeklyUploads = prefs.getInt('weeklyUploads') ?? 0;
      _monthlyUploads = prefs.getInt('monthlyUploads') ?? 0;
      _userName = prefs.getString('userName') ?? 'User';
      _totalStudyTime = prefs.getDouble('totalStudyTime') ?? 0.0;
      _averageAccuracy = prefs.getDouble('averageAccuracy') ?? 0.0;
      _preferredStudyTime = prefs.getString('preferredStudyTime') ?? 'Morning';

      // Load maps/lists from JSON strings
      _fileTypeStats = Map<String, int>.from(
        jsonDecode(prefs.getString('fileTypeStats') ?? '{}'),
      );
      _dailyActivity = Map<String, int>.from(
        jsonDecode(prefs.getString('dailyActivity') ?? '{}'),
      );
      _unlockedBadges = List<String>.from(
        jsonDecode(prefs.getString('unlockedBadges') ?? '[]'),
      );
      _recentAchievements = List<String>.from(
        jsonDecode(prefs.getString('recentAchievements') ?? '[]'),
      );
      _studyTimeBySubject = Map<String, double>.from(
        jsonDecode(prefs.getString('studyTimeBySubject') ?? '{}'),
      );
      _weakAreas = List<String>.from(
        jsonDecode(prefs.getString('weakAreas') ?? '[]'),
      );
    });
  }

  Future<void> _fetchFromFirestore() async {
    if (!mounted) return;

    try {
      // Always prefer user collection for the source of truth
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      final dashboardDoc =
          await _firestore.collection('dashboards').doc(widget.userId).get();

      if (!mounted) return;

      Map<String, dynamic>? data;

      // Use user data as primary source, dashboard as backup
      if (userDoc.exists) {
        data = userDoc.data();
      } else if (dashboardDoc.exists) {
        data = dashboardDoc.data();
      }

      if (data != null && mounted) {
        setState(() {
          _applyDashboardData(data!);
        });
      } else {
        // Create initial document
        if (mounted) {
          await _saveToFirestore();
        }
      }
    } catch (e) {
      debugPrint('Error fetching from Firestore: $e');
    }
  }

  // <— Factor common assignment logic here (no setState inside)
  void _applyDashboardData(Map<String, dynamic> data) {
    _filesUploaded = data['filesUploaded'] ?? _filesUploaded;
    _aiChatInteractions = data['aiChatInteractions'] ?? _aiChatInteractions;
    _questionsAnswered = data['questionsAnswered'] ?? _questionsAnswered;
    _correctAnswers = data['correctAnswers'] ?? _correctAnswers;
    _loginDays = data['loginDays'] ?? _loginDays;
    _totalPoints = data['totalPoints'] ?? _totalPoints;
    _weeklyUploads = data['weeklyUploads'] ?? _weeklyUploads;
    _monthlyUploads = data['monthlyUploads'] ?? _monthlyUploads;
    _userName = data['userName'] ?? _userName;
    _totalStudyTime = (data['totalStudyTime'] ?? _totalStudyTime).toDouble();
    _averageAccuracy = (data['averageAccuracy'] ?? _averageAccuracy).toDouble();
    _preferredStudyTime = data['preferredStudyTime'] ?? _preferredStudyTime;

    _fileTypeStats = Map<String, int>.from(
      data['fileTypeStats'] ?? _fileTypeStats,
    );
    _dailyActivity = Map<String, int>.from(
      data['dailyActivity'] ?? _dailyActivity,
    );
    _unlockedBadges = List<String>.from(
      data['unlockedBadges'] ?? _unlockedBadges,
    );
    _recentAchievements = List<String>.from(
      data['recentAchievements'] ?? _recentAchievements,
    );
    _studyTimeBySubject = Map<String, double>.from(
      data['studyTimeBySubject'] ?? _studyTimeBySubject,
    );
    _weakAreas = List<String>.from(data['weakAreas'] ?? _weakAreas);
    _performanceHistory = List<Map<String, dynamic>>.from(
      data['performanceHistory'] ?? _performanceHistory,
    );
    _weeklyPerformance = Map<String, int>.from(
      data['weeklyPerformance'] ?? _weeklyPerformance,
    );
    _aiRecommendations = List<Map<String, dynamic>>.from(
      data['aiRecommendations'] ?? _aiRecommendations,
    );
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('filesUploaded', _filesUploaded);
    await prefs.setInt('aiChatInteractions', _aiChatInteractions);
    await prefs.setInt('questionsAnswered', _questionsAnswered);
    await prefs.setInt('correctAnswers', _correctAnswers);
    await prefs.setInt('loginDays', _loginDays);
    await prefs.setInt('totalPoints', _totalPoints);
    await prefs.setInt('weeklyUploads', _weeklyUploads);
    await prefs.setInt('monthlyUploads', _monthlyUploads);
    await prefs.setString('userName', _userName);
    await prefs.setDouble('totalStudyTime', _totalStudyTime);
    await prefs.setDouble('averageAccuracy', _averageAccuracy);
    await prefs.setString('preferredStudyTime', _preferredStudyTime);

    // Save maps/lists as JSON strings
    await prefs.setString('fileTypeStats', jsonEncode(_fileTypeStats));
    await prefs.setString('dailyActivity', jsonEncode(_dailyActivity));
    await prefs.setString('unlockedBadges', jsonEncode(_unlockedBadges));
    await prefs.setString(
      'recentAchievements',
      jsonEncode(_recentAchievements),
    );
    await prefs.setString(
      'studyTimeBySubject',
      jsonEncode(_studyTimeBySubject),
    );
    await prefs.setString('weakAreas', jsonEncode(_weakAreas));
  }

  Future<void> _saveToFirestore() async {
    final docRef = _firestore.collection('dashboards').doc(widget.userId);

    final data = {
      'filesUploaded': _filesUploaded,
      'aiChatInteractions': _aiChatInteractions,
      'questionsAnswered': _questionsAnswered,
      'correctAnswers': _correctAnswers,
      'loginDays': _loginDays,
      'totalPoints': _totalPoints,
      'weeklyUploads': _weeklyUploads,
      'monthlyUploads': _monthlyUploads,
      'userName': _userName,
      'totalStudyTime': _totalStudyTime,
      'averageAccuracy': _averageAccuracy,
      'preferredStudyTime': _preferredStudyTime,
      'fileTypeStats': _fileTypeStats,
      'dailyActivity': _dailyActivity,
      'unlockedBadges': _unlockedBadges,
      'recentAchievements': _recentAchievements,
      'studyTimeBySubject': _studyTimeBySubject,
      'weakAreas': _weakAreas,
      'performanceHistory': _performanceHistory,
      'weeklyPerformance': _weeklyPerformance,
      'aiRecommendations': _aiRecommendations,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // Use set with merge:true to create or update the document
    await docRef.set(data, SetOptions(merge: true));
  }

  Future<void> _refreshData() async {
    if (mounted) {
      await _loadDashboardData();
    }
  }

  Future<void> _fetchUserName() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      if (!mounted) return; // guard after await
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        setState(() {
          _userName = data['name'] ?? 'User';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userName = 'User';
      });
    }
  }

  // Expose a public refresh method
  Future<void> refreshDashboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _fetchFromFirestore();
      await _saveToCache();
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) _buildLoadingIndicator(),
              if (_hasError) _buildErrorWidget(),
              if (!_isLoading && !_hasError) ...[
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildUserLevelCard(),
                const SizedBox(height: 24),
                _buildMainMetrics(),
                const SizedBox(height: 24),
                // Responsive reordering: on mobile, stack sections vertically as requested
                if (isMobile) ...[
                  // 1) Streak card
                  _buildStreakCard(),
                  const SizedBox(height: 24),
                  // 2) Achievement badges
                  _buildBadgeSystem(),
                  const SizedBox(height: 24),
                  // 3) Activity heatmap
                  _buildActivityGraph(),
                  const SizedBox(height: 24),
                  // 4) Quick actions
                  _buildQuickActions(),
                ] else ...[
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
                ],
                const SizedBox(height: 24),
                _buildAnalyticsSection(),
                const SizedBox(height: 24),
                _buildRecentAchievements(),
                const SizedBox(height: 24),
                _buildDailyQuote(),
                const SizedBox(height: 32),
                const AppFooter(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kBrand),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrand,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
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

    if (isMobile) {
      // Mobile: vertical stack
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with back button
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 28,
                ),
                onPressed: () => widget.onBackPressed?.call(),
              ),
              const SizedBox(width: 8),
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome, $_userName!',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                      '$_totalPoints XP',
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

    // Desktop/tablet: original header
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
                    'Welcome, $_userName!',
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
                    '$_totalPoints XP',
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
    final currentLevel = (_totalPoints / 100).floor() + 1;
    final nextLevelPoints = currentLevel * 100;
    final progressToNext = (_totalPoints % 100) / 100;

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
                  '${nextLevelPoints - _totalPoints} XP to Level ${currentLevel + 1}',
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
    // Use Wrap for responsiveness to avoid overflow on small widths
    final items = <Widget>[
      _buildMetricCard(
        'Files Uploaded',
        _filesUploaded.toString(),
        Icons.cloud_upload,
        Colors.blue,
        '+$_weeklyUploads this week',
      ),
      _buildMetricCard(
        'Questions Answered',
        _questionsAnswered.toString(),
        Icons.quiz,
        Colors.green,
        '${_questionsAnswered > 0 ? ((_correctAnswers / _questionsAnswered) * 100).toInt() : 0}% accuracy',
      ),
      _buildMetricCard(
        'AI Interactions',
        _aiChatInteractions.toString(),
        Icons.smart_toy,
        Colors.purple,
        'Explore more!',
      ),
      _buildMetricCard(
        'Login Streak',
        '$_loginDays days',
        Icons.local_fire_department,
        Colors.orange,
        'Keep it up!',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1000;
        if (isNarrow) {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children:
                items
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
    final unlockedCount = badges.where((b) => b['unlocked'] as bool).length;

    // Use dynamic crossAxisCount to avoid overflow on small widths
    final crossAxisCount = MediaQuery.of(context).size.width < 1100 ? 4 : 6;

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
                  color: kBrand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$unlockedCount / ${badges.length}',
                  style: TextStyle(
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                unlocked
                    ? LinearGradient(colors: [kBrand, kBrand.withOpacity(0.7)])
                    : null,
            color: unlocked ? null : Colors.grey[300],
          ),
          child: Icon(
            icon,
            size: 20,
            color: unlocked ? Colors.white : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: unlocked ? Colors.black87 : Colors.grey[500],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (!unlocked) Icon(Icons.lock, size: 8, color: Colors.grey[400]),
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
                _dailyActivity.isEmpty
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
                      itemCount: _dailyActivity.length,
                      itemBuilder: (context, index) {
                        final entry = _dailyActivity.entries.elementAt(index);
                        final date = entry.key;
                        final activity = entry.value;
                        final maxActivity =
                            _dailyActivity.values.isNotEmpty
                                ? _dailyActivity.values.reduce(
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
            '$_loginDays Day Streak',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _loginDays >= 7 ? 'Amazing consistency!' : 'Keep going!',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_loginDays % 7) / 7,
            backgroundColor: Colors.orange.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            'Next milestone: ${7 - (_loginDays % 7)} days',
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
    if (_recentAchievements.isEmpty) {
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
                '${_recentAchievements.length} new',
                style: TextStyle(color: kBrand, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _recentAchievements.take(10).map((achievement) {
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

  Widget _buildAnalyticsSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
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

          // Study time breakdown — mobile first: Study Time, then Weekly Activity
          if (isMobile) ...[
            _buildStudyTimeChart(),
            const SizedBox(height: 16),
            const Text(
              'Weekly Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildWeeklyActivityChart(),
          ] else ...[
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
                      _buildWeeklyActivityChart(),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStudyTimeChart() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
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
              Expanded(
                child: Text(
                  'Study Time by Subject',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 8,
                  vertical: isMobile ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_totalStudyTime.toStringAsFixed(1)}h total',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Bar Chart for Study Time
          if (_studyTimeBySubject.isNotEmpty)
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
    if (_studyTimeBySubject.isEmpty || _studyTimeBySubject.values.isEmpty) {
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
    final values = _studyTimeBySubject.values.where((v) => v > 0).toList();
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
    final subjects = _studyTimeBySubject.keys.toList();

    return Column(
      children:
          subjects.map((subject) {
            final value = _studyTimeBySubject[subject]!;
            final percentage = maxValue > 0 ? value / maxValue : 0.0;
            final color = _getSubjectColor(subject);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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

  Widget _buildWeeklyActivityChart() {
    // Expected keys: Mon..Sun or similar labels; handle empty gracefully
    if (_weeklyPerformance.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No weekly activity yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final orderedDays = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    // Map keys may be full names; normalize common variants
    int normalizeIndex(String k) {
      final kk = k.substring(0, k.length < 3 ? k.length : 3).toLowerCase();
      switch (kk) {
        case 'mon':
          return 0;
        case 'tue':
          return 1;
        case 'wed':
          return 2;
        case 'thu':
          return 3;
        case 'fri':
          return 4;
        case 'sat':
          return 5;
        case 'sun':
          return 6;
        default:
          return 0;
      }
    }

    final entries =
        _weeklyPerformance.entries.toList()..sort(
          (a, b) => normalizeIndex(a.key).compareTo(normalizeIndex(b.key)),
        );
    final maxVal = entries
        .map((e) => e.value)
        .fold<int>(1, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            entries.map((e) {
              final dayShort = orderedDays[normalizeIndex(e.key)];
              final h =
                  (e.value / (maxVal == 0 ? 1 : maxVal)) * 120 +
                  8; // min height 8
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: kBrand.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayShort,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
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
        'unlocked': _unlockedBadges.contains('first_file'),
        'description': 'Upload your first file ($_filesUploaded/1)',
      },
      {
        'icon': Icons.folder,
        'label': 'File Master',
        'unlocked': _unlockedBadges.contains('file_master'),
        'description': 'Upload 10 files ($_filesUploaded/10)',
      },
      {
        'icon': Icons.workspace_premium,
        'label': 'File Expert',
        'unlocked': _unlockedBadges.contains('file_expert'),
        'description': 'Upload 50 files ($_filesUploaded/50)',
      },
      {
        'icon': Icons.emoji_events,
        'label': 'Week Warrior',
        'unlocked': _unlockedBadges.contains('week_warrior'),
        'description': 'Login for 7 consecutive days ($_loginDays/7)',
      },
      {
        'icon': Icons.stars,
        'label': 'Month Master',
        'unlocked': _unlockedBadges.contains('month_master'),
        'description': 'Login for 30 consecutive days ($_loginDays/30)',
      },
      {
        'icon': Icons.smart_toy,
        'label': 'AI Explorer',
        'unlocked': _unlockedBadges.contains('ai_explorer'),
        'description': 'Use AI chat 5 times ($_aiChatInteractions/5)',
      },
      {
        'icon': Icons.quiz,
        'label': 'Quiz Master',
        'unlocked': _unlockedBadges.contains('quiz_master'),
        'description': 'Answer 20 questions correctly ($_correctAnswers/20)',
      },
      {
        'icon': Icons.military_tech,
        'label': 'Century Club',
        'unlocked': _unlockedBadges.contains('century_club'),
        'description': 'Earn 100 XP ($_totalPoints/100)',
      },
      {
        'icon': Icons.diamond,
        'label': 'Point Prodigy',
        'unlocked': _unlockedBadges.contains('point_prodigy'),
        'description': 'Earn 500 XP ($_totalPoints/500)',
      },
      {
        'icon': Icons.school,
        'label': 'Scholar',
        'unlocked': _unlockedBadges.contains('scholar'),
        'description': 'Answer 100 questions ($_questionsAnswered/100)',
      },
      {
        'icon': Icons.psychology,
        'label': 'Genius',
        'unlocked': _unlockedBadges.contains('genius'),
        'description': 'Get 50 correct answers ($_correctAnswers/50)',
      },
      {
        'icon': Icons.auto_awesome,
        'label': 'Legendary',
        'unlocked': _unlockedBadges.contains('legendary'),
        'description': 'Reach 1000 XP ($_totalPoints/1000)',
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
          colors: [kBrand, kBrand.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBrand.withOpacity(0.3),
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
                  color: Colors.white.withOpacity(0.2),
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
                color: Colors.white.withOpacity(0.2),
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

  // Footer moved to widgets/app_footer.dart and reused across screens.

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
