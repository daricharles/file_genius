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

class MainPane extends StatelessWidget {
  MainPane({
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

  final ValueNotifier<List<int>> pdfPageNotifier = ValueNotifier([1, 1]);

  @override
  Widget build(BuildContext context) {
    // If a file is selected for preview, show split view
    if (previewFile != null) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Header with file name, page indicator, and delete icon
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // File name
                      Expanded(
                        child: Text(
                          previewFile!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Page number indicator (for PDFs only)
                      if (previewFile!.type.toLowerCase() == 'pdf')
                        ValueListenableBuilder<List<int>>(
                          valueListenable: pdfPageNotifier,
                          builder: (context, value, _) {
                            final current = value[0];
                            final total = value[1];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text('Page $current of $total'),
                            );
                          },
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
                    key: ValueKey(
                      previewFile!.id,
                    ), // or previewFile!.url if id is not unique
                    fileUrl: previewFile!.url,
                    fileType: previewFile!.type.toLowerCase(),
                    onPdfPageChanged:
                        (current, total) =>
                            pdfPageNotifier.value = [current, total],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right pane: AI chat
          Expanded(flex: 1, child: ChatPane()),
        ],
      );
    }

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

    // ─── Folder selected: file list ───
    return Row(
      children: [
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
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text(file.name),
                        subtitle: Text(
                          '${(file.size / 1024).toStringAsFixed(1)} KB • ${file.type}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => onOpenUrl(file.url),
                        ),
                        onTap: () => onSelectFile?.call(file),
                      );
                    },
                  ),
        ),
        const VerticalDivider(width: 1),
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

class ChatPane extends StatefulWidget {
  const ChatPane({super.key});

  @override
  State<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<ChatPane> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _aiTyping = false; // Placeholder for future AI typing indicator

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _aiTyping = true;
    });
    _controller.clear();
    // Simulate AI response after a short delay (for demo)
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: 'This is a placeholder AI response.',
            isUser: false,
          ),
        );
        _aiTyping = false;
      });
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Expanded(
                child: Text(
                  'AI Chat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_aiTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_aiTyping && index == _messages.length) {
                // Typing indicator
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('AI is typing...'),
                  ),
                );
              }
              final msg = _messages[index];
              return Align(
                alignment:
                    msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isUser ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(msg.isUser ? 12 : 0),
                      bottomRight: Radius.circular(msg.isUser ? 0 : 12),
                    ),
                  ),
                  child: Text(msg.text),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              // Microphone icon for speech-to-text (future)
              IconButton(
                icon: const Icon(Icons.mic),
                tooltip: 'Speak (coming soon)',
                onPressed: () {
                  // Placeholder for future speech-to-text
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Speech-to-text coming soon!'),
                    ),
                  );
                },
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
