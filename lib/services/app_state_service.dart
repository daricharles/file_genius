import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';

/// Central service for managing application state
class AppStateService extends ChangeNotifier {
  // User state
  User? _user;
  String _userName = 'User';
  bool _isLoading = false;
  bool _hasLoadedUserData = false;

  // UI state
  bool _sidebarCollapsed = false;
  bool _showDashboard = false;
  bool _showUserProfile = false;
  Folder? _selectedFolder;
  FileMeta? _previewFile;

  // File management state
  final List<Folder> _folders = [];
  final List<FileMeta> _topLevelFiles = [];
  final Map<String, List<FileMeta>> _filesByFolder = {};
  final Set<String> _collapsed = {};

  // Getters
  User? get user => _user;
  String get userName => _userName;
  bool get isLoading => _isLoading;
  bool get hasLoadedUserData => _hasLoadedUserData;
  bool get sidebarCollapsed => _sidebarCollapsed;
  bool get showDashboard => _showDashboard;
  bool get showUserProfile => _showUserProfile;
  Folder? get selectedFolder => _selectedFolder;
  FileMeta? get previewFile => _previewFile;
  List<Folder> get folders => List.unmodifiable(_folders);
  List<FileMeta> get topLevelFiles => List.unmodifiable(_topLevelFiles);
  Map<String, List<FileMeta>> get filesByFolder =>
      Map.unmodifiable(_filesByFolder);
  Set<String> get collapsed => Set.unmodifiable(_collapsed);

  /// Initialize the service
  Future<void> initialize() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      await _loadUserData();
    }
  }

  /// Set loading state
  void setLoading(bool loading, {String? message}) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Toggle sidebar
  void toggleSidebar() {
    _sidebarCollapsed = !_sidebarCollapsed;
    notifyListeners();
  }

  /// Show dashboard
  void setDashboardVisible() {
    _showDashboard = true;
    _showUserProfile = false;
    _selectedFolder = null;
    _previewFile = null;
    notifyListeners();
  }

  /// Show user profile
  void setUserProfileVisible() {
    _showUserProfile = true;
    _showDashboard = false;
    _selectedFolder = null;
    _previewFile = null;
    notifyListeners();
  }

  /// Select folder
  void selectFolder(String? folderId) {
    if (folderId == null) {
      _selectedFolder = null;
    } else {
      _selectedFolder = _folders.firstWhere((f) => f.id == folderId);
    }
    _previewFile = null;
    _showDashboard = false;
    _showUserProfile = false;
    notifyListeners();
  }

  /// Select file
  void selectFile(FileMeta? file) {
    _previewFile = file;
    _showDashboard = false;
    _showUserProfile = false;
    notifyListeners();
  }

  /// Toggle folder collapse
  void toggleFolderCollapse(String folderId) {
    if (_collapsed.contains(folderId)) {
      _collapsed.remove(folderId);
    } else {
      _collapsed.add(folderId);
    }
    notifyListeners();
  }

  /// Update folders
  void updateFolders(List<Folder> folders) {
    _folders.clear();
    _folders.addAll(folders);
    notifyListeners();
  }

  /// Update top level files
  void updateTopLevelFiles(List<FileMeta> files) {
    _topLevelFiles.clear();
    _topLevelFiles.addAll(files);
    notifyListeners();
  }

  /// Update files by folder
  void updateFilesByFolder(String folderId, List<FileMeta> files) {
    _filesByFolder[folderId] = files;
    notifyListeners();
  }

  /// Get visible files based on current selection
  List<FileMeta> getVisibleFiles() {
    if (_selectedFolder == null) {
      return _topLevelFiles;
    }
    return _filesByFolder[_selectedFolder!.id] ?? [];
  }

  /// Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_user == null) return;

    setLoading(true);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        _userName = data['displayName'] ?? data['userName'] ?? 'User';
        _hasLoadedUserData = true;
      } else {
        _hasLoadedUserData = true;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Clear all state
  void clearState() {
    _folders.clear();
    _topLevelFiles.clear();
    _filesByFolder.clear();
    _collapsed.clear();
    _selectedFolder = null;
    _previewFile = null;
    _showDashboard = false;
    _showUserProfile = false;
    notifyListeners();
  }
}
