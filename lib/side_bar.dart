// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'constants.dart';
import 'models.dart';

class FileGeniusSidebar extends StatelessWidget {
  final List<Folder> folders;
  final List<FileMeta> topLevelFiles;
  final Map<String, List<FileMeta>> filesByFolder;
  final String? selectedFolderId;
  final Set<String> collapsed;
  final VoidCallback onDashboardTap;
  final VoidCallback onCreateFolder;
  final VoidCallback onUploadFile;
  final void Function(String folderId) onToggleFolder;
  final void Function(String? folderId) onSelectFolder;
  final void Function(FileMeta file)? onSelectTopFile;
  final void Function(FileMeta file)? onSelectAnyFile;
  final VoidCallback onSignOut;
  final VoidCallback onUpgradePlan;
  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final String? selectedFileId;
  final void Function(FileMeta file, String? folderId)? onMoveFile;
  final void Function(String folderId, int newIndex)? onMoveFolder;
  final VoidCallback? onClearData;
  final Future<void> Function(Folder folder)? onDeleteFolder;
  final Future<void> Function(Folder folder, String newName)? onRenameFolder;
  final Future<void> Function(FileMeta file)? onDeleteFile;
  final VoidCallback? onUserProfilePressed; // Add this line

  const FileGeniusSidebar({
    super.key,
    required this.folders,
    required this.topLevelFiles,
    required this.filesByFolder,
    required this.selectedFolderId,
    required this.collapsed,
    required this.onDashboardTap,
    required this.onCreateFolder,
    required this.onUploadFile,
    required this.onToggleFolder,
    required this.onSelectFolder,
    this.onSelectTopFile,
    this.onSelectAnyFile,
    required this.onSignOut,
    required this.onUpgradePlan,
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
    required this.selectedFileId,
    this.onMoveFile,
    this.onMoveFolder,
    this.onClearData,
    this.onDeleteFolder,
    this.onRenameFolder,
    this.onDeleteFile,
    this.onUserProfilePressed, // Add this line
  });

  Widget _topFileTile(BuildContext context, FileMeta f) {
    final isSelected = selectedFileId == f.id;
    return Draggable<FileMeta>(
      data: f,
      feedback: Opacity(
        opacity: 0.3,
        child: Material(
          child: _buildFileTileContent(context, f, isSelected, nested: false),
        ),
      ),
      child: _buildFileTileContent(context, f, isSelected, nested: false),
    );
  }

  Widget _fileTile(BuildContext context, FileMeta f, {bool nested = false}) {
    final isSelected = selectedFileId == f.id;
    return Draggable<FileMeta>(
      data: f,
      feedback: Opacity(
        opacity: 0.3,
        child: Material(
          child: _buildFileTileContent(context, f, isSelected, nested: nested),
        ),
      ),
      child: _buildFileTileContent(context, f, isSelected, nested: nested),
    );
  }

