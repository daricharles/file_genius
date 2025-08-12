// mainPane.dart – split‑pane workspace
//
// Exposed as a reusable widget so `home_screen.dart` (or any
// parent) can drop it in and control it via the callbacks.
// ─────────────────────────────────────────────────────────────
// • Left Pane  – file upload / list / preview (depending on state)
// • Right Pane – AI chat area (placeholder)
//
// It expects:
//   – a `selectedFolder` (nullable)
//   – current file list for that folder (empty list allowed)
//   – callbacks for picking & dropping files, opening a file URL
//
// NOTE:  This file only focuses on layout + state‑aware rendering.
//        Drag‑and‑drop UI itself lives in `drag_drop_zone.dart`.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'models.dart'; // ← contains Folder & FileMeta classes
import 'drag_drop_zone.dart';
import 'file_viewer.dart';
import 'services/file_content_extractor.dart';
import 'widgets/enhanced_ai_chat_widget.dart';

class MainPane extends StatefulWidget {
  const MainPane({
    super.key,
    required this.selectedFolder,
    required this.files,
    required this.onPickFiles,
    required this.onDropFiles,
    required this.onOpenUrl,
    this.previewFile,
    this.onSelectFile,
    this.onDeleteFile,
    this.onAIInteractionSuccess,
  });

  final Folder? selectedFolder;
  final List<FileMeta> files;
  final VoidCallback onPickFiles;
  final void Function(List<PlatformFile>) onDropFiles;
  final void Function(String url) onOpenUrl;
  final FileMeta? previewFile;
  final void Function(FileMeta? file)? onSelectFile;
  final void Function(FileMeta file)? onDeleteFile;
  final VoidCallback? onAIInteractionSuccess;

  @override
  State<MainPane> createState() => _MainPaneState();
}

class _MainPaneState extends State<MainPane> {
  final Map<String, String> _fileContentCache = {};
  Future<String>? _fileContentFuture;
  String? _fileContentFutureKey; // cacheKey the future corresponds to

  @override
  void initState() {
    super.initState();
    _prepareFileContentFuture(); // initialize if previewFile already set
  }

  @override
  void didUpdateWidget(MainPane oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only prepare a new future when the previewed file actually changes
    if (widget.previewFile?.id != oldWidget.previewFile?.id) {
      _prepareFileContentFuture();
    }

    // If previewFile cleared
    if (widget.previewFile == null && oldWidget.previewFile != null) {
      _fileContentFuture = null;
      _fileContentFutureKey = null;
    }
  }

