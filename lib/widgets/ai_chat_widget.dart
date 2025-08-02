// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';

class AIChatWidget extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String fileContent;

  const AIChatWidget({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.fileContent,
  });

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  // For typing indicator
  bool _aiTyping = false;

  // Quick prompt suggestions
  final List<String> _quickPrompts = [
    "Summarize this file",
    "List the main points",
    "What is this about?",
  ];

  final List<String> _roles = ['Student', 'Researcher', 'Teacher', 'Other'];
  final List<String> _docTypes = [
    'Notes',
    'Lecture Slides',
    'Exam Prep',
    'Other',
  ];
  final List<String> _formats = [
    'Bullet Points',
    'Numbered List',
    'Paragraph',
    'Other',
  ];

  String? _selectedRole;
  String? _selectedDocType;
  String? _selectedFormat;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text:
            'Hello! I\'m FileGenius AI. I can help you analyze "${widget.fileName}" and answer questions about it. What would you like to know?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? prompt}) async {
    final question = prompt ?? _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: question, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
      _aiTyping = true;
      _errorMessage = null;
    });

    _questionController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.askQuestion(
        fileName: widget.fileName,
        fileType: widget.fileType,
        fileContent: widget.fileContent,
        question: question,
        userRole: _selectedRole,
        docType: _selectedDocType,
        preferredFormat: _selectedFormat,
      );

      setState(() {
        _isLoading = false;
        _aiTyping = false;
        if (response.success) {
          _messages.add(
            ChatMessage(
              text: response.data!['answer'],
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          _errorMessage = response.message;

          // If it's a rate limit error, show a helpful message
          if (response.message.contains('Rate limit')) {
            _messages.add(
              ChatMessage(
                text:
                    '⚠️ **Rate Limit Reached**\n\nI\'ve hit the OpenAI rate limit. ${response.message}\n\n**What you can do:**\n• Wait for the specified time and try again\n• Check your usage at https://platform.openai.com/usage\n• Consider upgrading your OpenAI plan for higher limits\n• Try asking a shorter question next time',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _aiTyping = false;
        _errorMessage = 'Failed to get response: ${e.toString()}';
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with quick actions and menu
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
              Icon(
                Icons.psychology,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Assistant - ${widget.fileName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More actions',
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
                    ],
                onSelected: (value) {
                  if (value == 'clear') {
                    setState(() {
                      _messages.clear();
                      _addWelcomeMessage();
                    });
                  }
                  // Implement export if needed
                },
              ),
            ],
          ),
        ),

        // Quick prompt chips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                _quickPrompts.map((prompt) {
                  return ActionChip(
                    label: Text(prompt),
                    onPressed:
                        _isLoading ? null : () => _sendMessage(prompt: prompt),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
          ),
        ),

        // Role, Doc Type, and Format selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // If the pane is less than 500px wide, stack vertically
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      hint: const Text('Role'),
                      items:
                          _roles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => _selectedRole = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDocType,
                      hint: const Text('Doc Type'),
                      items:
                          _docTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => _selectedDocType = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedFormat,
                      hint: const Text('Format'),
                      items:
                          _formats
                              .map(
                                (fmt) => DropdownMenuItem(
                                  value: fmt,
                                  child: Text(fmt),
                                ),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => _selectedFormat = val),
                    ),
                  ],
                );
              } else {
                // Wide: show in a row
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        hint: const Text('Role'),
                        items:
                            _roles
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _selectedRole = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDocType,
                        hint: const Text('Doc Type'),
                        items:
                            _docTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _selectedDocType = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFormat,
                        hint: const Text('Format'),
                        items:
                            _formats
                                .map(
                                  (fmt) => DropdownMenuItem(
                                    value: fmt,
                                    child: Text(fmt),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _selectedFormat = val),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),

        // Chat messages
        Expanded(
          child:
              _messages.isEmpty
                  ? const Center(
                    child: Text(
                      'Start a conversation with AI about your file!',
                    ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text('AI is typing...'),
                            ],
                          ),
                        );
                      }

                      final message = _messages[index];
                      return ChatMessageWidget(message: message);
                    },
                  ),
        ),

        // Error message
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
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
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

        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 120, // Maximum height for the text input
                  ),
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Ask a question about ${widget.fileName}...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Send',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color:
                        _isLoading
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        message.isUser
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        message.isUser
                            ? null
                            : Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                    boxShadow: [
                      if (!message.isUser)
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
                      if (!message.isUser)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: message.text),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Response copied to clipboard',
                                    ),
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
                      message.isUser
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
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
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

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
