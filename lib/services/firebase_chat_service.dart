// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/chat_models.dart';

/// Firebase-based chat storage service for persistent conversations
class FirebaseChatService {
  static final FirebaseChatService _instance = FirebaseChatService._internal();
  factory FirebaseChatService() => _instance;
  FirebaseChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get collection reference for user's chat sessions
  CollectionReference? get _sessionsCollection =>
      _userId != null
          ? _firestore
              .collection('users')
              .doc(_userId)
              .collection('chat_sessions')
          : null;

  /// Get collection reference for user's chat analytics
  DocumentReference? get _analyticsDocument =>
      _userId != null ? _firestore.collection('users').doc(_userId) : null;

  /// Save a chat session to Firebase
  Future<void> saveChatSession(ChatSession session) async {
    try {
      if (_sessionsCollection == null) {
        debugPrint('No user logged in, cannot save chat session');
        return;
      }

      await _sessionsCollection!.doc(session.id).set(session.toJson());
      debugPrint('Chat session saved: ${session.id}');
    } catch (e) {
      debugPrint('Error saving chat session: $e');
      rethrow;
    }
  }

  /// Load all chat sessions for the current user
  Future<List<ChatSession>> loadChatSessions() async {
    try {
      if (_sessionsCollection == null) {
        debugPrint('No user logged in, cannot load chat sessions');
        return [];
      }

      final snapshot =
          await _sessionsCollection!
              .orderBy('lastUpdatedAt', descending: true)
              .get();

      final sessions =
          snapshot.docs
              .map(
                (doc) =>
                    ChatSession.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();

      debugPrint('Loaded ${sessions.length} chat sessions from Firebase');
      return sessions;
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
      return [];
    }
  }

  /// Get a specific chat session by ID
  Future<ChatSession?> getChatSession(String sessionId) async {
    try {
      if (_sessionsCollection == null) return null;

      final doc = await _sessionsCollection!.doc(sessionId).get();
      if (!doc.exists) return null;

      return ChatSession.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting chat session: $e');
      return null;
    }
  }

  /// Delete a chat session
  Future<void> deleteChatSession(String sessionId) async {
    try {
      if (_sessionsCollection == null) return;

      await _sessionsCollection!.doc(sessionId).delete();
      debugPrint('Chat session deleted: $sessionId');
    } catch (e) {
      debugPrint('Error deleting chat session: $e');
      rethrow;
    }
  }

  /// Archive a chat session
  Future<void> archiveChatSession(String sessionId) async {
    try {
      if (_sessionsCollection == null) return;

      await _sessionsCollection!.doc(sessionId).update({
        'isArchived': true,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Chat session archived: $sessionId');
    } catch (e) {
      debugPrint('Error archiving chat session: $e');
      rethrow;
    }
  }

  /// Save chat analytics to Firebase
  Future<void> saveChatAnalytics(ChatAnalytics analytics) async {
    try {
      if (_analyticsDocument == null) return;

      await _analyticsDocument!.set({
        'chatAnalytics': analytics.toJson(),
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      debugPrint('Chat analytics saved to Firebase');
    } catch (e) {
      debugPrint('Error saving chat analytics: $e');
      rethrow;
    }
  }

  /// Load chat analytics from Firebase
  Future<ChatAnalytics?> loadChatAnalytics() async {
    try {
      if (_analyticsDocument == null) return null;

      final doc = await _analyticsDocument!.get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('chatAnalytics')) return null;

      return ChatAnalytics.fromJson(
        data['chatAnalytics'] as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Error loading chat analytics: $e');
      return null;
    }
  }

  /// Listen to chat sessions in real-time
  Stream<List<ChatSession>> watchChatSessions() {
    if (_sessionsCollection == null) {
      return Stream.value([]);
    }

    return _sessionsCollection!
        .orderBy('lastUpdatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ChatSession.fromJson(
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  /// Clear all chat data for the current user
  Future<void> clearAllChatData() async {
    try {
      if (_sessionsCollection == null) return;

      // Delete all chat sessions
      final sessions = await _sessionsCollection!.get();
      for (final doc in sessions.docs) {
        await doc.reference.delete();
      }

      // Clear analytics
      if (_analyticsDocument != null) {
        await _analyticsDocument!.update({
          'chatAnalytics': FieldValue.delete(),
        });
      }

      debugPrint('All chat data cleared from Firebase');
    } catch (e) {
      debugPrint('Error clearing chat data: $e');
      rethrow;
    }
  }

  /// Export chat sessions to JSON
  Future<String> exportChatSessions() async {
    try {
      final sessions = await loadChatSessions();
      final export = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': _userId,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
      return json.encode(export);
    } catch (e) {
      debugPrint('Error exporting chat sessions: $e');
      rethrow;
    }
  }
}
