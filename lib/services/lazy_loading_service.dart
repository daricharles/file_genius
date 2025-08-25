import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models.dart';

/// Service for lazy loading file content and implementing pagination
class LazyLoadingService extends ChangeNotifier {
  static const int _defaultPageSize = 20;
  static const int _maxCacheSize = 100;

  final Map<String, LazyLoadedFile> _loadedFiles = {};
  final Map<String, List<List<FileMeta>>> _filePages = {};
  final Map<String, int> _currentPages = {};
  final Map<String, bool> _hasMorePages = {};

  // Getters
  Map<String, LazyLoadedFile> get loadedFiles => Map.unmodifiable(_loadedFiles);
  Map<String, List<List<FileMeta>>> get filePages =>
      Map.unmodifiable(_filePages);

  /// Load file content lazily
  Future<String> loadFileContent(
    FileMeta file, {
    int chunkSize = 1000,
    bool forceReload = false,
  }) async {
    // Check if already loaded
    if (!forceReload && _loadedFiles.containsKey(file.id)) {
      final loadedFile = _loadedFiles[file.id]!;
      if (!loadedFile.isExpired) {
        return loadedFile.content;
      }
    }

    try {
      // Load content in chunks for large files
      String content;
      if (file.size > chunkSize * 10) {
        content = await _loadContentInChunks(file, chunkSize);
      } else {
        content = await _loadFullContent(file);
      }

      // Cache the loaded content
      _loadedFiles[file.id] = LazyLoadedFile(
        fileId: file.id,
        content: content,
        loadedAt: DateTime.now(),
        chunkSize: chunkSize,
      );

      // Cleanup if cache is too large
      _cleanupCache();

      notifyListeners();
      return content;
    } catch (e) {
      debugPrint('Error loading file content: $e');
      rethrow;
    }
  }

  /// Load content in chunks for large files
  Future<String> _loadContentInChunks(FileMeta file, int chunkSize) async {
    // This is a placeholder implementation
    // In a real app, you would implement actual chunked loading
    // based on your file storage system

    final content = file.extractedText ?? '';
    if (content.isEmpty) {
      return 'Content not available';
    }

    // Simulate chunked loading
    final chunks = <String>[];
    for (int i = 0; i < content.length; i += chunkSize) {
      final end =
          (i + chunkSize < content.length) ? i + chunkSize : content.length;
      chunks.add(content.substring(i, end));
    }

    return chunks.join('\n---\n');
  }

  /// Load full content for small files
  Future<String> _loadFullContent(FileMeta file) async {
    // This would typically call your file content extractor
    return file.extractedText ?? 'Content not available';
  }

  /// Load file page with pagination
  Future<List<FileMeta>> loadFilePage(
    String folderId, {
    int page = 1,
    int pageSize = _defaultPageSize,
    bool forceReload = false,
  }) async {
    final cacheKey = '${folderId}_$pageSize';

    // Check if page is already loaded
    if (!forceReload && _filePages.containsKey(cacheKey)) {
      final pages = _filePages[cacheKey]!;
      if (page <= pages.length) {
        return pages[page - 1];
      }
    }

    try {
      // Load the requested page
      final files = await _loadFilesFromStorage(folderId, page, pageSize);

      // Update cache
      if (!_filePages.containsKey(cacheKey)) {
        _filePages[cacheKey] = [];
      }

      final pages = _filePages[cacheKey]!;
      while (pages.length < page) {
        pages.add(<FileMeta>[]);
      }

      if (pages.length < page) {
        pages.addAll(List.filled(page - pages.length, <FileMeta>[]));
      }

      pages[page - 1] = files;
      _currentPages[cacheKey] = page;
      _hasMorePages[cacheKey] = files.length == pageSize;

      notifyListeners();
      return files;
    } catch (e) {
      debugPrint('Error loading file page: $e');
      return [];
    }
  }

  /// Load files from storage (placeholder implementation)
  Future<List<FileMeta>> _loadFilesFromStorage(
    String folderId,
    int page,
    int pageSize,
  ) async {
    // This is a placeholder implementation
    // In a real app, you would implement actual pagination
    // based on your storage system

    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // Simulate network delay

    // Return empty list for now
    return [];
  }

  /// Check if more pages are available
  bool hasMorePages(String folderId, int pageSize) {
    final cacheKey = '${folderId}_$pageSize';
    return _hasMorePages[cacheKey] ?? false;
  }

  /// Get current page
  int getCurrentPage(String folderId, int pageSize) {
    final cacheKey = '${folderId}_$pageSize';
    return _currentPages[cacheKey] ?? 1;
  }

  /// Preload next page
  Future<void> preloadNextPage(String folderId, int pageSize) async {
    final cacheKey = '${folderId}_$pageSize';
    final currentPage = _currentPages[cacheKey] ?? 1;

    if (_hasMorePages[cacheKey] == true) {
      await loadFilePage(folderId, page: currentPage + 1, pageSize: pageSize);
    }
  }

  /// Preload file content
  Future<void> preloadFileContent(FileMeta file) async {
    if (!_loadedFiles.containsKey(file.id)) {
      // Load in background
      unawaited(loadFileContent(file));
    }
  }

  /// Get file content chunk
  String getFileContentChunk(String fileId, int start, int length) {
    final loadedFile = _loadedFiles[fileId];
    if (loadedFile == null) return '';

    final content = loadedFile.content;
    if (start >= content.length) return '';

    final end =
        (start + length < content.length) ? start + length : content.length;
    return content.substring(start, end);
  }

  /// Check if file content is loaded
  bool isFileLoaded(String fileId) {
    return _loadedFiles.containsKey(fileId) && !_loadedFiles[fileId]!.isExpired;
  }

  /// Get loaded file info
  LazyLoadedFile? getLoadedFileInfo(String fileId) {
    return _loadedFiles[fileId];
  }

  /// Remove file from cache
  void removeFile(String fileId) {
    _loadedFiles.remove(fileId);
    notifyListeners();
  }

  /// Clear all caches
  void clearCache() {
    _loadedFiles.clear();
    _filePages.clear();
    _currentPages.clear();
    _hasMorePages.clear();
    notifyListeners();
  }

  /// Cleanup cache if it's too large
  void _cleanupCache() {
    if (_loadedFiles.length <= _maxCacheSize) return;

    // Remove oldest files first
    final sortedFiles =
        _loadedFiles.entries.toList()
          ..sort((a, b) => a.value.loadedAt.compareTo(b.value.loadedAt));

    final removeCount = _loadedFiles.length - _maxCacheSize;
    for (int i = 0; i < removeCount; i++) {
      _loadedFiles.remove(sortedFiles[i].key);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'loadedFiles': _loadedFiles.length,
      'filePages': _filePages.length,
      'maxCacheSize': _maxCacheSize,
      'cacheKeys': _loadedFiles.keys.toList(),
    };
  }
}

/// Lazy loaded file wrapper
class LazyLoadedFile {
  final String fileId;
  final String content;
  final DateTime loadedAt;
  final int chunkSize;
  final Duration expiry;

  LazyLoadedFile({
    required this.fileId,
    required this.content,
    required this.loadedAt,
    required this.chunkSize,
    Duration? expiry,
  }) : expiry = expiry ?? const Duration(hours: 2);

  bool get isExpired => DateTime.now().isAfter(loadedAt.add(expiry));
  int get contentLength => content.length;
  int get chunkCount => (content.length / chunkSize).ceil();
}
