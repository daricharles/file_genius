import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:math';
import '../constants.dart';

final String? apiKey = dotenv.env['GEMINI_API_KEY'];

/// Builds a detailed prompt based on context
String buildPrompt({
  required String task,
  required String fileName,
  required String fileType,
  required String content,
  String? userRole,
  String? docType,
  String? preferredFormat,
  String? additionalContext,
}) {
  return '''
Perform the following task: $task

File Name: $fileName
File Type: $fileType
User Role: ${userRole ?? 'N/A'}
Document Type: ${docType ?? 'N/A'}
Preferred Output Format: ${preferredFormat ?? 'N/A'}
${additionalContext != null ? 'Additional Context: $additionalContext' : ''}

File Content:
$content
''';
}

class AIService {
  static final GeminiHttpFallback _fallback = GeminiHttpFallback();

  Future<AIResponse> _handleRequest(String prompt, String model) async {
    // Ordered attempts: requested model, then the other family (pro <-> flash)
    final attempts =
        <String>{
          model,
          if (model == kDefaultGeminiModel)
            kFallbackGeminiModel
          else
            kDefaultGeminiModel,
        }.toList();

    // Simple exponential backoff with jitter for retryable errors
    final rand = Random();
    final backoffs = <Duration>[
      const Duration(milliseconds: 750),
      const Duration(milliseconds: 1500),
    ];

    DioException? lastDioError;

    for (final m in attempts) {
      for (int i = 0; i <= backoffs.length; i++) {
        try {
          final answer = await _fallback.generateContent(prompt, model: m);
          return AIResponse(
            success: true,
            message: 'AI response received successfully',
            data: {'answer': answer, 'model': m},
          );
        } on DioException catch (e) {
          lastDioError = e;
          final code = e.response?.statusCode ?? 0;
          final retryable = code == 429 || code == 503; // quota or transient
          if (retryable && i < backoffs.length) {
            final jitter = Duration(milliseconds: rand.nextInt(300));
            await Future.delayed(backoffs[i] + jitter);
            continue; // retry same model
          }
          break; // move to next model or finish
        }
      }
    }

    // Build a clear error after exhausting retries/models
    final statusCode = lastDioError?.response?.statusCode;
    if (statusCode == 429) {
      return AIResponse(
        success: false,
        message: 'You’ve exceeded your quota. Please try again later.',
        data: null,
      );
    }
    final errorMessage =
        lastDioError?.response?.data?['error']?['message'] ??
        lastDioError?.message ??
        'Unknown error';
    return AIResponse(
      success: false,
      message: 'Gemini API error: $errorMessage',
      data: null,
    );
  }

  Future<AIResponse> askQuestion({
    required String fileName,
    required String fileType,
    required String fileContent,
    required String question,
    String? userRole,
    String? docType,
    String? preferredFormat,
    String? additionalContext, // NEW
    String model = kDefaultGeminiModel,
    bool rawMode = false, // kept (currently informational)
  }) async {
    final prompt = buildPrompt(
      task: question,
      fileName: fileName,
      fileType: fileType,
      content: fileContent,
      userRole: userRole,
      docType: docType,
      preferredFormat: preferredFormat,
      additionalContext: additionalContext,
    );
    // rawMode could be used to switch formatting if you later modify _handleRequest
    return await _handleRequest(prompt, model);
  }

  Future<AIResponse> analyzeFile({
    required String fileName,
    required String fileType,
    required String fileContent,
    String? additionalContext,
    String? userRole,
    String? docType,
    String? preferredFormat,
    String model = kDefaultGeminiModel,
  }) async {
    final prompt = buildPrompt(
      task: 'Analyze the file and provide insights',
      fileName: fileName,
      fileType: fileType,
      content: fileContent,
      userRole: userRole,
      docType: docType,
      preferredFormat: preferredFormat,
      additionalContext: additionalContext,
    );
    return await _handleRequest(prompt, model);
  }

