import 'package:flutter/material.dart';
import '../models/chat_models.dart';

/// Intelligent question suggestions service
class QuestionSuggestionsService {
  static QuestionSuggestionsService? _instance;
  static QuestionSuggestionsService get instance =>
      _instance ??= QuestionSuggestionsService._();
  QuestionSuggestionsService._();

  // Base question suggestions by file type
  static final Map<String, List<QuestionSuggestion>> _baseQuestions = {
    'pdf': [
      QuestionSuggestion(
        id: 'pdf_summary',
        question: 'Summarize this document',
        category: 'Summary',
        icon: Icons.summarize,
        popularity: 100,
        applicableFileTypes: ['pdf'],
        description: 'Get a concise overview of the document',
      ),
      QuestionSuggestion(
        id: 'pdf_key_points',
        question: 'What are the main points?',
        category: 'Analysis',
        icon: Icons.list_alt,
        popularity: 95,
        applicableFileTypes: ['pdf'],
        description: 'Extract the most important information',
      ),
      QuestionSuggestion(
        id: 'pdf_structure',
        question: 'Analyze the document structure',
        category: 'Structure',
        icon: Icons.account_tree,
        popularity: 80,
        applicableFileTypes: ['pdf'],
        description: 'Understand how the document is organized',
      ),
      QuestionSuggestion(
        id: 'pdf_citations',
        question: 'List all citations and references',
        category: 'Research',
        icon: Icons.format_quote,
        popularity: 75,
        applicableFileTypes: ['pdf'],
        description: 'Find all academic references',
      ),
      QuestionSuggestion(
        id: 'pdf_methodology',
        question: 'What methodology is used?',
        category: 'Research',
        icon: Icons.science,
        popularity: 70,
        applicableFileTypes: ['pdf'],
        description: 'Understand the research approach',
      ),
      QuestionSuggestion(
        id: 'pdf_conclusions',
        question: 'What are the conclusions?',
        category: 'Analysis',
        icon: Icons.check_circle,
        popularity: 85,
        applicableFileTypes: ['pdf'],
        description: 'Get the final takeaways',
      ),
    ],
    'docx': [
      QuestionSuggestion(
        id: 'docx_summary',
        question: 'Summarize this document',
        category: 'Summary',
        icon: Icons.summarize,
        popularity: 100,
        applicableFileTypes: ['docx'],
        description: 'Get a concise overview',
      ),
      QuestionSuggestion(
        id: 'docx_outline',
        question: 'Create an outline of this document',
        category: 'Structure',
        icon: Icons.format_list_numbered,
        popularity: 90,
        applicableFileTypes: ['docx'],
        description: 'See the document structure',
      ),
      QuestionSuggestion(
        id: 'docx_tone',
        question: 'Analyze the writing tone and style',
        category: 'Analysis',
        icon: Icons.psychology,
        popularity: 75,
        applicableFileTypes: ['docx'],
        description: 'Understand the writing approach',
      ),
      QuestionSuggestion(
        id: 'docx_improvements',
        question: 'Suggest improvements for this document',
        category: 'Feedback',
        icon: Icons.edit_note,
        popularity: 80,
        applicableFileTypes: ['docx'],
        description: 'Get enhancement suggestions',
      ),
      QuestionSuggestion(
        id: 'docx_keywords',
        question: 'Extract key terms and concepts',
        category: 'Analysis',
        icon: Icons.tag,
        popularity: 70,
        applicableFileTypes: ['docx'],
        description: 'Identify important topics',
      ),
    ],
    'pptx': [
      QuestionSuggestion(
        id: 'pptx_summary',
        question: 'Summarize this presentation',
        category: 'Summary',
        icon: Icons.slideshow,
        popularity: 100,
        applicableFileTypes: ['pptx'],
        description: 'Get an overview of all slides',
      ),
      QuestionSuggestion(
        id: 'pptx_key_messages',
        question: 'What are the key messages?',
        category: 'Analysis',
        icon: Icons.message,
        popularity: 95,
        applicableFileTypes: ['pptx'],
        description: 'Extract main takeaways',
      ),
      QuestionSuggestion(
        id: 'pptx_structure',
        question: 'Analyze the presentation flow',
        category: 'Structure',
        icon: Icons.timeline,
        popularity: 85,
        applicableFileTypes: ['pptx'],
        description: 'Understand the narrative structure',
      ),
      QuestionSuggestion(
        id: 'pptx_data',
        question: 'Extract data and statistics',
        category: 'Data',
        icon: Icons.bar_chart,
        popularity: 80,
        applicableFileTypes: ['pptx'],
        description: 'Find numerical information',
      ),
      QuestionSuggestion(
        id: 'pptx_action_items',
        question: 'Identify action items and next steps',
        category: 'Action',
        icon: Icons.task_alt,
        popularity: 75,
        applicableFileTypes: ['pptx'],
        description: 'Find actionable items',
      ),
    ],
    'xlsx': [
      QuestionSuggestion(
        id: 'xlsx_summary',
        question: 'Summarize the data in this spreadsheet',
        category: 'Summary',
        icon: Icons.table_chart,
        popularity: 100,
        applicableFileTypes: ['xlsx'],
        description: 'Get an overview of the data',
      ),
      QuestionSuggestion(
        id: 'xlsx_patterns',
        question: 'Identify patterns and trends',
        category: 'Analysis',
        icon: Icons.trending_up,
        popularity: 95,
        applicableFileTypes: ['xlsx'],
        description: 'Find data patterns',
      ),
      QuestionSuggestion(
        id: 'xlsx_statistics',
        question: 'Calculate key statistics',
        category: 'Statistics',
        icon: Icons.calculate,
        popularity: 90,
        applicableFileTypes: ['xlsx'],
        description: 'Get statistical summary',
      ),
      QuestionSuggestion(
        id: 'xlsx_outliers',
        question: 'Find outliers and anomalies',
        category: 'Analysis',
        icon: Icons.error_outline,
        popularity: 80,
        applicableFileTypes: ['xlsx'],
        description: 'Identify unusual data points',
      ),
      QuestionSuggestion(
        id: 'xlsx_insights',
        question: 'What insights can be drawn from this data?',
        category: 'Insights',
        icon: Icons.lightbulb,
        popularity: 85,
        applicableFileTypes: ['xlsx'],
        description: 'Generate data insights',
      ),
    ],
    'txt': [
      QuestionSuggestion(
        id: 'txt_summary',
        question: 'Summarize this text',
        category: 'Summary',
        icon: Icons.text_snippet,
        popularity: 100,
        applicableFileTypes: ['txt', 'md'],
        description: 'Get a text summary',
      ),
      QuestionSuggestion(
        id: 'txt_topics',
        question: 'What topics are covered?',
        category: 'Analysis',
        icon: Icons.topic,
        popularity: 90,
        applicableFileTypes: ['txt', 'md'],
        description: 'Identify main topics',
      ),
      QuestionSuggestion(
        id: 'txt_sentiment',
        question: 'Analyze the sentiment and tone',
        category: 'Analysis',
        icon: Icons.sentiment_satisfied,
        popularity: 75,
        applicableFileTypes: ['txt', 'md'],
        description: 'Understand emotional tone',
      ),
      QuestionSuggestion(
        id: 'txt_entities',
        question: 'Extract names, dates, and entities',
        category: 'Extraction',
        icon: Icons.person_search,
        popularity: 70,
        applicableFileTypes: ['txt', 'md'],
        description: 'Find important entities',
      ),
    ],
    'json': [
      QuestionSuggestion(
        id: 'json_structure',
        question: 'Analyze the JSON structure',
        category: 'Structure',
        icon: Icons.data_object,
        popularity: 100,
        applicableFileTypes: ['json'],
        description: 'Understand data structure',
      ),
      QuestionSuggestion(
        id: 'json_fields',
        question: 'List all fields and their types',
        category: 'Analysis',
        icon: Icons.list,
        popularity: 95,
        applicableFileTypes: ['json'],
        description: 'Get field information',
      ),
      QuestionSuggestion(
        id: 'json_validate',
        question: 'Validate the JSON format',
        category: 'Validation',
        icon: Icons.check_circle,
        popularity: 85,
        applicableFileTypes: ['json'],
        description: 'Check for errors',
      ),
      QuestionSuggestion(
        id: 'json_schema',
        question: 'Generate a schema for this JSON',
        category: 'Schema',
        icon: Icons.schema,
        popularity: 80,
        applicableFileTypes: ['json'],
        description: 'Create data schema',
      ),
    ],
    'csv': [
      QuestionSuggestion(
        id: 'csv_summary',
        question: 'Summarize the CSV data',
        category: 'Summary',
        icon: Icons.table_view,
        popularity: 100,
        applicableFileTypes: ['csv'],
        description: 'Get data overview',
      ),
      QuestionSuggestion(
        id: 'csv_columns',
        question: 'Describe each column',
        category: 'Analysis',
        icon: Icons.view_column,
        popularity: 95,
        applicableFileTypes: ['csv'],
        description: 'Understand column data',
      ),
      QuestionSuggestion(
        id: 'csv_stats',
        question: 'Calculate column statistics',
        category: 'Statistics',
        icon: Icons.analytics,
        popularity: 90,
        applicableFileTypes: ['csv'],
        description: 'Get statistical analysis',
      ),
      QuestionSuggestion(
        id: 'csv_correlations',
        question: 'Find correlations between columns',
        category: 'Analysis',
        icon: Icons.scatter_plot,
        popularity: 85,
        applicableFileTypes: ['csv'],
        description: 'Discover relationships',
      ),
    ],
  };

