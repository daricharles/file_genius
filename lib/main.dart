// lib/main.dart
// Root:  FileGeniusSidebar  ⇆  MainPane  +  FileViewer
// -----------------------------------------------------

// ignore_for_file: prefer_final_fields

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'services/speech_service.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

// WebView for web support
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

// UI
import 'constants.dart';
import 'login_page.dart';
import 'side_bar.dart';
import 'main_pane.dart';
import 'models.dart';
import 'dash_board.dart';
import 'user_profile.dart';
import 'services/file_analysis_orchestrator.dart';
import 'services/file_content_extractor.dart';
import 'services/ai_service.dart';
import 'services/question_suggestions_service.dart';

/// Achievement notification dialog with animations
class AchievementDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final int points;

  const AchievementDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.points,
  });

  @override
  State<AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<AchievementDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();

    // Auto-dismiss after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kBrand.withValues(alpha: 0.9), kBrand],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kBrand.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      '🎉 Achievement Unlocked! 🎉',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.points} Total Points',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Safely writes data to Firestore and logs the result.
Future<void> _safeSet(DocumentReference ref, Map<String, dynamic> data) async {
  try {
    await ref.set(data);
    debugPrint('✅ wrote to [32m[1m[4m${ref.path}[0m');
  } catch (e, st) {
    debugPrint('❌ Firestore write failed: $e\n$st');
    rethrow;
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/.env'); // match pubspec asset
  } catch (e) {
    debugPrint('dotenv not loaded: $e'); // don’t crash on web
  }

  // initialize Firebase here using your normal path
  await _initNotifications();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SpeechService>(
          create: (_) => SpeechService()..initialize(),
        ),
        // Core analysis services (now the imports are used)
        Provider<FileContentExtractor>(create: (_) => FileContentExtractor()),
        Provider<AIService>(create: (_) => AIService()),
        ProxyProvider<AIService, QuestionSuggestionsService>(
          update:
              (_, aiService, _) =>
                  QuestionSuggestionsService(aiService: aiService),
        ),
        // Orchestrator that depends on the above.
        ProxyProvider3<
          FileContentExtractor,
          AIService,
          QuestionSuggestionsService,
          FileAnalysisOrchestrator
        >(
          update:
              (_, extractor, ai, qs, previous) => FileAnalysisOrchestrator(
                extractor: extractor,
                aiService: ai,
                questionSuggestions: qs,
              ),
        ),
      ],
      child: const FileGeniusApp(),
    ),
  );
}

/// The root widget that gates access based on authentication state.
class FileGeniusApp extends StatelessWidget {
  const FileGeniusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FileGenius',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: kBrand, useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snap.data == null ? const LoginPage() : const HomeScreen();
        },
      ),
    );
  }
}

