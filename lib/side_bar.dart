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
          const SizedBox(height: 8),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'FILES & FOLDERS',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ),
          // Scrollable tree with drop zones
          Expanded(
            child: DragTarget<String>(
              onWillAcceptWithDetails:
                  (details) => details.data.startsWith('folder:'),
              onAcceptWithDetails: (details) {
                final data = details.data;
                final folderId = data.substring(7); // Remove 'folder:' prefix
                final folderIndex = folders.indexWhere((f) => f.id == folderId);
                if (folderIndex != -1) {
                  onMoveFolder?.call(folderId, 0); // Move to top
                }
              },
              builder: (context, candidateData, rejectedData) {
                return DragTarget<FileMeta>(
                  onWillAcceptWithDetails: (details) => true,
                  onAcceptWithDetails: (details) {
                    onMoveFile?.call(details.data, null); // Move to top level
                  },
                  builder: (context, candidateData, rejectedData) {
                    return ListView(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      children: [
                        ...topLevelFiles.map((f) => _topFileTile(f)),
                        ...folders.map((f) => _buildFolderTile(context, f)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 24),
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
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            onMoveFile?.call(
              details.data,
              folder.id,
            ); // Move file into this folder
          },
          builder: (context, candidateData, rejectedData) {
            return Draggable<String>(
              data: 'folder:${folder.id}',
              feedback: Material(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        folder.name,
                        style: const TextStyle(color: Colors.blue),
                      ),
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
                  isDropTarget: candidateData.isNotEmpty,
                ),
              ),
              child: _buildFolderTileContent(
                folder,
                isCollapsed,
                isSelected,
                kids,
                isDropTarget: candidateData.isNotEmpty,
              ),
            );
          },
        ),
        if (!isCollapsed && kids.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Column(
              children: kids.map((f) => _fileTile(f, nested: true)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFolderTileContent(
    Folder folder,
    bool isCollapsed,
    bool isSelected,
    List<FileMeta> kids, {
    bool isDropTarget = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? kBrand.withOpacity(0.10)
                  : isDropTarget
                  ? Colors.blue.withOpacity(0.08)
                  : null,
          border:
              isSelected
                  ? Border(left: BorderSide(color: kBrand, width: 4))
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(Icons.folder, color: isSelected ? kBrand : Colors.blue),
          title: Text(
            folder.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? kBrand : null,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_right
                  : Icons.keyboard_arrow_down,
              size: 22,
              color: Colors.grey[700],
            ),
            tooltip: isCollapsed ? 'Expand' : 'Collapse',
            onPressed: () => onToggleFolder(folder.id),
            splashRadius: 18,
          ),
          tileColor: Colors.transparent,
          hoverColor: Colors.grey[200],
          selected: isSelected,
          dense: true,
          contentPadding: const EdgeInsets.only(left: 8, right: 4),
          onTap: () => onSelectFolder(folder.id),
        ),
      ),
    );
  }

  Widget _fileTile(FileMeta f, {bool nested = false}) {
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
        child: _buildFileTileContent(f, isSelected, nested: nested),
      ),
      child: _buildFileTileContent(f, isSelected, nested: nested),
    );
  }

  Widget _buildFileTileContent(
    FileMeta f,
    bool isSelected, {
    bool nested = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: isSelected ? kBrand.withOpacity(0.10) : null,
          border:
              isSelected
                  ? Border(left: BorderSide(color: kBrand, width: 4))
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: nested ? const EdgeInsets.only(left: 8) : null,
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.insert_drive_file_outlined, size: 18),
          title: Text(f.name, style: const TextStyle(fontSize: 13)),
          tileColor: Colors.transparent,
          hoverColor: Colors.grey[200],
          selected: isSelected,
          contentPadding: const EdgeInsets.only(left: 8, right: 4),
          onTap: () {
            onSelectAnyFile?.call(f);
            onSelectTopFile?.call(f);
          },
        ),
      ),
    );
  }

  Widget _topFileTile(FileMeta f) => _fileTile(f, nested: false);
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
      cursor: SystemMouseCursors.click,
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
    final displayName = user?.displayName;
    final email = user?.email;
    final avatarText =
        (displayName?.isNotEmpty == true
                ? displayName![0]
                : (email?.isNotEmpty == true ? email![0] : 'U'))
            .toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: kBrand,
            radius: 24,
            backgroundImage:
                user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child:
                user?.photoURL == null
                    ? Text(
                      avatarText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 8),
          Text(
            displayName ?? email ?? 'User',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          // Example plan badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Free Plan',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.workspace_premium, color: Colors.orange),
                tooltip: 'Upgrade plan',
                onPressed: onUpgradePlan,
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: 'Sign out',
                onPressed: onSignOut,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
