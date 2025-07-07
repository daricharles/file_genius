// main.dart
//
// Root file – wires Sidebar, MainPane and DragDropZone together.
// Make sure you have created:
//
//   • constants.dart  → kBrand, kHover, kSidebarW
//   • sideBar.dart    → SideBar     widget (from our earlier step)
//   • mainPane.dart   → MainPane    widget (uses DragDropZone)
//   • dragDropZone.dart → DragDropZone widget
//
// Firebase is initialized, an auth‑gate shows LoginPage if not signed‑in.

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

// UI pieces you split out
import 'side_bar.dart';
import 'constants.dart';
import 'login_page.dart'; // your login screen // Make sure this file exists and exports SideBar
import 'main_pane.dart';
import 'models.dart';

// ──────────────────────────────────────────────────────────────────────────
//  Entry‑point
// ──────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FileGeniusApp());
}

// ──────────────────────────────────────────────────────────────────────────
//  Root – Auth‑gate
// ──────────────────────────────────────────────────────────────────────────

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

// ──────────────────────────────────────────────────────────────────────────
//  HomeScreen – holds the state (folders / files) and handlers
// ──────────────────────────────────────────────────────────────────────────

enum HoverTarget { dashboard, newFolder, upload }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /* ───── in‑memory state ───── */
  final List<Folder> _folders = [];
  final Map<String, List<FileMeta>> _filesByFolder = {};
  Folder? _selected;

  /* convenience */
  List<FileMeta> get _selectedFiles =>
      _selected == null ? const [] : (_filesByFolder[_selected!.id] ?? []);

  // ──────────────────────────────────────────────────  UI  ──────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, limits) {
        final compact = limits.maxWidth < 700;

        final sidebar = FileGeniusSidebar(
          folders: _folders,
          filesByFolder: _filesByFolder,
          selectedFolderId: _selected?.id,
          collapsed: {/* your collapsed set if needed */},
          onDashboardTap: () => _showSnack('Dashboard (todo)'),
          onCreateFolder: _handleCreateFolder,
          onUploadFile: _pickFiles,
          onToggleFolder: (id) {
            /* your logic */
          },
          onSelectFolder: (id) {
            /* your logic */
          },
          onSignOut: () async => FirebaseAuth.instance.signOut(),
          onUpgradePlan: () {
            /* your logic */
          },
        );

        final mainPane = MainPane(
          selectedFolder: _selected,
          files: _selectedFiles,
          onPickFiles: _pickFiles,
          onDropFiles: (files) => _handleDroppedFiles(files, _selected),
          onOpenUrl: _openFile,
        );

        return Scaffold(
          drawer: compact ? Drawer(child: sidebar) : null,
          body:
              compact
                  ? mainPane
                  : Row(
                    children: [
                      sidebar,
                      const VerticalDivider(width: 1),
                      Expanded(child: mainPane),
                    ],
                  ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────  Folder creation
  void _handleCreateFolder() {
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

                  // optimistic UI
                  setState(() {
                    _folders.add(f);
                    _selected = f;
                  });
                  Navigator.pop(context);

                  // persist
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance
                      .doc('users/$uid/folders/${f.id}')
                      .set({
                        'name': f.name,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  // ──────────────────────────────────────────────────  File picker
  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'pptx', 'docx'],
    );
    if (res != null) _handleDroppedFiles(res.files, _selected);
  }

  // ──────────────────────────────────────────────────  Handle dropped files
  Future<void> _handleDroppedFiles(
    List<PlatformFile> dropped,
    Folder? target,
  ) async {
    if (dropped.isEmpty) return;

    target ??=
        _selected ??
        (_folders.isEmpty
            ? (_folders..add(Folder(id: '_root', name: 'Root'))).first
            : _folders.first);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final pathPrefix = 'users/$uid/folders/${target.id}';

    // optimistic placeholders
    final plats =
        dropped
            .map(
              (p) => FileMeta(
                name: p.name,
                size: p.size,
                url: 'uploading…',
                type: p.extension ?? '',
                uploadedAt: DateTime.now(),
              ),
            )
            .toList();

    setState(() {
      _filesByFolder.putIfAbsent(target!.id, () => []).addAll(plats);
      _selected = target;
    });

    // upload each
    for (final file in dropped) {
      try {
        final ref = FirebaseStorage.instance.ref('$pathPrefix/${file.name}');
        UploadTask task;
        if (file.bytes != null) {
          task = ref.putData(file.bytes!);
        } else {
          task = ref.putFile(File(file.path!));
        }

        final snap = await task;
        final url = await snap.ref.getDownloadURL();

        final meta = FileMeta(
          name: file.name,
          size: file.size,
          url: url,
          type: file.extension ?? '',
          uploadedAt: DateTime.now(),
        );

        // replace placeholder
        setState(() {
          final list = _filesByFolder[target!.id]!;
          final idx = list.indexWhere((m) => m.name == file.name);
          if (idx != -1) list[idx] = meta;
        });

        await FirebaseFirestore.instance
            .doc('users/$uid/folders/${target.id}')
            .collection('files')
            .add({
              'name': meta.name,
              'size': meta.size,
              'type': meta.type,
              'url': meta.url,
              'uploadedAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        _showSnack('Failed to upload ${file.name}: $e', isErr: true);
      }
    }
  }

  // ──────────────────────────────────────────────────  Helpers
  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Cannot open file', isErr: true);
    }
  }

  void _showSnack(String msg, {bool isErr = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isErr ? Colors.red : null),
    );
  }
}