/// The main home screen after authentication.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  User? _user;

  // State variables for user stats
  int _filesUploaded = 0;
  int _aiChatInteractions = 0;
  int _questionsAnswered = 0;
  int _correctAnswers = 0;
  int _loginDays = 0;
  int _totalPoints = 0;
  List<String> _unlockedBadges = [];
  List<String> _recentAchievements = [];
  DateTime? _lastLoginDate;

  /* reactive state */
  final List<Folder> _folders = [];
  final List<FileMeta> _topLevelFiles = [];
  final Map<String, List<FileMeta>> _filesByFolder = {};
  final Set<String> _collapsed = {};

  // Dashboard key for refreshing
  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();

  Folder? _selectedFolder; // highlighted in tree
  FileMeta? _previewFile; // shown in right‑hand viewer
  List<StreamSubscription> _folderSubs = [];
  StreamSubscription? _foldersSubscription;
  StreamSubscription? _topLevelFilesSubscription;
  Timer? _backupTimer;
  bool _sidebarCollapsed = false;
  bool _showDashboard = false;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _loadingMessage = '';

  // Enhanced Analytics for Phase 2
  int _weeklyUploads = 0;
  int _monthlyUploads = 0;
  Map<String, int> _fileTypeStats = {};
  Map<String, int> _dailyActivity = {};

  // User data
  String _userName = 'User';

  // Last activity tracking
  DateTime? _lastActivityTime;
  Timer? _inactivityTimer;

  // User profile flag
  bool _showUserProfile = false;

  // Guard to prevent saving zeroed defaults before remote load completes
  bool _hasLoadedUserData = false;

  // === Learning Analytics (added) ===
  Map<String, double> _studyTimeBySubject = {}; // subject -> hours
  Map<String, int> _weeklyPerformance = {}; // weekday (Mon..Sun) -> sessions
  double _totalStudyTime = 0.0;
  DateTime? _currentStudyStart;
  String? _currentStudySubject;
  Timer? _studyTickTimer;
  // ====================================

  /* life‑cycle */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _user = FirebaseAuth.instance.currentUser;
    _attachFirestoreStreams();

    _loadUserData().then((_) {
      if (_hasLoadedUserData) {
        _syncDashboardToFirestore();
      }
    });

    _backupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _backupAllProgressData(),
    );

    _startInactivityMonitor();
    _startStudyTick();
  }

  @override
  void dispose() {
    _endStudySession(flush: true);
    _studyTickTimer?.cancel();
    _saveUserData();
    _syncDashboardToFirestore();

    _backupTimer?.cancel();
    _inactivityTimer?.cancel();

    _foldersSubscription?.cancel();
    _topLevelFilesSubscription?.cancel();
    for (final s in _folderSubs) {
      s.cancel();
    }
    _folderSubs.clear();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _backupAllProgressData();
    }
  }

  /* Firestore listeners */
  void _attachFirestoreStreams() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // folders
    _foldersSubscription = FirebaseFirestore.instance
        .collection('users/$uid/folders')
        .orderBy('createdAt')
        .snapshots()
        .listen(
          (q) {
            if (mounted) {
              setState(() {
                _folders
                  ..clear()
                  ..addAll(q.docs.map(Folder.fromDoc));
              });
              _rebindFolderFileStreams();
            }
          },
          onError: (error) {
            debugPrint('❌ Firestore folders listener error: $error');
            if (mounted) {
              _snack('Failed to load folders: $error', err: true);
            }
          },
        );

    // top‑level files
    _topLevelFilesSubscription = FirebaseFirestore.instance
        .collection('users/$uid/files')
        .orderBy('uploadedAt')
        .snapshots()
        .listen(
          (q) {
            if (mounted) {
              setState(() {
                _topLevelFiles
                  ..clear()
                  ..addAll(q.docs.map(FileMeta.fromDoc));
              });
            }
          },
          onError: (error) {
            debugPrint('❌ Firestore files listener error: $error');
            if (mounted) {
              _snack('Failed to load files: $error', err: true);
            }
          },
        );
  }

  void _rebindFolderFileStreams() {
    for (final s in _folderSubs) {
      s.cancel();
    }
    _folderSubs =
        _folders.map((f) {
          final uid = FirebaseAuth.instance.currentUser!.uid;
          return FirebaseFirestore.instance
              .collection('users/$uid/folders/${f.id}/files')
              .orderBy('uploadedAt')
              .snapshots()
              .listen((q) {
                if (mounted) {
                  setState(
                    () =>
                        _filesByFolder[f.id] =
                            q.docs.map(FileMeta.fromDoc).toList(),
                  );
                }
              });
        }).toList();
  }

  /* helpers */
  List<FileMeta> get _visibleFiles =>
      _selectedFolder == null
          ? _topLevelFiles
          : (_filesByFolder[_selectedFolder!.id] ?? []);

  void _clearPreview() => setState(() => _previewFile = null);

  /* User Data Loading, Saving, and Tracking */
  Future<void> _saveUserData({bool isNewUser = false}) async {
    if (_user == null) return;
    if (!isNewUser && !_hasLoadedUserData) {
      debugPrint('⏭ Skipping _saveUserData: user data not loaded yet.');
      return;
    }

    // Flush any running study session before saving
    _endStudySession(flush: true);

    final userData = {
      'filesUploaded': _filesUploaded,
      'aiChatInteractions': _aiChatInteractions,
      'questionsAnswered': _questionsAnswered,
      'correctAnswers': _correctAnswers,
      'totalPoints': _totalPoints,
      'loginDays': _loginDays,
      'lastLoginDate':
          _lastLoginDate != null ? Timestamp.fromDate(_lastLoginDate!) : null,
      'unlockedBadges': _unlockedBadges,
      'recentAchievements': _recentAchievements,
      'email': _user!.email,
      'displayName': _user!.displayName ?? _userName,
      'fileTypeStats': _fileTypeStats,
      'dailyActivity': _dailyActivity,
      'weeklyUploads': _weeklyUploads,
      'monthlyUploads': _monthlyUploads,
      // --- Added analytics fields ---
      'studyTimeBySubject': _studyTimeBySubject,
      'weeklyPerformance': _weeklyPerformance,
      'totalStudyTime': _totalStudyTime,
      // --------------------------------
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (isNewUser) {
      userData['createdAt'] = FieldValue.serverTimestamp();
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set(userData, SetOptions(merge: !isNewUser));
      debugPrint('✅ User data saved to Firestore');
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Add this helper to keep dashboards/<uid> in sync with the counters
  Future<void> _syncDashboardToFirestore() async {
    if (_user == null) return;
    if (!_hasLoadedUserData) {
      debugPrint('⏭ Skipping _syncDashboardToFirestore: data not loaded yet.');
      return;
    }
    _endStudySession(flush: true);
    try {
      await FirebaseFirestore.instance
          .collection('dashboards')
          .doc(_user!.uid)
          .set({
            'filesUploaded': _filesUploaded,
            'aiChatInteractions': _aiChatInteractions,
            'questionsAnswered': _questionsAnswered,
            'correctAnswers': _correctAnswers,
            'loginDays': _loginDays,
            'totalPoints': _totalPoints,
            'weeklyUploads': _weeklyUploads,
            'monthlyUploads': _monthlyUploads,
            'userName': _userName,
            'fileTypeStats': _fileTypeStats,
            'dailyActivity': _dailyActivity,
            'unlockedBadges': _unlockedBadges,
            'recentAchievements': _recentAchievements,
            // --- Added analytics fields ---
            'studyTimeBySubject': _studyTimeBySubject,
            'weeklyPerformance': _weeklyPerformance,
            'totalStudyTime': _totalStudyTime,
            // --------------------------------
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing dashboard: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid);
      final doc = await docRef.get();

      if (!mounted) return; // <-- Add this check right after the await

      if (doc.exists) {
        final data = doc.data()!;

        // CRITICAL FIX: Load data into state variables BEFORE any other operations
        setState(() {
          _filesUploaded = data['filesUploaded'] ?? _filesUploaded;
          _aiChatInteractions =
              data['aiChatInteractions'] ?? _aiChatInteractions;
          _questionsAnswered = data['questionsAnswered'] ?? _questionsAnswered;
          _correctAnswers = data['correctAnswers'] ?? _correctAnswers;
          _loginDays = data['loginDays'] ?? _loginDays;
          _totalPoints = data['totalPoints'] ?? _totalPoints;
          _weeklyUploads = data['weeklyUploads'] ?? _weeklyUploads;
          _monthlyUploads = data['monthlyUploads'] ?? _monthlyUploads;
          _unlockedBadges = List<String>.from(data['unlockedBadges'] ?? []);
          _recentAchievements = List<String>.from(
            data['recentAchievements'] ?? [],
          );
          _fileTypeStats = Map<String, int>.from(
            data['fileTypeStats'] ?? _fileTypeStats,
          );
          _dailyActivity = Map<String, int>.from(
            data['dailyActivity'] ?? _dailyActivity,
          );
          _userName = data['displayName'] ?? data['userName'] ?? 'User';
          final lastLoginTimestamp = data['lastLoginDate'] as Timestamp?;
          _lastLoginDate = lastLoginTimestamp?.toDate();
          _hasLoadedUserData = true;
        });

        // After loading data, THEN track login day
        await _trackLoginDay();
      } else {
        // First-time user
        await _saveUserData(isNewUser: true);
        _hasLoadedUserData = true;
        await _trackLoginDay();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Do NOT write zeros back if load failed.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Update the _trackLoginDay method to be additive rather than overwriting
  Future<void> _trackLoginDay() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !mounted) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int? difference;
      if (_lastLoginDate != null) {
        final last = DateTime(
          _lastLoginDate!.year,
          _lastLoginDate!.month,
          _lastLoginDate!.day,
        );
        difference = today.difference(last).inDays;
      }

      setState(() {
        if (_lastLoginDate == null) {
          // First ever login - only add points if not already awarded
          _loginDays = 1;
          if (_totalPoints == 0) {
            _totalPoints += 5; // Only add if starting fresh
          }
        } else if (difference == 1) {
          // Consecutive day - extend streak
          _loginDays += 1;
          _totalPoints += 5;
        } else if (difference != null && difference > 1) {
          // Streak broken - reset streak but don't reset total points
          _loginDays = 1;
          _totalPoints += 5;
        } else if (difference == 0) {
          // Same day login - don't add points or change streak
          return;
        }

        // Always update lastLoginDate
        _lastLoginDate = now;
      });

      _trackDailyActivity();
      _checkForNewAchievements();

      await _saveUserData();
      _syncDashboardToFirestore();

      if (_loginDays % 3 == 0) {
        _showStreakNotification(_loginDays);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void onAIInteractionSuccess() {
    _updateLastActivity();
    setState(() {
      _aiChatInteractions++;
      _totalPoints += 5;
    });
    _trackDailyActivity();
    _checkForNewAchievements();

    // Make sure data is saved
    _saveUserData();
    _syncDashboardToFirestore();

    // Force dashboard refresh with a delay to ensure Firestore write completes
    Future.delayed(const Duration(milliseconds: 500), () {
      _dashboardKey.currentState?.refreshDashboard();
    });
  }

  void _onFileUploadSuccess(FileMeta file) {
    _updateLastActivity();
    final fileType = file.type.toLowerCase();
    setState(() {
      _filesUploaded++;
      _totalPoints += 10;
      _weeklyUploads++;
      _monthlyUploads++;
      _fileTypeStats[fileType] = (_fileTypeStats[fileType] ?? 0) + 1;
    });

    _trackDailyActivity();
    _checkForNewAchievements();

    // Make sure data is saved
    _saveUserData();
    _syncDashboardToFirestore();

    // Force dashboard refresh with a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _dashboardKey.currentState?.refreshDashboard();
    });
  }

  void onQuizAnswerSubmitted(bool isCorrect) {
    _updateLastActivity();
    setState(() {
      _questionsAnswered++;
      if (isCorrect) {
        _correctAnswers++;
        _totalPoints += 15;
      } else {
        _totalPoints += 2;
      }
    });

    _trackDailyActivity();
    _checkForNewAchievements();

    // Make sure data is saved
    _saveUserData();
    _syncDashboardToFirestore();

    // Force dashboard refresh with a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _dashboardKey.currentState?.refreshDashboard();
    });
  }

  // Implement periodic backup
  void _backupAllProgressData() async {
    if (_user == null) return;

    debugPrint('📦 Backing up user progress data...');
    await _saveUserData();
  }

  void _checkForNewAchievements() {
    final newBadges = <String>[];

    // Check for new badge unlocks
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

    if (_aiChatInteractions >= 5 && !_unlockedBadges.contains('ai_explorer')) {
      newBadges.add('ai_explorer');
      _recentAchievements.add('AI Explorer');
    }

    if (_correctAnswers >= 20 && !_unlockedBadges.contains('quiz_master')) {
      newBadges.add('quiz_master');
      _recentAchievements.add('Quiz Master');
    }

    if (_totalPoints >= 100 && !_unlockedBadges.contains('century_club')) {
      newBadges.add('century_club');
      _recentAchievements.add('Century Club');
    }

    if (_totalPoints >= 500 && !_unlockedBadges.contains('point_prodigy')) {
      newBadges.add('point_prodigy');
      _recentAchievements.add('Point Prodigy');
    }

    if (_questionsAnswered >= 100 && !_unlockedBadges.contains('scholar')) {
      newBadges.add('scholar');
      _recentAchievements.add('Scholar');
    }

    if (_correctAnswers >= 50 && !_unlockedBadges.contains('genius')) {
      newBadges.add('genius');
      _recentAchievements.add('Genius');
    }

    if (_totalPoints >= 1000 && !_unlockedBadges.contains('legendary')) {
      newBadges.add('legendary');
      _recentAchievements.add('Legendary');
    }

    // Add streak milestones
    if (_loginDays >= 30 && !_unlockedBadges.contains('month_master')) {
      newBadges.add('month_master');
      _recentAchievements.add('Month Master');
    }

    // Add new badges to unlocked list
    _unlockedBadges.addAll(newBadges);

    // Keep only last 5 recent achievements
    if (_recentAchievements.length > 5) {
      _recentAchievements =
          _recentAchievements.skip(_recentAchievements.length - 5).toList();
    }

    // CRITICAL: Save immediately after unlocking achievements
    if (newBadges.isNotEmpty) {
      _saveUserData();
      _syncDashboardToFirestore();
    }

    // Show achievement dialog for new badges
    for (final badge in newBadges) {
      _showAchievementDialog(badge);
    }
  }

  void _showAchievementDialog(String badgeId) {
    final badgeInfo = _getBadgeInfo(badgeId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AchievementDialog(
            title: badgeInfo['title']!,
            icon: badgeInfo['icon'] as IconData,
            points: badgeInfo['points'] as int,
          ),
    );
  }

  Map<String, dynamic> _getBadgeInfo(String badgeId) {
    switch (badgeId) {
      case 'first_file':
        return {
          'title': 'First Upload!',
          'icon': Icons.upload_file,
          'points': 50,
        };
      case 'file_master':
        return {'title': 'File Master!', 'icon': Icons.folder, 'points': 100};
      case 'file_expert':
        return {
          'title': 'File Expert!',
          'icon': Icons.workspace_premium,
          'points': 150,
        };
      case 'ai_explorer':
        return {'title': 'AI Explorer!', 'icon': Icons.smart_toy, 'points': 75};
      case 'quiz_master':
        return {'title': 'Quiz Master!', 'icon': Icons.quiz, 'points': 200};
      case 'century_club':
        return {
          'title': 'Century Club!',
          'icon': Icons.military_tech,
          'points': 200,
        };
      case 'point_prodigy':
        return {
          'title': 'Point Prodigy!',
          'icon': Icons.diamond,
          'points': 300,
        };
      case 'week_warrior':
        return {
          'title': 'Week Warrior!',
          'icon': Icons.emoji_events,
          'points': 150,
        };
      case 'month_master':
        return {'title': 'Month Master!', 'icon': Icons.stars, 'points': 250};
      case 'scholar':
        return {'title': 'Scholar!', 'icon': Icons.school, 'points': 250};
      case 'genius':
        return {'title': 'Genius!', 'icon': Icons.psychology, 'points': 300};
      case 'legendary':
        return {
          'title': 'Legendary!',
          'icon': Icons.auto_awesome,
          'points': 500,
        };
      default:
        return {'title': 'Achievement!', 'icon': Icons.star, 'points': 25};
    }
  }

  /// Updates the last activity timestamp.
  void _updateLastActivity() async {
    _lastActivityTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastActivity', _lastActivityTime!.toIso8601String());
    _startInactivityMonitor(); // Restart the inactivity monitor
  }

  void _startInactivityMonitor() {
    _inactivityTimer?.cancel(); // Cancel previous timer if any
    _inactivityTimer = Timer.periodic(const Duration(minutes: 10), (
      timer,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityStr = prefs.getString('lastActivity');
      if (lastActivityStr == null) return;
      final lastActivity = DateTime.parse(lastActivityStr);
      final now = DateTime.now();
      if (now.difference(lastActivity).inMinutes >= 120) {
        _showStudyReminderNotification();
        timer.cancel(); // Only notify once until next activity
        _inactivityTimer = null;
      }
    });
  }

  Future<void> _showStudyReminderNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'study_reminder_channel',
          'Study Reminders',
          channelDescription: 'Reminders to reinforce learning',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Time to Study!',
      'You haven\'t been active for a while. Let\'s reinforce your learning!',
      platformChannelSpecifics,
    );
  }

  Future<void> _showStreakNotification(int streakDays) async {
    await flutterLocalNotificationsPlugin.show(
      1,
      'Streak Alert!',
      'You\'re on a $streakDays-day learning streak! Keep going for more rewards!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_channel',
          'Streak Notifications',
          channelDescription: 'Notifications for learning streaks',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, dims) {
      final compact = dims.maxWidth < 700;

      /* Sidebar */
      final sidebar = FileGeniusSidebar(
        folders: _folders,
        topLevelFiles: _topLevelFiles,
        filesByFolder: _filesByFolder,
        selectedFolderId: _selectedFolder?.id,
        collapsed: _collapsed,
        onDashboardTap: () {
          // Backup progress when opening dashboard
          _backupAllProgressData();
          setState(() {
            _showDashboard = true;
            _showUserProfile = false;
            _selectedFolder = null;
            _previewFile = null;
          });
        },
        onCreateFolder: _createFolderDialog,
        onUploadFile: _pickFiles,
        onToggleFolder:
            (id) => setState(() {
              _collapsed.contains(id)
                  ? _collapsed.remove(id)
                  : _collapsed.add(id);
            }),
        onSelectFolder:
            (id) => setState(() {
              _selectedFolder =
                  id == null ? null : _folders.firstWhere((f) => f.id == id);
              _previewFile = null;
              _showDashboard = false;
              _showUserProfile = false;
            }),
        onSelectAnyFile:
            (file) => setState(() {
              _previewFile = file;
              _showDashboard = false;
              _showUserProfile = false;
            }),
        onSignOut: () async {
          _clearPreview(); // Clear preview on sign out
          await FirebaseAuth.instance.signOut();
        },
        onUpgradePlan: () => _snack('Upgrade plan (todo)'),
        sidebarCollapsed: _sidebarCollapsed,
        onToggleSidebar:
            () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
        selectedFileId: _previewFile?.id,
        onMoveFile: _moveFile,
        onMoveFolder: _moveFolder,
        onClearData: _handleClearData,
        onDeleteFolder: _handleDeleteFolder,
        onRenameFolder: _handleRenameFolder,
        onDeleteFile: _handleDeleteFile,
        onUserProfilePressed:
            () => setState(() {
              _showUserProfile = true;
              _showDashboard = false;
              _selectedFolder = null;
              _previewFile = null;
            }),
      );

      /* Main content area */
      Widget content;
      if (_showUserProfile) {
        content = UserProfileScreen(
          onBackPressed: () {
            setState(() => _showUserProfile = false);
          },
        );
      } else if (_showDashboard) {
        content = DashboardScreen(
          key: _dashboardKey,
          userId: _user!.uid,
          onBackPressed: () {
            setState(() {
              _showDashboard = false;
            });
          },
          onUploadFiles: () {
            setState(() {
              _showDashboard = false;
            });
            _pickFiles();
          },
          onGenerateQuiz: () {
            setState(() {
              _showDashboard = false;
            });
            _snack('Quiz generation feature coming soon!');
          },
          onAIInteraction: () {
            setState(() {
              _showDashboard = false;
            });
            _snack(
              'AI Assistant: Ask questions about your files in the file preview pane',
            );
          },
          dashboardKey: _dashboardKey,
        );
      } else if (_previewFile != null) {
        final subject = _deriveSubject(_previewFile!);
        _startStudySession(subject);
        content = MainPane(
          key: ValueKey('main_pane_${_previewFile?.id}'),
          selectedFolder: _selectedFolder,
          files: _visibleFiles,
          onPickFiles: _pickFiles,
          onDropFiles: (fs) => _handleDroppedFiles(fs, _selectedFolder?.id),
          onOpenUrl: _openUrl,
          previewFile: _previewFile,
          onSelectFile:
              (file) => setState(() {
                _previewFile = file;
                if (file != null) _startStudySession(_deriveSubject(file));
              }),
          onDeleteFile: _handleDeleteFile,
          onAIInteractionSuccess: onAIInteractionSuccess,
          onQuizAnswerSubmitted: onQuizAnswerSubmitted,
        );
      } else if (_selectedFolder != null) {
        // Leaving file view -> end session
        _endStudySession(flush: true);
        content = MainPane(
          selectedFolder: _selectedFolder,
          files: _visibleFiles,
          onPickFiles: _pickFiles,
          onDropFiles: (fs) => _handleDroppedFiles(fs, _selectedFolder?.id),
          onOpenUrl: _openUrl,
          previewFile: _previewFile,
          onSelectFile:
              (file) => setState(() {
                _previewFile = file;
                if (file != null) _startStudySession(_deriveSubject(file));
              }),
          onDeleteFile: _handleDeleteFile,
          onAIInteractionSuccess: onAIInteractionSuccess,
          onQuizAnswerSubmitted: onQuizAnswerSubmitted,
        );
      } else {
        _endStudySession(flush: true);
        content = MainPane(
          selectedFolder: null,
          files: const [],
          onPickFiles: _pickFiles,
          onDropFiles: (fs) => _handleDroppedFiles(fs, null),
          onOpenUrl: _openUrl,
          previewFile: null,
          onSelectFile:
              (file) => setState(() {
                _previewFile = file;
                if (file != null) _startStudySession(_deriveSubject(file));
              }),
          onDeleteFile: _handleDeleteFile,
          onAIInteractionSuccess: onAIInteractionSuccess,
          onQuizAnswerSubmitted: onQuizAnswerSubmitted,
        );
      }

      return Stack(
        children: [
          Scaffold(
            drawer: compact ? Drawer(child: sidebar) : null,
            body:
                compact
                    ? content
                    : Row(
                      children: [
                        sidebar,
                        const VerticalDivider(width: 1),
                        Expanded(child: content),
                      ],
                    ),
            floatingActionButton: null,
          ),
          // Loading overlay
          if (_isLoading || _isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage.isNotEmpty
                              ? _loadingMessage
                              : 'Loading...',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (_isUploading && _uploadProgress > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                LinearProgressIndicator(value: _uploadProgress),
                                const SizedBox(height: 8),
                                Text('${(_uploadProgress * 100).toInt()}%'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  /* folder creation dialog */
  void _createFolderDialog() {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Create folder'),
            content: TextField(
              controller: ctl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Folder name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = ctl.text.trim();
                  if (name.isEmpty) return;

                  Navigator.pop(context);
                  setState(() {
                    _isLoading = true;
                    _loadingMessage = 'Creating folder...';
                  });

                  try {
                    final f = Folder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                    );
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    await _safeSet(
                      FirebaseFirestore.instance.doc(
                        'users/$uid/folders/${f.id}',
                      ),
                      {
                        'name': f.name,
                        'createdAt': FieldValue.serverTimestamp(),
                      },
                    );
                    if (mounted) {
                      setState(() {
                        _folders.add(f);
                      });
                      _snack('Folder "$name" created successfully');
                    }
                  } catch (e) {
                    _snack('Failed to create folder: $e', err: true);
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _loadingMessage = '';
                      });
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  /* file picker & uploads */
  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'pptx', 'docx'],
    );
    if (res != null) _handleDroppedFiles(res.files, _selectedFolder?.id);
  }

  Future<void> _handleDroppedFiles(
    List<PlatformFile> dropped,
    String? folderId,
  ) async {
    if (dropped.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _loadingMessage = 'Uploading files...';
    });

    FileMeta? firstReal;

    int completed = 0;
    for (final p in dropped) {
      try {
        final meta = await _uploadOne(pFile: p, folderId: folderId);
        firstReal ??= meta;
        completed++;
        if (mounted) {
          setState(() {
            _uploadProgress = completed / dropped.length;
          });
        }
      } catch (e) {
        _snack('Failed to upload ${p.name}: $e', err: true);
      }
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _loadingMessage = '';
      });
    }

    if (firstReal != null) {
      // Auto-select and analyze with a small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 200));
      _startAutoAnalysis(firstReal);
    }

    _snack('$completed file(s) uploaded successfully');
  }

  // Add helper method below in _HomeScreenState:

  void _updateFileMeta(FileMeta updated) {
    final list =
        updated.folderId == null
            ? _topLevelFiles
            : _filesByFolder[updated.folderId] ?? [];
    final idx = list.indexWhere((f) => f.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
    }
  }

  void _startAutoAnalysis(FileMeta file) async {
    setState(() => _previewFile = file);
    final orchestrator = context.read<FileAnalysisOrchestrator>();
    final analyzed = await orchestrator.analyzeFile(file);
    if (!mounted) return;
    setState(() {
      _updateFileMeta(analyzed);
      if (_previewFile?.id == analyzed.id) {
        _previewFile = analyzed;
      }
    });

    // Force a rebuild of the chat widget to trigger auto-summary
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        // This will force the EnhancedAIChatWidget to rebuild with autoSummarize
        _previewFile = analyzed;
      });
    }
  }

  Future<FileMeta> _uploadOne({
    required PlatformFile pFile,
    required String? folderId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref(
      folderId == null
          ? 'users/$uid/files/${pFile.name}'
          : 'users/$uid/folders/$folderId/${pFile.name}',
    );

    final uploadTask = await ref.putData(pFile.bytes!);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    final doc =
        folderId == null
            ? FirebaseFirestore.instance.collection('users/$uid/files').doc()
            : FirebaseFirestore.instance
                .collection('users/$uid/folders/$folderId/files')
                .doc();

    await _safeSet(doc, {
      'name': pFile.name,
      'size': pFile.size,
      'type': pFile.extension,
      'url': downloadUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
      'folderId': folderId,
    });

    final result = FileMeta(
      id: doc.id,
      name: pFile.name,
      size: pFile.size,
      url: downloadUrl,
      type: pFile.extension ?? '',
      uploadedAt: DateTime.now(),
      folderId: folderId,
    );

    _onFileUploadSuccess(result);
    return result;
  }

  // Remove (or comment out) the unused _replaceStub method if present.

  /* data deletion & modification */

  // These are the public-facing methods that include dialogs.
  // They call the private "_" methods to do the actual work.

  Future<void> _handleDeleteFile(FileMeta file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete File'),
            content: Text(
              'Are you sure you want to delete "${file.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Deleting file...';
      });

      try {
        await _deleteFile(file);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadingMessage = '';
          });
        }
      }
    }
  }

  Future<void> _handleDeleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Folder'),
            content: Text(
              'Are you sure you want to delete "${folder.name}" and all its contents? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Deleting folder...';
      });

      try {
        await _deleteFolder(folder);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadingMessage = '';
          });
        }
      }
    }
  }

  Future<void> _handleRenameFolder(Folder folder, String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty || cleanName == folder.name) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .doc('users/$uid/folders/${folder.id}')
          .update({'name': cleanName});
      _snack('Folder renamed to "$cleanName"');
    } catch (e) {
      _snack('Error renaming folder: $e', err: true);
    }
  }

  void _handleClearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Clear All Data'),
            content: const Text(
              'Are you sure you want to delete ALL files and folders? This action is permanent and cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('DELETE EVERYTHING'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Clearing all data...';
      });

      try {
        await _performClearAllData();
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadingMessage = '';
          });
        }
      }
    }
  }

  // --- Private Worker Methods ---

  Future<void> _deleteFile(FileMeta file, {bool showSnack = true}) async {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final storagePath =
        file.folderId == null
            ? 'users/$uid/files/${file.name}'
            : 'users/$uid/folders/${file.folderId}/${file.name}';
    final docRef =
        file.folderId == null
            ? FirebaseFirestore.instance.doc('users/$uid/files/${file.id}')
            : FirebaseFirestore.instance.doc(
              'users/$uid/folders/${file.folderId}/files/${file.id}',
            );

    try {
      try {
        await FirebaseStorage.instance.ref(storagePath).delete();
      } catch (e) {
        debugPrint('Storage deletion failed (might be okay): $e');
      }
      await docRef.delete();
      if (mounted) {
        if (_previewFile?.id == file.id) {
          setState(() => _previewFile = null);
        }
        if (showSnack) _snack('File "${file.name}" deleted.');
      }
    } catch (e) {
      if (showSnack) _snack('Error deleting file: $e', err: true);
    }
  }

  Future<void> _deleteFolder(Folder folder, {bool showSnack = true}) async {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final folderRef = FirebaseFirestore.instance.doc(
      'users/$uid/folders/${folder.id}',
    );

    try {
      final filesSnapshot = await folderRef.collection('files').get();
      for (final doc in filesSnapshot.docs) {
        final file = FileMeta.fromDoc(doc);
        try {
          final storagePath = 'users/$uid/folders/${folder.id}/${file.name}';
          await FirebaseStorage.instance.ref(storagePath).delete();
        } catch (e) {
          debugPrint('Storage deletion failed for ${file.name}: $e');
        }
        await doc.reference.delete();
      }

      await folderRef.delete();

      if (mounted) {
        if (_selectedFolder?.id == folder.id) {
          setState(() {
            _selectedFolder = null;
            _previewFile = null;
          });
        }
        if (showSnack) _snack('Folder "${folder.name}" deleted.');
      }
    } catch (e) {
      if (showSnack) _snack('Error deleting folder: $e', err: true);
    }
  }

  Future<void> _performClearAllData() async {
    if (!mounted) return;
    _snack('Clearing all data...');
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 1. Get all folders
      final foldersSnapshot =
          await FirebaseFirestore.instance
              .collection('users/$uid/folders')
              .get();

      // 2. Delete each folder and its contents
      for (final folderDoc in foldersSnapshot.docs) {
        await _deleteFolder(Folder.fromDoc(folderDoc), showSnack: false);
      }

      // 3. Get all top-level files
      final topLevelFilesSnapshot =
          await FirebaseFirestore.instance.collection('users/$uid/files').get();

      // 4. Delete each top-level file
      for (final fileDoc in topLevelFilesSnapshot.docs) {
        await _deleteFile(FileMeta.fromDoc(fileDoc), showSnack: false);
      }

      if (mounted) {
        // The streams will handle clearing the lists, but we should clear selections.
        setState(() {
          _selectedFolder = null;
          _previewFile = null;
        });
        _snack('All files and folders have been cleared.');
      }
    } catch (e) {
      _snack('An error occurred while clearing data: $e', err: true);
    }
  }

  /* misc helpers */
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Cannot open file', err: true);
    }
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: err ? Colors.red : null),
    );
  }

  /* drag & drop operations */
  Future<void> _moveFile(FileMeta file, String? targetFolderId) async {
    // Prevent moving a file to its current location
    if (file.folderId == targetFolderId) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();

    try {
      // 1. Define old and new paths for Storage and Firestore
      final oldStoragePath =
          file.folderId == null
              ? 'users/$uid/files/${file.name}'
              : 'users/$uid/folders/${file.folderId}/${file.name}';
      final newStoragePath =
          targetFolderId == null
              ? 'users/$uid/files/${file.name}'
              : 'users/$uid/folders/$targetFolderId/${file.name}';

      final oldDocRef =
          file.folderId == null
              ? FirebaseFirestore.instance.doc('users/$uid/files/${file.id}')
              : FirebaseFirestore.instance.doc(
                'users/$uid/folders/${file.folderId}/files/${file.id}',
              );

      // The new document will have a new ID
      final newDocRef =
          targetFolderId == null
              ? FirebaseFirestore.instance.collection('users/$uid/files').doc()
              : FirebaseFirestore.instance
                  .collection('users/$uid/folders/$targetFolderId/files')
                  .doc();

      // 2. Copy file in Firebase Storage if its path changes
      String newUrl;
      if (oldStoragePath != newStoragePath) {
        final oldStorageRef = FirebaseStorage.instance.ref(oldStoragePath);
        final newStorageRef = FirebaseStorage.instance.ref(newStoragePath);
        final data = await oldStorageRef.getData();
        if (data == null) throw Exception('Could not read original file data.');
        await newStorageRef.putData(data);
        newUrl = await newStorageRef.getDownloadURL();
      } else {
        newUrl = file.url; // URL doesn't change if path is the same
      }

      // 3. Create new Firestore document in a batch
      final newFileData = {
        'name': file.name,
        'size': file.size,
        'type': file.type,
        'url': newUrl,
        'uploadedAt': Timestamp.fromDate(
          file.uploadedAt,
        ), // Use original upload date
        'folderId': targetFolderId,
      };
      batch.set(newDocRef, newFileData);

      // 4. Delete old Firestore document in a batch
      batch.delete(oldDocRef);

      // 5. Commit Firestore changes
      await batch.commit();

      // 6. Delete old file from Storage (after Firestore is updated)
      if (oldStoragePath != newStoragePath) {
        await FirebaseStorage.instance.ref(oldStoragePath).delete();
      }

      _snack('File moved successfully.');

      // The UI will update via streams. We can clear the selection
      // or try to find the new file and select it. For now, just clear.
      if (mounted) {
        setState(() {
          _previewFile = null;
          // Optionally, select the folder the file was moved to
          if (targetFolderId != null) {
            final matchingFolders = _folders.where(
              (f) => f.id == targetFolderId,
            );
            _selectedFolder =
                matchingFolders.isNotEmpty ? matchingFolders.first : null;
          } else {
            _selectedFolder = null;
          }
        });
      }
    } catch (e) {
      _snack('Failed to move file: $e', err: true);
      // In a real app, you might want rollback logic here.
      // e.g., if Firestore commit fails, delete the copied storage file.
    }
  }

  Future<void> _moveFolder(String folderId, int newIndex) async {
    try {
      // For now, just show a message since folder reordering is complex
      // and would require updating all folder documents with new order
      _snack('Folder reordering coming soon!');
    } catch (e) {
      _snack('Failed to move folder: $e', err: true);
    }
  }

  void _trackDailyActivity() {
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    setState(() {
      _dailyActivity[key] = (_dailyActivity[key] ?? 0) + 1;
    });
    _syncDashboardToFirestore(); // <— quickly reflect daily activity blocks
  }

  // ====== Study Session Tracking ======
  void _startStudySession(String subject) {
    // End previous session first
    _endStudySession(flush: true);
    _currentStudySubject = subject;
    _currentStudyStart = DateTime.now();

    // Increment weekly performance session count
    final weekday = _weekdayKey(DateTime.now());
    _weeklyPerformance[weekday] = (_weeklyPerformance[weekday] ?? 0) + 1;
    _syncDashboardToFirestore();
  }

  void _endStudySession({bool flush = false}) {
    if (_currentStudyStart == null || _currentStudySubject == null) return;
    final elapsed =
        DateTime.now().difference(_currentStudyStart!).inSeconds / 3600.0;
    if (elapsed > 0) {
      _studyTimeBySubject[_currentStudySubject!] =
          (_studyTimeBySubject[_currentStudySubject!] ?? 0) + elapsed;
      _totalStudyTime = _studyTimeBySubject.values.fold<double>(
        0.0,
        (a, b) => a + b,
      );
    }
    _currentStudyStart = null;
    _currentStudySubject = null;
    if (flush) {
      _saveUserData();
      _syncDashboardToFirestore();
    }
  }

  void _startStudyTick() {
    _studyTickTimer?.cancel();
    _studyTickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Periodically accumulate partial time so dashboard feels live
      if (_currentStudyStart != null && _currentStudySubject != null) {
        // Preserve subject before ending (since _endStudySession clears it)
        final subject = _currentStudySubject!;
        _endStudySession(
          flush: false,
        ); // adds elapsed time without flushing to Firestore
        // Restart continuous session
        _currentStudySubject = subject;
        _currentStudyStart = DateTime.now();
        _syncDashboardToFirestore(); // now push updated cumulative study time
      }
    });
  }

  String _weekdayKey(DateTime dt) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[dt.weekday - 1];
  }

  String _deriveSubject(FileMeta file) {
    final ext = file.type.toLowerCase();
    if (ext == 'pdf') return 'Reading';
    if (ext == 'pptx') return 'Slides';
    if (ext == 'docx') return 'Docs';
    return 'Other';
  }
}
