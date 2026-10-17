// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'constants.dart';
import 'widgets/app_footer.dart';
import 'widgets/dashboard/dashboard_header.dart';
import 'widgets/dashboard/user_level_card.dart';
import 'widgets/dashboard/main_metrics_card.dart';
import 'widgets/dashboard/badge_system_card.dart';
import 'widgets/dashboard/activity_heatmap_card.dart';
import 'widgets/dashboard/streak_card.dart';
import 'widgets/dashboard/quick_actions_card.dart';
import 'widgets/dashboard/analytics_section_card.dart';
import 'widgets/dashboard/recent_achievements_card.dart';
import 'widgets/dashboard/daily_quote_card.dart';

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
  _dashboardSubscription; // <â€” add

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _loadDashboardData();

    _dashboardSubscription = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('dashboard')
        .doc('stats')
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
    _dashboardSubscription?.cancel(); // <â€” cancel stream
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
      // Primary source: user subcollection dashboard stats, then user doc, with legacy fallback
      final dashboardDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('dashboard')
          .doc('stats')
          .get();
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

      if (!mounted) return;

      Map<String, dynamic>? data;

      if (dashboardDoc.exists) {
        data = dashboardDoc.data();
      } else if (userDoc.exists) {
        data = userDoc.data();
      } else {
        // Fallback for legacy dashboards collection if existing
        try {
          final legacyDoc = await _firestore
              .collection('dashboards')
              .doc(widget.userId)
              .get();
          if (legacyDoc.exists) {
            data = legacyDoc.data();
          }
        } catch (_) {}
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

  // <â€” Factor common assignment logic here (no setState inside)
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
    final docRef = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('dashboard')
        .doc('stats');

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
                DashboardHeader(
                  userName: _userName,
                  totalPoints: _totalPoints,
                  onBackPressed: widget.onBackPressed,
                ),
                const SizedBox(height: 32),
                UserLevelCard(totalPoints: _totalPoints),
                const SizedBox(height: 24),
                MainMetricsCard(
                  filesUploaded: _filesUploaded,
                  weeklyUploads: _weeklyUploads,
                  questionsAnswered: _questionsAnswered,
                  correctAnswers: _correctAnswers,
                  aiChatInteractions: _aiChatInteractions,
                  loginDays: _loginDays,
                ),
                const SizedBox(height: 24),
                // Responsive reordering: on mobile, stack sections vertically as requested
                if (isMobile) ...[
                  // 1) Streak card
                  StreakCard(loginDays: _loginDays),
                  const SizedBox(height: 24),
                  // 2) Achievement badges
                  BadgeSystemCard(
                    unlockedBadges: _unlockedBadges,
                    filesUploaded: _filesUploaded,
                    loginDays: _loginDays,
                    aiChatInteractions: _aiChatInteractions,
                    correctAnswers: _correctAnswers,
                    totalPoints: _totalPoints,
                    questionsAnswered: _questionsAnswered,
                  ),
                  const SizedBox(height: 24),
                  // 3) Activity heatmap
                  ActivityHeatmapCard(dailyActivity: _dailyActivity),
                  const SizedBox(height: 24),
                  // 4) Quick actions
                  QuickActionsCard(
                    onUploadFiles: widget.onUploadFiles,
                    onGenerateQuiz: widget.onGenerateQuiz,
                    onAIInteraction: widget.onAIInteraction,
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            BadgeSystemCard(
                              unlockedBadges: _unlockedBadges,
                              filesUploaded: _filesUploaded,
                              loginDays: _loginDays,
                              aiChatInteractions: _aiChatInteractions,
                              correctAnswers: _correctAnswers,
                              totalPoints: _totalPoints,
                              questionsAnswered: _questionsAnswered,
                            ),
                            const SizedBox(height: 24),
                            ActivityHeatmapCard(dailyActivity: _dailyActivity),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            StreakCard(loginDays: _loginDays),
                            const SizedBox(height: 24),
                            QuickActionsCard(
                              onUploadFiles: widget.onUploadFiles,
                              onGenerateQuiz: widget.onGenerateQuiz,
                              onAIInteraction: widget.onAIInteraction,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                AnalyticsSectionCard(
                  totalStudyTime: _totalStudyTime,
                  studyTimeBySubject: _studyTimeBySubject,
                  weeklyPerformance: _weeklyPerformance,
                ),
                const SizedBox(height: 24),
                RecentAchievementsCard(
                  recentAchievements: _recentAchievements,
                ),
                const SizedBox(height: 24),
                const DailyQuoteCard(),
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
}
