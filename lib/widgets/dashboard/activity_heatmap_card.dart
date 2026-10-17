import 'package:flutter/material.dart';
import '../../constants.dart';

/// Card showing the user's daily activity heatmap with proportional intensity.
class ActivityHeatmapCard extends StatelessWidget {
  final Map<String, int> dailyActivity;

  const ActivityHeatmapCard({
    super.key,
    required this.dailyActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            'Activity Heatmap',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: dailyActivity.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start uploading files to see your activity!',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dailyActivity.length,
                    itemBuilder: (context, index) {
                      final entry = dailyActivity.entries.elementAt(index);
                      final date = entry.key;
                      final activity = entry.value;
                      final maxActivity = dailyActivity.values.isNotEmpty
                          ? dailyActivity.values.reduce(
                              (a, b) => a > b ? a : b,
                            )
                          : 1;
                      final intensity = (activity / maxActivity).clamp(
                        0.1,
                        1.0,
                      );

                      return Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kBrand.withValues(alpha: intensity),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    activity.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: intensity > 0.5
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(date, style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