  /// Get context-aware question suggestions based on file type
  List<QuestionSuggestion> getContextualSuggestions({
    required String fileType,
    String? content,
    List<EnhancedChatMessage>? conversationHistory,
    int maxSuggestions = 6,
  }) {
    final baseQuestions = _getBaseQuestions(fileType);
    final contextQuestions = _getContextBasedQuestions(fileType, content);
    final followUpQuestions = _getFollowUpQuestions(conversationHistory);

    // Combine and score questions
    final allQuestions = <QuestionSuggestion>[
      ...baseQuestions,
      ...contextQuestions,
      ...followUpQuestions,
    ];

    // Sort by popularity and relevance
    allQuestions.sort((a, b) => b.popularity.compareTo(a.popularity));

    // Return top suggestions
    return allQuestions.take(maxSuggestions).toList();
  }

  /// Get base questions for a file type
  List<QuestionSuggestion> _getBaseQuestions(String fileType) {
    final normalizedType = fileType.toLowerCase().replaceAll('.', '');
    return _baseQuestions[normalizedType] ?? _baseQuestions['txt'] ?? [];
  }

  /// Get context-based questions by analyzing content
  List<QuestionSuggestion> _getContextBasedQuestions(
    String fileType,
    String? content,
  ) {
    if (content == null || content.isEmpty) return [];

    final contextQuestions = <QuestionSuggestion>[];
    final lowerContent = content.toLowerCase();

    // Academic paper detection
    if (_isAcademicPaper(lowerContent)) {
      contextQuestions.addAll([
        QuestionSuggestion(
          id: 'academic_hypothesis',
          question: 'What is the main hypothesis?',
          category: 'Research',
          icon: Icons.science,
          popularity: 90,
          description: 'Find the research hypothesis',
        ),
        QuestionSuggestion(
          id: 'academic_findings',
          question: 'What are the key findings?',
          category: 'Research',
          icon: Icons.search,
          popularity: 95,
          description: 'Extract research results',
        ),
      ]);
    }

    // Business document detection
    if (_isBusinessDocument(lowerContent)) {
      contextQuestions.addAll([
        QuestionSuggestion(
          id: 'business_objectives',
          question: 'What are the business objectives?',
          category: 'Business',
          icon: Icons.business_center,
          popularity: 90,
          description: 'Identify business goals',
        ),
        QuestionSuggestion(
          id: 'business_metrics',
          question: 'Extract KPIs and metrics',
          category: 'Business',
          icon: Icons.analytics,
          popularity: 85,
          description: 'Find key performance indicators',
        ),
      ]);
    }

    // Technical document detection
    if (_isTechnicalDocument(lowerContent)) {
      contextQuestions.addAll([
        QuestionSuggestion(
          id: 'tech_requirements',
          question: 'What are the technical requirements?',
          category: 'Technical',
          icon: Icons.engineering,
          popularity: 90,
          description: 'Find technical specifications',
        ),
        QuestionSuggestion(
          id: 'tech_architecture',
          question: 'Describe the system architecture',
          category: 'Technical',
          icon: Icons.architecture,
          popularity: 85,
          description: 'Understand system design',
        ),
      ]);
    }

    // Legal document detection
    if (_isLegalDocument(lowerContent)) {
      contextQuestions.addAll([
        QuestionSuggestion(
          id: 'legal_clauses',
          question: 'Identify key legal clauses',
          category: 'Legal',
          icon: Icons.gavel,
          popularity: 95,
          description: 'Find important legal terms',
        ),
        QuestionSuggestion(
          id: 'legal_obligations',
          question: 'What are the obligations and rights?',
          category: 'Legal',
          icon: Icons.balance,
          popularity: 90,
          description: 'Understand legal responsibilities',
        ),
      ]);
    }

    return contextQuestions;
  }

