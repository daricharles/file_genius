import 'package:flutter/foundation.dart';
import '../models.dart';
import 'file_content_extractor.dart';
import 'ai_service.dart';
import 'question_suggestions_service.dart';

class FileAnalysisOrchestrator extends ChangeNotifier {
  final FileContentExtractor extractor;
  final AIService ai;
  final QuestionSuggestionsService questions;

  FileAnalysisOrchestrator({
    required this.extractor,
    required this.ai,
    required this.questions,
  });

  Future<FileMeta> analyzeFile(FileMeta file) async {
    FileMeta working = file.copyWith(isAnalyzing: true);
    notifyListeners();
    try {
      String extracted = working.extractedText ?? '';
      if (extracted.isEmpty) {
        // Try static extractor (method expects named params)
        try {
          extracted = await FileContentExtractor.extractContent(
            fileUrl: working.url,
            fileType: working.type,
            fileName: working.name,
          );
        } catch (_) {
          // fallback silent
        }
        working = working.copyWith(extractedText: extracted);
      }

      final truncated =
          extracted.length > 9000 ? extracted.substring(0, 9000) : extracted;

      final summary = await ai.generateFileSummary(
        fileName: working.name,
        content: truncated,
      );

      final qs = await questions.generateFollowUpQuestions(
        fileName: working.name,
        summary: summary,
        excerpt: truncated.substring(0, truncated.length.clamp(0, 4000)),
      );

      working = working.copyWith(
        summary: summary,
        followUpQuestions: qs,
        isAnalyzing: false,
      );
      return working;
    } catch (e, st) {
      if (kDebugMode) {
        print('File analysis failed: $e\n$st');
      }
      return working.copyWith(isAnalyzing: false);
    } finally {
      notifyListeners();
    }
  }
}
