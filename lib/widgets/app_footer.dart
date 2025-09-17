import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:url_launcher/url_launcher.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    final items = <_FooterItemData>[
      _FooterItemData(
        icon: Icons.info_outline,
        label: 'About',
        onTap: () => _showAbout(context),
      ),
      _FooterItemData(
        icon: Icons.help_center_outlined,
        label: 'FAQs',
        onTap: () => _showFaqs(context),
      ),
      _FooterItemData(
        icon: Icons.privacy_tip,
        label: 'Privacy',
        onTap: () => _showPrivacy(context),
      ),
      _FooterItemData(
        icon: Icons.contact_support,
        label: 'Contact',
        onTap: () => _contactSupport(context),
      ),
    ];

    final buttons =
        isMobile
            ? Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children:
                  items
                      .map(
                        (e) => _FooterItem(
                          icon: e.icon,
                          label: e.label,
                          onTap: e.onTap,
                        ),
                      )
                      .toList(),
            )
            : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  items
                      .map(
                        (e) => _FooterItem(
                          icon: e.icon,
                          label: e.label,
                          onTap: e.onTap,
                        ),
                      )
                      .toList(),
            );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'FileGenius Learning Platform',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          buttons,
          const SizedBox(height: 24),
          Text(
            'Version 1.0.0 • © $year FileGenius',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  static void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('About FileGenius'),
            content: const Text(
              'FileGenius helps you upload, analyze, and learn from your documents with AI assistance, quizzes, and rich analytics.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  static void _showFaqs(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('FAQs'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q: Which file types are supported?'),
                  SizedBox(height: 4),
                  Text('A: PDF, DOCX, PPTX, and XLSX are supported.'),
                  SizedBox(height: 12),
                  Text('Q: How are analytics calculated?'),
                  SizedBox(height: 4),
                  Text(
                    'A: Study time accumulates while previewing files; weekly activity counts study sessions by weekday.',
                  ),
                  SizedBox(height: 12),
                  Text('Q: Is my data private?'),
                  SizedBox(height: 4),
                  Text(
                    'A: Yes, your data is stored securely in Firebase with access limited to your account.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  static void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Privacy Policy'),
            content: const SingleChildScrollView(
              child: Text(
                'We use Firebase Auth, Firestore, and Storage to provide the service. We do not sell your data. Your files and analytics are only visible to you. Contact support for any questions or data removal requests.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  static Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@filegenius.app',
      query: Uri.encodeQueryComponent(
        'subject=Support Request&body=Describe your issue here.',
      ),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email client. Email: support@filegenius.app',
            ),
          ),
        );
      }
    }
  }
}

class _FooterItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _FooterItemData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FooterItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBrand.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kBrand, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