  /// Get follow-up questions based on conversation history
  List<QuestionSuggestion> _getFollowUpQuestions(
    List<EnhancedChatMessage>? history,
  ) {
    if (history == null || history.isEmpty) return [];

    final followUpQuestions = <QuestionSuggestion>[];
    final lastUserMessage = history.lastWhere(
      (m) => m.isUser,
      orElse: () => history.first,
    );

    final lastMessageLower = lastUserMessage.text.toLowerCase();

    // Follow-up based on previous questions
    if (lastMessageLower.contains('summary') ||
        lastMessageLower.contains('summarize')) {
      followUpQuestions.addAll([
        QuestionSuggestion(
          id: 'followup_details',
          question: 'Provide more details on the main points',
          category: 'Follow-up',
          icon: Icons.zoom_in,
          popularity: 80,
          description: 'Get deeper insights',
        ),
        QuestionSuggestion(
          id: 'followup_examples',
          question: 'Give specific examples from the document',
          category: 'Follow-up',
          icon: Icons.format_quote,
          popularity: 75,
          description: 'Find concrete examples',
        ),
      ]);
    }

    if (lastMessageLower.contains('data') ||
        lastMessageLower.contains('statistics')) {
      followUpQuestions.addAll([
        QuestionSuggestion(
          id: 'followup_trends',
          question: 'What trends can you identify?',
          category: 'Follow-up',
          icon: Icons.trending_up,
          popularity: 80,
          description: 'Analyze trends in data',
        ),
        QuestionSuggestion(
          id: 'followup_implications',
          question: 'What are the implications of this data?',
          category: 'Follow-up',
          icon: Icons.insights,
          popularity: 75,
          description: 'Understand data implications',
        ),
      ]);
    }

    return followUpQuestions;
  }

