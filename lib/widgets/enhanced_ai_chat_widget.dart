// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../services/ai_service.dart';
import '../services/conversation_manager.dart';
import '../models/chat_models.dart';
import 'package:intl/intl.dart';
import '../services/speech_service.dart';

class EnhancedAIChatWidget extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String fileContent;
  final String filePath;
  final Map<String, dynamic>? fileMetadata;
  final VoidCallback? onInteractionSuccess;

  const EnhancedAIChatWidget({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.fileContent,
    required this.filePath,
    this.fileMetadata,
    this.onInteractionSuccess,
  });

  @override
  State<EnhancedAIChatWidget> createState() => _EnhancedAIChatWidgetState();
}

class _EnhancedAIChatWidgetState extends State<EnhancedAIChatWidget>
    with TickerProviderStateMixin {
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

  // UI State
  String? _selectedRole;
  String? _selectedDocType;
  String? _selectedFormat;

  // Animation controllers
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  final List<String> _roles = [
    'Student',
    'Researcher',
    'Teacher',
    'Professional',
    'Other',
  ];
  final List<String> _docTypes = [
    'Notes',
    'Lecture Slides',
    'Research Paper',
    'Report',
    'Other',
  ];
  final List<String> _formats = [
    'Bullet Points',
    'Numbered List',
    'Paragraph',
    'Table',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
    _initializeSpeechService();
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeChat() async {
    await _loadChatSession();
  }

  Future<void> _initializeSpeechService() async {
    await _speechService.initialize();
    setState(() {
      _isSpeechServiceInitialized = true;
    });
  }

  @override
  void didUpdateWidget(EnhancedAIChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reinitialize if the actual file has changed, not just parent state
    if (widget.filePath != oldWidget.filePath ||
        widget.fileName != oldWidget.fileName) {
      setState(() {
        _isInitializing = true;
      });
      _loadChatSession();
    }
    // Ignore other property changes that don't affect the chat session
  }

  Future<void> _loadChatSession() async {
    try {
      await _conversationManager.initialize();

      _currentSession = await _conversationManager.getOrCreateSession(
        fileName: widget.fileName,
        fileType: widget.fileType,
        filePath: widget.filePath,
        fileMetadata: widget.fileMetadata,
      );

      if (!mounted) return;

      // Set state to false to trigger a rebuild with the new chat session.
      setState(() {
        _isInitializing = false;
      });

      // After the UI has been rebuilt with the new messages, scroll to the bottom.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom(isInitialScroll: true);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      debugPrint('Failed to initialize chat: $e');
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

    final messageId = _uuid.v4();
    final userMessage = EnhancedChatMessage(
      id: messageId,
      text: question,
      isUser: true,
      timestamp: DateTime.now(),
      messageType: messageType ?? 'question',
    );

    // Add user message to UI immediately and update loading state
    setState(() {
      _currentSession!.messages.add(userMessage);
      _isLoading = true;
      _aiTyping = true;
    });

    _typingAnimationController.repeat();
    _questionController.clear();

    // Scroll to bottom after the user message is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Add user message to session in the background
    await _conversationManager.addMessage(
      sessionId: _currentSession!.id,
      message: userMessage,
    );

    try {
      // Get conversation context for better AI responses
      _conversationManager.getConversationContext(_currentSession!.id);

      final response = await _aiService.askQuestion(
        fileName: widget.fileName,
        fileType: widget.fileType,
        fileContent: widget.fileContent,
        question: question,
        userRole: _selectedRole,
        docType: _selectedDocType,
        preferredFormat: _selectedFormat,
      );

      _typingAnimationController.stop();

      if (response.success) {
        final aiResponseId = _uuid.v4();
        final aiMessage = EnhancedChatMessage(
          id: aiResponseId,
          text: response.data!['answer'],
          isUser: false,
          timestamp: DateTime.now(),
          messageType: 'response',
          metadata: {
            'model': 'gemini-1.5-flash-latest',
            'prompt_tokens': response.data?['prompt_tokens'],
            'completion_tokens': response.data?['completion_tokens'],
          },
        );

        // Add AI response to UI and update loading state
        setState(() {
          _currentSession!.messages.add(aiMessage);
          _isLoading = false;
          _aiTyping = false;
        });

        // Add AI message to session in the background
        await _conversationManager.addMessage(
          sessionId: _currentSession!.id,
          message: aiMessage,
        );

        // Call success callback
        widget.onInteractionSuccess?.call();

        // Scroll to bottom after AI response is added
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        // Handle error state
        await _showErrorMessage(response.message);
      }
    } catch (e) {
      _typingAnimationController.stop();
      // Handle error state
      await _showErrorMessage('Failed to get response: ${e.toString()}');
    }
  }

  Future<void> _showErrorMessage(String message) async {
    final errorId = _uuid.v4();
    final errorMessage = EnhancedChatMessage(
      id: errorId,
      text:
          '⚠️ **Error**: $message\n\nPlease try again or contact support if the issue persists.',
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

    // Scroll to bottom after error message is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom({bool isInitialScroll = false}) {
    // Use post-frame callback to ensure the UI has been updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performScrollToBottom(isInitialScroll: isInitialScroll);
    });
  }

  void _performScrollToBottom({
    bool isInitialScroll = false,
    int retryCount = 0,
  }) {
    if (!_scrollController.hasClients) return;

    // Get the current max extent
    final currentMaxExtent = _scrollController.position.maxScrollExtent;
    final currentPosition = _scrollController.position.pixels;

    // If we're already at the bottom or this is the first message, no need to scroll
    if (currentMaxExtent == 0 || (currentPosition >= currentMaxExtent - 10)) {
      return;
    }

    if (isInitialScroll) {
      // For initial scroll, jump directly
      _scrollController.jumpTo(currentMaxExtent);
    } else {
      // For new messages, animate to bottom
      _scrollController
          .animateTo(
            currentMaxExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) {
            // Double-check if we actually reached the bottom after animation
            // Sometimes the maxScrollExtent changes during animation due to text rendering
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                final newMaxExtent = _scrollController.position.maxScrollExtent;
                final newPosition = _scrollController.position.pixels;

                // If we're not at the bottom and the content has grown, scroll again
                if (newPosition < newMaxExtent - 10 && retryCount < 2) {
                  Future.delayed(const Duration(milliseconds: 50), () {
                    _performScrollToBottom(
                      isInitialScroll: false,
                      retryCount: retryCount + 1,
                    );
                  });
                }
              }
            });
          });
    }
  }

  Future<void> _clearChat() async {
    if (_currentSession != null) {
      await _conversationManager.clearSession(_currentSession!.id);
      // Refresh current session reference to get updated state
      _currentSession = await _conversationManager.getOrCreateSession(
        fileName: widget.fileName,
        fileType: widget.fileType,
        filePath: widget.filePath,
        fileMetadata: widget.fileMetadata,
      );
      setState(() {
        // Trigger rebuild to show cleared chat
      });
    }
  }

  Future<void> _exportChat() async {
    if (_currentSession == null) return;

    try {
      final content = await _conversationManager.exportSession(
        sessionId: _currentSession!.id,
        format: ExportFormat.md,
      );

      await Clipboard.setData(ClipboardData(text: content));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat exported to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bookmarkMessage(String messageId) async {
    if (_currentSession == null) return;

    final messageIndex = _currentSession!.messages.indexWhere(
      (m) => m.id == messageId,
    );
    if (messageIndex != -1) {
      final message = _currentSession!.messages[messageIndex];
      final updatedMessage = message.copyWith(
        isBookmarked: !message.isBookmarked,
      );

      await _conversationManager.updateMessage(
        sessionId: _currentSession!.id,
        messageId: messageId,
        updatedMessage: updatedMessage,
      );

      // Refresh current session reference to get updated state
      _currentSession = await _conversationManager.getOrCreateSession(
        fileName: widget.fileName,
        fileType: widget.fileType,
        filePath: widget.filePath,
        fileMetadata: widget.fileMetadata,
      );

      setState(() {
        // Trigger rebuild to show updated bookmark state
      });
    }
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
        _buildRoleSelections(),
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
            tooltip: 'Chat options',
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: const [
                        Icon(Icons.clear_all, size: 18),
                        SizedBox(width: 8),
                        Text('Clear chat'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: const [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Export chat'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: const [
                        Icon(Icons.archive, size: 18),
                        SizedBox(width: 8),
                        Text('Archive session'),
                      ],
                    ),
                  ),
                ],
            onSelected: (value) {
              switch (value) {
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
    if (_currentSession == null) return const SizedBox();

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

  Widget _buildRoleSelections() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 500) {
            return Column(
              children: [
                _buildDropdown(
                  'Role',
                  _selectedRole,
                  _roles,
                  (val) => setState(() => _selectedRole = val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        'Doc Type',
                        _selectedDocType,
                        _docTypes,
                        (val) => setState(() => _selectedDocType = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        'Format',
                        _selectedFormat,
                        _formats,
                        (val) => setState(() => _selectedFormat = val),
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Role',
                    _selectedRole,
                    _roles,
                    (val) => setState(() => _selectedRole = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    'Doc Type',
                    _selectedDocType,
                    _docTypes,
                    (val) => setState(() => _selectedDocType = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    'Format',
                    _selectedFormat,
                    _formats,
                    (val) => setState(() => _selectedFormat = val),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: const TextStyle(fontSize: 12)),
      items:
          items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_currentSession?.messages.isEmpty ?? true) {
      return const Center(child: Text('Start a conversation!'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _currentSession!.messages.length,
      itemBuilder: (context, index) {
        final message = _currentSession!.messages[index];
        return _buildMessageWidget(message);
      },
    );
  }

  Widget _buildMessageWidget(EnhancedChatMessage message) {
    final isUser = message.isUser;
    final isError = message.metadata?['isError'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  isError
                      ? Colors.red[100]
                      : Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                isError ? Icons.error : Icons.psychology,
                color:
                    isError ? Colors.red[600] : Theme.of(context).primaryColor,
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
                            ? Colors.red[50]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12).copyWith(
                      topLeft:
                          isUser
                              ? const Radius.circular(12)
                              : const Radius.circular(4),
                      topRight:
                          isUser
                              ? const Radius.circular(4)
                              : const Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.messageType != null &&
                          message.messageType != 'question' &&
                          message.messageType != 'response')
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getMessageTypeIcon(message.messageType!),
                                size: 12,
                                color:
                                    isUser ? Colors.white70 : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                message.messageType!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isUser
                                          ? Colors.white70
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      if (!isUser && !isError)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Spacer(),
                            // Bookmark button
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
                                      : 'Bookmark response',
                            ),
                            const SizedBox(width: 4),
                            // Copy button
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: message.text),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Copy response',
                            ),
                            const SizedBox(width: 4),
                            // TTS button
                            if (_isSpeechServiceInitialized)
                              ListenableBuilder(
                                listenable: _speechService,
                                builder: (context, child) {
                                  return IconButton(
                                    icon: Icon(
                                      _speechService.isSpeaking &&
                                              !_speechService.isPaused
                                          ? Icons.volume_up
                                          : _speechService.isPaused
                                          ? Icons.pause
                                          : Icons.volume_off,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      if (_speechService.isSpeaking) {
                                        if (_speechService.isPaused) {
                                          _speechService.speak(message.text);
                                        } else {
                                          _speechService.pause();
                                        }
                                      } else {
                                        _speechService.speak(message.text);
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip:
                                        _speechService.isSpeaking
                                            ? (_speechService.isPaused
                                                ? 'Resume'
                                                : 'Pause')
                                            : 'Read aloud',
                                  );
                                },
                              ),
                            // Stop TTS button
                            if (_isSpeechServiceInitialized)
                              ListenableBuilder(
                                listenable: _speechService,
                                builder: (context, child) {
                                  return _speechService.isSpeaking
                                      ? IconButton(
                                        icon: Icon(
                                          Icons.stop,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () => _speechService.stop(),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Stop reading',
                                      )
                                      : const SizedBox.shrink();
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
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
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(
                        0.3 +
                            (0.7 *
                                (((_typingAnimation.value + index * 0.3) %
                                    1.0))),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
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

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 120, // Set maximum height
                minHeight: 48, // Set minimum height
              ),
              child: TextField(
                controller: _questionController,
                minLines: 1,
                maxLines: 4, // cap height; internal scroll after 4 lines
                enabled: !_isLoading,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Ask a question about ${widget.fileName}...',
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
                          ? Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.all(12),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                          : null,
                ),
                onSubmitted: _isLoading ? null : (value) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // STT button
          if (_isSpeechServiceInitialized)
            ListenableBuilder(
              listenable: _speechService,
              builder: (context, child) {
                return IconButton(
                  icon: Icon(
                    _speechService.isListening ? Icons.mic : Icons.mic_none,
                    color:
                        _speechService.isListening
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                  ),
                  onPressed:
                      _speechService.speechEnabled && !_isLoading
                          ? () {
                            if (_speechService.isListening) {
                              _speechService.stopListening();
                            } else {
                              _speechService.startListening(
                                onResult: (result) {
                                  if (result.isNotEmpty) {
                                    _questionController.text = result;
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
                );
              },
            ),
          const SizedBox(width: 8),
          // Send button
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }
}
