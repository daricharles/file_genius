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

class MainPane extends StatelessWidget {
  const MainPane({
    super.key,
    required this.selectedFolder,
    required this.files,
    required this.onPickFiles,
    required this.onDropFiles,
    required this.onOpenUrl,
  });

  final Folder? selectedFolder;
  final List<FileMeta> files;
  final VoidCallback onPickFiles;
  final void Function(List<PlatformFile>) onDropFiles;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    // ─── Nothing selected: big welcome + upload CTA ───
    if (selectedFolder == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to FileGenius',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

    // ─── Folder selected: split pane ───
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildLeftPane(context),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 1,
          child: _buildRightPane(context),
        ),
      ],
    );
  }

  // ───────────────────────────────────────── Left
  Widget _buildLeftPane(BuildContext context) {
    if (files.isEmpty) {
      // Show a dedicated upload zone for that folder
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: DragDropZone(
          label: 'Drop files here to upload to “${selectedFolder!.name}”',
          onFilesPicked: onPickFiles,
          onFilesDropped: onDropFiles,
        ),
      );
    }

    // Show simple list of files for now (tap opens URL)
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (_, i) {
        final f = files[i];
        return ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: Text(f.name),
          subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB • ${f.type}'),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => onOpenUrl(f.url),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────── Right (AI area)
  Widget _buildRightPane(BuildContext context) {
    if (files.isEmpty) {
      return const Center(
        child: Text(
          'Upload a file to start interacting with AI',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Placeholder chat area – replace with your own chat widget.
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'AI Chat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        const Expanded(
          child: Center(child: Text('Chat UI goes here …')),
        ),
      ],
    );
  }
}
