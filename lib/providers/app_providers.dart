import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

// App State Provider
class AppStateProvider extends ChangeNotifier {
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
  Set<String> get collapsed => Set.unmodifiable(_collapsed);

  /// Initialize the provider
  Future<void> initialize() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      await _loadUserData();
    }
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Toggle sidebar
  void toggleSidebar() {
    _sidebarCollapsed = !_sidebarCollapsed;
    notifyListeners();
  }

  /// Show dashboard
  void openDashboard() {
    _showDashboard = true;
    _showUserProfile = false;
    _selectedFolder = null;
    _previewFile = null;
    notifyListeners();
  }

  /// Show user profile
  void openUserProfile() {
    _showUserProfile = true;
    _showDashboard = false;
    _selectedFolder = null;
    _previewFile = null;
    notifyListeners();
  }

  /// Select folder
  void selectFolder(Folder? folder) {
    _selectedFolder = folder;
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
    _selectedFolder = null;
    _previewFile = null;
    _showDashboard = false;
    _showUserProfile = false;
    _collapsed.clear();
    notifyListeners();
  }
}

// File Operations Provider
class FileOperationsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _loadingMessage = '';

  // Getters
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get loadingMessage => _loadingMessage;

  /// Create a new folder
  Future<Folder?> createFolder(String name, String userId) async {
    try {
      final folder = Folder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
      );

      await _firestore.collection('users/$userId/folders').doc(folder.id).set({
        'name': folder.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return folder;
    } catch (e) {
      debugPrint('Error creating folder: $e');
      return null;
    }
  }

  /// Delete a folder and all its contents
  Future<bool> deleteFolder(Folder folder, String userId) async {
    try {
      // Get all files in the folder
      final filesSnapshot =
          await _firestore
              .collection('users/$userId/folders/${folder.id}/files')
              .get();

      // Delete each file
      for (final doc in filesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the folder document
      await _firestore
          .collection('users/$userId/folders')
          .doc(folder.id)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting folder: $e');
      return false;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(FileMeta file, String userId) async {
    try {
      if (file.folderId != null) {
        await _firestore
            .doc('users/$userId/folders/${file.folderId}/files/${file.id}')
            .delete();
      } else {
        await _firestore.doc('users/$userId/files/${file.id}').delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Set upload state
  void setUploadState(bool uploading, [String message = '']) {
    _isUploading = uploading;
    _loadingMessage = message;
    if (!uploading) {
      _uploadProgress = 0.0;
    }
    notifyListeners();
  }

  /// Update upload progress
  void updateUploadProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }
}

// Error Handler Provider
class ErrorHandlerProvider extends ChangeNotifier {
  String? _errorMessage;
  String? _errorTitle;
  bool _showError = false;

  // Getters
  String? get errorMessage => _errorMessage;
  String? get errorTitle => _errorTitle;
  bool get showError => _showError;

  /// Show error
  void displayError(String title, String message) {
    _errorTitle = title;
    _errorMessage = message;
    _showError = true;
    notifyListeners();
  }

  /// Hide error
  void hideError() {
    _showError = false;
    _errorMessage = null;
    _errorTitle = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    _errorTitle = null;
    _showError = false;
    notifyListeners();
  }
}

// Multi-provider setup
List<ChangeNotifierProvider> get appProviders => [
  ChangeNotifierProvider<AppStateProvider>(create: (_) => AppStateProvider()),
  ChangeNotifierProvider<FileOperationsProvider>(
    create: (_) => FileOperationsProvider(),
  ),
  ChangeNotifierProvider<ErrorHandlerProvider>(
    create: (_) => ErrorHandlerProvider(),
  ),
];
