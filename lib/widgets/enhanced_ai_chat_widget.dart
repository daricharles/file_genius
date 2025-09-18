// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../services/ai_service.dart';
import '../services/conversation_manager.dart';
import '../models/chat_models.dart';
import '../services/speech_service.dart';
import '../services/tts_coordinator.dart';
import 'flashcard_widget.dart';

class EnhancedAIChatWidget extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String fileContent;
  final String filePath;
  final String? fileId;
  final Map<String, dynamic>? fileMetadata; // stays
  final VoidCallback? onInteractionSuccess;
  final void Function(bool isCorrect)? onQuizAnswerSubmitted;
  final VoidCallback? onPerfectQuizAllCorrect;
  final bool autoSummarize;

  const EnhancedAIChatWidget({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.fileContent,
    required this.filePath,
    required this.fileId,
    this.fileMetadata, // <-- ADDED (initializes final field)
    this.onInteractionSuccess,
    this.onQuizAnswerSubmitted,
    this.onPerfectQuizAllCorrect,
    this.autoSummarize = false,
  });

  @override
  State<EnhancedAIChatWidget> createState() => _EnhancedAIChatWidgetState();
}

class _EnhancedAIChatWidgetState extends State<EnhancedAIChatWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final ConversationManager _conversationManager = ConversationManager.instance;
  final Uuid _uuid = const Uuid();
  final SpeechService _speechService = SpeechService();
  // Chat TTS UI state: which message is speaking and whether it's paused
  String? _speakingMessageId;
  bool _chatTtsPaused = false;

  ChatSession? _currentSession;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _aiTyping = false;
  bool _isSpeechServiceInitialized = false;
  bool _aiBusy = false;
  bool _autoSummaryRun = false;

  DateTime? _lastSendAt;
  String? _lastSendText;

  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  List<String> _followUps = []; // NEW

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
    _initializeSpeechService();
    // Reset chat TTS UI when another source (file preview) takes over
    TtsCoordinator.instance.addListener(() {
      if (!mounted) return;
      final active = TtsCoordinator.instance.activeSource;
      if (active != TtsSource.chat &&
          (_speakingMessageId != null || _chatTtsPaused)) {
        setState(() {
          _speakingMessageId = null;
          _chatTtsPaused = false;
        });
      }
    });
  }

  Future<void> _runAutoSummary() async {
    if (_autoSummaryRun || _aiBusy || widget.fileContent.trim().isEmpty) return;

    setState(() {
      _aiBusy = true;
      _autoSummaryRun = true; // Set this early to prevent re-runs
    });

    final res = await _aiService.summarizeFile(
      fileName: widget.fileName,
      fileType: widget.fileType,
      fileContent: widget.fileContent,
    );

    if (!mounted) return;

    if (res.success) {
      final summary = (res.data?['summary'] ?? '').toString();
      final followUps =
          (res.data?['follow_ups'] as List?)?.cast<String>() ?? [];

      // Persist the summary message with follow-ups in metadata
      await _appendAIMessage(
        '**Summary**\n\n$summary',
        messageType: 'summary',
        metadata: {'follow_ups': followUps},
      );

      if (!mounted) return;
      setState(() {
        _aiBusy = false;
        _followUps = followUps;
      });
    } else {
      // Persist the failure notice as well
      await _appendAIMessage(
        'Auto summary failed: ${res.message}. You can still ask questions.',
      );

      if (!mounted) return;
      setState(() {
        _aiBusy = false;
      });
    }
  }

  Future<void> _appendAIMessage(
    String text, {
    String messageType = 'response',
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentSession == null) return;
    final msg = EnhancedChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      messageType: messageType,
      metadata: metadata,
    );
    setState(() {
      _currentSession!.messages.add(msg);
    });
    // Persist message so it's restored on refresh/revisit
    await _conversationManager.addMessage(
      sessionId: _currentSession!.id,
      message: msg,
    );
    _scrollToBottom();
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeChat() async {
    await _loadChatSession();
  }

  Future<void> _initializeSpeechService() async {
    await _speechService.initialize();
    if (mounted) {
      setState(() => _isSpeechServiceInitialized = true);
    }
  }

  @override
  void didUpdateWidget(covariant EnhancedAIChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fileId != oldWidget.fileId ||
        widget.filePath != oldWidget.filePath ||
        widget.fileName != oldWidget.fileName) {
      setState(() => _isInitializing = true);
      _loadChatSession();
    }
  }

  Future<void> _loadChatSession() async {
    try {
      await _conversationManager.initialize();
      _currentSession = await _conversationManager.getOrCreateSession(
        fileName: widget.fileName,
        fileType: widget.fileType,
        filePath: widget.filePath,
        fileMetadata: widget.fileMetadata,
        fileId: widget.fileId,
      );

      // REMOVE any auto‑inserted greeting so only the summary (autoSummarize) appears
      if (_currentSession != null &&
          _currentSession!.messages.length == 1 &&
          !_currentSession!.messages.first.isUser) {
        final first = _currentSession!.messages.first.text;
        if (first.startsWith("Hello! I'm FileGenius AI")) {
          _currentSession!.messages.clear();
        }
      }

      if (!mounted) return;
      setState(() => _isInitializing = false);

      // Check if we have existing messages
      if (_currentSession!.messages.isNotEmpty) {
        // Extract follow-ups from existing chat history
        _extractFollowUpsFromHistory();
        // Mark auto-summary as already run since we have existing messages
        _autoSummaryRun = true;
      } else {
        // Only run auto-summary if there are no existing messages
        if (widget.autoSummarize && !_autoSummaryRun) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _runAutoSummary(),
          );
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom(isInitialScroll: true);
      });
    } catch (e) {
      if (mounted) setState(() => _isInitializing = false);
      debugPrint('Failed to initialize chat: $e');
    }
  }

  // Extract follow-ups from existing chat history
  void _extractFollowUpsFromHistory() {
    for (final message in _currentSession!.messages) {
      if (message.messageType == 'summary' && !message.isUser) {
        // Check if this message has follow-ups in metadata
        final metadata = message.metadata;
        if (metadata != null && metadata.containsKey('follow_ups')) {
          final followUps = metadata['follow_ups'] as List?;
          if (followUps != null) {
            setState(() {
              _followUps = followUps.cast<String>();
            });
            break; // Only get follow-ups from the first summary message
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? prompt, String? messageType}) async {
    final question = prompt ?? _questionController.text.trim();
    if (question.isEmpty || _currentSession == null) return;

    // NEW: Skip if last user message text matches (prevents duplicate after navigation/refresh)
    EnhancedChatMessage? lastUser;
    for (var i = _currentSession!.messages.length - 1; i >= 0; i--) {
      final m = _currentSession!.messages[i];
      if (m.isUser) {
        lastUser = m;
        break;
      }
    }
    if (lastUser != null && lastUser.text.trim() == question) {
      debugPrint('Skipped duplicate (same as last user message): $question');
      return;
    }

    final now = DateTime.now();
    if (_lastSendText == question &&
        _lastSendAt != null &&
        now.difference(_lastSendAt!) < const Duration(seconds: 2)) {
      return; // suppress rapid duplicate
    }
    _lastSendText = question;
    _lastSendAt = now;

    final userMessage = EnhancedChatMessage(
      id: _uuid.v4(),
      text: question,
      isUser: true,
      timestamp: DateTime.now(),
      messageType: messageType ?? 'question',
    );

    setState(() {
      _currentSession!.messages.add(userMessage);
      _isLoading = true;
      _aiTyping = true;
    });

    _typingAnimationController.repeat();
    _questionController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    await _conversationManager.addMessage(
      sessionId: _currentSession!.id,
      message: userMessage,
    );

    try {
      _conversationManager.getConversationContext(_currentSession!.id);

      // UPDATED: removed role/doc/format parameters
      final response = await _aiService.askQuestion(
        fileName: widget.fileName,
        fileType: widget.fileType,
        fileContent: widget.fileContent,
        question: question,
        // userRole: null, docType: null, preferredFormat: null  // <- if still required as named params keep nulls
      );

      _typingAnimationController.stop();

      if (response.success) {
        final answer = (response.data?['answer'] as String?)?.trim();
        if (answer == null || answer.isEmpty) {
          await _showErrorMessage('Empty response from AI');
          return;
        }

        // If this was a quiz request, try to parse JSON and store flashcards in metadata
        if ((messageType ?? 'question') == 'quiz') {
          final parsed = _tryParseQuizCards(answer);
          if (parsed != null && parsed.isNotEmpty) {
            final aiMessage = EnhancedChatMessage(
              id: _uuid.v4(),
              text:
                  'Quiz generated: ${parsed.length} cards. Flip each card to view the answer.',
              isUser: false,
              timestamp: DateTime.now(),
              messageType: 'quiz',
              metadata: {
                'model': response.data?['model'] ?? 'gemini-1.5-pro-latest',
                'cards': parsed,
                'prompt_tokens': response.data?['prompt_tokens'],
                'completion_tokens': response.data?['completion_tokens'],
              },
            );

            setState(() {
              _currentSession!.messages.add(aiMessage);
              _isLoading = false;
              _aiTyping = false;
            });

            await _conversationManager.addMessage(
              sessionId: _currentSession!.id,
              message: aiMessage,
            );

            widget.onInteractionSuccess?.call();
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );
          } else {
            // Fallback: show raw text but still as response
            final aiMessage = EnhancedChatMessage(
              id: _uuid.v4(),
              text: answer,
              isUser: false,
              timestamp: DateTime.now(),
              messageType: 'response',
              metadata: {
                'model': response.data?['model'] ?? 'gemini-1.5-pro-latest',
                'prompt_tokens': response.data?['prompt_tokens'],
                'completion_tokens': response.data?['completion_tokens'],
              },
            );

            setState(() {
              _currentSession!.messages.add(aiMessage);
              _isLoading = false;
              _aiTyping = false;
            });

            await _conversationManager.addMessage(
              sessionId: _currentSession!.id,
              message: aiMessage,
            );

            widget.onInteractionSuccess?.call();
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );
          }
        } else {
          final aiMessage = EnhancedChatMessage(
            id: _uuid.v4(),
            text: answer,
            isUser: false,
            timestamp: DateTime.now(),
            messageType: 'response',
            metadata: {
              'model': response.data?['model'] ?? 'gemini-1.5-pro-latest',
              'prompt_tokens': response.data?['prompt_tokens'],
              'completion_tokens': response.data?['completion_tokens'],
            },
          );

          setState(() {
            _currentSession!.messages.add(aiMessage);
            _isLoading = false;
            _aiTyping = false;
          });

          await _conversationManager.addMessage(
            sessionId: _currentSession!.id,
            message: aiMessage,
          );

          widget.onInteractionSuccess?.call();
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      } else {
        await _showErrorMessage(response.message);
      }
    } catch (e) {
      _typingAnimationController.stop();
      await _showErrorMessage('Failed to get response: $e');
    } finally {
      if (_typingAnimationController.isAnimating) {
        _typingAnimationController.stop();
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _aiTyping = false;
        });
      }
    }
  }

  Future<void> _sendUserPrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;

    // Set the prompt in the text field and send it
    _questionController.text = prompt;
    await _sendMessage(prompt: prompt);
  }

  Future<void> _showErrorMessage(String message) async {
    final errorMessage = EnhancedChatMessage(
      id: _uuid.v4(),
      text: '⚠️ **Error**: $message\n\nPlease try again.',
      isUser: false,
      timestamp: DateTime.now(),
      messageType: 'error',
      metadata: {'isError': true},
    );

    setState(() {
      _currentSession!.messages.add(errorMessage);
      _isLoading = false;
      _aiTyping = false;
    });

    await _conversationManager.addMessage(
      sessionId: _currentSession!.id,
      message: errorMessage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom({bool isInitialScroll = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (isInitialScroll) {
        _scrollController.jumpTo(max);
      } else {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    if (_currentSession == null) return;
    await _conversationManager.clearSession(_currentSession!.id);
    _currentSession = await _conversationManager.getOrCreateSession(
      fileName: widget.fileName,
      fileType: widget.fileType,
      filePath: widget.filePath,
      fileMetadata: widget.fileMetadata,
      fileId: widget.fileId,
    );
    setState(() {});
  }

  Future<void> _exportChat() async {
    if (_currentSession == null) return;
    try {
      final content = await _conversationManager.exportSession(
        sessionId: _currentSession!.id,
        format: ExportFormat.md,
      );
      await Clipboard.setData(ClipboardData(text: content));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat exported to clipboard!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bookmarkMessage(String messageId) async {
    if (_currentSession == null) return;
    final idx = _currentSession!.messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final m = _currentSession!.messages[idx];
    final updated = m.copyWith(isBookmarked: !m.isBookmarked);
    await _conversationManager.updateMessage(
      sessionId: _currentSession!.id,
      messageId: messageId,
      updatedMessage: updated,
    );
    _currentSession = await _conversationManager.getOrCreateSession(
      fileName: widget.fileName,
      fileType: widget.fileType,
      filePath: widget.filePath,
      fileMetadata: widget.fileMetadata,
      fileId: widget.fileId,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_currentSession == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text('Failed to load chat session'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeChat,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildMessageList()),
        if (_aiTyping) _buildTypingIndicator(),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.psychology,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.fileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildSessionInfo(),

          // NEW: Generate Quiz button
          IconButton(
            tooltip: 'Generate Quiz',
            icon: const Icon(Icons.quiz),
            onPressed: _openGenerateQuizDialog,
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder:
                (c) => const [
                  PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.clear_all),
                      title: Text('Clear chat'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text('Export chat'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      leading: Icon(Icons.archive),
                      title: Text('Archive session'),
                      dense: true,
                    ),
                  ),
                ],
            onSelected: (v) {
              switch (v) {
                case 'clear':
                  _clearChat();
                  break;
                case 'export':
                  _exportChat();
                  break;
                case 'archive':
                  if (_currentSession != null) {
                    _conversationManager.archiveSession(_currentSession!.id);
                  }
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  // NEW: Quiz dialog and dispatch
  void _openGenerateQuizDialog() {
    String quizType = 'MCQs';
    final controller = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Generate Quiz'),
          content: StatefulBuilder(
            builder:
                (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: quizType,
                      items: const [
                        DropdownMenuItem(value: 'MCQs', child: Text('MCQs')),
                        DropdownMenuItem(
                          value: 'True/False',
                          child: Text('True/False'),
                        ),
                        DropdownMenuItem(
                          value: 'Fill-in-the-Blank',
                          child: Text('Fill-in-the-Blank'),
                        ),
                      ],
                      onChanged: (v) => setState(() => quizType = v ?? 'MCQs'),
                      decoration: const InputDecoration(
                        labelText: 'Question type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number of questions (max 50)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final raw = int.tryParse(controller.text.trim()) ?? 0;
                final count = raw.clamp(1, 50);
                Navigator.pop(ctx);

                // Map to normalized types
                final type = () {
                  switch (quizType) {
                    case 'MCQs':
                      return 'mcq';
                    case 'True/False':
                      return 'true_false';
                    case 'Fill-in-the-Blank':
                      return 'fill_blank';
                    default:
                      return 'mcq';
                  }
                }();

                // Strict JSON instruction. No markdown fences. No prose.
                final prompt = [
                  'You are generating a flashcard quiz strictly in JSON for study.',
                  'Use ONLY this schema and return ONLY minified JSON with no markdown and no commentary:',
                  '{"cards":[{"type":"mcq","question":"...","options":["...","..."],"answer":"...","explanation":"..."}]}',
                  'Supported types: mcq | true_false | fill_blank.',
                  'Requirements:',
                  '- Create exactly $count cards of type $type.',
                  '- Questions must be relevant to the provided document content.',
                  '- Do NOT include answers inside the question text. Place them only in the answer field.',
                  '- For mcq: include 4 options and set answer to one of the options.',
                  '- For true_false: set answer to true or false (boolean).',
                  '- For fill_blank: use a clear sentence with a blank and provide the correct answer.',
                  'Return only: {"cards":[...]}',
                ].join(' ');

                await _sendMessage(prompt: prompt, messageType: 'quiz');
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionInfo() {
    if (_currentSession == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 14,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${_currentSession!.userMessageCount}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120, minHeight: 48),
              child: TextField(
                controller: _questionController,
                minLines: 1,
                maxLines: 1, // single-line to prevent newlines
                enabled: !_isLoading,
                textInputAction: TextInputAction.send, // Enter sends
                keyboardType: TextInputType.text,
                onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask about ${widget.fileName}...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon:
                      _isLoading
                          ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isSpeechServiceInitialized)
            ListenableBuilder(
              listenable: _speechService,
              builder:
                  (_, _) => IconButton(
                    icon: Icon(
                      _speechService.isListening ? Icons.mic : Icons.mic_none,
                      color:
                          _speechService.isListening
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                    ),
                    onPressed:
                        (_speechService.speechEnabled && !_isLoading)
                            ? () {
                              if (_speechService.isListening) {
                                _speechService.stopListening();
                              } else {
                                _speechService.startListening(
                                  onResult: (r) {
                                    if (r.isNotEmpty) {
                                      _questionController.text = r;
                                      setState(() {});
                                    }
                                  },
                                );
                              }
                            }
                            : null,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _speechService.isListening
                              ? Colors.red.withOpacity(0.1)
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : () => _sendMessage(),
            icon: Icon(
              Icons.send,
              color: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  _isLoading
                      ? Colors.grey.withOpacity(0.1)
                      : Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_currentSession!.messages.isEmpty) {
      return const Center(child: Text('Start a conversation!'));
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _currentSession!.messages.length,
      itemBuilder:
          (context, i) => _buildMessageWidget(_currentSession!.messages[i]),
    );
  }

  Widget _buildMessageWidget(EnhancedChatMessage message) {
    final isUser = message.isUser;
    final isError = message.metadata?['isError'] == true;
    final isSummary = message.messageType == 'summary';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                _getMessageTypeIcon(message.messageType ?? 'chat'),
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isUser
                            ? Theme.of(context).primaryColor
                            : isError
                            ? Colors.red.shade50
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        isError ? Border.all(color: Colors.red.shade200) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isUser
                          ? Text(
                            message.text,
                            style: const TextStyle(color: Colors.white),
                          )
                          : MarkdownBody(
                            data: message.text,
                            styleSheet: MarkdownStyleSheet(
                              p: Theme.of(context).textTheme.bodyMedium,
                              strong: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),

                      // Render flashcards for quiz messages
                      if (!isUser && message.messageType == 'quiz') ...[
                        const SizedBox(height: 12),
                        _buildFlashcards(
                          message.metadata?['cards'],
                          parentMessage: message,
                        ),
                      ],

                      // Show follow-ups for summary messages
                      if (isSummary && _followUps.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Follow-up Questions:',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _followUps.map((question) {
                                return ActionChip(
                                  label: Text(
                                    question,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed:
                                      _aiBusy
                                          ? null
                                          : () => _sendUserPrompt(question),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.3),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                if (!isUser && !isError)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () => _bookmarkMessage(message.id),
                        icon: Icon(
                          message.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 16,
                          color:
                              message.isBookmarked
                                  ? Colors.amber
                                  : Colors.grey[600],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip:
                            message.isBookmarked
                                ? 'Remove bookmark'
                                : 'Bookmark',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Copy',
                      ),
                      const SizedBox(width: 4),
                      if (_isSpeechServiceInitialized)
                        ListenableBuilder(
                          listenable: TtsCoordinator.instance,
                          builder: (_, _) {
                            final isThisSpeaking =
                                _speakingMessageId == message.id &&
                                TtsCoordinator.instance.activeSource ==
                                    TtsSource.chat &&
                                TtsCoordinator.instance.activeMessageId ==
                                    message.id;
                            final isPaused = isThisSpeaking && _chatTtsPaused;
                            return IconButton(
                              icon: Icon(
                                isThisSpeaking
                                    ? (isPaused
                                        ? Icons.play_arrow
                                        : Icons.pause)
                                    : Icons.volume_up,
                              ),
                              onPressed: () async {
                                try {
                                  // If tapping the same message that's currently speaking
                                  if (_speakingMessageId == message.id &&
                                      TtsCoordinator.instance.activeSource ==
                                          TtsSource.chat) {
                                    if (_chatTtsPaused) {
                                      final ok = await _speechService.resume();
                                      if (!ok) {
                                        await _speechService.stop();
                                        TtsCoordinator.instance.setActive(
                                          source: TtsSource.chat,
                                          messageId: message.id,
                                        );
                                        await _speechService.speak(
                                          message.text,
                                          onComplete: () {
                                            if (!mounted) return;
                                            setState(() {
                                              _speakingMessageId = null;
                                              _chatTtsPaused = false;
                                            });
                                            TtsCoordinator.instance
                                                .clearIfMatches(
                                                  source: TtsSource.chat,
                                                  messageId: message.id,
                                                );
                                          },
                                        );
                                      }
                                      if (mounted)
                                        setState(() => _chatTtsPaused = false);
                                    } else {
                                      try {
                                        await _speechService.pause();
                                        if (mounted)
                                          setState(() => _chatTtsPaused = true);
                                      } catch (_) {
                                        await _speechService.stop();
                                        if (mounted)
                                          setState(() {
                                            _chatTtsPaused = false;
                                            _speakingMessageId = null;
                                          });
                                      }
                                    }
                                    return;
                                  }

                                  // Otherwise, start playing this message anew
                                  if (TtsCoordinator.instance.activeSource !=
                                          null &&
                                      TtsCoordinator.instance.activeSource !=
                                          TtsSource.chat) {
                                    await _speechService.stop();
                                  }
                                  _speakingMessageId = message.id;
                                  _chatTtsPaused = false;
                                  setState(() {});
                                  await _speechService.stop();
                                  // Mark coordinator for chat
                                  TtsCoordinator.instance.setActive(
                                    source: TtsSource.chat,
                                    messageId: message.id,
                                  );
                                  await _speechService.speak(
                                    message.text,
                                    onComplete: () {
                                      if (!mounted) return;
                                      setState(() {
                                        _speakingMessageId = null;
                                        _chatTtsPaused = false;
                                      });
                                      TtsCoordinator.instance.clearIfMatches(
                                        source: TtsSource.chat,
                                        messageId: message.id,
                                      );
                                    },
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('TTS failed: $e')),
                                  );
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip:
                                  isThisSpeaking
                                      ? (isPaused ? 'Resume' : 'Pause')
                                      : 'Read aloud',
                            );
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                    if (message.isBookmarked) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.bookmark, size: 12, color: Colors.amber[600]),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.psychology,
              color: Theme.of(context).primaryColor,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _typingAnimation,
            builder:
                (context, _) => Row(
                  children: List.generate(3, (i) {
                    final opacity =
                        0.3 +
                        (0.7 * (((_typingAnimation.value + i * 0.3) % 1.0)));
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
          ),
          const SizedBox(width: 8),
          Text(
            'AI is thinking...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMessageTypeIcon(String messageType) {
    switch (messageType.toLowerCase()) {
      case 'summary':
        return Icons.summarize;
      case 'analysis':
        return Icons.analytics;
      case 'quiz':
        return Icons.quiz;
      case 'quick action':
        return Icons.flash_on;
      case 'follow_up':
        return Icons.reply;
      case 'error':
        return Icons.error;
      default:
        return Icons.chat;
    }
  }

  // Try to parse JSON array of cards from AI answer
  List<Map<String, dynamic>>? _tryParseQuizCards(String raw) {
    try {
      // Extract first {...} block in case model sends prose or fences
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) return null;
      final jsonStr = raw.substring(start, end + 1);
      final Map<String, dynamic> decoded = json.decode(jsonStr);
      final cards = decoded['cards'];
      if (cards is List) {
        // Normalize entries to map
        return cards
            .whereType<dynamic>()
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Build a grid/column of flashcards using FlashcardWidget
  Widget _buildFlashcards(
    dynamic cardsRaw, {
    required EnhancedChatMessage parentMessage,
  }) {
    if (cardsRaw is! List) return const SizedBox.shrink();
    final cards =
        cardsRaw
            .whereType<dynamic>()
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Simple responsive width
        final maxWidth = constraints.maxWidth;
        final crossAxisCount =
            maxWidth > 900
                ? 3
                : maxWidth > 600
                ? 2
                : 1;
        final itemWidth =
            (maxWidth - (12 * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              cards.asMap().entries.map((entry) {
                final idx = entry.key;
                final card = entry.value;
                final type = (card['type'] ?? '').toString();
                final q = (card['question'] ?? '').toString();
                final explanation = (card['explanation'] ?? '').toString();
                String question = q;
                String answer;

                switch (type) {
                  case 'mcq':
                    final options =
                        (card['options'] as List?)
                            ?.cast<dynamic>()
                            .map((e) => e.toString())
                            .toList() ??
                        const <String>[];
                    final ans = (card['answer'] ?? '').toString();
                    final optsText =
                        options.isEmpty
                            ? ''
                            : '\n\nOptions:\n${List.generate(options.length, (i) => '${String.fromCharCode(65 + i)}. ${options[i]}').join('\n')}';
                    question = q + optsText;
                    answer =
                        'Answer: $ans${explanation.isNotEmpty ? '\n\n$explanation' : ''}';
                    break;
                  case 'true_false':
                    final ansRaw = card['answer'];
                    final boolAns =
                        (ansRaw is bool)
                            ? ansRaw
                            : ansRaw.toString().toLowerCase().trim() == 'true';
                    answer =
                        'Answer: ${boolAns ? 'True' : 'False'}${explanation.isNotEmpty ? '\n\n$explanation' : ''}';
                    break;
                  case 'fill_blank':
                  case 'fill-in-the-blank':
                    final ans = (card['answer'] ?? '').toString();
                    answer =
                        'Answer: $ans${explanation.isNotEmpty ? '\n\n$explanation' : ''}';
                    break;
                  default:
                    final ans = (card['answer'] ?? '').toString();
                    answer =
                        'Answer: $ans${explanation.isNotEmpty ? '\n\n$explanation' : ''}';
                }

                // Determine if this card was previously answered from THIS message metadata
                final answered =
                    (parentMessage.metadata?['answeredIndexes'] as List?)
                        ?.cast<int>() ??
                    const <int>[];

                return SizedBox(
                  width: itemWidth,
                  child: FlashcardWidget(
                    question: question,
                    answer: answer,
                    index: idx,
                    type: type,
                    options:
                        (card['options'] as List?)
                            ?.map((e) => e.toString())
                            .toList(),
                    initiallyAnswered: answered.contains(idx),
                    onAnswered: (isCorrect) async {
                      widget.onQuizAnswerSubmitted?.call(isCorrect);
                      // Persist that this flashcard index was answered to prevent re-answers
                      try {
                        // Persist against the same parentMessage (this quiz block)
                        final quizIndex = _currentSession!.messages.indexWhere(
                          (m) => m.id == parentMessage.id,
                        );
                        if (quizIndex != -1) {
                          final quizMsg = _currentSession!.messages[quizIndex];
                          final meta = Map<String, dynamic>.from(
                            quizMsg.metadata ?? {},
                          );
                          final List<int> answeredIdx =
                              (meta['answeredIndexes'] as List?)?.cast<int>() ??
                              <int>[];
                          if (!answeredIdx.contains(idx)) {
                            answeredIdx.add(idx);
                          }
                          // Track correctness as well
                          final List<int> correctIdx =
                              (meta['correctIndexes'] as List?)?.cast<int>() ??
                              <int>[];
                          if (isCorrect && !correctIdx.contains(idx)) {
                            correctIdx.add(idx);
                          }
                          // Check for perfect quiz condition (all answered and all correct)
                          final totalCards = cards.length;
                          final bool alreadyRewarded =
                              meta['rewardedPerfect'] == true;
                          final bool allAnswered =
                              answeredIdx.length >= totalCards;
                          final bool allCorrect =
                              correctIdx.length >= totalCards;
                          meta['answeredIndexes'] = answeredIdx;
                          meta['correctIndexes'] = correctIdx;
                          // Update message locally and in Firestore
                          final updated = quizMsg.copyWith(metadata: meta);
                          _currentSession!.messages[quizIndex] = updated;
                          await _conversationManager.updateMessage(
                            sessionId: _currentSession!.id,
                            messageId: quizMsg.id,
                            updatedMessage: updated,
                          );
                          // Trigger perfect-quiz reward once
                          if (!alreadyRewarded && allAnswered && allCorrect) {
                            // Mark rewarded flag first to avoid duplicates
                            final rewardedMeta = Map<String, dynamic>.from(
                              updated.metadata ?? {},
                            );
                            rewardedMeta['rewardedPerfect'] = true;
                            final rewardedMsg = updated.copyWith(
                              metadata: rewardedMeta,
                            );
                            _currentSession!.messages[quizIndex] = rewardedMsg;
                            await _conversationManager.updateMessage(
                              sessionId: _currentSession!.id,
                              messageId: rewardedMsg.id,
                              updatedMessage: rewardedMsg,
                            );
                            // Now call the callback to grant XP and celebrate
                            widget.onPerfectQuizAllCorrect?.call();
                          }
                          setState(() {});
                        }
                      } catch (e) {
                        debugPrint('Failed to persist answered state: $e');
                      }
                    },
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  String _formatTime(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(ts);
    return DateFormat('MMM d, HH:mm').format(ts);
  }
}
