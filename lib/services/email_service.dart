import 'dart:convert';
import 'package:dio/dio.dart';

class EmailService {
  EmailService({Dio? client}) : _client = client ?? Dio();
  final Dio _client;

  // Proxy base URL (same host as gemini-proxy)
  static const String _baseUrl = 'http://localhost:3000';

  Future<bool> sendEmail({
    required String to,
    required String subject,
    String? html,
    String? text,
  }) async {
    try {
      final resp = await _client.post(
        '$_baseUrl/send-email',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: jsonEncode({
          'to': to,
          'subject': subject,
          if (html != null) 'html': html,
          if (text != null) 'text': text,
        }),
      );
      return resp.statusCode == 200 &&
          (resp.data is Map && resp.data['ok'] == true);
    } catch (e) {
      // Swallow and return false; caller can log
      return false;
    }
  }
}
