// lib/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Folder {
  final String id;
  final String name;
  Folder({required this.id, required this.name});

  // Firestore → model
  factory Folder.fromDoc(DocumentSnapshot d) =>
      Folder(id: d.id, name: d.get('name') as String);
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

  factory FileMeta.fromDoc(DocumentSnapshot d) => FileMeta(
    id: d.id,
    name: d.get('name') as String,
    size: d.get('size') as int,
    url: d.get('url') as String,
    type: d.get('type') as String,
    folderId: d.get('folderId'),
    uploadedAt: (d.get('uploadedAt') as Timestamp).toDate(),
  );
}
