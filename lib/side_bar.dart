import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart'; // in side_bar.dart
import 'models.dart';

/// -----------------------------------------------------------------///
/// Sidebar ✨
/// -----------------------------------------------------------------///
/// * `folders`              – List of user folders
// ignore: unintended_html_in_doc_comment
/// * `filesByFolder`        – Map<folderId, List<FileMeta>> for nesting
/// * `selectedFolderId`     – Currently highlighted folder
// ignore: unintended_html_in_doc_comment
/// * `collapsed`            – Set<folderId> that are collapsed
/// * Callbacks for user actions (create, upload, select,…)
class FileGeniusSidebar extends StatelessWidget {
  const FileGeniusSidebar({
    super.key,
    required this.folders,
    required this.filesByFolder,
    required this.selectedFolderId,
    required this.collapsed,
    required this.onDashboardTap,
    required this.onCreateFolder,
    required this.onUploadFile,
    required this.onToggleFolder,
    required this.onSelectFolder,
    required this.onSignOut,
    required this.onUpgradePlan,
  });

  /// Data
  final List<Folder> folders;
  final Map<String, List<FileMeta>> filesByFolder;
  final String? selectedFolderId;
  final Set<String> collapsed;

  /// Callbacks
  final VoidCallback onDashboardTap;
  final VoidCallback onCreateFolder;
  final VoidCallback onUploadFile;
  final void Function(String folderId) onToggleFolder;
  final void Function(String? folderId) onSelectFolder;
  final VoidCallback onSignOut;
  final VoidCallback onUpgradePlan;

  @override
  Widget build(BuildContext context) => Container(
    width: kSidebarW,
    color: Colors.grey.shade100,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AppHeader(),
        // ── core nav buttons ──
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
        // ── dynamic folders / files list ──
        Expanded(
          child: ListView(
            children: [
              ...folders.map((f) => _buildFolderTile(context, f)),
              // files not in a folder (folderId == null)
              if (filesByFolder['__root__']?.isNotEmpty == true)
                ...filesByFolder['__root__']!.map(
                  (file) => Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.insert_drive_file, size: 18),
                      title: Text(
                        file.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => onSelectFolder(null),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(),
        _UserSection(onSignOut: onSignOut, onUpgradePlan: onUpgradePlan),
      ],
    ),
  );

  /// Folder with expansion arrow + nested files
  Widget _buildFolderTile(BuildContext context, Folder folder) {
    final isCollapsed = collapsed.contains(folder.id);
    final isSelected = selectedFolderId == folder.id;
    final files = filesByFolder[folder.id] ?? const <FileMeta>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.folder),
          title: Text(folder.name),
          trailing:
              files.isEmpty
                  ? null
                  : Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_right
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
          tileColor: isSelected ? kHover : null,
          onTap: () => onSelectFolder(folder.id),
          onLongPress: files.isEmpty ? null : () => onToggleFolder(folder.id),
        ),
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children:
                  files
                      .map(
                        (f) => ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.insert_drive_file,
                            size: 18,
                          ),
                          title: Text(
                            f.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () => onSelectFolder(folder.id),
                        ),
                      )
                      .toList(),
            ),
          ),
      ],
    );
  }
}

/*──────────────── UI bits ───────────────*/
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        CircleAvatar(
          backgroundColor: kBrand,
          child: Text(
            FirebaseAuth.instance.currentUser?.displayName
                    ?.substring(0, 1)
                    .toUpperCase() ??
                'U',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          FirebaseAuth.instance.currentUser?.displayName ??
              FirebaseAuth.instance.currentUser?.email ??
              'User',
          textAlign: TextAlign.center,
        ),
        TextButton(onPressed: onUpgradePlan, child: const Text('Upgrade plan')),
        OutlinedButton(onPressed: onSignOut, child: const Text('Sign out')),
      ],
    ),
  );
}
