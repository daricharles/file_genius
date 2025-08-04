import 'package:flutter/material.dart';
import '../models/advanced_analysis_models.dart';
import 'package:intl/intl.dart';

class AnalysisDashboardWidget extends StatefulWidget {
  final String? selectedFileId;
  final VoidCallback? onAnalysisRequested;

  const AnalysisDashboardWidget({
    super.key,
    this.selectedFileId,
    this.onAnalysisRequested,
  });

  @override
  State<AnalysisDashboardWidget> createState() =>
      _AnalysisDashboardWidgetState();
}

class _AnalysisDashboardWidgetState extends State<AnalysisDashboardWidget>
    with TickerProviderStateMixin {
  late AnimationController _statsController;
  late Animation<double> _statsAnimation;

  List<MultiModalAnalysisResult> _recentAnalyses = [];
  Map<SpecializedCategory, int> _categoryStats = {};
  Map<ModalityType, int> _modalityStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsAnimation = CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    );

    _loadDashboardData();
  }

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate loading recent analyses and statistics
      await Future.delayed(const Duration(milliseconds: 500));

      // Generate mock data for demonstration
      _recentAnalyses = _generateMockAnalyses();
      _categoryStats = _calculateCategoryStats();
      _modalityStats = _calculateModalityStats();

      _statsController.forward();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<MultiModalAnalysisResult> _generateMockAnalyses() {
    return [
      MultiModalAnalysisResult(
        analysisId: 'analysis_1',
        fileId: '1',
        mode: AnalysisMode.academic,
        modalityResults: {ModalityType.text: {}, ModalityType.visual: {}},
        insights: [
          AnalysisInsight(
            id: 'insight_1',
            type: 'citation_analysis',
            title: 'High Citation Density',
            description:
                'Document contains 47 citations with strong academic credibility',
            confidence: 0.92,
            value: 47,
            sourceModality: ModalityType.text,
            metadata: {},
            tags: ['citations', 'academic'],
          ),
        ],
        combinedInsights: {
          'summary': 'Academic paper with strong research foundation',
          'key_findings': ['High citation count', 'Clear methodology'],
        },
        confidenceScore: 0.89,
        analyzedAt: DateTime.now().subtract(const Duration(hours: 2)),
        processingTime: Duration(milliseconds: 1234),
      ),
      MultiModalAnalysisResult(
        analysisId: 'analysis_2',
        fileId: '2',
        mode: AnalysisMode.business,
        modalityResults: {ModalityType.text: {}, ModalityType.structure: {}},
        insights: [
          AnalysisInsight(
            id: 'insight_2',
            type: 'roi_analysis',
            title: 'ROI Projection Identified',
            description:
                'Document contains detailed ROI projections for next 3 years',
            confidence: 0.84,
            value: 3,
            sourceModality: ModalityType.text,
            metadata: {},
            tags: ['roi', 'financial'],
          ),
        ],
        combinedInsights: {
          'summary': 'Comprehensive business plan with financial projections',
          'recommendations': [
            'Review risk assessment',
            'Update market analysis',
          ],
        },
        confidenceScore: 0.78,
        analyzedAt: DateTime.now().subtract(const Duration(days: 1)),
        processingTime: Duration(milliseconds: 987),
      ),
    ];
  }

  Map<SpecializedCategory, int> _calculateCategoryStats() {
    final stats = <SpecializedCategory, int>{};
    for (final category in SpecializedCategory.values) {
      stats[category] = (category.index + 1) * 3; // Mock data
    }
    return stats;
  }

  Map<ModalityType, int> _calculateModalityStats() {
    final stats = <ModalityType, int>{};
    for (final modality in ModalityType.values) {
      stats[modality] = (modality.index + 1) * 5; // Mock data
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_isLoading)
            _buildLoadingState()
          else ...[
            _buildStatsRow(),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildRecentAnalysesSection(),
                        const SizedBox(height: 16),
                        _buildQuickAnalysisSection(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildCategoryDistribution(),
                        const SizedBox(height: 16),
                        _buildModalityUsage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.analytics, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analysis Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Monitor and track your file analysis activities',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: widget.onAnalysisRequested,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Analysis'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statsAnimation.value,
          child: Opacity(
            opacity: _statsAnimation.value,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Analyses',
                    _recentAnalyses.length.toString(),
                    Icons.assessment,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Success Rate',
                    '94.2%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avg Processing',
                    '1.2s',
                    Icons.speed,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Files Processed',
                    '156',
                    Icons.folder,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green.shade600, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnalysesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Analyses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to full analysis history
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentAnalyses.isEmpty)
            _buildEmptyAnalysesState()
          else
            Column(
              children:
                  _recentAnalyses.take(5).map((analysis) {
                    return _buildAnalysisListItem(analysis);
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalysesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No analyses yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start analyzing files to see results here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisListItem(MultiModalAnalysisResult analysis) {
    final config = AnalysisModeConfig.getConfig(analysis.mode);
    // Simulate file name based on file ID
    final fileName =
        analysis.fileId == '1' ? 'Research_Paper.pdf' : 'Business_Plan.docx';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  config?.color.withValues(alpha: 0.1) ??
                  Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              config?.icon ?? Icons.analytics,
              color: config?.color ?? Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      config?.name ?? analysis.mode.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: config?.color ?? Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(analysis.analyzedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(
                    analysis.confidenceScore,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(analysis.confidenceScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getConfidenceColor(analysis.confidenceScore),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${analysis.insights.length} insights',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildQuickAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Text Analysis',
                  Icons.text_fields,
                  Colors.blue,
                  () => _startQuickAnalysis(AnalysisMode.basic),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Multi-Modal',
                  Icons.auto_awesome,
                  Colors.purple,
                  () => _startQuickAnalysis(AnalysisMode.multiModal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Academic',
                  Icons.school,
                  Colors.green,
                  () => _startQuickAnalysis(AnalysisMode.academic),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Business',
                  Icons.business,
                  Colors.orange,
                  () => _startQuickAnalysis(AnalysisMode.business),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _startQuickAnalysis(AnalysisMode mode) {
    // Trigger quick analysis with the selected mode
    widget.onAnalysisRequested?.call();
  }

  Widget _buildCategoryDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ..._categoryStats.entries.take(4).map((entry) {
            final total = _categoryStats.values.fold(0, (a, b) => a + b);
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            final (icon, name, color) = _getCategoryInfo(entry.key);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 14)),
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: entry.value / total,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModalityUsage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modality Usage',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ..._modalityStats.entries.map((entry) {
            final (icon, name, color) = _getModalityInfo(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name, style: const TextStyle(fontSize: 14)),
                  ),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  (IconData, String, Color) _getCategoryInfo(SpecializedCategory category) {
    switch (category) {
      case SpecializedCategory.academic:
        return (Icons.school, 'Academic', Colors.green);
      case SpecializedCategory.business:
        return (Icons.business, 'Business', Colors.orange);
      case SpecializedCategory.legal:
        return (Icons.gavel, 'Legal', Colors.red);
      case SpecializedCategory.technical:
        return (Icons.code, 'Technical', Colors.teal);
      case SpecializedCategory.financial:
        return (Icons.attach_money, 'Financial', Colors.indigo);
      case SpecializedCategory.medical:
        return (Icons.medical_services, 'Medical', Colors.pink);
      case SpecializedCategory.educational:
        return (Icons.menu_book, 'Educational', Colors.cyan);
      case SpecializedCategory.creative:
        return (Icons.palette, 'Creative', Colors.deepPurple);
    }
  }

  (IconData, String, Color) _getModalityInfo(ModalityType modality) {
    switch (modality) {
      case ModalityType.text:
        return (Icons.text_fields, 'Text', Colors.blue);
      case ModalityType.visual:
        return (Icons.image, 'Visual', Colors.green);
      case ModalityType.audio:
        return (Icons.audio_file, 'Audio', Colors.orange);
      case ModalityType.metadata:
        return (Icons.info, 'Metadata', Colors.purple);
      case ModalityType.structure:
        return (Icons.account_tree, 'Structure', Colors.teal);
    }
  }
}
