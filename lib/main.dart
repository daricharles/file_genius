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

class _HomeScreenState extends State<HomeScreen> {
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

  /* ── life‑cycle ───────────────────────────────────────────── */
  @override
  void initState() {
    super.initState();
    _attachFirestoreStreams();
  }

  @override
  void dispose() {
    _foldersSubscription?.cancel();
    _topLevelFilesSubscription?.cancel();
    for (final s in _folderSubs) {
      s.cancel();
    }
    super.dispose();
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
        onDashboardTap: () => _snack('Dashboard (todo)'),
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
            }),
        onSelectAnyFile: (file) => setState(() => _previewFile = file),
        onSignOut: () async => FirebaseAuth.instance.signOut(),
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
      if (_previewFile != null) {
        content = MainPane(
          selectedFolder: _selectedFolder,
          files: _visibleFiles,
          onPickFiles: _pickFiles,
          onDropFiles: (fs) => _handleDroppedFiles(fs, _selectedFolder),
          onOpenUrl: _openUrl,
          previewFile: _previewFile,
          onSelectFile: (file) => setState(() => _previewFile = file),
          onDeleteFile: _handleDeleteFile,
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
        );
      }

      return Scaffold(
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

                  final f = Folder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                  );
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  await _safeSet(
                    FirebaseFirestore.instance.doc(
                      'users/$uid/folders/${f.id}',
                    ),
                    {'name': f.name, 'createdAt': FieldValue.serverTimestamp()},
                  );
                  if (mounted) {
                    setState(() {
                      _folders.add(f);
                      _selectedFolder = f;
                      _clearPreview();
                    });
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
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
    for (final p in dropped) {
      try {
        final meta = await _uploadOne(pFile: p, folderId: folderId);
        _replaceStub(meta);
      } catch (e) {
        _snack('Failed to upload ${p.name}: $e', err: true);
      }
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

    return FileMeta(
      id: doc.id,
      name: pFile.name,
      size: pFile.size,
      url: downloadUrl,
      type: pFile.extension ?? '',
      uploadedAt: DateTime.now(),
      folderId: folderId,
    );
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
      await _deleteFile(file);
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
      await _deleteFolder(folder);
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
      await _performClearAllData();
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
