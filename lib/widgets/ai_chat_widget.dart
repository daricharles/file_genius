// Cleaned: removed welcome message + role/doc/format selections + broken fragments.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

import '../services/ai_service.dart';

class AIChatWidget extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String fileContent;
  final String? fileId;
  final VoidCallback? onInteractionSuccess;
  final bool autoSummarize;

  const AIChatWidget({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.fileContent,
    this.fileId,
    this.onInteractionSuccess,
    this.autoSummarize = false,
  });

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  // Simple in‑memory per file session cache
  static final Map<String, List<ChatMessage>> _sessionMessages = {};

  late final String _sessionKey;

  bool _isSending = false;
  bool _aiTyping = false;
  String? _errorMessage;

  String? _lastSentText;
  DateTime? _lastSentAt;

  final List<String> _quickPrompts = const [
    "Summarize this file",
    "List the main points",
    "What is this about?",
  ];

  late List<ChatMessage> _messages;

  bool _summaryRequested = false;
  List<String> _dynamicFollowUps = [];

  @override
  void initState() {
    super.initState();
    _sessionKey = widget.fileId ?? '${widget.fileName}_${widget.fileType}';
    _sessionMessages.putIfAbsent(_sessionKey, () => <ChatMessage>[]);
    _messages = _sessionMessages[_sessionKey]!;

    if (widget.autoSummarize && !_summaryRequested) {
      _summaryRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoSummary());
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runAutoSummary() async {
    if (widget.fileContent.trim().isEmpty) return;
    setState(() {
      _aiTyping = true;
    });
    final res = await _aiService.summarizeFile(
      fileName: widget.fileName,
      fileType: widget.fileType,
      fileContent: widget.fileContent,
    );
    if (!mounted) return;
    setState(() {
      _aiTyping = false;
      if (res.success) {
        final summary = res.data?['summary'] ?? 'No summary returned.';
        _messages.add(ChatMessage(
          text: '**Auto Summary**\n\n$summary',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _dynamicFollowUps =
            (res.data?['follow_ups'] as List?)?.cast<String>() ?? [];
      } else {
        _messages.add(ChatMessage(
          text:
              'Failed to auto-summarize this file. You can still ask questions.\n\nError: ${res.message}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage({String? prompt}) async {
    final raw = prompt ?? _questionController.text;
    final question = raw.trim();
    if (question.isEmpty) return;
    if (_isSending) return;

    // Prevent identical immediate resend
    final now = DateTime.now();
    if (_lastSentText != null &&
        _lastSentText == question &&
        _lastSentAt != null &&
        now.difference(_lastSentAt!) < const Duration(seconds: 2)) {
      return;
    }

    // Prevent same as last user message anytime
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        if (_messages[i].text.trim() == question) return;
        break;
      }
    }

    _lastSentText = question;
    _lastSentAt = now;

    setState(() {
      _isSending = true;
      _aiTyping = true;
      _errorMessage = null;
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _questionController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.askQuestion(
        fileName: widget.fileName,
        fileType: widget.fileType,
        fileContent: widget.fileContent,
        question: question,
      );
      if (!mounted) return;
      if (response.success) {
        setState(() {
          _aiTyping = false;
          _messages.add(ChatMessage(
            text: response.data!['answer'],
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        widget.onInteractionSuccess?.call();
      } else {
        setState(() {
          _aiTyping = false;
          _errorMessage = response.message;
          if (response.message.contains('Rate limit')) {
            _messages.add(ChatMessage(
              text:
                  '⚠️ **Rate Limit Reached**\n\n${response.message}\n\n**Suggestions:**\n• Wait and retry\n• Check usage dashboard\n• Shorten the question\n• Consider upgrading your plan',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiTyping = false;
        _errorMessage = 'Failed to get response: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildChips() {
    final chips = <Widget>[
      ..._quickPrompts.map(
        (p) => ActionChip(
          label: Text(p),
            onPressed: _isSending ? null : () => _sendMessage(prompt: p),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ];
    if (_dynamicFollowUps.isNotEmpty) {
      chips.add(const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Text(
          'Follow-ups:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ));
      chips.addAll(_dynamicFollowUps.map(
        (q) => InputChip(
          label: Text(q),
          onPressed: _isSending ? null : () => _sendMessage(prompt: q),
          tooltip: 'Ask follow-up',
        ),
      ));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: chips,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.08),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.psychology,
                  color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Assistant - ${widget.fileName}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (c) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 18),
                        SizedBox(width: 8),
                        Text('Clear chat'),
                      ],
                    ),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'clear') {
                    setState(() {
                      _messages.clear();
                      _dynamicFollowUps.clear();
                    });
                  }
                },
              ),
            ],
          ),
        ),

        _buildChips(),

        // Messages
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Text('Start a conversation about your file.'),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_aiTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _aiTyping) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 16),
                            Text('AI is typing...'),
                          ],
                        ),
                      );
                    }
                    final msg = _messages[index];
                    return ChatMessageWidget(message: msg);
                  },
                ),
        ),

        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _errorMessage = null),
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

        // Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 120, minHeight: 48),
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Ask about ${widget.fileName}...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    keyboardType: TextInputType.multiline,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Send',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isSending
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.psychology, color: Colors.white, size: 16),
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
                    color: isUser
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isUser
                        ? null
                        : Border.all(
                            color: Theme.of(context).dividerColor, width: 1),
                    boxShadow: [
                      if (!isUser)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: message.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Response copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Copy response',
                            ),
                          ],
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
                                strong: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Icon(Icons.person,
                  color: Theme.of(context).primaryColor, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime ts) =>
      '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
}
