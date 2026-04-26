import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'constants.dart';
import 'models.dart';
import 'services/file_content_extractor.dart';

class DragDropZone extends StatelessWidget {
  const DragDropZone({
    super.key,
    required this.label,
    required this.onFilesPicked,
    required this.onFilesDropped,
    this.height = 230,
    this.icon = Icons.cloud_upload,
    this.onFileReady,
  });

  final String label;
  final VoidCallback onFilesPicked;
  final void Function(List<PlatformFile>) onFilesDropped;
  final double height;
  final IconData icon;
  final void Function(FileItem file)? onFileReady;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: kBrand,
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        radius: const Radius.circular(12),
      ),
      child: DragTarget<PlatformFile>(
        onAcceptWithDetails: (details) async {
          final pf = details.data;
          onFilesDropped([pf]);

          String rawText =
              pf.bytes != null
                  ? _decodeBytes(pf.bytes!)
                  : '(No inline bytes. Implement path-based reading if available)';

          // Try remote/static extractor ONLY if you truly have a URL/path (optional)
          // Otherwise fall back to bytes helper for immediate AI summary usage.
          if ((pf.bytes != null) && rawText.trim().isEmpty) {
            rawText = await FileContentExtractor.extractFromBytes(
              bytes: pf.bytes!,
              fileName: pf.name,
              fileType: pf.extension ?? 'unknown',
            );
          }

          final createdFileItem = FileItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: pf.name,
            type: pf.extension ?? 'unknown',
            content: rawText,
            size: pf.size,
          );

          onFileReady?.call(createdFileItem);
        },
        onWillAcceptWithDetails: (_) => true,
        builder: (context, candidateData, _) {
          final isHovering = candidateData.isNotEmpty;
          return InkWell(
            onTap: onFilesPicked,
            child: Container(
              height: height,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              color: isHovering ? kHover : Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: kBrand),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _decodeBytes(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }
}
