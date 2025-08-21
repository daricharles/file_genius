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
  String? _fileContentFutureKey;
  final Set<String> _autoSummarized = {}; // now used

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
    if (_fileContentFuture != null && _fileContentFutureKey == cacheKey) return;

    // If we already cached (e.g. just uploaded locally)
    if (_fileContentCache.containsKey(cacheKey)) {
      _fileContentFuture = Future.value(_fileContentCache[cacheKey]!);
      _fileContentFutureKey = cacheKey;
      return;
    }

    // Skip remote extraction if url is empty (local temp)
    if (file.url.isEmpty) {
      _fileContentFuture = Future.value('');
      _fileContentFutureKey = cacheKey;
      return;
    }

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

  // REPLACED _handleFileReady to convert FileItem -> FileMeta and inject content cache
  void _handleFileReady(FileItem f) {
    final folderId = widget.selectedFolder?.id ?? '';
    final meta = FileMeta(
      id: f.id,
      name: f.name,
      type: f.type,
      size: f.size,
      url: '', // local (no remote URL yet)
      folderId: folderId, // REQUIRED
      uploadedAt: DateTime.now(), // REQUIRED
    );

    final cacheKey = '${meta.id}_${meta.name}';
    _fileContentCache[cacheKey] = f.content;

    setState(() {
      widget.files.add(meta);
      widget.onSelectFile?.call(meta); // auto select -> opens panes
      _fileContentFuture = Future.value(f.content);
      _fileContentFutureKey = cacheKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If a file is selected for preview, show split view
    if (widget.previewFile != null) {
      final supported = FileContentExtractor.supportsAIAnalysis(
        widget.previewFile!.type,
      );
      final shouldAutoSummarize = _autoSummarized.add(
        widget.previewFile!.id,
      ); // true first time only

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
                // widget.previewFile is guaranteed non-null in this branch
                Expanded(
                  child: FileViewer(
                    file: widget.previewFile!,
                    onPdfPageChanged: (currentPage, totalPages) {
                      // Optional: Handle page changes if needed for analytics
                      debugPrint('PDF page changed: $currentPage/$totalPages');
                    },
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
                                  color: Colors.redAccent,
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

                        return EnhancedAIChatWidget(
                          key: ValueKey(
                            'enhanced_ai_chat_${widget.previewFile!.id}',
                          ),
                          fileName: widget.previewFile!.name,
                          fileType: widget.previewFile!.type,
                          fileContent: snapshot.data ?? '',
                          filePath: widget.previewFile!.url,
                          fileId: widget.previewFile!.id,
                          autoSummarize: shouldAutoSummarize, // now supported
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
              label: 'Drag & drop files or click to upload',
              onFilesPicked: widget.onPickFiles,
              onFilesDropped: widget.onDropFiles,
              onFileReady: _handleFileReady, // ensure callback wired
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
                      onFileReady: _handleFileReady, // add here too
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.files.length,
                    separatorBuilder:
                        (_, i) => const Divider(
                          height: 1,
                        ), // renamed second param to avoid lint
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

  // REMOVE the nested PaneController class (was invalid inside this class)
}

// (Optional) If you still need PaneController, define it at top-level, outside any class:

class PaneController extends ChangeNotifier {
  bool _showFilePreview = false;
  bool _showAIPane = false;

  void openFilePreviewAndAI() {
    _showFilePreview = true;
    _showAIPane = true;
    notifyListeners();
  }

  bool get showFilePreview => _showFilePreview;
  bool get showAIPane => _showAIPane;
}
