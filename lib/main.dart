// lib/main.dart
//
// Root:  FileGeniusSidebar  ⇆  MainPane  +  FileViewer
// -----------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load();

  // Register WebView platform for web
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  runApp(const FileGeniusApp());
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
  /* ── reactive state ───────────────────────────────────────── */
  final List<Folder> _folders = [];
  final List<FileMeta> _topLevelFiles = [];
  final Map<String, List<FileMeta>> _filesByFolder = {};
  final Set<String> _collapsed = {};

  Folder? _selectedFolder; // highlighted in tree
  FileMeta? _previewFile; // shown in right‑hand viewer
  List<StreamSubscription> _folderSubs = [];
  StreamSubscription? _foldersSubscription;
  StreamSubscription? _topLevelFilesSubscription;
  bool _sidebarCollapsed = false;
  bool _showDashboard = false;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _loadingMessage = '';

  // Badge tracking
  int _filesUploaded = 0;
  int _aiChatInteractions = 0;
  int _questionsAnswered = 0;
  int _correctAnswers = 0;
  int _loginDays = 0;
  DateTime? _lastLoginDate;

  // Enhanced Analytics for Phase 2
  int _totalPoints = 0;
  int _weeklyUploads = 0;
  int _monthlyUploads = 0;
  Map<String, int> _fileTypeStats = {};
  Map<String, int> _dailyActivity = {};
  List<String> _unlockedBadges = [];
  List<String> _recentAchievements = [];

  // User data
  String _userName = 'User';

  // Periodic backup timer
  Timer? _backupTimer;

  /* ── life‑cycle ───────────────────────────────────────────── */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachFirestoreStreams();
    _loadBadgeProgress();
    _loadUserData();
    _trackLoginDay();

    // Set up periodic backup every 5 minutes
    _backupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _backupAllProgressData(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backupTimer?.cancel();
    _foldersSubscription?.cancel();
    _topLevelFilesSubscription?.cancel();
    for (final s in _folderSubs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Backup data when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _backupAllProgressData();
    }
  }

  /* ── Firestore listeners ──────────────────────────────────── */
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

  /* ── helpers ──────────────────────────────────────────────── */
  List<FileMeta> get _visibleFiles =>
      _selectedFolder == null
          ? _topLevelFiles
          : (_filesByFolder[_selectedFolder!.id] ?? []);

  void _clearPreview() => setState(() => _previewFile = null);

  /* ── User Data Loading ────────────────────────────────────── */
  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        setState(() {
          _userName = data['displayName'] ?? data['fullName'] ?? 'User';
        });
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  /* ── AI Interaction Method for Real File-Based Chat ──────── */
  void onAIInteractionSuccess() {
    // This method will be called from the AI chat widget when a successful interaction occurs
    _incrementAiChatInteraction();
    _snack('AI interaction recorded! +5 points for file analysis');
  }

  /* ── Badge Progress Tracking ──────────────────────────────── */
  Future<void> _loadBadgeProgress() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('settings')
              .doc('badge_progress')
              .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _filesUploaded = data['filesUploaded'] ?? 0;
          _aiChatInteractions = data['aiChatInteractions'] ?? 0;
          _questionsAnswered = data['questionsAnswered'] ?? 0;
          _correctAnswers = data['correctAnswers'] ?? 0;
          _loginDays = data['loginDays'] ?? 0;
          _totalPoints = data['totalPoints'] ?? 0;
          _weeklyUploads = data['weeklyUploads'] ?? 0;
          _monthlyUploads = data['monthlyUploads'] ?? 0;
          _fileTypeStats = Map<String, int>.from(data['fileTypeStats'] ?? {});
          _dailyActivity = Map<String, int>.from(data['dailyActivity'] ?? {});
          _unlockedBadges = List<String>.from(data['unlockedBadges'] ?? []);
          _recentAchievements = List<String>.from(
            data['recentAchievements'] ?? [],
          );
          if (data['lastLoginDate'] != null) {
            _lastLoginDate = (data['lastLoginDate'] as Timestamp).toDate();
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load badge progress: $e');
    }
  }

  Future<void> _updateBadgeProgress(Map<String, dynamic> updates) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('badge_progress')
          .set(updates, SetOptions(merge: true));
      debugPrint('✅ Badge progress updated: ${updates.keys.join(', ')}');
    } catch (e) {
      debugPrint('Failed to update badge progress: $e');
    }
  }

  // Comprehensive backup of all user progress data
  Future<void> _backupAllProgressData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final allData = {
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
        'lastLoginDate':
            _lastLoginDate != null ? Timestamp.fromDate(_lastLoginDate!) : null,
        'lastBackupDate': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('badge_progress')
          .set(allData);

      debugPrint('✅ Complete progress data backed up successfully');
    } catch (e) {
      debugPrint('Failed to backup complete progress data: $e');
    }
  }

  void _trackLoginDay() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_lastLoginDate == null) {
      // First login
      setState(() {
        _loginDays = 1;
        _lastLoginDate = todayDate;
      });
      _updateBadgeProgress({
        'loginDays': _loginDays,
        'lastLoginDate': Timestamp.fromDate(todayDate),
      });
      _calculatePoints('daily_login');
    } else {
      final lastDate = DateTime(
        _lastLoginDate!.year,
        _lastLoginDate!.month,
        _lastLoginDate!.day,
      );
      final daysDifference = todayDate.difference(lastDate).inDays;

      if (daysDifference == 1) {
        // Consecutive day
        setState(() {
          _loginDays++;
          _lastLoginDate = todayDate;
        });
        _updateBadgeProgress({
          'loginDays': _loginDays,
          'lastLoginDate': Timestamp.fromDate(todayDate),
        });
        _calculatePoints('daily_login');
        _calculatePoints('streak_bonus');
      } else if (daysDifference > 1) {
        // Streak broken, reset
        setState(() {
          _loginDays = 1;
          _lastLoginDate = todayDate;
        });
        _updateBadgeProgress({
          'loginDays': _loginDays,
          'lastLoginDate': Timestamp.fromDate(todayDate),
        });
        _calculatePoints('daily_login');
      }
      // If daysDifference == 0, it's the same day, no update needed
    }

    // Backup all progress data when user logs in
    _backupAllProgressData();
  }

  void _incrementFileUploaded() {
    setState(() {
      _filesUploaded++;
    });

    // Track file type statistics
    final today = DateTime.now().toString().substring(0, 10);
    setState(() {
      _dailyActivity[today] = (_dailyActivity[today] ?? 0) + 1;
      _weeklyUploads++;
      _monthlyUploads++;
    });

    // Immediate persistence of all file-related data
    _updateBadgeProgress({
      'filesUploaded': _filesUploaded,
      'dailyActivity': _dailyActivity,
      'weeklyUploads': _weeklyUploads,
      'monthlyUploads': _monthlyUploads,
    });
    _calculatePoints('file_upload');
    _checkForNewAchievements();
  }

  void _incrementAiChatInteraction() {
    setState(() {
      _aiChatInteractions++;
    });
    // Immediate persistence
    _updateBadgeProgress({'aiChatInteractions': _aiChatInteractions});
    _calculatePoints('ai_chat');
    _checkForNewAchievements();
  }

  /* ── Points & Achievements System ─────────────────────────── */
  void _calculatePoints(String action) {
    int points = 0;
    switch (action) {
      case 'file_upload':
        points = 10;
        break;
      case 'ai_chat':
        points = 5;
        break;
      case 'correct_answer':
        points = 15;
        break;
      case 'answer_attempt':
        points = 2;
        break;
      case 'daily_login':
        points = 5;
        break;
      case 'streak_bonus':
        points = _loginDays * 2; // Bonus points for streaks
        break;
    }

    setState(() {
      _totalPoints += points;
    });

    // Immediate persistence of points
    _updateBadgeProgress({'totalPoints': _totalPoints});
  }

  void _checkForNewAchievements() {
    List<String> newAchievements = [];

    // File upload achievements
    if (_filesUploaded == 1 && !_unlockedBadges.contains('first_file')) {
      newAchievements.add('first_file');
      _showAchievementNotification('First File Uploaded!', Icons.upload_file);
    }
    if (_filesUploaded == 10 && !_unlockedBadges.contains('file_master')) {
      newAchievements.add('file_master');
      _showAchievementNotification('File Master!', Icons.folder);
    }
    if (_filesUploaded == 50 && !_unlockedBadges.contains('file_expert')) {
      newAchievements.add('file_expert');
      _showAchievementNotification('File Expert!', Icons.workspace_premium);
    }

    // Login streak achievements
    if (_loginDays == 7 && !_unlockedBadges.contains('week_warrior')) {
      newAchievements.add('week_warrior');
      _showAchievementNotification('Week Warrior!', Icons.emoji_events);
    }
    if (_loginDays == 30 && !_unlockedBadges.contains('month_master')) {
      newAchievements.add('month_master');
      _showAchievementNotification('Month Master!', Icons.stars);
    }

    // Points achievements
    if (_totalPoints >= 100 && !_unlockedBadges.contains('century_club')) {
      newAchievements.add('century_club');
      _showAchievementNotification('Century Club!', Icons.military_tech);
    }
    if (_totalPoints >= 500 && !_unlockedBadges.contains('point_prodigy')) {
      newAchievements.add('point_prodigy');
      _showAchievementNotification('Point Prodigy!', Icons.diamond);
    }

    if (newAchievements.isNotEmpty) {
      setState(() {
        _unlockedBadges.addAll(newAchievements);
        _recentAchievements.addAll(newAchievements);
        // Keep only last 5 recent achievements
        if (_recentAchievements.length > 5) {
          _recentAchievements = _recentAchievements.sublist(
            _recentAchievements.length - 5,
          );
        }
      });

      // Immediate persistence of badge progress
      _updateBadgeProgress({
        'unlockedBadges': _unlockedBadges,
        'recentAchievements': _recentAchievements,
      });
    }
  }

  void _showAchievementNotification(String title, IconData icon) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              AchievementDialog(title: title, icon: icon, points: _totalPoints),
    );
  }

  /* ── UI build ─────────────────────────────────────────────── */
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
            }),
        onSelectAnyFile:
            (file) => setState(() {
              _previewFile = file;
              _showDashboard = false;
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
      );

      /* Main content area */
      Widget content;
      if (_showDashboard) {
        content = DashboardScreen(
          filesUploaded: _filesUploaded,
          aiChatInteractions: _aiChatInteractions,
          questionsAnswered: _questionsAnswered,
          correctAnswers: _correctAnswers,
          loginDays: _loginDays,
          totalPoints: _totalPoints,
          weeklyUploads: _weeklyUploads,
          monthlyUploads: _monthlyUploads,
          fileTypeStats: _fileTypeStats,
          dailyActivity: _dailyActivity,
          unlockedBadges: _unlockedBadges,
          recentAchievements: _recentAchievements,
          userName: _userName,
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
        );
      } else if (_previewFile != null) {
        content = MainPane(
          selectedFolder: _selectedFolder,
          files: _visibleFiles,
          onPickFiles: _pickFiles,
          onDropFiles: (fs) => _handleDroppedFiles(fs, _selectedFolder),
          onOpenUrl: _openUrl,
          previewFile: _previewFile,
          onSelectFile: (file) => setState(() => _previewFile = file),
          onDeleteFile: _handleDeleteFile,
          onAIInteractionSuccess: onAIInteractionSuccess,
        );
      } else if (_selectedFolder != null) {
        content = MainPane(
          selectedFolder: _selectedFolder,
          files: _visibleFiles,
          onPickFiles: _pickFiles,
          onDropFiles: (fs) => _handleDroppedFiles(fs, _selectedFolder),
          onOpenUrl: _openUrl,
          previewFile: _previewFile,
          onSelectFile: (file) => setState(() => _previewFile = file),
          onDeleteFile: _handleDeleteFile,
          onAIInteractionSuccess: onAIInteractionSuccess,
        );
      } else {
        // Show welcome/upload screen (no folder or file selected)
        content = MainPane(
          selectedFolder: null,
          files: const [],
          onPickFiles: _pickFiles,
          onDropFiles: (fs) => _handleDroppedFiles(fs, null),
          onOpenUrl: _openUrl,
          previewFile: null,
          onSelectFile: (file) => setState(() => _previewFile = file),
          onDeleteFile: _handleDeleteFile,
          onAIInteractionSuccess: onAIInteractionSuccess,
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
            floatingActionButton: null, // Removed demo buttons
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

  /* ── folder creation dialog ───────────────────────────────── */
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

  /* ── file picker & uploads ───────────────────────────────── */
  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'pptx', 'docx'],
    );
    if (res != null) _handleDroppedFiles(res.files, _selectedFolder);
  }

  Future<void> _handleDroppedFiles(
    List<PlatformFile> dropped,
    Folder? target,
  ) async {
    if (dropped.isEmpty) return;
    final folderId = target?.id; // null → top level

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _loadingMessage = 'Uploading files...';
    });

    // optimistic UI
    final stubs = dropped.map(
      (p) => FileMeta(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: p.name,
        size: p.size,
        url: 'uploading…',
        type: p.extension ?? '',
        uploadedAt: DateTime.now(),
        folderId: folderId,
      ),
    );

    if (mounted) {
      setState(() {
        if (folderId == null) {
          _topLevelFiles.addAll(stubs);
        } else {
          _filesByFolder.putIfAbsent(folderId, () => []).addAll(stubs);
        }
      });
    }

    // real upload
    int completed = 0;
    for (final p in dropped) {
      try {
        final meta = await _uploadOne(pFile: p, folderId: folderId);
        _replaceStub(meta);
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

    _snack('$completed file(s) uploaded successfully');
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

    // Track badge progress
    _incrementFileUploaded();

    return result;
  }

  void _replaceStub(FileMeta real) {
    if (mounted) {
      setState(() {
        final list =
            real.folderId == null
                ? _topLevelFiles
                : _filesByFolder[real.folderId]!;
        final idx = list.indexWhere((m) => m.name == real.name);
        if (idx != -1) list[idx] = real;
      });
    }
  }

  /* ── data deletion & modification ─────────────────────────── */

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

  /* ── misc helpers ─────────────────────────────────────────── */
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

  /* ── drag & drop operations ─────────────────────────────── */
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
}
