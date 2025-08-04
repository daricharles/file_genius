import 'package:flutter/material.dart';

/// Enhanced chat message model with additional features
class EnhancedChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? messageType; // 'text', 'analysis', 'summary', 'follow_up'
  final Map<String, dynamic>? metadata;
  final bool isBookmarked;
  final List<String> tags;
  final String? replyToId; // For threaded conversations

  EnhancedChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType,
    this.metadata,
    this.isBookmarked = false,
    this.tags = const [],
    this.replyToId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType,
      'metadata': metadata,
      'isBookmarked': isBookmarked,
      'tags': tags,
      'replyToId': replyToId,
    };
  }

  factory EnhancedChatMessage.fromJson(Map<String, dynamic> json) {
    return EnhancedChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      messageType: json['messageType'],
      metadata: json['metadata'],
      isBookmarked: json['isBookmarked'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      replyToId: json['replyToId'],
    );
  }

  EnhancedChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? messageType,
    Map<String, dynamic>? metadata,
    bool? isBookmarked,
    List<String>? tags,
    String? replyToId,
  }) {
    return EnhancedChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      tags: tags ?? this.tags,
      replyToId: replyToId ?? this.replyToId,
    );
  }
}

/// Chat session model for file-specific conversations
class ChatSession {
  final String id;
  final String fileName;
  final String fileType;
  final String filePath;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final List<EnhancedChatMessage> messages;
  final Map<String, dynamic> fileMetadata;
  final List<String> tags;
  final bool isArchived;

  ChatSession({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.messages,
    this.fileMetadata = const {},
    this.tags = const [],
    this.isArchived = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileType': fileType,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'fileMetadata': fileMetadata,
      'tags': tags,
      'isArchived': isArchived,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      filePath: json['filePath'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt']),
      messages:
          (json['messages'] as List)
              .map((m) => EnhancedChatMessage.fromJson(m))
              .toList(),
      fileMetadata: json['fileMetadata'] ?? {},
      tags: List<String>.from(json['tags'] ?? []),
      isArchived: json['isArchived'] ?? false,
    );
  }

  ChatSession copyWith({
    String? id,
    String? fileName,
    String? fileType,
    String? filePath,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    List<EnhancedChatMessage>? messages,
    Map<String, dynamic>? fileMetadata,
    List<String>? tags,
    bool? isArchived,
  }) {
    return ChatSession(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      messages: messages ?? this.messages,
      fileMetadata: fileMetadata ?? this.fileMetadata,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  /// Get the last message in the session
  EnhancedChatMessage? get lastMessage {
    return messages.isNotEmpty ? messages.last : null;
  }

  /// Get the number of user messages (questions asked)
  int get userMessageCount {
    return messages.where((m) => m.isUser).length;
  }

  /// Get the number of AI responses
  int get aiResponseCount {
    return messages.where((m) => !m.isUser).length;
  }

  /// Check if session is active (has recent activity)
  bool get isActive {
    final now = DateTime.now();
    return now.difference(lastUpdatedAt).inDays < 7;
  }
}

/// Question suggestion model
class QuestionSuggestion {
  final String id;
  final String question;
  final String category;
  final IconData icon;
  final int popularity;
  final List<String> applicableFileTypes;
  final String? description;

  QuestionSuggestion({
    required this.id,
    required this.question,
    required this.category,
    required this.icon,
    this.popularity = 0,
    this.applicableFileTypes = const [],
    this.description,
  });
}

/// Follow-up suggestion model
class FollowUpSuggestion {
  final String question;
  final String reason;
  final IconData icon;
  final String category;

  FollowUpSuggestion({
    required this.question,
    required this.reason,
    required this.icon,
    required this.category,
  });
}

/// Export format options
enum ExportFormat {
  pdf('PDF Document', 'pdf'),
  txt('Text File', 'txt'),
  md('Markdown File', 'md'),
  json('JSON File', 'json');

  const ExportFormat(this.displayName, this.extension);
  final String displayName;
  final String extension;
}

/// Chat analytics model
class ChatAnalytics {
  final int totalSessions;
  final int totalMessages;
  final int totalQuestions;
  final Map<String, int> questionCategories;
  final Map<String, int> fileTypeInteractions;
  final double averageSessionLength;
  final List<String> popularQuestions;
  final DateTime lastAnalyzed;

  ChatAnalytics({
    required this.totalSessions,
    required this.totalMessages,
    required this.totalQuestions,
    required this.questionCategories,
    required this.fileTypeInteractions,
    required this.averageSessionLength,
    required this.popularQuestions,
    required this.lastAnalyzed,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'totalMessages': totalMessages,
      'totalQuestions': totalQuestions,
      'questionCategories': questionCategories,
      'fileTypeInteractions': fileTypeInteractions,
      'averageSessionLength': averageSessionLength,
      'popularQuestions': popularQuestions,
      'lastAnalyzed': lastAnalyzed.toIso8601String(),
    };
  }

  factory ChatAnalytics.fromJson(Map<String, dynamic> json) {
    return ChatAnalytics(
      totalSessions: json['totalSessions'],
      totalMessages: json['totalMessages'],
      totalQuestions: json['totalQuestions'],
      questionCategories: Map<String, int>.from(json['questionCategories']),
      fileTypeInteractions: Map<String, int>.from(json['fileTypeInteractions']),
      averageSessionLength: json['averageSessionLength'].toDouble(),
      popularQuestions: List<String>.from(json['popularQuestions']),
      lastAnalyzed: DateTime.parse(json['lastAnalyzed']),
    );
  }
}
