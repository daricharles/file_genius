import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'constants.dart';
import 'models.dart';

/// Pure UI – no Firebase calls.
class FileGeniusSidebar extends StatelessWidget {
  const FileGeniusSidebar({
    super.key,
    // data
    required this.folders,
    required this.topLevelFiles,
    required this.filesByFolder,
    required this.selectedFolderId,
    required this.collapsed,

    // callbacks
    required this.onDashboardTap,
    required this.onCreateFolder,
    required this.onUploadFile,
    required this.onToggleFolder,
    required this.onSelectFolder, // nullable id (= select a folder)
    this.onSelectTopFile, // top‑level file click (now optional)
    this.onSelectAnyFile, // fires for *any* file
    required this.onSignOut,
    required this.onUpgradePlan,
  });

  // ───────── DATA ─────────
  final List<Folder> folders;
  final List<FileMeta> topLevelFiles;
  final Map<String, List<FileMeta>> filesByFolder;
  final String? selectedFolderId;
  final Set<String> collapsed; // folder‑ids

  // ───────── CALLBACKS ─────────
  final VoidCallback onDashboardTap;
  final VoidCallback onCreateFolder;
  final VoidCallback onUploadFile;
  final void Function(String folderId) onToggleFolder;
  final void Function(String? folderId) onSelectFolder;
  final void Function(FileMeta file)? onSelectTopFile;
  final void Function(FileMeta file)? onSelectAnyFile; // 🔸 optional
  final VoidCallback onSignOut;
  final VoidCallback onUpgradePlan;

  // ────────────────────────────────────────── UI tree
  @override
  Widget build(BuildContext context) => Container(
    width: kSidebarW,
    color: Colors.grey.shade100,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AppHeader(),

        // Core nav
        _SidebarButton(
          icon: Icons.dashboard,
          label: 'Dashboard',
          onTap: onDashboardTap,
        ),
        _SidebarButton(
          icon: Icons.create_new_folder,
          label: 'New Folder',
          onTap: onCreateFolder,
        ),
        _SidebarButton(
          icon: Icons.upload_file,
          label: 'Upload File',
          onTap: onUploadFile,
        ),

        const Divider(),
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 8),
          child: Text('Files & Folders', style: TextStyle(color: Colors.grey)),
        ),

        // Scrollable tree
        Expanded(
          child: ListView(
            children: [
              // 1) top‑level (un‑foldered) files
              ...topLevelFiles.map(_topFileTile),

              // 2) user folders with nested files
              ...folders.map((f) => _buildFolderTile(context, f)),
            ],
          ),
        ),

        const Divider(),
        _UserSection(onSignOut: onSignOut, onUpgradePlan: onUpgradePlan),
      ],
    ),
  );

  //──────────────────  Tiles  ──────────────────
  Widget _buildFolderTile(BuildContext context, Folder folder) {
    final isCollapsed = collapsed.contains(folder.id);
    final isSelected = selectedFolderId == folder.id;
    final kids = filesByFolder[folder.id] ?? const <FileMeta>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.folder),
          title: Text(folder.name),
          trailing:
              kids.isEmpty
                  ? null
                  : Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_right
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
          tileColor: isSelected ? kHover : null,
          onTap: () => onSelectFolder(folder.id),
          onLongPress: kids.isEmpty ? null : () => onToggleFolder(folder.id),
        ),

        if (!isCollapsed && kids.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children:
                  kids
                      .map(
                        (f) => ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.insert_drive_file_outlined,
                            size: 18,
                          ),
                          title: Text(
                            f.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () {
                            onSelectAnyFile?.call(f);
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
      ],
    );
  }

  /// Top‑level file (no folder)
  Widget _topFileTile(FileMeta f) => ListTile(
    dense: true,
    leading: const Icon(Icons.insert_drive_file_outlined, size: 18),
    title: Text(f.name, style: const TextStyle(fontSize: 13)),
    onTap: () {
      // new unified callback
      onSelectAnyFile?.call(f);
      // legacy callback (optional)
      onSelectTopFile?.call(f);
    },
  );
}

/*────────────────── cosmetics ──────────────────*/
class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        const Icon(Icons.book, color: kBrand, size: 28),
        const SizedBox(width: 8),
        Text(
          'FileGenius',
          style: Theme.of(
            ctx,
          ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: kBrand),
    title: Text(label),
    onTap: onTap,
    hoverColor: kHover,
  );
}

class _UserSection extends StatelessWidget {
  const _UserSection({required this.onSignOut, required this.onUpgradePlan});
  final VoidCallback onSignOut;
  final VoidCallback onUpgradePlan;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: kBrand,
            child: Text(
              (user?.displayName?.isNotEmpty == true
                      ? user!.displayName![0]
                      : 'U')
                  .toUpperCase(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.displayName ?? user?.email ?? 'User',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: onUpgradePlan,
            child: const Text('Upgrade plan'),
          ),
          OutlinedButton(onPressed: onSignOut, child: const Text('Sign out')),
        ],
      ),
    );
  }
}
