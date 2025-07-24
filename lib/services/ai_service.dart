import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    try {
      final answer = await _fallback.generateContent(prompt, model: model);
      return AIResponse(
        success: true,
        message: 'AI response received successfully',
        data: {'answer': answer},
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorMessage = e.response?.data?['error']?['message'] ?? e.message;

      // Fallback logic
      if (model == 'gemini-1.5-flash-latest' && statusCode == 429) {
        try {
          final fallbackAnswer = await _fallback.generateContent(
            prompt,
            model: 'gemini-1.5-pro-latest',
          );
          return AIResponse(
            success: true,
            message: 'Fallback model used: gemini-1.5-pro-latest',
            data: {'answer': fallbackAnswer},
          );
        } catch (_) {
          return AIResponse(
            success: false,
            message: 'Free-tier quota exceeded and fallback also failed.',
            data: null,
          );
        }
      }

      // Friendly quota error
      if (statusCode == 429) {
        return AIResponse(
          success: false,
          message: 'You’ve exceeded your quota. Please try again later.',
          data: null,
        );
      }

      return AIResponse(
        success: false,
        message: 'Gemini API error: $errorMessage',
        data: null,
      );
    } catch (e) {
      return AIResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<AIResponse> askQuestion({
    required String fileName,
    required String fileType,
    required String fileContent,
    required String question,
    String? userRole,
    String? docType,
    String? preferredFormat,
    String? additionalContext,
    String model = 'gemini-1.5-flash-latest', // ✅ New default
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
    String model = 'gemini-1.5-flash-latest', // ✅ New default
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
    String model = 'gemini-1.5-flash-latest', // ✅ New default
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
        return candidates[0]['content']['parts'][0]['text'] ?? 'No text returned';
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