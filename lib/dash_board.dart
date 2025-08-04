// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'constants.dart';

// Badge tile widget (top-level)
class BadgeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool unlocked;
  final String description;

  const BadgeTile({
    required this.icon,
    required this.label,
    required this.unlocked,
    required this.description,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: unlocked ? kBrand : Colors.grey.shade300,
          child: Icon(
            icon,
            size: 32,
            color: unlocked ? Colors.white : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: unlocked ? kBrand : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        if (!unlocked)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Icon(Icons.lock, size: 16, color: Colors.grey),
          ),
      ],
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final int filesUploaded;
  final int aiChatInteractions;
  final int questionsAnswered;
  final int correctAnswers;
  final int loginDays;

  const DashboardScreen({
    super.key,
    this.filesUploaded = 0,
    this.aiChatInteractions = 0,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.loginDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBack(context),
            const SizedBox(height: 24),
            _buildOverview(),
            const SizedBox(height: 24),
            _buildBadgesSection(),
            const SizedBox(height: 24),
            _buildFileProgress(context),
            const SizedBox(height: 24),
            _buildBottomSections(context),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWithBack(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
              tooltip: 'Back',
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Welcome back, John Doe!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Here's a summary of your learning activity and progress.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Thursday',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              '29th May 2025',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > 1200
                ? 5
                : (constraints.maxWidth > 800 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: const [
            _OverviewCard(title: 'Files Uploaded', value: '12'),
            _OverviewCard(title: 'Completed', value: '8'),
            _OverviewCard(title: 'Questions Generated', value: '50'),
            _OverviewCard(title: 'Correct Answers', value: '85%'),
            _OverviewCard(title: 'Points/Rewards', value: '1500'),
          ],
        );
      },
    );
  }

  Widget _buildBadgesSection() {
    // Badge system with actual progress tracking
    final badges = [
      BadgeTile(
        icon: Icons.emoji_events,
        label: '7-Day Streak',
        unlocked: loginDays >= 7,
        description: 'Log in for 7 consecutive days. ($loginDays/7)',
      ),
      BadgeTile(
        icon: Icons.upload_file,
        label: 'File Uploader',
        unlocked: filesUploaded >= 1,
        description: 'Upload your first file. ($filesUploaded uploaded)',
      ),
      BadgeTile(
        icon: Icons.chat_bubble_outline,
        label: 'AI Chat Explorer',
        unlocked: aiChatInteractions >= 5,
        description: 'Interact with AI chat 5 times. ($aiChatInteractions/5)',
      ),
      BadgeTile(
        icon: Icons.question_answer,
        label: 'Quiz Master',
        unlocked: correctAnswers >= 20,
        description: 'Answer 20 questions correctly. ($correctAnswers/20)',
      ),
      BadgeTile(
        icon: Icons.star_border,
        label: 'File Master',
        unlocked: filesUploaded >= 10,
        description: 'Upload 10 files. ($filesUploaded/10)',
      ),
    ];
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Badges & Trophies',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: badges,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileProgress(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'File Progress',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade100,
                      ),
                      columns: const [
                        DataColumn(label: Text('File Name')),
                        DataColumn(label: Text('Progress')),
                        DataColumn(label: Text('Questions')),
                        DataColumn(label: Text('Correct Answers')),
                        DataColumn(label: Text('Points')),
                      ],
                      rows: [
                        _fileProgressRow(
                          'Math 101 Notes',
                          0.75,
                          '20',
                          '15',
                          '300',
                        ),
                        _fileProgressRow(
                          'History Essay',
                          0.50,
                          '10',
                          '5',
                          '150',
                        ),
                        _fileProgressRow(
                          'Science Report',
                          0.90,
                          '15',
                          '14',
                          '450',
                        ),
                        _fileProgressRow(
                          'English Literature',
                          0.60,
                          '12',
                          '8',
                          '200',
                        ),
                        _fileProgressRow(
                          'Physics Problems',
                          0.80,
                          '18',
                          '16',
                          '400',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  DataRow _fileProgressRow(
    String name,
    double progress,
    String questions,
    String correct,
    String points,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(name)),
        DataCell(
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(kBrand),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(progress * 100).toInt()}%'),
            ],
          ),
        ),
        DataCell(Text(questions)),
        DataCell(Text(correct)),
        DataCell(Text(points)),
      ],
    );
  }

  Widget _buildBottomSections(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBadgesSection(),
                    const SizedBox(height: 24),
                    _buildLeaderboard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildRecentActivity(context),
                    const SizedBox(height: 24),
                    _buildQuoteOfTheDay(),
                  ],
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildBadgesSection(),
              const SizedBox(height: 24),
              _buildLeaderboard(),
              const SizedBox(height: 24),
              _buildRecentActivity(context),
              const SizedBox(height: 24),
              _buildQuoteOfTheDay(),
            ],
          );
        }
      },
    );
  }

  Widget _buildLeaderboard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leaderboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _leaderboardTile(
              'Ethan',
              '1200 points',
              1,
              'assets/images/google_logo.png',
            ),
            const Divider(),
            _leaderboardTile(
              'Olivia',
              '1150 points',
              2,
              'assets/images/google_logo.png',
            ),
            const Divider(),
            _leaderboardTile(
              'Noah',
              '1100 points',
              3,
              'assets/images/google_logo.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardTile(
    String name,
    String points,
    int rank,
    String avatarAsset,
  ) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: AssetImage(avatarAsset)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(points),
      trailing: Text(
        '#$rank',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _activityTile(
              context,
              Icons.check_circle_outline,
              'You',
              'Completed 5 questions in Math 101',
              '2h ago',
            ),
            const Divider(),
            _activityTile(
              context,
              Icons.lightbulb_outline,
              'You',
              'Generated 10 questions for History Essay',
              '4h ago',
            ),
            const Divider(),
            _activityTile(
              context,
              Icons.upload_file_outlined,
              'You',
              'Uploaded Science Report',
              '6h ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(
    BuildContext context,
    IconData icon,
    String user,
    String title,
    String time,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: kBrand.withOpacity(0.1),
        child: Icon(icon, color: kBrand),
      ),
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: user,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' $title'),
          ],
        ),
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildQuoteOfTheDay() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kBrand,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quote of the Day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '"The only way to do great work is to love what you do."',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: const Text(
                '- Steve Jobs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Files'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: kBrand,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.lightbulb),
          label: const Text('Generate Questions'),
          style: ElevatedButton.styleFrom(
            foregroundColor: kBrand,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: kBrand),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '© 2025 FileGenius. All rights reserved.',
            style: TextStyle(color: Colors.grey),
          ),
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text('Help')),
              TextButton(onPressed: () {}, child: const Text('Terms')),
              TextButton(onPressed: () {}, child: const Text('Contact')),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;

  const _OverviewCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
