import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import 'firebase_chat_service.dart';

/// Smart conversation manager for enhanced AI chat functionality using Firebase
class ConversationManager {
  static ConversationManager? _instance;
  static ConversationManager get instance =>
      _instance ??= ConversationManager._();
  ConversationManager._();

  final FirebaseChatService _firebaseService = FirebaseChatService();
  List<ChatSession> _sessions = [];
  ChatAnalytics? _analytics;

  /// Initialize the conversation manager
  Future<void> initialize() async {
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

  /// Save analytics to Firebase
  Future<void> _saveAnalytics() async {
    try {
      if (_analytics != null) {
        await _firebaseService.saveChatAnalytics(_analytics!);
      }
    } catch (e) {
      debugPrint('Error saving chat analytics: $e');
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
    bool keyMatcher(ChatSession s) {
      if (fileId != null && s.fileId == fileId && !s.isArchived) return true;
      return s.filePath == filePath && !s.isArchived;
    }

    ChatSession? existing;
    try {
      existing = _sessions.firstWhere(keyMatcher);
    } catch (_) {
      existing = null;
    }

    if (existing != null) {
      _deduplicateSessionMessages(existing);
      return existing;
    }

    final newSession = _createNewSession(
      fileName: fileName,
      fileType: fileType,
      filePath: filePath,
      fileId: fileId,
      fileMetadata: fileMetadata,
    );
    _sessions.insert(0, newSession);
    await _firebaseService.saveChatSession(newSession);
    return newSession;
  }

  /// Create a new chat session
  ChatSession _createNewSession({
    required String fileName,
    required String fileType,
    required String filePath,
    String? fileId, // ADDED
    Map<String, dynamic>? fileMetadata,
  }) {
    final now = DateTime.now();
    final sessionId = _generateSessionId();

    return ChatSession(
      id: sessionId,
      fileName: fileName,
      fileType: fileType,
      filePath: filePath,
      fileId: fileId, // ADDED
      createdAt: now,
      lastUpdatedAt: now,
      messages: [_createWelcomeMessage(fileName, sessionId)],
      fileMetadata: fileMetadata ?? {},
    );
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final now = DateTime.now();
    final random = Random();
    return 'session_${now.millisecondsSinceEpoch}_${random.nextInt(10000)}';
  }

  /// Create a welcome message for new sessions
  EnhancedChatMessage _createWelcomeMessage(String fileName, String sessionId) {
    return EnhancedChatMessage(
      id: '${sessionId}_welcome',
      text:
          'Hello! I\'m FileGenius AI. I can help you analyze "$fileName" and answer questions about it. What would you like to know?',
      isUser: false,
      timestamp: DateTime.now(),
      messageType: 'welcome',
      metadata: {'isSystemMessage': true},
    );
  }

  /// Add a message to a session
  Future<void> addMessage({
    required String sessionId,
    required EnhancedChatMessage message,
  }) async {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return;
    final session = _sessions[idx];

    // Skip duplicate id
    if (session.messages.any((m) => m.id == message.id)) {
      debugPrint('ConversationManager: duplicate id ${message.id}, skipped');
      return;
    }
    // Skip consecutive identical (same author + trimmed text)
    final last = session.messages.isNotEmpty ? session.messages.last : null;
    if (last != null &&
        last.isUser == message.isUser &&
        last.text.trim() == message.text.trim()) {
      debugPrint('ConversationManager: consecutive duplicate text skipped');
      return;
    }

    final updated = session.copyWith(
      messages: [...session.messages, message],
      lastUpdatedAt: DateTime.now(),
    );
    _sessions[idx] = updated;
    await _persistSession(updated);
    await _updateAnalytics(message);
  }

  /// Update a specific message in a session
  Future<void> updateMessage({
    required String sessionId,
    required String messageId,
    required EnhancedChatMessage updatedMessage,
  }) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final messages = _sessions[sessionIndex].messages;
      final messageIndex = messages.indexWhere((m) => m.id == messageId);

      if (messageIndex != -1) {
        messages[messageIndex] = updatedMessage;
        _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
          messages: messages,
          lastUpdatedAt: DateTime.now(),
        );
        // Save individual session to Firebase
        await _firebaseService.saveChatSession(_sessions[sessionIndex]);
      }
    }
  }

  /// Delete a message from a session
  Future<void> deleteMessage({
    required String sessionId,
    required String messageId,
  }) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final updatedMessages =
          _sessions[sessionIndex].messages
              .where((m) => m.id != messageId)
              .toList();

      _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
        messages: updatedMessages,
        lastUpdatedAt: DateTime.now(),
      );
      // Save individual session to Firebase
      await _firebaseService.saveChatSession(_sessions[sessionIndex]);
    }
  }

  /// Clear all messages in a session (except welcome message)
  Future<void> clearSession(String sessionId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final session = _sessions[sessionIndex];
      final welcomeMessage = session.messages.firstWhere(
        (m) => m.messageType == 'welcome',
        orElse: () => _createWelcomeMessage(session.fileName, sessionId),
      );

      _sessions[sessionIndex] = session.copyWith(
        messages: [welcomeMessage],
        lastUpdatedAt: DateTime.now(),
      );
      // Save individual session to Firebase
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

  /// Update analytics based on new message
  Future<void> _updateAnalytics(EnhancedChatMessage message) async {
    // Initialize analytics if null
    _analytics ??= ChatAnalytics(
      totalSessions: 0,
      totalMessages: 0,
      totalQuestions: 0,
      questionCategories: {},
      fileTypeInteractions: {},
      averageSessionLength: 0.0,
      popularQuestions: [],
      lastAnalyzed: DateTime.now(),
    );

    // Update analytics
    if (message.isUser) {
      // This is a user question
      final updatedQuestionCategories = Map<String, int>.from(
        _analytics!.questionCategories,
      );
      final category = message.messageType ?? 'general';
      updatedQuestionCategories[category] =
          (updatedQuestionCategories[category] ?? 0) + 1;

      _analytics = ChatAnalytics(
        totalSessions: _sessions.length,
        totalMessages: _analytics!.totalMessages + 1,
        totalQuestions: _analytics!.totalQuestions + 1,
        questionCategories: updatedQuestionCategories,
        fileTypeInteractions: _analytics!.fileTypeInteractions,
        averageSessionLength: _calculateAverageSessionLength(),
        popularQuestions: _analytics!.popularQuestions,
        lastAnalyzed: DateTime.now(),
      );
    } else {
      // This is an AI response
      _analytics = ChatAnalytics(
        totalSessions: _sessions.length,
        totalMessages: _analytics!.totalMessages + 1,
        totalQuestions: _analytics!.totalQuestions,
        questionCategories: _analytics!.questionCategories,
        fileTypeInteractions: _analytics!.fileTypeInteractions,
        averageSessionLength: _calculateAverageSessionLength(),
        popularQuestions: _analytics!.popularQuestions,
        lastAnalyzed: DateTime.now(),
      );
    }

    await _saveAnalytics();
  }

  /// Calculate average session length
  double _calculateAverageSessionLength() {
    if (_sessions.isEmpty) return 0.0;

    final totalMessages = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.messages.length,
    );

    return totalMessages / _sessions.length;
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
}
