import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_genius/services/file_content_extractor.dart';

void main() {
  group('FileContentExtractor', () {
    test('supportsAIAnalysis includes Office files (docx, pptx, xlsx) and others', () {
      expect(FileContentExtractor.supportsAIAnalysis('pdf'), isTrue);
      expect(FileContentExtractor.supportsAIAnalysis('docx'), isTrue);
      expect(FileContentExtractor.supportsAIAnalysis('pptx'), isTrue);
      expect(FileContentExtractor.supportsAIAnalysis('xlsx'), isTrue);
      expect(FileContentExtractor.supportsAIAnalysis('txt'), isTrue);
      expect(FileContentExtractor.supportsAIAnalysis('md'), isTrue);
      expect(FileContentExtractor.supportsAIAnalysis('csv'), isTrue);
      expect(FileContentExtractor.supportsAIAnalysis('exe'), isFalse);
    });

    test('getAnalysisSuggestions returns appropriate prompts for docx, pptx, xlsx', () {
      final docxSuggestions = FileContentExtractor.getAnalysisSuggestions('docx');
      expect(docxSuggestions, isNotEmpty);
      expect(docxSuggestions.any((s) => s.contains('document')), isTrue);

      final pptxSuggestions = FileContentExtractor.getAnalysisSuggestions('pptx');
      expect(pptxSuggestions, isNotEmpty);
      expect(pptxSuggestions.any((s) => s.contains('presentation')), isTrue);

      final xlsxSuggestions = FileContentExtractor.getAnalysisSuggestions('xlsx');
      expect(xlsxSuggestions, isNotEmpty);
      expect(xlsxSuggestions.any((s) => s.contains('data')), isTrue);
    });

    test('getFileMetadata extracts accurate metadata map', () {
      final now = DateTime.now();
      final meta = FileContentExtractor.getFileMetadata(
        fileName: 'report.docx',
        fileType: 'docx',
        fileSize: 1048576,
        uploadedAt: now,
      );

      expect(meta['fileName'], equals('report.docx'));
      expect(meta['fileType'], equals('docx'));
      expect(meta['fileSize'], equals(1048576));
      expect(meta['fileExtension'], equals('docx'));
      expect(meta['uploadedAt'], equals(now.toIso8601String()));
    });

    test('createAnalysisContext constructs correct string', () {
      final now = DateTime(2026, 10, 15);
      final ctx = FileContentExtractor.createAnalysisContext(
        fileName: 'slides.pptx',
        fileType: 'pptx',
        fileSize: 2097152,
        uploadedAt: now,
        folderName: 'Lectures',
      );

      expect(ctx, contains('slides.pptx'));
      expect(ctx, contains('PPTX'));
      expect(ctx, contains('2.00 MB'));
      expect(ctx, contains('Lectures'));
    });

    test('extractContent for unsupported file type returns descriptive message', () async {
      final res = await FileContentExtractor.extractContent(
        fileUrl: 'http://example.com/file.bin',
        fileType: 'bin',
        fileName: 'file.bin',
      );
      expect(res, contains('not supported'));
    });

    test('extractFromBytes for plain text decodes successfully', () async {
      final textBytes = Uint8List.fromList('Hello World plain text'.codeUnits);
      final res = await FileContentExtractor.extractFromBytes(
        bytes: textBytes,
        fileName: 'note.txt',
        fileType: 'txt',
      );
      expect(res, equals('Hello World plain text'));
    });
  });
}
