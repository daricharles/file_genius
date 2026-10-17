import 'package:flutter/material.dart';
import '../../constants.dart';

/// Card rendering a rotating daily inspirational quote.
class DailyQuoteCard extends StatelessWidget {
  const DailyQuoteCard({super.key});

  List<Map<String, String>> _getDailyQuotes() {
    return const [
      {
        'quote': 'The only way to do great work is to love what you do.',
        'author': 'Steve Jobs',
      },
      {
        'quote': 'What we learn with pleasure we never forget.',
        'author': 'Alfred Mercier',
      },
      {
        'quote':
            'Learning is not attained by chance, it must be sought for with ardor and attended to with diligence.',
        'author': 'Abigail Adams',
      },
      {
        'quote': 'The journey of a thousand miles begins with one step.',
        'author': 'Lao Tzu',
      },
      {
        'quote': 'The best investment you can make is in yourself.',
        'author': 'Warren Buffett',
      },
      {
        'quote':
            'Continuous learning is the minimum requirement for success in any field.',
        'author': 'Brian Tracy',
      },
      {
        'quote': 'The more you know, the more you realize you don\'t know.',
        'author': 'Aristotle',
      },
      {
        'quote': 'Success is where preparation and opportunity meet.',
        'author': 'Bobby Unser',
      },
      {
        'quote': 'Every accomplishment starts with the decision to try.',
        'author': 'John F. Kennedy',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quotes = _getDailyQuotes();
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final selectedQuote = quotes[dayOfYear % quotes.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBrand, kBrand.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBrand.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Daily Inspiration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '"${selectedQuote['quote']}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '— ${selectedQuote['author']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
