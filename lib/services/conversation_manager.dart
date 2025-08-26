import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_models.dart';
import 'firebase_chat_service.dart';

/// Smart conversation manager for enhanced AI chat functionality using Firebase
class ConversationManager {
  static ConversationManager? _instance;
  static ConversationManager get instance =>
      _instance ??= ConversationManager._();
  ConversationManager._();

  final FirebaseChatService _firebaseService = FirebaseChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ChatSession> _sessions = [];
  ChatAnalytics? _analytics;
  User? _user;

  /// Initialize the conversation manager
  Future<void> initialize() async {
    _user = FirebaseAuth.instance.currentUser;
    await _loadSessions();
    await _loadAnalytics();
  }

  /// Load all chat sessions from Firebase
  Future<void> _loadSessions() async {
    try {
      _sessions = await _firebaseService.loadChatSessions();
      for (final s in _sessions) {
        _deduplicateSessionMessages(s);
      }
      // Sort by last updated (most recent first)
      _sessions.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
      _sessions = [];
    }
  }


  /// Load analytics from Firebase
  Future<void> _loadAnalytics() async {
    try {
      _analytics = await _firebaseService.loadChatAnalytics();
    } catch (e) {
      debugPrint('Error loading chat analytics: $e');
    }
  }

  /// Clear all chat data
  Future<void> clearAllData() async {
    try {
      _sessions.clear();
      _analytics = null; // Reset analytics to null
      await _firebaseService.clearAllChatData();
    } catch (e) {
      debugPrint('Error clearing all chat data: $e');
    }
  }

  /// Get or create a chat session for a specific file
  Future<ChatSession> getOrCreateSession({
    required String fileName,
    required String fileType,
    required String filePath,
    Map<String, dynamic>? fileMetadata,
    String? fileId,
  }) async {
    final sessionId = _generateSessionId(fileName, filePath, fileId);

    // Try to load existing session first
    ChatSession? existingSession = await _loadSession(sessionId);

    if (existingSession != null) {
      return existingSession;
    }

    // Create new session if none exists
    final session = ChatSession(
      id: sessionId,
      fileName: fileName,
      fileType: fileType,
      filePath: filePath,
      fileMetadata: fileMetadata ?? {},
      fileId: fileId,
      createdAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      messages: [],
    );

    await _saveSession(session);
    return session;
  }

