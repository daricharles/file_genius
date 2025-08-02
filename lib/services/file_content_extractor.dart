import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:read_pdf_text/read_pdf_text.dart';

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
          return await _extractOfficeContent(fileUrl, fileType);
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
        // Web: Use backend to extract PDF text
        final response = await http.post(
          Uri.parse('http://localhost:3000/extract-pdf-text'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'url': fileUrl}),
        );
        if (response.statusCode == 200) {
          final text = response.body;
          if (text.trim().isEmpty) {
            return 'No extractable text found in this PDF.';
          }
          return text;
        } else {
          return 'Failed to extract PDF text from backend: \n${response.body}';
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

  // Extract content from Office files
  static Future<String> _extractOfficeContent(
    String fileUrl,
    String fileType,
  ) async {
    try {
      if (kIsWeb) {
        String endpoint;
        switch (fileType.toLowerCase()) {
          case 'pptx':
            endpoint = 'extract-pptx-text';
            break;
          case 'docx':
            endpoint = 'extract-docx-text';
            break;
          case 'xlsx':
            endpoint = 'extract-xlsx-text';
            break;
          default:
            return 'Office document. Content can be analyzed through the file viewer interface.';
        }
        final response = await http.post(
          Uri.parse('http://localhost:3000/$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'url': fileUrl}),
        );
        if (response.statusCode == 200) {
          final text = response.body;
          if (text.trim().isEmpty) {
            return 'No extractable text found in this $fileType file.';
          }
          return text;
        } else {
          return 'Failed to extract $fileType text from backend: \n${response.body}';
        }
      } else {
        // For Office files, we'll return a description since direct text extraction
        // requires specialized libraries
        switch (fileType.toLowerCase()) {
          case 'docx':
            return 'Microsoft Word document. Content can be analyzed through the file viewer interface.';
          case 'pptx':
            return 'Microsoft PowerPoint presentation. Content can be analyzed through the file viewer interface.';
          case 'xlsx':
            return 'Microsoft Excel spreadsheet. Content can be analyzed through the file viewer interface.';
          default:
            return 'Office document. Content can be analyzed through the file viewer interface.';
        }
      }
    } catch (e) {
      return 'Error extracting Office content: ${e.toString()}';
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
}
