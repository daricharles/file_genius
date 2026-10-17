import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../screens/chat_sessions_screen.dart';

/// Card providing quick shortcuts to file uploads, chat sessions, quizzes, and AI assistant.
class QuickActionsCard extends StatelessWidget {
  final VoidCallback? onUploadFiles;
  final VoidCallback? onGenerateQuiz;
  final VoidCallback? onAIInteraction;

  const QuickActionsCard({
    super.key,
    this.onUploadFiles,
    this.onGenerateQuiz,
    this.onAIInteraction,
  });

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: 'Upload Files',
            icon: Icons.cloud_upload,
            color: kBrand,
            onTap: () => onUploadFiles?.call(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Chat Sessions',
            icon: Icons.chat_bubble,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatSessionsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Generate Quiz',
            icon: Icons.quiz,
            color: Colors.green,
            onTap: () => onGenerateQuiz?.call(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'AI Assistant',
            icon: Icons.smart_toy,
            color: Colors.purple,
            onTap: () => onAIInteraction?.call(),
          ),
        ],
      ),
    );
  }
}