  void _prepareFileContentFuture() {
    final file = widget.previewFile;
    if (file == null) {
      _fileContentFuture = null;
      _fileContentFutureKey = null;
      return;
    }
    final cacheKey = '${file.id}_${file.name}';
    // Reuse if we already have a future for this cacheKey
    if (_fileContentFuture != null && _fileContentFutureKey == cacheKey) {
      return;
    }

    if (_fileContentCache.containsKey(cacheKey)) {
      // Immediate future with cached value
      _fileContentFuture = Future.value(_fileContentCache[cacheKey]!);
      _fileContentFutureKey = cacheKey;
    } else {
      _fileContentFuture = FileContentExtractor.extractContent(
        fileUrl: file.url,
        fileType: file.type,
        fileName: file.name,
      ).then((content) {
        _fileContentCache[cacheKey] = content;
        return content;
      });
      _fileContentFutureKey = cacheKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If a file is selected for preview, show split view
    if (widget.previewFile != null) {
      final supported = FileContentExtractor.supportsAIAnalysis(
        widget.previewFile!.type,
      );

      return Row(
        children: [
          // Left: File preview pane
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Header with file name, info, and actions
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // File icon
                      Icon(
                        _iconForFileType(widget.previewFile!.type),
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      // File name and info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.previewFile!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_formatFileSize(widget.previewFile!.size)} • ${widget.previewFile!.type}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Download icon
                      IconButton(
                        icon: const Icon(Icons.download_rounded),
                        tooltip: 'Download file',
                        onPressed:
                            () => widget.onOpenUrl(widget.previewFile!.url),
                      ),
                      // Delete icon
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete file',
                        onPressed:
                            () =>
                                widget.onDeleteFile?.call(widget.previewFile!),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // File viewer
                Expanded(
                  child: FileViewer(
                    key: ValueKey('file_viewer_${widget.previewFile!.id}'),
                    fileUrl: widget.previewFile!.url,
                    fileType: widget.previewFile!.type.toLowerCase(),
                  ),
                ),
              ],
            ),
          ),
          // Split divider
          Container(
            width: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(vertical: 12),
          ),
          // Right pane: AI chat
          Expanded(
            flex: 1,
            child:
                !supported
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'AI chat is not supported for this file type.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Supported formats: PDF, DOC, TXT, and more.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : FutureBuilder<String>(
                      // CHANGED: use the memoized future
                      future: _fileContentFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading file content...'),
                              ],
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load file content',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  snapshot.error.toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        // Use a stable key that includes file ID to prevent recreation
                        return EnhancedAIChatWidget(
                          key: ValueKey(
                            'enhanced_ai_chat_${widget.previewFile!.id}',
                          ),
                          fileName: widget.previewFile!.name,
                          fileType: widget.previewFile!.type,
                          fileContent: snapshot.data ?? '',
                          filePath: widget.previewFile!.url,
                          fileId: widget.previewFile!.id, // NEW
                          onInteractionSuccess: widget.onAIInteractionSuccess,
                        );
                      },
                    ),
          ),
        ],
      );
    }

    // ─── Nothing selected: big welcome + upload CTA ───
    if (widget.selectedFolder == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.blue[200]),
            const SizedBox(height: 16),
            const Text(
              'Welcome to FileGenius',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by uploading your files or selecting a folder.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            DragDropZone(
              label: 'Drag & drop files here\nor click to upload',
              onFilesPicked: widget.onPickFiles,
              onFilesDropped: widget.onDropFiles,
            ),
          ],
        ),
      );
    }

    // ─── Folder selected: file list ───
    return Row(
      children: [
        // Left: File list
        Expanded(
          flex: 1,
          child:
              widget.files.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DragDropZone(
                      label:
                          'Drop files here to upload to "${widget.selectedFolder!.name}"',
                      onFilesPicked: widget.onPickFiles,
                      onFilesDropped: widget.onDropFiles,
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.files.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = widget.files[index];
                      final isSelected = file == widget.previewFile;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.blue.withOpacity(0.08)
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              _iconForFileType(file.type),
                              color: Colors.blue,
                            ),
                            title: Text(
                              file.name,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatFileSize(file.size)} • ${file.type}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Open in new tab',
                                  child: IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    onPressed: () => widget.onOpenUrl(file.url),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Delete file',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => widget.onDeleteFile?.call(file),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => widget.onSelectFile?.call(file),
                            selected: isSelected,
                            hoverColor: Colors.blue.withOpacity(0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
        // Split divider
        Container(
          width: 1,
          color: Colors.grey[300],
          margin: const EdgeInsets.symmetric(vertical: 12),
        ),
        // Right pane: Placeholder
        Expanded(
          flex: 1,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a file to start chatting with AI.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI can help analyze your documents and answer questions.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Helper: File type icon
IconData _iconForFileType(String type) {
  final t = type.toLowerCase();
  if (t.contains('pdf')) return Icons.picture_as_pdf;
  if (t.contains('doc') || t.contains('word')) return Icons.description;
  if (t.contains('xls') || t.contains('sheet')) return Icons.table_chart;
  if (t.contains('ppt')) return Icons.slideshow;
  if (t.contains('image')) return Icons.image;
  if (t.contains('audio')) return Icons.audiotrack;
  if (t.contains('video')) return Icons.videocam;
  return Icons.insert_drive_file;
}

// Helper: Format file size
String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
