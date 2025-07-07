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
            ),
          ],
        ),
      ],
    );
  }

  /* ──────────────────── MAIN PANE ──────────────────── */
  Widget _buildMainPane() {
    // Nothing selected yet
    if (selectedFolder == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.folder_open, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('No folder selected.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // A folder is selected → show split panel
    return Row(
      children: [
        // Left: list of files in this folder (+ upload zone)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              DottedBorderBox(onPressed: _pickFile),
              const SizedBox(height: 8),
              Expanded(child: _buildFileList(selectedFolder!)),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: placeholder chat/preview panel
        Expanded(
          flex: 2,
          child: Center(
            child:
                folderFiles[selectedFolder]!.isEmpty
                    ? const Text(
                      'No PDFs yet',
                      style: TextStyle(color: Colors.black54),
                    )
                    : const Text('Chat panel – coming soon'),
          ),
        ),
      ],
    );
  }

  Widget _buildFileList(String folder) {
    final files = folderFiles[folder]!;
    if (files.isEmpty) {
      return const Center(
        child: Text('Empty folder', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      itemCount: files.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder:
          (_, i) => ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            title: Text(files[i]),
            dense: true,
          ),
    );
  }

  /* ──────────────────── HOVER BUTTON ─────────────────── */
  Widget _hoverButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
    TextStyle? labelStyle,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool hover = false;
        /* ───── inside _hoverButton (replace the AnimatedContainer build) ───── */
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hover = true),
          onExit: (_) => setState(() => hover = false),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: hover ? color.withAlpha((0.85 * 255).round()) : color,
                borderRadius: BorderRadius.circular(8),
                boxShadow:
                    hover
                        ? [
                          const BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                        : [],
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: labelStyle ?? const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ────────────────── DOTTED BORDER BOX ────────────────── */

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black45,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cloud_upload, size: 36, color: Colors.black54),
            SizedBox(height: 8),
            Text(
              'Drag & drop your files here',
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 4),
            Text('or'),
            SizedBox(height: 4),
            Text(
              'Click to upload',
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ────────────── Dummy “Upgrade plan” page ────────────── */
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: const Center(child: Text('Choose a plan – coming soon')),
    );
  }
}
