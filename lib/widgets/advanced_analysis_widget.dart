import 'package:flutter/material.dart';
import '../models/advanced_analysis_models.dart';
import '../services/multi_modal_analysis_service.dart';
import '../services/specialized_analysis_service.dart';

class AdvancedAnalysisWidget extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String fileContent;
  final String filePath;
  final Map<String, dynamic>? fileMetadata;
  final VoidCallback? onAnalysisComplete;

  const AdvancedAnalysisWidget({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.fileContent,
    required this.filePath,
    this.fileMetadata,
    this.onAnalysisComplete,
  });

  @override
  State<AdvancedAnalysisWidget> createState() => _AdvancedAnalysisWidgetState();
}

class _AdvancedAnalysisWidgetState extends State<AdvancedAnalysisWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  final MultiModalAnalysisService _multiModalService =
      MultiModalAnalysisService.instance;
  final SpecializedAnalysisService _specializedService =
      SpecializedAnalysisService.instance;

  AnalysisMode _selectedMode = AnalysisMode.basic;
  SpecializedCategory? _selectedCategory;
  List<ModalityType> _selectedModalities = [ModalityType.text];

  bool _isAnalyzing = false;
  MultiModalAnalysisResult? _multiModalResult;
  SpecializedAnalysisResult? _specializedResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _initializeDefaults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _initializeDefaults() {
    // Set default modalities based on file type
    switch (widget.fileType.toLowerCase()) {
      case 'pdf':
        _selectedModalities = [
          ModalityType.text,
          ModalityType.visual,
          ModalityType.structure,
        ];
        break;
      case 'docx':
        _selectedModalities = [ModalityType.text, ModalityType.structure];
        break;
      case 'pptx':
        _selectedModalities = [ModalityType.text, ModalityType.visual];
        break;
      case 'mp4':
        _selectedModalities = [ModalityType.audio, ModalityType.visual];
        break;
      default:
        _selectedModalities = [ModalityType.text];
    }

    // Suggest appropriate analysis mode
    _selectedMode = _suggestAnalysisMode();
  }

  AnalysisMode _suggestAnalysisMode() {
    final content = widget.fileContent.toLowerCase();

    if (content.contains('abstract') ||
        content.contains('methodology') ||
        content.contains('citation')) {
      return AnalysisMode.academic;
    } else if (content.contains('roi') ||
        content.contains('business') ||
        content.contains('revenue')) {
      return AnalysisMode.business;
    } else if (content.contains('contract') ||
        content.contains('agreement') ||
        content.contains('liability')) {
      return AnalysisMode.legal;
    } else if (content.contains('api') ||
        content.contains('function') ||
        content.contains('class')) {
      return AnalysisMode.technical;
    }

    return AnalysisMode.multiModal;
  }

  Future<void> _performAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _multiModalResult = null;
      _specializedResult = null;
    });

    _loadingController.repeat();

    try {
      final request = AdvancedAnalysisRequest(
        fileId: widget.filePath.hashCode.toString(),
        fileName: widget.fileName,
        fileType: widget.fileType,
        filePath: widget.filePath,
        mode: _selectedMode,
        category: _selectedCategory,
        modalities: _selectedModalities,
        parameters: _getAnalysisParameters(),
        timestamp: DateTime.now(),
      );

      // Perform multi-modal analysis
      _multiModalResult = await _multiModalService.analyzeFile(
        request: request,
        fileContent: widget.fileContent,
      );

      // Perform specialized analysis if category is selected
      if (_selectedCategory != null) {
        _specializedResult = await _specializedService
            .performSpecializedAnalysis(
              category: _selectedCategory!,
              fileName: widget.fileName,
              fileType: widget.fileType,
              fileContent: widget.fileContent,
              parameters: _getAnalysisParameters(),
            );
      }

      widget.onAnalysisComplete?.call();
    } catch (e) {
      setState(() {
        _errorMessage = 'Analysis failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
      _loadingController.stop();
    }
  }

  Map<String, dynamic> _getAnalysisParameters() {
    return {
      'includeOCR': _selectedModalities.contains(ModalityType.visual),
      'includeAudio': _selectedModalities.contains(ModalityType.audio),
      'deepAnalysis': _selectedMode != AnalysisMode.basic,
      'fileMetadata': widget.fileMetadata ?? {},
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConfigurationTab(),
                _buildMultiModalResultsTab(),
                _buildSpecializedResultsTab(),
                _buildInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.fileName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isAnalyzing)
                AnimatedBuilder(
                  animation: _loadingAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _loadingAnimation.value * 2 * 3.14159,
                      child: Icon(Icons.sync, color: Colors.white),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            tabs: const [
              Tab(text: 'Configure', icon: Icon(Icons.settings, size: 18)),
              Tab(
                text: 'Multi-Modal',
                icon: Icon(Icons.auto_awesome, size: 18),
              ),
              Tab(text: 'Specialized', icon: Icon(Icons.psychology, size: 18)),
              Tab(text: 'Insights', icon: Icon(Icons.lightbulb, size: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisModeSelector(),
          const SizedBox(height: 20),
          _buildModalitySelector(),
          const SizedBox(height: 20),
          _buildSpecializedCategorySelector(),
          const Spacer(),
          _buildAnalyzeButton(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
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

  Widget _buildAnalysisModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analysis Mode',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              AnalysisModeConfig.allModes.map((config) {
                final isSelected = _selectedMode == config.mode;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMode = config.mode;
                      if (config.mode == AnalysisMode.academic) {
                        _selectedCategory = SpecializedCategory.academic;
                      } else if (config.mode == AnalysisMode.business) {
                        _selectedCategory = SpecializedCategory.business;
                      } else if (config.mode == AnalysisMode.legal) {
                        _selectedCategory = SpecializedCategory.legal;
                      } else if (config.mode == AnalysisMode.technical) {
                        _selectedCategory = SpecializedCategory.technical;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? config.color.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? config.color : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          config.icon,
                          color:
                              isSelected ? config.color : Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          config.name,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? config.color
                                    : Colors.grey.shade700,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildModalitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analysis Modalities',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ModalityType.values.map((modality) {
                final isSelected = _selectedModalities.contains(modality);
                final (icon, name, color) = _getModalityInfo(modality);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedModalities.remove(modality);
                      } else {
                        _selectedModalities.add(modality);
                      }
                      // Ensure at least one modality is selected
                      if (_selectedModalities.isEmpty) {
                        _selectedModalities.add(ModalityType.text);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? color.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: isSelected ? color : Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: TextStyle(
                            color: isSelected ? color : Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
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

  Widget _buildSpecializedCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specialized Category (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCategoryChip(null, 'None', Icons.clear, Colors.grey),
            ...SpecializedCategory.values.map((category) {
              final (icon, name, color) = _getCategoryInfo(category);
              return _buildCategoryChip(category, name, icon, color);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    SpecializedCategory? category,
    String name,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _performAnalysis,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAnalyzing) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Analyzing...'),
            ] else ...[
              Icon(Icons.play_arrow, size: 20),
              const SizedBox(width: 8),
              const Text('Start Analysis'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMultiModalResultsTab() {
    if (_multiModalResult == null) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        title: 'No Multi-Modal Analysis',
        subtitle: 'Run analysis to see multi-modal results',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisMetrics(_multiModalResult!),
          const SizedBox(height: 20),
          _buildModalityResults(_multiModalResult!),
          const SizedBox(height: 20),
          _buildCombinedInsights(_multiModalResult!),
        ],
      ),
    );
  }

  Widget _buildSpecializedResultsTab() {
    if (_specializedResult == null) {
      return _buildEmptyState(
        icon: Icons.psychology,
        title: 'No Specialized Analysis',
        subtitle:
            'Select a category and run analysis to see specialized results',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpecializedMetrics(_specializedResult!),
          const SizedBox(height: 20),
          _buildDomainResults(_specializedResult!),
          const SizedBox(height: 20),
          _buildRecommendations(_specializedResult!),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    final allInsights = <AnalysisInsight>[];

    if (_multiModalResult != null) {
      allInsights.addAll(_multiModalResult!.insights);
    }

    if (_specializedResult != null) {
      allInsights.addAll(_specializedResult!.keyFindings);
    }

    if (allInsights.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lightbulb_outline,
        title: 'No Insights Available',
        subtitle: 'Run analysis to generate insights',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: allInsights.length,
      itemBuilder: (context, index) {
        return _buildInsightCard(allInsights[index]);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisMetrics(MultiModalAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricItem(
                  'Confidence',
                  '${(result.confidenceScore * 100).toStringAsFixed(1)}%',
                  Icons.verified,
                  Colors.green,
                ),
                _buildMetricItem(
                  'Processing Time',
                  '${result.processingTime.inMilliseconds}ms',
                  Icons.timer,
                  Colors.blue,
                ),
                _buildMetricItem(
                  'Modalities',
                  '${result.modalityResults.length}',
                  Icons.layers,
                  Colors.purple,
                ),
                _buildMetricItem(
                  'Insights',
                  '${result.insights.length}',
                  Icons.lightbulb,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildModalityResults(MultiModalAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modality Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...result.modalityResults.entries.map((entry) {
              final (icon, name, color) = _getModalityInfo(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedInsights(MultiModalAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Combined Insights',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (result.combinedInsights['summary'] != null)
              Text(result.combinedInsights['summary']),
            if (result.combinedInsights['recommendations'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              ...(result.combinedInsights['recommendations'] as List<String>)
                  .map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecializedMetrics(SpecializedAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getCategoryInfo(result.category).$1, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_getCategoryInfo(result.category).$2} Analysis',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children:
                  result.confidenceScores.entries.map((entry) {
                    return Column(
                      children: [
                        Text(
                          '${(entry.value * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          entry.key.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainResults(SpecializedAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Domain-Specific Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...result.domainSpecificResults.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(SpecializedAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...result.recommendations.map((recommendation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(recommendation)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(AnalysisInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    insight.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(insight.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(_getModalityInfo(insight.sourceModality).$1, size: 16),
                const SizedBox(width: 4),
                Text(
                  _getModalityInfo(insight.sourceModality).$2,
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Text(
                  insight.value.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (insight.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children:
                    insight.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