  /// Generate smart follow-up suggestions based on AI response
  List<FollowUpSuggestion> generateFollowUpSuggestions({
    required String aiResponse,
    required String fileType,
    String? originalQuestion,
  }) {
    final suggestions = <FollowUpSuggestion>[];
    final responseLower = aiResponse.toLowerCase();

    // Generic follow-ups
    suggestions.addAll([
      FollowUpSuggestion(
        question: 'Can you elaborate on this?',
        reason: 'Get more detailed information',
        icon: Icons.expand_more,
        category: 'Clarification',
      ),
      FollowUpSuggestion(
        question: 'What are the practical implications?',
        reason: 'Understand real-world applications',
        icon: Icons.real_estate_agent,
        category: 'Application',
      ),
    ]);

    // Content-specific follow-ups
    if (responseLower.contains('conclusion') ||
        responseLower.contains('finding')) {
      suggestions.add(
        FollowUpSuggestion(
          question: 'What evidence supports this conclusion?',
          reason: 'Find supporting evidence',
          icon: Icons.fact_check,
          category: 'Evidence',
        ),
      );
    }

    if (responseLower.contains('method') ||
        responseLower.contains('approach')) {
      suggestions.add(
        FollowUpSuggestion(
          question: 'What are the limitations of this method?',
          reason: 'Understand method constraints',
          icon: Icons.warning,
          category: 'Limitations',
        ),
      );
    }

    if (responseLower.contains('data') || responseLower.contains('number')) {
      suggestions.add(
        FollowUpSuggestion(
          question: 'How reliable is this data?',
          reason: 'Assess data quality',
          icon: Icons.verified,
          category: 'Reliability',
        ),
      );
    }

    return suggestions.take(4).toList();
  }