  Widget _buildFileTileContent(
    BuildContext context,
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
          leading: const Icon(Icons.insert_drive_file_outlined, size: 18),
          title:
              sidebarCollapsed
                  ? null
                  : Text(f.name, style: const TextStyle(fontSize: 13)),
          trailing:
              sidebarCollapsed
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    tooltip: 'Delete file',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text('Delete File'),
                              content: const Text(
                                'Are you sure you want to delete this file?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await onDeleteFile?.call(f);
                      }
                    },
                  ),
          tileColor: Colors.transparent,
          hoverColor: Colors.grey[200],
          selected: isSelected,
          contentPadding: const EdgeInsets.only(left: 8, right: 4),
          onTap: () {
            onSelectAnyFile?.call(f);
          },
        ),
      ),
    );
  }

  Widget _buildFolderTile(BuildContext context, Folder folder) {
    final isCollapsed = collapsed.contains(folder.id);
    final isSelected = selectedFolderId == folder.id;
    final kids = filesByFolder[folder.id] ?? const <FileMeta>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DragTarget<FileMeta>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            onMoveFile?.call(details.data, folder.id);
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
                  context,
                  folder,
                  isCollapsed,
                  isSelected,
                  kids,
                  isDropTarget: candidateData.isNotEmpty,
                ),
              ),
              child: _buildFolderTileContent(
                context,
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
              children:
                  kids.map((f) => _fileTile(context, f, nested: true)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFolderTileContent(
    BuildContext context,
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
          title:
              sidebarCollapsed
                  ? null
                  : Text(
                    folder.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? kBrand : null,
                    ),
                  ),
          trailing:
              sidebarCollapsed
                  ? null
                  : IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.chevron_right : Icons.expand_more,
                    ),
                    onPressed: () => onToggleFolder(folder.id),
                  ),
          onTap: () => onSelectFolder(folder.id),
          onLongPress: () {
            // Show context menu
            final RenderBox overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;
            showMenu(
              context: context,
              position: RelativeRect.fromRect(
                (context.findRenderObject() as RenderBox).localToGlobal(
                      Offset.zero,
                      ancestor: overlay,
                    ) &
                    const Size(40, 40), // smaller rect, the touch area
                Offset.zero & overlay.size,
              ),
              items: [
                PopupMenuItem(
                  value: 'rename',
                  child: const Text('Rename'),
                  onTap: () async {
                    // Your rename logic here
                    final ctl = TextEditingController(text: folder.name);
                    final newName = await showDialog<String>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('Rename Folder'),
                            content: TextField(
                              controller: ctl,
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                              TextButton(
                                child: const Text('Rename'),
                                onPressed:
                                    () =>
                                        Navigator.of(ctx).pop(ctl.text.trim()),
                              ),
                            ],
                          ),
                    );
                    if (newName != null &&
                        newName.isNotEmpty &&
                        newName != folder.name) {
                      await onRenameFolder?.call(folder, newName);
                    }
                  },
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Text('Delete'),
                  onTap: () async {
                    // Your delete logic here
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('Delete Folder'),
                            content: const Text(
                              'Are you sure you want to delete this folder and all its contents?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(ctx).pop(false),
                              ),
                              ElevatedButton(
                                child: const Text('Delete'),
                                onPressed: () => Navigator.of(ctx).pop(true),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      await onDeleteFolder?.call(folder);
                    }
                  },
                ),
              ],
            );
          },
          tileColor: Colors.transparent,
          hoverColor: Colors.grey[200],
          selected: isSelected,
          dense: true,
          contentPadding: const EdgeInsets.only(left: 8, right: 4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarCollapsed ? 56 : kSidebarW,
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(sidebarCollapsed ? Icons.menu : Icons.close),
                  onPressed: onToggleSidebar,
                ),
                if (!sidebarCollapsed)
                  const Text(
                    'FileGenius',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          if (!sidebarCollapsed) ...[
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
            // Clear All Files & Folders button
            if (onClearData != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: const Text('Clear All Files & Folders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(36),
                  ),
                  onPressed: onClearData,
                ),
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
            Expanded(
              child: DragTarget<String>(
                onWillAcceptWithDetails:
                    (details) => details.data.startsWith('folder:'),
                onAcceptWithDetails: (details) {
                  final data = details.data;
                  final folderId = data.substring(7); // Remove 'folder:' prefix
                  final folderIndex = folders.indexWhere(
                    (f) => f.id == folderId,
                  );
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
                          ...topLevelFiles.map((f) => _topFileTile(context, f)),
                          ...folders.map((f) => _buildFolderTile(context, f)),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 24),
            _UserSection(
              onSignOut: onSignOut,
              onUpgradePlan: onUpgradePlan,
              onUserProfilePressed: onUserProfilePressed,
            ), // Pass the callback here
          ],
        ],
      ),
    );
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
  const _UserSection({
    required this.onSignOut,
    required this.onUpgradePlan,
    this.onUserProfilePressed,
  });
  final VoidCallback onSignOut;
  final VoidCallback onUpgradePlan;
  final VoidCallback? onUserProfilePressed; // Add this line

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
          GestureDetector(
            onTap: () {
              // Navigate to user profile
              // Instead of Navigator.push, use a callback to show in main pane
              onUserProfilePressed?.call();
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CircleAvatar(
                backgroundColor: kBrand,
                radius: 24,
                backgroundImage:
                    user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                child:
                    user?.photoURL == null
                        ? Text(
                          avatarText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                        : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Navigate to user profile
              // Instead of Navigator.push, use a callback to show in main pane
              onUserProfilePressed?.call();
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                displayName ?? email ?? 'User',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
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

class FileGeniusSidebarContainer extends StatefulWidget {
  const FileGeniusSidebarContainer({super.key});

  @override
  State<FileGeniusSidebarContainer> createState() =>
      _FileGeniusSidebarContainerState();
}

class _FileGeniusSidebarContainerState
    extends State<FileGeniusSidebarContainer> {
  List<Folder> folders = []; // Load from Firestore
  List<FileMeta> topLevelFiles = []; // Load from Firestore
  Map<String, List<FileMeta>> filesByFolder = {}; // Load from Firestore
  Set<String> collapsed = {};
  String? selectedFolderId;
  String? selectedFileId;

  // Clear all files and folders
  void _handleClearData() async {
    // Delete all files from Firestore
    final filesSnapshot =
        await FirebaseFirestore.instance.collection('files').get();
    for (var doc in filesSnapshot.docs) {
      // Delete file from Firestore
      await doc.reference.delete();
      // Delete file from Storage (if you store file URLs/paths in Firestore)
      final fileUrl = doc.data()['url'];
      if (fileUrl != null) {
        final ref = FirebaseStorage.instance.refFromURL(fileUrl);
        await ref.delete();
      }
    }

    // Delete all folders from Firestore
    final foldersSnapshot =
        await FirebaseFirestore.instance.collection('folders').get();
    for (var doc in foldersSnapshot.docs) {
      await doc.reference.delete();
    }

    // Clear local state and rebuild UI
    setState(() {
      folders.clear();
      topLevelFiles.clear();
      filesByFolder.clear();
      selectedFolderId = null;
      selectedFileId = null;
    });
  }

  // Rename a folder
  Future<void> _handleRenameFolder(Folder folder, String newName) async {
    // Update folder name in Firestore
    await FirebaseFirestore.instance
        .collection('folders')
        .doc(folder.id)
        .update({'name': newName});
    // Update local state
    setState(() {
      final idx = folders.indexWhere((f) => f.id == folder.id);
      if (idx != -1) {
        folders[idx] = Folder(id: folder.id, name: newName);
      }
    });
  }

  // Delete a folder and all its related subcollections
  Future<void> _handleDeleteFolder(Folder folder) async {
    // Delete all files in this folder from Firestore and Storage
    final files = filesByFolder[folder.id] ?? [];
    for (var file in files) {
      await FirebaseFirestore.instance
          .collection('files')
          .doc(file.id)
          .delete();
      if (file.url.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(file.url);
          await ref.delete();
        } catch (e) {
          print('Error deleting from storage: $e');
        }
      }
    }
    // Delete folder document
    await FirebaseFirestore.instance
        .collection('folders')
        .doc(folder.id)
        .delete();
    // Update local state
    setState(() {
      folders.removeWhere((f) => f.id == folder.id);
      filesByFolder.remove(folder.id);
      if (selectedFolderId == folder.id) selectedFolderId = null;
    });
  }

  // Delete a top-level file and its subcollections
  Future<void> _handleDeleteFile(FileMeta file) async {
    await FirebaseFirestore.instance.collection('files').doc(file.id).delete();
    if (file.url.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(file.url);
        await ref.delete();
      } catch (e) {
        print('Error deleting from storage: $e');
      }
    }
    setState(() {
      topLevelFiles.removeWhere((f) => f.id == file.id);
      filesByFolder.forEach((k, v) => v.removeWhere((f) => f.id == file.id));
      if (selectedFileId == file.id) selectedFileId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FileGeniusSidebar(
      folders: folders,
      topLevelFiles: topLevelFiles,
      filesByFolder: filesByFolder,
      selectedFolderId: selectedFolderId,
      collapsed: collapsed,
      onDashboardTap: () {},
      onCreateFolder: () {},
      onUploadFile: () {},
      onToggleFolder: (folderId) {
        setState(() {
          /* ... */
        });
      },
      onSelectFolder: (folderId) {
        setState(() {
          selectedFolderId = folderId;
        });
      },
      onSelectTopFile: (file) {
        setState(() {
          selectedFileId = file.id;
        });
      },
      onSelectAnyFile: (file) {
        setState(() {
          selectedFileId = file.id;
        });
      },
      onSignOut: () {},
      onUpgradePlan: () {},
      sidebarCollapsed: false,
      onToggleSidebar: () {},
      selectedFileId: selectedFileId,
      onMoveFile: (file, folderId) {
        /* implement move logic */
      },
      onMoveFolder: (folderId, newIndex) {
        /* implement move logic */
      },
      onClearData: _handleClearData,
      onDeleteFolder: _handleDeleteFolder,
      onRenameFolder: _handleRenameFolder,
      onDeleteFile: _handleDeleteFile,
      onUserProfilePressed: () {
        // Handle user profile navigation
        // For example, you can show a dialog with user info
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('User Profile'),
                content: const Text('User profile details go here.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      },
    );
  }
}