  Future<AIResponse> generateSummary({
    required String fileName,
    required String fileType,
    required String fileContent,
    String? userRole,
    String? docType,
    String? preferredFormat,
    String? additionalContext,
    String model = kDefaultGeminiModel,
  }) async {
    final prompt = buildPrompt(
      task: 'Generate a comprehensive summary of this file',
      fileName: fileName,
      fileType: fileType,
      content: fileContent,
      userRole: userRole,
      docType: docType,
      preferredFormat: preferredFormat,
      additionalContext: additionalContext,
    );
    return await _handleRequest(prompt, model);
  }

  /// Lightweight helper used by summary / follow‑up generators.
  /// maxTokens is accepted for API parity but currently not passed to Gemini (no direct param).
  Future<String> sendPrompt(
    String prompt, {
    int maxTokens = 512,
    String model = kDefaultGeminiModel,
  }) async {
    final text = await _fallback.generateContent(prompt, model: model);
    return text.trim();
  }

  Future<String> generateFileSummary({
    required String fileName,
    required String content,
  }) async {
    final prompt = '''
Provide a concise analytical summary of the file "$fileName".
Return:
1 line high-level overview.
Then 5-8 bullet points of key insights.
Make bullets crisp.
Content:
$content
''';
    final resp = await sendPrompt(prompt, maxTokens: 600);
    return resp.trim();
  }

  Future<AIResponse> summarizeFile({
    required String fileName,
    required String fileType,
    required String fileContent,
    String? userRole,
    String? docType,
    String? preferredFormat,
  }) async {
    final prompt = '''
You are an educational assistant. Summarize the provided file content briefly (<= 160 words) and then produce 5 concise, helpful follow-up questions a user could ask to deepen understanding.

Return ONLY valid minified JSON with the following structure:
{
  "summary": "string",
  "follow_ups": ["q1","q2","q3","q4","q5"]
}

User Role: ${userRole ?? "Unknown"}
Document Type: ${docType ?? "Unknown"}
Preferred Format: ${preferredFormat ?? "Not specified"}
File Name: $fileName
File Type: $fileType

Content:
$fileContent
''';

    try {
      final base = await askQuestion(
        fileName: fileName,
        fileType: fileType,
        fileContent: fileContent,
        question: prompt,
        userRole: userRole,
        docType: docType,
        preferredFormat: preferredFormat,
        additionalContext: null,
        rawMode: true,
      );

      if (!base.success) {
        return AIResponse(success: false, message: base.message, data: null);
      }

      final raw = base.data?['answer'] ?? '';
      Map<String, dynamic> parsed;
      try {
        parsed = json.decode(_extractJson(raw));
      } catch (_) {
        return AIResponse(
          success: true,
          message: 'Non-JSON summary fallback',
          data: {'summary': raw, 'follow_ups': <String>[]},
        );
      }

      return AIResponse(
        success: true,
        message: 'Summary generated',
        data: {
          'summary': parsed['summary'] ?? '',
          'follow_ups': (parsed['follow_ups'] as List?)?.cast<String>() ?? [],
        },
      );
    } catch (e) {
      return AIResponse(
        success: false,
        message: 'Summary failed: $e',
        data: null,
      );
    }
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }
}

class GeminiHttpFallback {
  Future<String> generateContent(
    String prompt, {
    String model = 'gemini-1.5-flash-latest',
  }) async {
    // Corrected endpoint to use v1beta
    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final dio = Dio();
    final response = await dio.post(
      endpoint,
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final candidates = response.data['candidates'];
    if (candidates != null && candidates.isNotEmpty) {
      // It's good practice to check for the existence of nested keys
      if (candidates[0]['content'] != null &&
          candidates[0]['content']['parts'] != null &&
          candidates[0]['content']['parts'].isNotEmpty) {
        return candidates[0]['content']['parts'][0]['text'] ??
            'No text returned';
      }
    }
    return 'No response from Gemini.';
  }
}

class AIResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  AIResponse({required this.success, required this.message, this.data});
}
