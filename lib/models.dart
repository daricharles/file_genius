// lib/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Folder {
  final String id;
  final String name;
  Folder({required this.id, required this.name});

  // Firestore → model
  factory Folder.fromDoc(DocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>;
    return Folder(id: d.id, name: data['name'] ?? 'Unnamed Folder');
  }
}

class FileMeta {
  final String id;
  final String name;
  final int size;
  final String url;
  final String type;
  final DateTime uploadedAt;
  final String? folderId; // null ⇒ top level

  FileMeta({
    required this.id,
    required this.name,
    required this.size,
    required this.url,
    required this.type,
    required this.uploadedAt,
    required this.folderId,
  });

  factory FileMeta.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle uploadedAt field safely
    DateTime uploadedAt;
    final uploadedAtData = data['uploadedAt'];
    if (uploadedAtData is Timestamp) {
      uploadedAt = uploadedAtData.toDate();
    } else if (uploadedAtData != null) {
      // If it's already a DateTime or other format, try to convert
      uploadedAt =
          DateTime.tryParse(uploadedAtData.toString()) ?? DateTime.now();
    } else {
      // Fallback to current time if null
      uploadedAt = DateTime.now();
    }

    return FileMeta(
      id: doc.id,
      name: data['name'] ?? '',
      size: data['size'] ?? 0,
      url: data['url'] ?? '',
      type: data['type'] ?? '',
      folderId: data['folderId'],
      uploadedAt: uploadedAt,
    );
  }
}
