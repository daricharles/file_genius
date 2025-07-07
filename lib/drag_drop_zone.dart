// dragDropZone.dart
//
// Re‑usable drag‑and‑drop upload area.
//
// Requires:
//   dotted_border: ^2.0.0
//   file_picker   : ^6.0.0
//
// Usage example:
//   DragDropZone(
//     label: 'Drag & drop files or click to upload',
//     onFilesPicked : _pickFiles,
//     onFilesDropped: (List<PlatformFile> files) { … },
//   );

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Change these imports (or values) if you moved the constants elsewhere.
import 'constants.dart'; // holds kBrand & kHover, etc.

class DragDropZone extends StatelessWidget {
  const DragDropZone({
    super.key,
    required this.label,
    required this.onFilesPicked,
    required this.onFilesDropped,
    this.height = 230,
    this.icon = Icons.cloud_upload,
  });

  final String label;
  final VoidCallback onFilesPicked;
  final void Function(List<PlatformFile>) onFilesDropped;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: kBrand,
      strokeWidth: 1.5,
      dashPattern: const [6, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      child: DragTarget<PlatformFile>(
        onAcceptWithDetails: (details) => onFilesDropped([details.data]),
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
}
