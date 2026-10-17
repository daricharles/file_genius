import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class FileContentExtractor {
  // Extract text content from different file types
  static Future<String> extractContent({
    required String fileUrl,
    required String fileType,
    required String fileName,
  }) async {
    try {
      switch (fileType.toLowerCase()) {
        case 'pdf':
          return await _extractPdfContent(fileUrl);
        case 'txt':
        case 'md':
        case 'json':
        case 'xml':
        case 'csv':
          return await _extractTextContent(fileUrl);
        case 'docx':
        case 'pptx':
        case 'xlsx':
          return await _extractOfficeContent(
            fileUrl: fileUrl,
            fileType: fileType,
            fileName: fileName,
          );
        default:
          return 'File type $fileType is not supported for text extraction.';
      }
    } catch (e) {
      return 'Failed to extract content: ${e.toString()}';
    }
  }

  // Extract text from PDF files
  static Future<String> _extractPdfContent(String fileUrl) async {
    try {
      if (kIsWeb) {
        // Web: Download PDF and extract text on the client-side
        final response = await http.get(Uri.parse(fileUrl));
        if (response.statusCode == 200) {
          final Uint8List fileBytes = response.bodyBytes;
          // Load the PDF document
          final PdfDocument document = PdfDocument(inputBytes: fileBytes);
          // Extract text from all pages
          String text = PdfTextExtractor(document).extractText();
          // Dispose the document
          document.dispose();
          if (text.trim().isEmpty) {
            return 'No extractable text found in this PDF.';
          }
          return text;
        } else {
          return 'Failed to download PDF for extraction: ${response.statusCode}';
        }
      } else {
        // Mobile/Desktop: Download and parse PDF
        final response = await http.get(Uri.parse(fileUrl));
        if (response.statusCode == 200) {
          // Save PDF to temp file
          final bytes = response.bodyBytes;
          final tempDir = await getTemporaryDirectory();
          final tempPath =
              '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf';
          final file = File(tempPath);
          await file.writeAsBytes(bytes);
          // Extract text using read_pdf_text
          final text = await ReadPdfText.getPDFtext(tempPath);
          if (text.trim().isEmpty) {
            return 'No extractable text found in this PDF.';
          }
          return text;
        } else {
          return 'Failed to download PDF file.';
        }
      }
    } catch (e) {
      return 'Error extracting PDF content: ${e.toString()}';
    }
  }

  // Extract text from plain text files
  static Future<String> _extractTextContent(String fileUrl) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      } else {
        return 'Failed to download text file.';
      }
    } catch (e) {
      return 'Error extracting text content: ${e.toString()}';
    }
  }

  static const String _proxyBaseUrl = 'http://localhost:3000';

  // Extract content from Office files via Node proxy multipart upload
  static Future<String> _extractOfficeContent({
    required String fileUrl,
    required String fileType,
    required String fileName,
  }) async {
    final lowerType = fileType.toLowerCase();
    final String endpoint;
    switch (lowerType) {
      case 'docx':
        endpoint = '/extract-docx-text';
        break;
      case 'pptx':
        endpoint = '/extract-pptx-text';
        break;
      case 'xlsx':
        endpoint = '/extract-xlsx-text';
        break;
      default:
        return 'Office file type $fileType is not supported for text extraction.';
    }

    try {
      final uri = Uri.parse('$_proxyBaseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add URL field as fallback / direct reference for proxy
      request.fields['url'] = fileUrl;
      request.fields['fileType'] = lowerType;

      // Download file bytes to upload as multipart/form-data
      Uint8List? fileBytes;
      try {
        if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
          final downloadRes = await http.get(Uri.parse(fileUrl));
          if (downloadRes.statusCode == 200) {
            fileBytes = downloadRes.bodyBytes;
          }
        }
      } catch (dlErr) {
        debugPrint(
          'Client-side download error (will rely on URL field): $dlErr',
        );
      }

      if (fileBytes != null && fileBytes.isNotEmpty) {
        final uploadFileName =
            fileName.isNotEmpty ? fileName : 'document.$lowerType';
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: uploadFileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic> && decoded.containsKey('text')) {
            final extracted = decoded['text']?.toString() ?? '';
            if (extracted.trim().isEmpty) {
              return 'No extractable text found in this $fileType file.';
            }
            return extracted;
          }
        } catch (_) {
          if (response.body.trim().isNotEmpty) {
            return response.body;
          }
        }
        return 'No extractable text found in this $fileType file.';
      } else {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
            return 'Failed to extract $fileType text: ${decoded['error']}';
          }
        } catch (_) {}
        return 'Failed to extract $fileType text (HTTP ${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      return 'Error extracting Office content via proxy: ${e.toString()}';
    }
  }

  // Get file metadata for AI context
  static Map<String, dynamic> getFileMetadata({
    required String fileName,
    required String fileType,
    required int fileSize,
    required DateTime uploadedAt,
  }) {
    return {
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
      'fileExtension': fileName.split('.').last.toLowerCase(),
    };
  }

  // Create a context string for AI analysis
  static String createAnalysisContext({
    required String fileName,
    required String fileType,
    required int fileSize,
    required DateTime uploadedAt,
    String? folderName,
  }) {
    final sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
    final uploadDate =
        '${uploadedAt.day}/${uploadedAt.month}/${uploadedAt.year}';

    return '''
File Information:
- Name: $fileName
- Type: ${fileType.toUpperCase()}
- Size: $sizeInMB MB
- Uploaded: $uploadDate
${folderName != null ? '- Folder: $folderName' : ''}
''';
  }

  // Validate if file type supports AI analysis
  static bool supportsAIAnalysis(String fileType) {
    final supportedTypes = [
      'pdf',
      'txt',
      'md',
      'json',
      'xml',
      'csv',
      'docx',
      'pptx',
      'xlsx',
    ];
    return supportedTypes.contains(fileType.toLowerCase());
  }

  // Get AI analysis suggestions based on file type
  static List<String> getAnalysisSuggestions(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return [
          'Summarize the main points of this document',
          'What are the key findings or conclusions?',
          'Extract important data or statistics',
          'Identify the document structure and sections',
        ];
      case 'docx':
        return [
          'Summarize the document content',
          'What is the main topic or theme?',
          'Extract key points and arguments',
          'Identify the document structure',
        ];
      case 'pptx':
        return [
          'Summarize the presentation content',
          'What are the main topics covered?',
          'Extract key points from each slide',
          'What is the presentation about?',
        ];
      case 'xlsx':
        return [
          'Analyze the data structure',
          'What types of data are included?',
          'Summarize the key metrics or values',
          'Identify patterns or trends in the data',
        ];
      case 'txt':
      case 'md':
        return [
          'Summarize the text content',
          'What is the main topic?',
          'Extract key information',
          'Identify the writing style and tone',
        ];
      case 'json':
        return [
          'Analyze the JSON structure',
          'What data is contained in this file?',
          'Summarize the key fields and values',
          'Identify the data schema',
        ];
      case 'csv':
        return [
          'Analyze the CSV data structure',
          'What columns and data types are included?',
          'Summarize the key data points',
          'Identify patterns in the data',
        ];
      default:
        return [
          'What is this file about?',
          'Summarize the main content',
          'What are the key points?',
          'Analyze the file structure',
        ];
    }
  }

  // Bytes-based fallback when we have local file bytes (drag & drop)
  static Future<String> extractFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String fileType,
  }) async {
    final lower = fileType.toLowerCase();
    if (['docx', 'pptx', 'xlsx'].contains(lower)) {
      return await _extractOfficeContentFromBytes(
        bytes: bytes,
        fileName: fileName,
        fileType: lower,
      );
    }
    // Try UTF‑8 decode; if it fails, return placeholder.
    try {
      final text = utf8.decode(bytes, allowMalformed: true);
      if (text.trim().isNotEmpty) return text;
    } catch (_) {}
    return '[Extracted $fileType content for $fileName is not plain text or needs specialized parser]';
  }

  static Future<String> _extractOfficeContentFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String fileType,
  }) async {
    final String endpoint;
    switch (fileType) {
      case 'docx':
        endpoint = '/extract-docx-text';
        break;
      case 'pptx':
        endpoint = '/extract-pptx-text';
        break;
      case 'xlsx':
        endpoint = '/extract-xlsx-text';
        break;
      default:
        return 'Office file type $fileType is not supported for text extraction.';
    }

    try {
      final uri = Uri.parse('$_proxyBaseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      final uploadFileName =
          fileName.isNotEmpty ? fileName : 'document.$fileType';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: uploadFileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic> && decoded.containsKey('text')) {
            final text = decoded['text']?.toString() ?? '';
            return text.isNotEmpty
                ? text
                : 'No extractable text found in this $fileType file.';
          }
        } catch (_) {
          if (response.body.trim().isNotEmpty) return response.body;
        }
        return 'No extractable text found in this $fileType file.';
      } else {
        return 'Failed to extract $fileType text from proxy (HTTP ${response.statusCode})';
      }
    } catch (e) {
      return 'Error extracting $fileType content via proxy: ${e.toString()}';
    }
  }
}
