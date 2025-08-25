import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing user statistics, achievements, and progress tracking
class UserStatsService extends ChangeNotifier {
  // User metrics
  int _filesUploaded = 0;
  int _aiChatInteractions = 0;
  int _questionsAnswered = 0;
  int _correctAnswers = 0;
  int _loginDays = 0;
  int _totalPoints = 0;
  int _weeklyUploads = 0;
  int _monthlyUploads = 0;

  // Analytics data
  Map<String, int> _fileTypeStats = {};
  Map<String, int> _dailyActivity = {};
  List<String> _unlockedBadges = [];
  List<String> _recentAchievements = [];

  // Learning analytics
  Map<String, double> _studyTimeBySubject = {};
  Map<String, int> _weeklyPerformance = {};
  double _totalStudyTime = 0.0;

  // Timestamps
  DateTime? _lastLoginDate;
  DateTime? _lastActivityTime;

  // Getters
  int get filesUploaded => _filesUploaded;
  int get aiChatInteractions => _aiChatInteractions;
  int get questionsAnswered => _questionsAnswered;
  int get correctAnswers => _correctAnswers;
  int get loginDays => _loginDays;
  int get totalPoints => _totalPoints;
  int get weeklyUploads => _weeklyUploads;
  int get monthlyUploads => _monthlyUploads;
  Map<String, int> get fileTypeStats => Map.unmodifiable(_fileTypeStats);
  Map<String, int> get dailyActivity => Map.unmodifiable(_dailyActivity);
  List<String> get unlockedBadges => List.unmodifiable(_unlockedBadges);
  List<String> get recentAchievements => List.unmodifiable(_recentAchievements);
  Map<String, double> get studyTimeBySubject =>
      Map.unmodifiable(_studyTimeBySubject);
  Map<String, int> get weeklyPerformance =>
      Map.unmodifiable(_weeklyPerformance);
  double get totalStudyTime => _totalStudyTime;
  DateTime? get lastLoginDate => _lastLoginDate;
  DateTime? get lastActivityTime => _lastActivityTime;

