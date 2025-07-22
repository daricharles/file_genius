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

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'models.dart'; // ← contains Folder & FileMeta classes
import 'drag_drop_zone.dart';
import 'file_viewer.dart';
import 'services/file_content_extractor.dart';
import 'widgets/ai_chat_widget.dart';

class MainPane extends StatelessWidget {
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
  });

  final Folder? selectedFolder;
  final List<FileMeta> files;
  final VoidCallback onPickFiles;
  final void Function(List<PlatformFile>) onDropFiles;
  final void Function(String url) onOpenUrl;
  final FileMeta? previewFile; // Add preview file parameter
  final void Function(FileMeta? file)?
  onSelectFile; // Add file selection callback
  final void Function(FileMeta file)? onDeleteFile;

  @override
  Widget build(BuildContext context) {
    // If a file is selected for preview, show split view
    if (previewFile != null) {
      return FutureBuilder<String>(
        future: FileContentExtractor.extractContent(
          fileUrl: previewFile!.url,
          fileType: previewFile!.type,
          fileName: previewFile!.name,
        ),
        builder: (context, snapshot) {
          final supported = FileContentExtractor.supportsAIAnalysis(
            previewFile!.type,
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
                            _iconForFileType(previewFile!.type),
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          // File name and info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  previewFile!.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_formatFileSize(previewFile!.size)} • ${previewFile!.type}',
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
                            onPressed: () => onOpenUrl(previewFile!.url),
                          ),
                          // Delete icon
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete file',
                            onPressed: () => onDeleteFile?.call(previewFile!),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // File viewer
                    Expanded(
                      child: FileViewer(
                        key: ValueKey(previewFile!.id),
                        fileUrl: previewFile!.url,
                        fileType: previewFile!.type.toLowerCase(),
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
                          child: Text(
                            'AI chat is not supported for this file type.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                        : (snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : AIChatWidget(
                              fileName: previewFile!.name,
                              fileType: previewFile!.type,
                              fileContent: snapshot.data ?? '',
                            )),
              ),
            ],
          );
        },
      );
    }

    // ─── Nothing selected: big welcome + upload CTA ───
    if (selectedFolder == null) {
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
              onFilesPicked: onPickFiles,
              onFilesDropped: onDropFiles,
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
              files.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DragDropZone(
                      label:
                          'Drop files here to upload to "${selectedFolder!.name}"',
                      onFilesPicked: onPickFiles,
                      onFilesDropped: onDropFiles,
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final isSelected = file == previewFile;
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
                                    onPressed: () => onOpenUrl(file.url),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Delete file',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => onDeleteFile?.call(file),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => onSelectFile?.call(file),
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
            child: Text(
              'Select a file to start chatting.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
