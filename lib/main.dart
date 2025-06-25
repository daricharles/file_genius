// main.dart
import 'package:file_genius/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:file_picker/file_picker.dart';
import 'dash_board.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp(title: 'FileGenius'));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const LoginPage(),
    );
  }
}

/* ───────────────────────── HOME SCREEN ───────────────────────── */

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required String title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// List of folder names (for simple ordering)
  final List<String> folders = [];

  /// Actual files per folder (`folder → [filenames]`)
  final Map<String, List<String>> folderFiles = {};

  String? selectedFolder;

  // ───────────────── FILE PICK ─────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (!mounted || result == null) return;

    final fileName = result.files.single.name;

    if (selectedFolder != null) {
      // Attach file to the current folder
      setState(() => folderFiles[selectedFolder]!.add(fileName));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to $selectedFolder: $fileName')),
      );
    } else {
      // No folder selected – just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select (or create) a folder first')),
      );
    }
  }

  // ──────────────── CREATE FOLDER ───────────────
  void _createNewFolder() {
    String folderName = '';
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Folder'),
            content: TextField(
              autofocus: true,
              onChanged: (v) => folderName = v.trim(),
              decoration: const InputDecoration(hintText: 'Enter folder name'),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Cancel'),
              ),
              TextButton(
                child: const Text('Create'),
                onPressed: () {
                  if (folderName.isEmpty) return;
                  setState(() {
                    folders.add(folderName);
                    folderFiles[folderName] = [];
                    selectedFolder = folderName; // auto-select
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  // ────────────────────────── BUILD ──────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [_buildSidebar(), Expanded(child: _buildMainPane())]),
    );
  }

  /* ─────────────────────── SIDEBAR ─────────────────────── */
  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF4A789C),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📘 FileGenius',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          _hoverButton(
            icon: Icons.dashboard,
            label: 'Dashboard',
            color: const Color(0xFFFAF7FC),
            iconColor: const Color(0xFF634F96),
            labelStyle: const TextStyle(color: Color(0xFF634F96)),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Dashboard()),
                ),
          ),
          const SizedBox(height: 12),
          _hoverButton(
            icon: Icons.create_new_folder,
            label: 'New Folder',
            color: const Color(0xFF302942),
            iconColor: Colors.white,
            onTap: _createNewFolder,
          ),
          const SizedBox(height: 12),
          _hoverButton(
            icon: Icons.upload_file,
            label: 'Upload PDF',
            color: const Color(0xFF302942),
            iconColor: Colors.white,
            onTap: _pickFile,
          ),
          const SizedBox(height: 24),
          const Text(
            'Files & Folders',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Color(0xFFFAF7FC), thickness: 0.5),
          Expanded(child: _buildFolderList()),
          const Divider(color: Colors.white30),
          _buildUserBlock(),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    if (folders.isEmpty) {
      return const Center(
        child: Text('No folders yet', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (_, i) {
        final f = folders[i];
        final isSel = f == selectedFolder;
        return ListTile(
          leading: const Icon(Icons.folder, color: Colors.amber),
          title: Text(f, style: const TextStyle(color: Colors.white)),
          selected: isSel,
          selectedTileColor: Colors.deepPurple.shade200,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          onTap: () => setState(() => selectedFolder = f),
        );
      },
    );
  }

  Widget _buildUserBlock() {
    return Row(
      children: [
        const CircleAvatar(
          backgroundImage: AssetImage('assets/images/user.png'),
          radius: 16,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('John Doe', style: TextStyle(color: Colors.white)),
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                  ),
              child: const Text(
                'Upgrade plan',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
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
