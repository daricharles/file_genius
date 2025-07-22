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
    required this.onDashboardTap,
    required this.onCreateFolder,
    required this.onUploadFile,
    required this.onToggleFolder,
    required this.onSelectFolder, // nullable id (= select a folder)
    this.onSelectTopFile, // top‑level file click (now optional)
    this.onSelectAnyFile, // fires for *any* file
    required this.onSignOut,
    required this.onUpgradePlan,
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
    required this.selectedFileId,
    // Drag and drop callbacks
    this.onMoveFile,
    this.onMoveFolder,
  });

  // ───────── DATA ─────────
  final List<Folder> folders;
  final List<FileMeta> topLevelFiles;
  final Map<String, List<FileMeta>> filesByFolder;
  final String? selectedFolderId;
  final Set<String> collapsed; // folder‑ids
  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final String? selectedFileId;

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
  // Drag and drop callbacks
  final void Function(FileMeta file, String? targetFolderId)? onMoveFile;
  final void Function(String folderId, int newIndex)? onMoveFolder;

  // ────────────────────────────────────────── UI tree
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: sidebarCollapsed ? 48 : kSidebarW,
    color: Colors.grey.shade100,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppHeader(
          onToggleSidebar: onToggleSidebar,
          collapsed: sidebarCollapsed,
        ),
        if (!sidebarCollapsed) ...[
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
            child: Text(
              'Files & Folders',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          // Scrollable tree with drop zones
          Expanded(
            child: DragTarget<String>(
              onWillAccept: (data) => data?.startsWith('folder:') == true,
              onAccept: (data) {
                final folderId = data.substring(7); // Remove 'folder:' prefix
                final folderIndex = folders.indexWhere((f) => f.id == folderId);
                if (folderIndex != -1) {
                  onMoveFolder?.call(folderId, 0); // Move to top
                }
              },
              builder: (context, candidateData, rejectedData) {
                return DragTarget<FileMeta>(
                  onWillAccept: (file) => true,
                  onAccept: (file) {
                    onMoveFile?.call(file, null); // Move to top level
                  },
                  builder: (context, candidateData, rejectedData) {
                    return ListView(
                      children: [
                        // 1) top‑level (un‑foldered) files
                        ...topLevelFiles.map((f) => _topFileTile(f)),
                        // 2) user folders with nested files
                        ...folders.map((f) => _buildFolderTile(context, f)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          _UserSection(onSignOut: onSignOut, onUpgradePlan: onUpgradePlan),
        ],
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
        // Draggable folder with drop zone
        DragTarget<FileMeta>(
          onWillAccept: (file) => file != null,
          onAccept: (file) {
            onMoveFile?.call(file, folder.id); // Move file into this folder
          },
          builder: (context, candidateData, rejectedData) {
            return Draggable<String>(
              data: 'folder:${folder.id}',
              feedback: Material(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(folder.name, style: const TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildFolderTileContent(
                  folder,
                  isCollapsed,
                  isSelected,
                  kids,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: candidateData.isNotEmpty
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildFolderTileContent(folder, isCollapsed, isSelected, kids),
              ),
            );
          },
        ),
        if (!isCollapsed && kids.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(children: kids.map((f) => _fileTile(f)).toList()),
          ),
      ],
    );
  }

  Widget _buildFolderTileContent(
    Folder folder,
    bool isCollapsed,
    bool isSelected,
    List<FileMeta> kids,
  ) {
    return MouseRegion(
      onEnter: (_) => {},
      onExit: (_) => {},
      child: GestureDetector(
        onTap: () => onSelectFolder(folder.id),
        child: Container(
          color: isSelected ? Colors.grey[300] : null,
          child: ListTile(
            leading: const Icon(Icons.folder),
            title: Text(folder.name),
            trailing:
                kids.isEmpty
                    ? null
                    : GestureDetector(
                      onTap: () => onToggleFolder(folder.id),
                      child: Icon(
                        isCollapsed
                            ? Icons.keyboard_arrow_right
                            : Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                    ),
            tileColor: isSelected ? Colors.grey[300] : null,
            hoverColor: Colors.grey[200],
            selected: isSelected,
          ),
        ),
      ),
    );
  }

  Widget _fileTile(FileMeta f) {
    final isSelected = selectedFileId == f.id;
    return Draggable<FileMeta>(
      data: f,
      feedback: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                color: Colors.green,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                f.name,
                style: const TextStyle(color: Colors.green, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildFileTileContent(f, isSelected),
      ),
      child: _buildFileTileContent(f, isSelected),
    );
  }

  Widget _buildFileTileContent(FileMeta f, bool isSelected) {
    return MouseRegion(
      onEnter: (_) => {},
      onExit: (_) => {},
      child: GestureDetector(
        onTap: () {
          onSelectAnyFile?.call(f);
          onSelectTopFile?.call(f);
        },
        child: Container(
          color: isSelected ? Colors.grey[300] : null,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.insert_drive_file_outlined, size: 18),
            title: Text(f.name, style: const TextStyle(fontSize: 13)),
            tileColor: isSelected ? Colors.grey[300] : null,
            hoverColor: Colors.grey[200],
            selected: isSelected,
          ),
        ),
      ),
    );
  }

  Widget _topFileTile(FileMeta f) => _fileTile(f);
}

/*────────────────── cosmetics ──────────────────*/
class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.onToggleSidebar, required this.collapsed});
  final VoidCallback onToggleSidebar;
  final bool collapsed;

  @override
  Widget build(BuildContext ctx) {
    if (collapsed) {
      // Collapsed: only show icons, centered, no extra padding
      return SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book, color: kBrand, size: 24),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Expand sidebar',
              onPressed: onToggleSidebar,
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    } else {
      // Expanded: show icon, text, and chevron
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.book, color: kBrand, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'FileGenius',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Collapse sidebar',
              onPressed: onToggleSidebar,
            ),
          ],
        ),
      );
    }
  }
}

class _SidebarButton extends StatefulWidget {
  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                _hovering
                    ? kBrand.withAlpha((0.12 * 255).round())
                    : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovering ? kBrand : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: kBrand),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(color: kBrand, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
