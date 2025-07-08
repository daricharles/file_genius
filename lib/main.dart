// lib/main.dart
//
// Root:  FileGeniusSidebar  ⇆  MainPane  +  FileViewer
// -----------------------------------------------------

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

// UI
import 'constants.dart';
import 'login_page.dart';
import 'side_bar.dart';
import 'main_pane.dart';
import 'file_viewer.dart';
import 'models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FileGeniusApp());
}

/*──────────────────────────  Auth‑gate  ──────────────────────────*/
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

/*──────────────────────────  Home  ───────────────────────────────*/
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
  late final List<StreamSubscription> _folderSubs;

  /* ── life‑cycle ───────────────────────────────────────────── */
  @override
  void initState() {
    super.initState();
    _folderSubs = [];
    _attachFirestoreStreams();
  }

  @override
  void dispose() {
    for (final s in _folderSubs) {
      s.cancel();
    }
    super.dispose();
  }

  /* ── Firestore listeners ──────────────────────────────────── */
  void _attachFirestoreStreams() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // folders
    FirebaseFirestore.instance
        .collection('users/$uid/folders')
        .orderBy('createdAt')
        .snapshots()
        .listen((q) {
          setState(() {
            _folders
              ..clear()
              ..addAll(q.docs.map(Folder.fromDoc));
          });
          _rebindFolderFileStreams();
        });

    // top‑level files
    FirebaseFirestore.instance
        .collection('users/$uid/files')
        .orderBy('uploadedAt')
        .snapshots()
        .listen((q) {
          setState(() {
            _topLevelFiles
              ..clear()
              ..addAll(q.docs.map(FileMeta.fromDoc));
          });
        });
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
              .listen(
                (q) => setState(
                  () =>
                      _filesByFolder[f.id] =
                          q.docs.map(FileMeta.fromDoc).toList(),
                ),
              );
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
              _clearPreview();
            }),
        // click on a top‑level file → preview it
        onSelectTopFile: (f) => setState(() => _previewFile = f),

        onSignOut: () async => FirebaseAuth.instance.signOut(),
        onUpgradePlan: () => _snack('Upgrade plan (todo)'),
      );

      /* Main list pane (left side of the content area) */
      final listPane = MainPane(
        selectedFolder: _selectedFolder,
        files: _visibleFiles,
        onPickFiles: _pickFiles,
        onDropFiles: (fs) => _handleDroppedFiles(fs, _selectedFolder),
        onOpenUrl: _openUrl,
      );

      /* Optional right‑hand preview */
      Widget content;
      if (_previewFile == null) {
        content = listPane;
      } else {
        // split the space: 50  % list / 50  % viewer
        content = Row(
          children: [
            Expanded(child: listPane),
            const VerticalDivider(width: 1),
            Expanded(
              child: FileViewer(
                url: _previewFile!.url,
                type: _previewFile!.type.toLowerCase(),
              ),
            ),
          ],
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
                  setState(() {
                    _folders.add(f);
                    _selectedFolder = f;
                    _clearPreview();
                  });
                  Navigator.pop(context);

                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  await _safeSet(
                    FirebaseFirestore.instance.doc(
                      'users/$uid/folders/${f.id}',
                    ),
                    {'name': f.name, 'createdAt': FieldValue.serverTimestamp()},
                  );
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

    setState(() {
      if (folderId == null) {
        _topLevelFiles.addAll(stubs);
      } else {
        _filesByFolder.putIfAbsent(folderId, () => []).addAll(stubs);
      }
    });

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

    final snap =
        await (pFile.bytes != null
            ? ref.putData(pFile.bytes!)
            : ref.putFile(File(pFile.path!)));
    final url = await snap.ref.getDownloadURL();

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
      'url': url,
      'uploadedAt': FieldValue.serverTimestamp(),
      'folderId': folderId,
    });

    return FileMeta(
      id: doc.id,
      name: pFile.name,
      size: pFile.size,
      url: url,
      type: pFile.extension ?? '',
      uploadedAt: DateTime.now(),
      folderId: folderId,
    );
  }

  void _replaceStub(FileMeta real) {
    setState(() {
      final list =
          real.folderId == null
              ? _topLevelFiles
              : _filesByFolder[real.folderId]!;
      final idx = list.indexWhere((m) => m.name == real.name);
      if (idx != -1) list[idx] = real;
    });
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

  Future<void> _safeSet(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {
    try {
      await ref.set(data);
      debugPrint('✅ wrote to ${ref.path}');
    } catch (e, st) {
      debugPrint('❌ Firestore write failed: $e\n$st');
      rethrow; // still bubble up to UI snackbar
    }
  }
}