  /// Load user statistics from Firestore
  Future<void> loadUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        _applyUserData(data);
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
  }

  /// Save user statistics to Firestore
  Future<void> saveUserStats({bool isNewUser = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userData = _buildUserDataMap();
      if (isNewUser) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: !isNewUser));

      await _syncDashboardToFirestore();
      debugPrint('✅ User stats saved to Firestore');
    } catch (e) {
      debugPrint('Error saving user stats: $e');
      rethrow;
    }
  }

  /// Track file upload
  void onFileUpload(String fileType) {
    _filesUploaded++;
    _totalPoints += 10;
    _weeklyUploads++;
    _monthlyUploads++;
    _fileTypeStats[fileType.toLowerCase()] =
        (_fileTypeStats[fileType.toLowerCase()] ?? 0) + 1;

    _trackDailyActivity();
    _checkForNewAchievements();
    notifyListeners();
  }

  /// Track AI interaction
  void onAIInteraction() {
    _aiChatInteractions++;
    _totalPoints += 5;
    _trackDailyActivity();
    _checkForNewAchievements();
    notifyListeners();
  }

  /// Track quiz answer
  void onQuizAnswer(bool isCorrect) {
    _questionsAnswered++;
    if (isCorrect) {
      _correctAnswers++;
      _totalPoints += 15;
    } else {
      _totalPoints += 2;
    }
    _trackDailyActivity();
    _checkForNewAchievements();
    notifyListeners();
  }

  /// Track login day
  Future<void> trackLoginDay() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastLoginDate == null) {
      _loginDays = 1;
      if (_totalPoints == 0) {
        _totalPoints += 5;
      }
    } else {
      final last = DateTime(
        _lastLoginDate!.year,
        _lastLoginDate!.month,
        _lastLoginDate!.day,
      );
      final difference = today.difference(last).inDays;

      if (difference == 1) {
        _loginDays += 1;
        _totalPoints += 5;
      } else if (difference > 1) {
        _loginDays = 1;
        _totalPoints += 5;
      }
    }

    _lastLoginDate = now;
    _trackDailyActivity();
    _checkForNewAchievements();
    notifyListeners();
  }

  /// Start study session
  void startStudySession(String subject) {
    final weekday = _weekdayKey(DateTime.now());
    _weeklyPerformance[weekday] = (_weeklyPerformance[weekday] ?? 0) + 1;
    notifyListeners();
  }

  /// End study session
  void endStudySession(String subject, Duration duration) {
    final hours = duration.inSeconds / 3600.0;
    _studyTimeBySubject[subject] = (_studyTimeBySubject[subject] ?? 0) + hours;
    _totalStudyTime = _studyTimeBySubject.values.fold<double>(
      0.0,
      (a, b) => a + b,
    );
    notifyListeners();
  }

  /// Update last activity
  void updateLastActivity() {
    _lastActivityTime = DateTime.now();
    notifyListeners();
  }

  /// Track daily activity
  void _trackDailyActivity() {
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    _dailyActivity[key] = (_dailyActivity[key] ?? 0) + 1;
  }

  /// Check for new achievements
  void _checkForNewAchievements() {
    final newBadges = <String>[];

    // File upload achievements
    if (_filesUploaded >= 1 && !_unlockedBadges.contains('first_file')) {
      newBadges.add('first_file');
      _recentAchievements.add('First Upload');
    }
    if (_filesUploaded >= 10 && !_unlockedBadges.contains('file_master')) {
      newBadges.add('file_master');
      _recentAchievements.add('File Master');
    }
    if (_filesUploaded >= 50 && !_unlockedBadges.contains('file_expert')) {
      newBadges.add('file_expert');
      _recentAchievements.add('File Expert');
    }

    // AI interaction achievements
    if (_aiChatInteractions >= 5 && !_unlockedBadges.contains('ai_explorer')) {
      newBadges.add('ai_explorer');
      _recentAchievements.add('AI Explorer');
    }

    // Quiz achievements
    if (_correctAnswers >= 20 && !_unlockedBadges.contains('quiz_master')) {
      newBadges.add('quiz_master');
      _recentAchievements.add('Quiz Master');
    }
    if (_questionsAnswered >= 100 && !_unlockedBadges.contains('scholar')) {
      newBadges.add('scholar');
      _recentAchievements.add('Scholar');
    }

    // Points achievements
    if (_totalPoints >= 100 && !_unlockedBadges.contains('century_club')) {
      newBadges.add('century_club');
      _recentAchievements.add('Century Club');
    }
    if (_totalPoints >= 500 && !_unlockedBadges.contains('point_prodigy')) {
      newBadges.add('point_prodigy');
      _recentAchievements.add('Point Prodigy');
    }
    if (_totalPoints >= 1000 && !_unlockedBadges.contains('legendary')) {
      newBadges.add('legendary');
      _recentAchievements.add('Legendary');
    }

    // Streak achievements
    if (_loginDays >= 30 && !_unlockedBadges.contains('month_master')) {
      newBadges.add('month_master');
      _recentAchievements.add('Month Master');
    }

    // Add new badges
    _unlockedBadges.addAll(newBadges);

    // Keep only last 5 recent achievements
    if (_recentAchievements.length > 5) {
      _recentAchievements =
          _recentAchievements.skip(_recentAchievements.length - 5).toList();
    }

    if (newBadges.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Sync dashboard data to Firestore
  Future<void> _syncDashboardToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('dashboards')
          .doc(user.uid)
          .set(_buildUserDataMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing dashboard: $e');
    }
  }

  /// Build user data map for Firestore
  Map<String, dynamic> _buildUserDataMap() {
    return {
      'filesUploaded': _filesUploaded,
      'aiChatInteractions': _aiChatInteractions,
      'questionsAnswered': _questionsAnswered,
      'correctAnswers': _correctAnswers,
      'loginDays': _loginDays,
      'totalPoints': _totalPoints,
      'weeklyUploads': _weeklyUploads,
      'monthlyUploads': _monthlyUploads,
      'fileTypeStats': _fileTypeStats,
      'dailyActivity': _dailyActivity,
      'unlockedBadges': _unlockedBadges,
      'recentAchievements': _recentAchievements,
      'studyTimeBySubject': _studyTimeBySubject,
      'weeklyPerformance': _weeklyPerformance,
      'totalStudyTime': _totalStudyTime,
      'lastLoginDate':
          _lastLoginDate != null ? Timestamp.fromDate(_lastLoginDate!) : null,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Apply user data from Firestore
  void _applyUserData(Map<String, dynamic> data) {
    _filesUploaded = data['filesUploaded'] ?? _filesUploaded;
    _aiChatInteractions = data['aiChatInteractions'] ?? _aiChatInteractions;
    _questionsAnswered = data['questionsAnswered'] ?? _questionsAnswered;
    _correctAnswers = data['correctAnswers'] ?? _correctAnswers;
    _loginDays = data['loginDays'] ?? _loginDays;
    _totalPoints = data['totalPoints'] ?? _totalPoints;
    _weeklyUploads = data['weeklyUploads'] ?? _weeklyUploads;
    _monthlyUploads = data['monthlyUploads'] ?? _monthlyUploads;
    _unlockedBadges = List<String>.from(data['unlockedBadges'] ?? []);
    _recentAchievements = List<String>.from(data['recentAchievements'] ?? []);
    _fileTypeStats = Map<String, int>.from(data['fileTypeStats'] ?? {});
    _dailyActivity = Map<String, int>.from(data['dailyActivity'] ?? {});
    _studyTimeBySubject = Map<String, double>.from(
      data['studyTimeBySubject'] ?? {},
    );
    _weeklyPerformance = Map<String, int>.from(data['weeklyPerformance'] ?? {});
    _totalStudyTime = (data['totalStudyTime'] ?? 0.0).toDouble();

    final lastLoginTimestamp = data['lastLoginDate'] as Timestamp?;
    _lastLoginDate = lastLoginTimestamp?.toDate();
  }

  /// Get weekday key
  String _weekdayKey(DateTime dt) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[dt.weekday - 1];
  }

  /// Reset all stats (for testing or data clearing)
  void resetStats() {
    _filesUploaded = 0;
    _aiChatInteractions = 0;
    _questionsAnswered = 0;
    _correctAnswers = 0;
    _loginDays = 0;
    _totalPoints = 0;
    _weeklyUploads = 0;
    _monthlyUploads = 0;
    _fileTypeStats.clear();
    _dailyActivity.clear();
    _unlockedBadges.clear();
    _recentAchievements.clear();
    _studyTimeBySubject.clear();
    _weeklyPerformance.clear();
    _totalStudyTime = 0.0;
    _lastLoginDate = null;
    _lastActivityTime = null;
    notifyListeners();
  }
}