  Future<ChatSession?> _loadSession(String sessionId) async {
    try {
      if (_user == null) return null;

      final doc =
          await _firestore
              .collection('users')
              .doc(_user!.uid)
              .collection('chat_sessions')
              .doc(sessionId)
              .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final messagesData = data['messages'] as List? ?? [];

      final messages =
          messagesData.map((msgData) {
            return EnhancedChatMessage(
              id: msgData['id'] ?? '',
              text: msgData['text'] ?? '',
              isUser: msgData['isUser'] ?? false,
              timestamp:
                  (msgData['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              messageType: msgData['messageType'] ?? 'response',
              metadata: msgData['metadata'] as Map<String, dynamic>?,
              isBookmarked: msgData['isBookmarked'] ?? false,
            );
          }).toList();

      return ChatSession(
        id: sessionId,
        fileName: data['fileName'] ?? '',
        fileType: data['fileType'] ?? '',
        filePath: data['filePath'] ?? '',
        fileMetadata: data['fileMetadata'] as Map<String, dynamic>? ?? {},
        fileId: data['fileId'],
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastUpdatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        messages: messages,
      );
    } catch (e) {
      debugPrint('Error loading session: $e');
      return null;
    }
  }

  Future<void> _saveSession(ChatSession session) async {
    try {
      if (_user == null) return;

      final messagesData =
          session.messages
              .map(
                (msg) => {
                  'id': msg.id,
                  'text': msg.text,
                  'isUser': msg.isUser,
                  'timestamp': Timestamp.fromDate(msg.timestamp),
                  'messageType': msg.messageType,
                  'metadata': msg.metadata,
                  'isBookmarked': msg.isBookmarked,
                },
              )
              .toList();

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('chat_sessions')
          .doc(session.id)
          .set({
            'fileName': session.fileName,
            'fileType': session.fileType,
            'filePath': session.filePath,
            'fileMetadata': session.fileMetadata,
            'fileId': session.fileId,
            'createdAt': Timestamp.fromDate(session.createdAt),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
            'messages': messagesData,
          });
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// Add a message to a session
  Future<void> addMessage({
    required String sessionId,
    required EnhancedChatMessage message,
  }) async {
    try {
      if (_user == null) return;

      // Update the session in Firestore
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .update({
            'messages': FieldValue.arrayUnion([
              {
                'id': message.id,
                'text': message.text,
                'isUser': message.isUser,
                'timestamp': Timestamp.fromDate(message.timestamp),
                'messageType': message.messageType,
                'metadata': message.metadata,
                'isBookmarked': message.isBookmarked,
              },
            ]),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      debugPrint('Error adding message: $e');
    }
  }

  /// Update a message in a session
  Future<void> updateMessage({
    required String sessionId,
    required String messageId,
    required EnhancedChatMessage updatedMessage,
  }) async {
    try {
      if (_user == null) return;

      // Load the session
      final session = await _loadSession(sessionId);
      if (session == null) return;

      // Update the message in the session
      final messageIndex = session.messages.indexWhere(
        (m) => m.id == messageId,
      );
      if (messageIndex == -1) return;

      session.messages[messageIndex] = updatedMessage;

      // Save the updated session
      await _saveSession(session);
    } catch (e) {
      debugPrint('Error updating message: $e');
    }
  }

  /// Clear all messages in a session (except welcome message)
  Future<void> clearSession(String sessionId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final session = _sessions[sessionIndex];

      _sessions[sessionIndex] = session.copyWith(
        // Previously preserved/added welcome; now fully cleared
        messages: [],
        lastUpdatedAt: DateTime.now(),
      );
      await _firebaseService.saveChatSession(_sessions[sessionIndex]);
    }
  }

  /// Archive a session
  Future<void> archiveSession(String sessionId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
        isArchived: true,
        lastUpdatedAt: DateTime.now(),
      );
      // Use Firebase archive method
      await _firebaseService.archiveChatSession(sessionId);
    }
  }

  /// Delete a session permanently
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    // Use Firebase delete method
    await _firebaseService.deleteChatSession(sessionId);
  }

  /// Get all active sessions
  List<ChatSession> getActiveSessions() {
    return _sessions.where((s) => !s.isArchived).toList();
  }

  /// Get archived sessions
  List<ChatSession> getArchivedSessions() {
    return _sessions.where((s) => s.isArchived).toList();
  }

  /// Get recent sessions (last 10)
  List<ChatSession> getRecentSessions({int limit = 10}) {
    return _sessions.where((s) => !s.isArchived).take(limit).toList();
  }

  /// Search sessions by filename or content
  List<ChatSession> searchSessions(String query) {
    final lowerQuery = query.toLowerCase();
    return _sessions.where((session) {
      return session.fileName.toLowerCase().contains(lowerQuery) ||
          session.messages.any(
            (message) => message.text.toLowerCase().contains(lowerQuery),
          );
    }).toList();
  }

  /// Get session by ID
  ChatSession? getSessionById(String sessionId) {
    try {
      return _sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }


  /// Get conversation context for AI (last few messages)
  List<EnhancedChatMessage> getConversationContext(
    String sessionId, {
    int maxMessages = 5,
  }) {
    final session = getSessionById(sessionId);
    if (session == null) return [];

    // Get last few messages for context, excluding system messages
    final contextMessages =
        session.messages
            .where((m) => m.metadata?['isSystemMessage'] != true)
            .toList();

    if (contextMessages.length <= maxMessages) {
      return contextMessages;
    }

    return contextMessages.sublist(contextMessages.length - maxMessages);
  }

  /// Get analytics
  ChatAnalytics? getAnalytics() => _analytics;

  /// Export session to different formats
  Future<String> exportSession({
    required String sessionId,
    required ExportFormat format,
  }) async {
    final session = getSessionById(sessionId);
    if (session == null) throw Exception('Session not found');

    switch (format) {
      case ExportFormat.txt:
        return _exportToText(session);
      case ExportFormat.md:
        return _exportToMarkdown(session);
      case ExportFormat.json:
        return _exportToJson(session);
      case ExportFormat.pdf:
        // PDF export would require additional dependencies
        throw UnimplementedError('PDF export not yet implemented');
    }
  }

  /// Export session to plain text
  String _exportToText(ChatSession session) {
    final buffer = StringBuffer();
    buffer.writeln('Chat Session Export');
    buffer.writeln('File: ${session.fileName}');
    buffer.writeln('Date: ${session.createdAt.toString()}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final message in session.messages) {
      final sender = message.isUser ? 'You' : 'AI Assistant';
      final time =
          '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

      buffer.writeln('[$time] $sender:');
      buffer.writeln(message.text);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Export session to Markdown
  String _exportToMarkdown(ChatSession session) {
    final buffer = StringBuffer();
    buffer.writeln('# Chat Session Export');
    buffer.writeln();
    buffer.writeln('**File:** ${session.fileName}');
    buffer.writeln('**Date:** ${session.createdAt.toString()}');
    buffer.writeln('**Message Count:** ${session.messages.length}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (final message in session.messages) {
      final sender = message.isUser ? '👤 **You**' : '🤖 **AI Assistant**';
      final time =
          '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

      buffer.writeln('## $sender *($time)*');
      buffer.writeln();
      buffer.writeln(message.text);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Export session to JSON
  String _exportToJson(ChatSession session) {
    return json.encode(session.toJson());
  }

  Future<void> _persistSession(ChatSession session) async {
    try {
      await _firebaseService.saveChatSession(session);
    } catch (e) {
      debugPrint('Error persisting session ${session.id}: $e');
    }
  }

  void _deduplicateSessionMessages(ChatSession session) {
    final seenIds = <String>{};
    final cleaned = <EnhancedChatMessage>[];

    for (final m in session.messages) {
      if (m.id.isNotEmpty && !seenIds.add(m.id)) continue;
      if (cleaned.isNotEmpty) {
        final prev = cleaned.last;
        if (prev.isUser == m.isUser && prev.text.trim() == m.text.trim()) {
          continue;
        }
      }
      cleaned.add(m);
    }

    if (cleaned.length != session.messages.length) {
      debugPrint(
        'ConversationManager: removed ${session.messages.length - cleaned.length} duplicate messages in ${session.id}',
      );
      session.messages
        ..clear()
        ..addAll(cleaned);
      _persistSession(session);
    }
  }

  String _generateSessionId(String fileName, String filePath, String? fileId) {
    // Use fileId if available for consistency, otherwise use file path
    final identifier = fileId ?? filePath;
    return 'session_${identifier.hashCode.abs()}';
  }
}