  /// Get quick action suggestions
  List<QuestionSuggestion> getQuickActions(String fileType) {
    return [
      QuestionSuggestion(
        id: 'quick_summary',
        question: 'Generate Summary',
        category: 'Quick Action',
        icon: Icons.summarize,
        popularity: 100,
        description: 'Get a quick summary',
      ),
      QuestionSuggestion(
        id: 'quick_key_points',
        question: 'Extract Key Points',
        category: 'Quick Action',
        icon: Icons.key,
        popularity: 95,
        description: 'Find main points',
      ),
      QuestionSuggestion(
        id: 'quick_analysis',
        question: 'Analyze Document',
        category: 'Quick Action',
        icon: Icons.analytics,
        popularity: 90,
        description: 'Comprehensive analysis',
      ),
      QuestionSuggestion(
        id: 'quick_questions',
        question: 'Generate Discussion Questions',
        category: 'Quick Action',
        icon: Icons.question_mark,
        popularity: 80,
        description: 'Create study questions',
      ),
    ];
  }

  // Helper methods for content detection
  bool _isAcademicPaper(String content) {
    final academicKeywords = [
      'abstract',
      'hypothesis',
      'methodology',
      'results',
      'conclusion',
      'references',
      'citation',
      'research',
      'study',
      'analysis',
      'experiment',
    ];
    return academicKeywords.any((keyword) => content.contains(keyword));
  }

  bool _isBusinessDocument(String content) {
    final businessKeywords = [
      'revenue',
      'profit',
      'strategy',
      'market',
      'customer',
      'business',
      'roi',
      'kpi',
      'quarterly',
      'budget',
      'forecast',
      'stakeholder',
    ];
    return businessKeywords.any((keyword) => content.contains(keyword));
  }

  bool _isTechnicalDocument(String content) {
    final techKeywords = [
      'api',
      'system',
      'architecture',
      'database',
      'server',
      'network',
      'algorithm',
      'protocol',
      'framework',
      'library',
      'configuration',
    ];
    return techKeywords.any((keyword) => content.contains(keyword));
  }

  bool _isLegalDocument(String content) {
    final legalKeywords = [
      'contract',
      'agreement',
      'clause',
      'liability',
      'rights',
      'obligations',
      'warranty',
      'indemnity',
      'jurisdiction',
      'governing law',
      'party',
    ];
    return legalKeywords.any((keyword) => content.contains(keyword));
  }

  /// Update question popularity based on usage
  void recordQuestionUsage(String questionId) {
    // This would typically update a database or analytics service
    // For now, we'll just log it (removed print for production)
    debugPrint('Question used: $questionId');
  }
}
