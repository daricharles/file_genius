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
  final String? folderId;

  // Analysis fields
  final String? extractedText;
  final String? summary;
  final List<String>? followUpQuestions;
  final bool isAnalyzing;

  FileMeta({
    required this.id,
    required this.name,
    required this.size,
    required this.url,
    required this.type,
    required this.uploadedAt,
    required this.folderId,
    this.extractedText,
    this.summary,
    this.followUpQuestions,
    this.isAnalyzing = false,
  });

  factory FileMeta.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FileMeta(
      id: doc.id,
      name: d['name'] ?? '',
      size: (d['size'] ?? 0) is int ? d['size'] : (d['size'] as num).toInt(),
      url: d['url'] ?? '',
      type: (d['type'] ?? '').toString(),
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      folderId: d['folderId'],
      extractedText: d['extractedText'],
      summary: d['summary'],
      followUpQuestions:
          (d['followUpQuestions'] as List?)?.map((e) => e.toString()).toList(),
      isAnalyzing: d['isAnalyzing'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'size': size,
    'url': url,
    'type': type,
    'uploadedAt': uploadedAt,
    'folderId': folderId,
    'extractedText': extractedText,
    'summary': summary,
    'followUpQuestions': followUpQuestions,
    'isAnalyzing': isAnalyzing,
  };

  FileMeta copyWith({
    String? url,
    String? extractedText,
    String? summary,
    List<String>? followUpQuestions,
    bool? isAnalyzing,
  }) {
    return FileMeta(
      id: id,
      name: name,
      size: size,
      url: url ?? this.url,
      type: type,
      uploadedAt: uploadedAt,
      folderId: folderId,
      extractedText: extractedText ?? this.extractedText,
      summary: summary ?? this.summary,
      followUpQuestions: followUpQuestions ?? this.followUpQuestions,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
}

class FileAnalysisData {
  final String summary;
  final List<String> followUpQuestions;
  final DateTime generatedAt;

  FileAnalysisData({
    required this.summary,
    required this.followUpQuestions,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}

// Example extension for an existing FileModel (rename to your actual model):
class FileModel {
  // ...existing code...
  final String id;
  final String name;
  final String path;
  final String mimeType;
  final String? extractedText;
  final FileAnalysisData? analysis;

  FileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.mimeType,
    this.extractedText,
    this.analysis,
  });

  FileModel copyWith({String? extractedText, FileAnalysisData? analysis}) {
    return FileModel(
      id: id,
      name: name,
      path: path,
      mimeType: mimeType,
      extractedText: extractedText ?? this.extractedText,
      analysis: analysis ?? this.analysis,
    );
  }
}

// Simple in‑memory dropped file model (distinct from FileMeta if that is cloud/meta)
class FileItem {
  final String id;
  final String name;
  final String type;
  final String content;
  final int size;

  FileItem({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    required this.size,
  });
}
