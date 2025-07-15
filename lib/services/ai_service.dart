import 'package:dio/dio.dart';

class AIService {
  static final GeminiHttpFallback _fallback = GeminiHttpFallback();

  // Ask a question about file content
  Future<AIResponse> askQuestion({
    required String fileName,
    required String fileType,
    required String fileContent,
    required String question,
  }) async {
    final prompt =
        'Answer the following question about this file:\n\nFile Name: $fileName\nFile Type: $fileType\nFile Content:\n$fileContent\n\nQuestion: $question';
    try {
      final answer = await _fallback.generateContent(prompt);
      return AIResponse(
        success: true,
        message: 'Question answered successfully',
        data: {
          'answer': answer,
          'question': question,
          'fileType': fileType,
          'fileName': fileName,
        },
      );
    } catch (e) {
      return AIResponse(
        success: false,
        message: 'Gemini HTTP error: \\${e.toString()}',
        data: null,
      );
    }
  }

  // Analyze file content and provide insights
  Future<AIResponse> analyzeFile({
    required String fileName,
    required String fileType,
    required String fileContent,
    String? additionalContext,
  }) async {
    final prompt =
        'Analyze the following file and provide insights:\n\nFile Name: $fileName\nFile Type: $fileType\nFile Content:\n$fileContent\n${additionalContext != null ? '\nAdditional Context: $additionalContext' : ''}\n\nPlease provide:\n1. Key insights and main points\n2. Document structure and organization\n3. Important data or information highlighted\n4. Any potential issues or areas of interest\n5. Recommendations for further analysis';
    try {
      final analysis = await _fallback.generateContent(prompt);
      return AIResponse(
        success: true,
        message: 'Analysis completed successfully',
        data: {
          'analysis': analysis,
          'fileType': fileType,
          'fileName': fileName,
        },
      );
    } catch (e) {
      return AIResponse(
        success: false,
        message: 'Gemini HTTP error: \\${e.toString()}',
        data: null,
      );
    }
  }

  // Generate summary of file content
  Future<AIResponse> generateSummary({
    required String fileName,
    required String fileType,
    required String fileContent,
  }) async {
    final prompt =
        'Generate a comprehensive summary of this file:\n\nFile Name: $fileName\nFile Type: $fileType\nFile Content:\n$fileContent\n\nPlease provide:\n1. Executive summary (2-3 sentences)\n2. Key points and findings\n3. Important data or statistics\n4. Main conclusions or takeaways';
    try {
      final summary = await _fallback.generateContent(prompt);
      return AIResponse(
        success: true,
        message: 'Summary generated successfully',
        data: {'summary': summary, 'fileType': fileType, 'fileName': fileName},
      );
    } catch (e) {
      return AIResponse(
        success: false,
        message: 'Gemini HTTP error: \\${e.toString()}',
        data: null,
      );
    }
  }
}

class GeminiHttpFallback {
  static const String _apiKey = 'AIzaSyAtlXoo6MhVsJ-Vy2xRhGnLtdVKFQuUamo';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';
  final Dio _dio = Dio();

  Future<String> generateContent(String prompt) async {
    try {
      final response = await _dio.post(
        _endpoint,
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
        return candidates[0]['content']['parts'][0]['text'] ?? '';
      }
      return 'No response from Gemini.';
    } catch (e) {
      return 'Gemini HTTP error: \\${e.toString()}';
    }
  }
}

class AIResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  AIResponse({required this.success, required this.message, this.data});
}
