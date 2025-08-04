import 'package:flutter/material.dart';

/// Enhanced analysis modes for different file types and use cases
enum AnalysisMode {
  basic,
  multiModal,
  academic,
  business,
  legal,
  technical,
  visual,
  audio,
  metadata,
  crossFile,
}

/// Multi-modal analysis types
enum ModalityType { text, visual, audio, metadata, structure }

/// Specialized analysis categories
enum SpecializedCategory {
  academic,
  business,
  legal,
  technical,
  creative,
  financial,
  medical,
  educational,
}

/// Advanced analysis request model
class AdvancedAnalysisRequest {
  final String fileId;
  final String fileName;
  final String fileType;
  final String filePath;
  final AnalysisMode mode;
  final SpecializedCategory? category;
  final List<ModalityType> modalities;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  const AdvancedAnalysisRequest({
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.mode,
    this.category,
    required this.modalities,
    required this.parameters,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'fileName': fileName,
    'fileType': fileType,
    'filePath': filePath,
    'mode': mode.toString(),
    'category': category?.toString(),
    'modalities': modalities.map((m) => m.toString()).toList(),
    'parameters': parameters,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AdvancedAnalysisRequest.fromJson(Map<String, dynamic> json) {
    return AdvancedAnalysisRequest(
      fileId: json['fileId'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      filePath: json['filePath'],
      mode: AnalysisMode.values.firstWhere(
        (m) => m.toString() == json['mode'],
        orElse: () => AnalysisMode.basic,
      ),
      category:
          json['category'] != null
              ? SpecializedCategory.values.firstWhere(
                (c) => c.toString() == json['category'],
                orElse: () => SpecializedCategory.academic,
              )
              : null,
      modalities:
          (json['modalities'] as List)
              .map(
                (m) => ModalityType.values.firstWhere(
                  (mt) => mt.toString() == m,
                  orElse: () => ModalityType.text,
                ),
              )
              .toList(),
      parameters: json['parameters'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Multi-modal analysis result
class MultiModalAnalysisResult {
  final String analysisId;
  final String fileId;
  final AnalysisMode mode;
  final Map<ModalityType, dynamic> modalityResults;
  final Map<String, dynamic> combinedInsights;
  final List<AnalysisInsight> insights;
  final double confidenceScore;
  final DateTime analyzedAt;
  final Duration processingTime;

  const MultiModalAnalysisResult({
    required this.analysisId,
    required this.fileId,
    required this.mode,
    required this.modalityResults,
    required this.combinedInsights,
    required this.insights,
    required this.confidenceScore,
    required this.analyzedAt,
    required this.processingTime,
  });

  Map<String, dynamic> toJson() => {
    'analysisId': analysisId,
    'fileId': fileId,
    'mode': mode.toString(),
    'modalityResults': modalityResults.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
    'combinedInsights': combinedInsights,
    'insights': insights.map((i) => i.toJson()).toList(),
    'confidenceScore': confidenceScore,
    'analyzedAt': analyzedAt.toIso8601String(),
    'processingTime': processingTime.inMilliseconds,
  };

  factory MultiModalAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MultiModalAnalysisResult(
      analysisId: json['analysisId'],
      fileId: json['fileId'],
      mode: AnalysisMode.values.firstWhere(
        (m) => m.toString() == json['mode'],
        orElse: () => AnalysisMode.basic,
      ),
      modalityResults: (json['modalityResults'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          ModalityType.values.firstWhere(
            (mt) => mt.toString() == key,
            orElse: () => ModalityType.text,
          ),
          value,
        ),
      ),
      combinedInsights: json['combinedInsights'],
      insights:
          (json['insights'] as List)
              .map((i) => AnalysisInsight.fromJson(i))
              .toList(),
      confidenceScore: json['confidenceScore'].toDouble(),
      analyzedAt: DateTime.parse(json['analyzedAt']),
      processingTime: Duration(milliseconds: json['processingTime']),
    );
  }
}

/// Individual analysis insight
class AnalysisInsight {
  final String id;
  final String type;
  final String title;
  final String description;
  final dynamic value;
  final double confidence;
  final ModalityType sourceModality;
  final Map<String, dynamic> metadata;
  final List<String> tags;

  const AnalysisInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.value,
    required this.confidence,
    required this.sourceModality,
    required this.metadata,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'value': value,
    'confidence': confidence,
    'sourceModality': sourceModality.toString(),
    'metadata': metadata,
    'tags': tags,
  };

  factory AnalysisInsight.fromJson(Map<String, dynamic> json) {
    return AnalysisInsight(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      value: json['value'],
      confidence: json['confidence'].toDouble(),
      sourceModality: ModalityType.values.firstWhere(
        (mt) => mt.toString() == json['sourceModality'],
        orElse: () => ModalityType.text,
      ),
      metadata: json['metadata'],
      tags: List<String>.from(json['tags']),
    );
  }
}

/// Visual content analysis result
class VisualAnalysisResult {
  final List<OCRResult> ocrResults;
  final List<ChartAnalysis> chartAnalyses;
  final List<ImageInsight> imageInsights;
  final Map<String, dynamic> visualMetrics;

  const VisualAnalysisResult({
    required this.ocrResults,
    required this.chartAnalyses,
    required this.imageInsights,
    required this.visualMetrics,
  });

  Map<String, dynamic> toJson() => {
    'ocrResults': ocrResults.map((o) => o.toJson()).toList(),
    'chartAnalyses': chartAnalyses.map((c) => c.toJson()).toList(),
    'imageInsights': imageInsights.map((i) => i.toJson()).toList(),
    'visualMetrics': visualMetrics,
  };

  factory VisualAnalysisResult.fromJson(Map<String, dynamic> json) {
    return VisualAnalysisResult(
      ocrResults:
          (json['ocrResults'] as List)
              .map((o) => OCRResult.fromJson(o))
              .toList(),
      chartAnalyses:
          (json['chartAnalyses'] as List)
              .map((c) => ChartAnalysis.fromJson(c))
              .toList(),
      imageInsights:
          (json['imageInsights'] as List)
              .map((i) => ImageInsight.fromJson(i))
              .toList(),
      visualMetrics: json['visualMetrics'],
    );
  }
}

/// OCR (Optical Character Recognition) result
class OCRResult {
  final String text;
  final double confidence;
  final Map<String, dynamic> boundingBox;
  final String language;
  final Map<String, dynamic> formatting;

  const OCRResult({
    required this.text,
    required this.confidence,
    required this.boundingBox,
    required this.language,
    required this.formatting,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'confidence': confidence,
    'boundingBox': boundingBox,
    'language': language,
    'formatting': formatting,
  };

  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      text: json['text'],
      confidence: json['confidence'].toDouble(),
      boundingBox: json['boundingBox'],
      language: json['language'],
      formatting: json['formatting'],
    );
  }
}

/// Chart analysis result
class ChartAnalysis {
  final String chartType;
  final Map<String, dynamic> data;
  final List<String> insights;
  final Map<String, dynamic> trends;
  final double confidence;

  const ChartAnalysis({
    required this.chartType,
    required this.data,
    required this.insights,
    required this.trends,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'chartType': chartType,
    'data': data,
    'insights': insights,
    'trends': trends,
    'confidence': confidence,
  };

  factory ChartAnalysis.fromJson(Map<String, dynamic> json) {
    return ChartAnalysis(
      chartType: json['chartType'],
      data: json['data'],
      insights: List<String>.from(json['insights']),
      trends: json['trends'],
      confidence: json['confidence'].toDouble(),
    );
  }
}

/// Image insight from visual analysis
class ImageInsight {
  final String category;
  final String description;
  final double confidence;
  final Map<String, dynamic> attributes;
  final List<String> objects;
  final Map<String, dynamic> colors;

  const ImageInsight({
    required this.category,
    required this.description,
    required this.confidence,
    required this.attributes,
    required this.objects,
    required this.colors,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'description': description,
    'confidence': confidence,
    'attributes': attributes,
    'objects': objects,
    'colors': colors,
  };

  factory ImageInsight.fromJson(Map<String, dynamic> json) {
    return ImageInsight(
      category: json['category'],
      description: json['description'],
      confidence: json['confidence'].toDouble(),
      attributes: json['attributes'],
      objects: List<String>.from(json['objects']),
      colors: json['colors'],
    );
  }
}

/// Audio analysis result
class AudioAnalysisResult {
  final String transcript;
  final double transcriptionConfidence;
  final List<SpeakerSegment> speakers;
  final List<AudioInsight> insights;
  final Map<String, dynamic> audioMetrics;

  const AudioAnalysisResult({
    required this.transcript,
    required this.transcriptionConfidence,
    required this.speakers,
    required this.insights,
    required this.audioMetrics,
  });

  Map<String, dynamic> toJson() => {
    'transcript': transcript,
    'transcriptionConfidence': transcriptionConfidence,
    'speakers': speakers.map((s) => s.toJson()).toList(),
    'insights': insights.map((i) => i.toJson()).toList(),
    'audioMetrics': audioMetrics,
  };

  factory AudioAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AudioAnalysisResult(
      transcript: json['transcript'],
      transcriptionConfidence: json['transcriptionConfidence'].toDouble(),
      speakers:
          (json['speakers'] as List)
              .map((s) => SpeakerSegment.fromJson(s))
              .toList(),
      insights:
          (json['insights'] as List)
              .map((i) => AudioInsight.fromJson(i))
              .toList(),
      audioMetrics: json['audioMetrics'],
    );
  }
}

/// Speaker segment in audio
class SpeakerSegment {
  final String speakerId;
  final Duration startTime;
  final Duration endTime;
  final String text;
  final double confidence;

  const SpeakerSegment({
    required this.speakerId,
    required this.startTime,
    required this.endTime,
    required this.text,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'speakerId': speakerId,
    'startTime': startTime.inMilliseconds,
    'endTime': endTime.inMilliseconds,
    'text': text,
    'confidence': confidence,
  };

  factory SpeakerSegment.fromJson(Map<String, dynamic> json) {
    return SpeakerSegment(
      speakerId: json['speakerId'],
      startTime: Duration(milliseconds: json['startTime']),
      endTime: Duration(milliseconds: json['endTime']),
      text: json['text'],
      confidence: json['confidence'].toDouble(),
    );
  }
}

/// Audio insight
class AudioInsight {
  final String type;
  final String description;
  final Duration timestamp;
  final double confidence;
  final Map<String, dynamic> metadata;

  const AudioInsight({
    required this.type,
    required this.description,
    required this.timestamp,
    required this.confidence,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'timestamp': timestamp.inMilliseconds,
    'confidence': confidence,
    'metadata': metadata,
  };

  factory AudioInsight.fromJson(Map<String, dynamic> json) {
    return AudioInsight(
      type: json['type'],
      description: json['description'],
      timestamp: Duration(milliseconds: json['timestamp']),
      confidence: json['confidence'].toDouble(),
      metadata: json['metadata'],
    );
  }
}

/// Specialized analysis result for different domains
class SpecializedAnalysisResult {
  final SpecializedCategory category;
  final Map<String, dynamic> domainSpecificResults;
  final List<AnalysisInsight> keyFindings;
  final List<String> recommendations;
  final Map<String, double> confidenceScores;

  const SpecializedAnalysisResult({
    required this.category,
    required this.domainSpecificResults,
    required this.keyFindings,
    required this.recommendations,
    required this.confidenceScores,
  });

  Map<String, dynamic> toJson() => {
    'category': category.toString(),
    'domainSpecificResults': domainSpecificResults,
    'keyFindings': keyFindings.map((f) => f.toJson()).toList(),
    'recommendations': recommendations,
    'confidenceScores': confidenceScores,
  };

  factory SpecializedAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SpecializedAnalysisResult(
      category: SpecializedCategory.values.firstWhere(
        (c) => c.toString() == json['category'],
        orElse: () => SpecializedCategory.academic,
      ),
      domainSpecificResults: json['domainSpecificResults'],
      keyFindings:
          (json['keyFindings'] as List)
              .map((f) => AnalysisInsight.fromJson(f))
              .toList(),
      recommendations: List<String>.from(json['recommendations']),
      confidenceScores: Map<String, double>.from(
        json['confidenceScores'].map((k, v) => MapEntry(k, v.toDouble())),
      ),
    );
  }
}

/// Cross-file analysis result
class CrossFileAnalysisResult {
  final List<String> fileIds;
  final List<AnalysisInsight> correlations;
  final Map<String, dynamic> patterns;
  final List<String> discrepancies;
  final Map<String, dynamic> aggregatedMetrics;

  const CrossFileAnalysisResult({
    required this.fileIds,
    required this.correlations,
    required this.patterns,
    required this.discrepancies,
    required this.aggregatedMetrics,
  });

  Map<String, dynamic> toJson() => {
    'fileIds': fileIds,
    'correlations': correlations.map((c) => c.toJson()).toList(),
    'patterns': patterns,
    'discrepancies': discrepancies,
    'aggregatedMetrics': aggregatedMetrics,
  };

  factory CrossFileAnalysisResult.fromJson(Map<String, dynamic> json) {
    return CrossFileAnalysisResult(
      fileIds: List<String>.from(json['fileIds']),
      correlations:
          (json['correlations'] as List)
              .map((c) => AnalysisInsight.fromJson(c))
              .toList(),
      patterns: json['patterns'],
      discrepancies: List<String>.from(json['discrepancies']),
      aggregatedMetrics: json['aggregatedMetrics'],
    );
  }
}

/// Analysis mode configuration
class AnalysisModeConfig {
  final AnalysisMode mode;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<ModalityType> supportedModalities;
  final List<String> supportedFileTypes;
  final Map<String, dynamic> defaultParameters;

  const AnalysisModeConfig({
    required this.mode,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.supportedModalities,
    required this.supportedFileTypes,
    required this.defaultParameters,
  });

  static List<AnalysisModeConfig> get allModes => [
    AnalysisModeConfig(
      mode: AnalysisMode.basic,
      name: 'Basic Analysis',
      description: 'Standard text analysis and content extraction',
      icon: Icons.text_fields,
      color: Colors.blue,
      supportedModalities: [ModalityType.text],
      supportedFileTypes: ['pdf', 'docx', 'txt', 'md'],
      defaultParameters: {},
    ),
    AnalysisModeConfig(
      mode: AnalysisMode.multiModal,
      name: 'Multi-Modal Analysis',
      description:
          'Comprehensive analysis across text, visual, and audio content',
      icon: Icons.auto_awesome,
      color: Colors.purple,
      supportedModalities: [
        ModalityType.text,
        ModalityType.visual,
        ModalityType.audio,
        ModalityType.metadata,
      ],
      supportedFileTypes: ['pdf', 'docx', 'pptx', 'mp4', 'mp3', 'png', 'jpg'],
      defaultParameters: {'includeOCR': true, 'includeAudio': true},
    ),
    AnalysisModeConfig(
      mode: AnalysisMode.academic,
      name: 'Academic Papers',
      description:
          'Specialized analysis for research papers and academic content',
      icon: Icons.school,
      color: Colors.green,
      supportedModalities: [ModalityType.text, ModalityType.structure],
      supportedFileTypes: ['pdf', 'docx'],
      defaultParameters: {'extractCitations': true, 'analyzeMethodology': true},
    ),
    AnalysisModeConfig(
      mode: AnalysisMode.business,
      name: 'Business Documents',
      description:
          'Analysis focused on business metrics, ROI, and decision points',
      icon: Icons.business,
      color: Colors.orange,
      supportedModalities: [ModalityType.text, ModalityType.visual],
      supportedFileTypes: ['pdf', 'docx', 'pptx', 'xlsx'],
      defaultParameters: {'extractMetrics': true, 'identifyActions': true},
    ),
    AnalysisModeConfig(
      mode: AnalysisMode.legal,
      name: 'Legal Documents',
      description:
          'Legal document analysis with clause identification and risk assessment',
      icon: Icons.gavel,
      color: Colors.red,
      supportedModalities: [ModalityType.text, ModalityType.structure],
      supportedFileTypes: ['pdf', 'docx'],
      defaultParameters: {'identifyClauses': true, 'assessRisks': true},
    ),
    AnalysisModeConfig(
      mode: AnalysisMode.technical,
      name: 'Technical Documentation',
      description:
          'Analysis for code documentation, APIs, and technical specifications',
      icon: Icons.code,
      color: Colors.teal,
      supportedModalities: [ModalityType.text, ModalityType.structure],
      supportedFileTypes: ['pdf', 'docx', 'md', 'txt'],
      defaultParameters: {'extractAPIs': true, 'analyzeCode': true},
    ),
  ];

  static AnalysisModeConfig? getConfig(AnalysisMode mode) {
    try {
      return allModes.firstWhere((config) => config.mode == mode);
    } catch (e) {
      return null;
    }
  }
}
