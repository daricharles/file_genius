import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/conversation_manager.dart';
import '../models/chat_models.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen>
    with TickerProviderStateMixin {
  final ConversationManager _conversationManager = ConversationManager.instance;
  late TabController _tabController;

  List<ChatSession> _activeSessions = [];
  List<ChatSession> _archivedSessions = [];
  ChatAnalytics? _analytics;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _conversationManager.initialize();
      _activeSessions = _conversationManager.getActiveSessions();
      _archivedSessions = _conversationManager.getArchivedSessions();
      _analytics = _conversationManager.getAnalytics();
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteSession(String sessionId) async {
    await _conversationManager.deleteSession(sessionId);
    await _loadData();
  }

  Future<void> _archiveSession(String sessionId) async {
    await _conversationManager.archiveSession(sessionId);
    await _loadData();
  }

  Future<void> _exportSession(String sessionId, ExportFormat format) async {
    try {
      final content = await _conversationManager.exportSession(
        sessionId: sessionId,
        format: format,
      );

      // In a real app, you'd save this to a file or share it
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Export (${format.extension.toUpperCase()})'),
                content: SingleChildScrollView(child: SelectableText(content)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _openSession(ChatSession session) {
    // This would typically navigate to the file viewer with the chat open
    // For now, we'll show a placeholder
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Open Chat Session'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: ${session.fileName}'),
                Text('Messages: ${session.messages.length}'),
                Text(
                  'Created: ${DateFormat('MMM d, yyyy HH:mm').format(session.createdAt)}',
                ),
                Text(
                  'Last Updated: ${DateFormat('MMM d, yyyy HH:mm').format(session.lastUpdatedAt)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Here you would navigate to the actual chat
                },
                child: const Text('Open Chat'),
              ),
            ],
          ),
    );
  }

  List<ChatSession> _getFilteredSessions(List<ChatSession> sessions) {
    if (_searchQuery.isEmpty) return sessions;

    return sessions.where((session) {
      return session.fileName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          session.messages.any(
            (message) =>
                message.text.toLowerCase().contains(_searchQuery.toLowerCase()),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Sessions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.chat)),
            Tab(text: 'Archived', icon: Icon(Icons.archive)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveSessionsTab(),
                  _buildArchivedSessionsTab(),
                  _buildAnalyticsTab(),
                ],
              ),
    );
  }

  Widget _buildActiveSessionsTab() {
    final filteredSessions = _getFilteredSessions(_activeSessions);

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child:
              filteredSessions.isEmpty
                  ? _buildEmptyState(
                    'No active chat sessions',
                    'Start chatting with your files to see sessions here',
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      return _buildSessionCard(session, isArchived: false);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildArchivedSessionsTab() {
    final filteredSessions = _getFilteredSessions(_archivedSessions);

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child:
              filteredSessions.isEmpty
                  ? _buildEmptyState(
                    'No archived sessions',
                    'Archived sessions will appear here',
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      return _buildSessionCard(session, isArchived: true);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null) {
      return _buildEmptyState(
        'No analytics data',
        'Chat with your files to generate analytics',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAnalyticsCard('Overview', [
          _buildStatRow('Total Sessions', '${_analytics!.totalSessions}'),
          _buildStatRow('Total Messages', '${_analytics!.totalMessages}'),
          _buildStatRow('Total Questions', '${_analytics!.totalQuestions}'),
          _buildStatRow(
            'Avg Session Length',
            '${_analytics!.averageSessionLength.toStringAsFixed(1)} messages',
          ),
        ]),
        const SizedBox(height: 16),
        _buildAnalyticsCard(
          'Question Categories',
          _analytics!.questionCategories.entries
              .map((entry) => _buildStatRow(entry.key, '${entry.value}'))
              .toList(),
        ),
        const SizedBox(height: 16),
        _buildAnalyticsCard(
          'File Type Interactions',
          _analytics!.fileTypeInteractions.entries
              .map(
                (entry) =>
                    _buildStatRow(entry.key.toUpperCase(), '${entry.value}'),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        if (_analytics!.popularQuestions.isNotEmpty)
          _buildAnalyticsCard(
            'Popular Questions',
            _analytics!.popularQuestions
                .map(
                  (question) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '• $question',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search sessions...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSessionCard(ChatSession session, {required bool isArchived}) {
    final lastMessage = session.lastMessage;
    final messagePreview = lastMessage?.text ?? 'No messages';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            _getFileTypeIcon(session.fileType),
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          session.fileName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              messagePreview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.message, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${session.messages.length} messages',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(session.lastUpdatedAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            switch (action) {
              case 'open':
                _openSession(session);
                break;
              case 'archive':
                await _archiveSession(session.id);
                break;
              case 'export_md':
                await _exportSession(session.id, ExportFormat.md);
                break;
              case 'export_txt':
                await _exportSession(session.id, ExportFormat.txt);
                break;
              case 'export_json':
                await _exportSession(session.id, ExportFormat.json);
                break;
              case 'delete':
                final confirmed = await _showDeleteConfirmation(
                  session.fileName,
                );
                if (confirmed) {
                  await _deleteSession(session.id);
                }
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'open',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new, size: 18),
                      SizedBox(width: 8),
                      Text('Open'),
                    ],
                  ),
                ),
                if (!isArchived)
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive, size: 18),
                        SizedBox(width: 8),
                        Text('Archive'),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'export_md',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 18),
                      SizedBox(width: 8),
                      Text('Export as Markdown'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_txt',
                  child: Row(
                    children: [
                      Icon(Icons.text_snippet, size: 18),
                      SizedBox(width: 8),
                      Text('Export as Text'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_json',
                  child: Row(
                    children: [
                      Icon(Icons.data_object, size: 18),
                      SizedBox(width: 8),
                      Text('Export as JSON'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
        onTap: () => _openSession(session),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(String fileName) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Session'),
            content: Text(
              'Are you sure you want to permanently delete the chat session for "$fileName"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'pptx':
        return Icons.slideshow;
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      case 'json':
        return Icons.data_object;
      case 'csv':
        return Icons.table_view;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
