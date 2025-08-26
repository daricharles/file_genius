// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../services/ai_service.dart';
import '../services/conversation_manager.dart';
import '../models/chat_models.dart';
import '../services/speech_service.dart';

class EnhancedAIChatWidget extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String fileContent;
  final String filePath;
  final String? fileId;
  final Map<String, dynamic>? fileMetadata; // stays
  final VoidCallback? onInteractionSuccess;
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

        final aiMessage = EnhancedChatMessage(
          id: _uuid.v4(),
          text: answer,
          isUser: false,
          timestamp: DateTime.now(),
          messageType: 'response',
          metadata: {
            'model': response.data?['model'] ?? 'gemini-1.5-flash-latest',
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
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder:
                (c) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.clear_all),
                      title: Text('Clear chat'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text('Export chat'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
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
                maxLines: 4,
                enabled: !_isLoading,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
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
                onSubmitted: _isLoading ? null : (_) => _sendMessage(),
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
                          listenable: _speechService,
                          builder:
                              (_, _) => IconButton(
                                icon: Icon(
                                  _speechService.isSpeaking
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                ),
                                onPressed: () {
                                  if (_speechService.isSpeaking) {
                                    _speechService.stop();
                                  } else {
                                    _speechService.speak(message.text);
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Read aloud',
                              ),
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

  String _formatTime(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(ts);
    return DateFormat('MMM d, HH:mm').format(ts);
  }
}
