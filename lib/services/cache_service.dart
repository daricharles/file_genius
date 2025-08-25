/// Generic cache service for improving app performance
class CacheService<T> {
  final Map<String, CachedItem<T>> _cache = {};
  final Duration _defaultExpiry;
  final int _maxItems;

  CacheService({Duration? defaultExpiry, int maxItems = 100})
    : _defaultExpiry = defaultExpiry ?? const Duration(hours: 1),
      _maxItems = maxItems;

  /// Get item from cache
  T? get(String key) {
    final item = _cache[key];
    if (item == null) return null;

    if (item.isExpired) {
      _cache.remove(key);
      return null;
    }

    // Update last accessed time
    item.lastAccessed = DateTime.now();
    return item.data;
  }

  /// Put item in cache
  void put(String key, T data, {Duration? expiry}) {
    // Remove expired items first
    _cleanupExpired();

    // Check if we need to remove items to make space
    if (_cache.length >= _maxItems) {
      _removeLeastRecentlyUsed();
    }

    _cache[key] = CachedItem<T>(data: data, expiry: expiry ?? _defaultExpiry);
  }

  /// Check if key exists in cache
  bool contains(String key) {
    final item = _cache[key];
    if (item == null) return false;

    if (item.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove item from cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Get cache size
  int get size => _cache.length;

  /// Get cache keys
  Set<String> get keys => _cache.keys.toSet();

  /// Cleanup expired items
  void _cleanupExpired() {
    final expiredKeys =
        _cache.keys.where((key) => _cache[key]!.isExpired).toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Remove least recently used items
  void _removeLeastRecentlyUsed() {
    if (_cache.isEmpty) return;

    // Sort by last accessed time and remove oldest
    final sortedEntries =
        _cache.entries.toList()..sort(
          (a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed),
        );

    // Remove 20% of oldest items
    final removeCount = (_cache.length * 0.2).ceil();
    for (int i = 0; i < removeCount && i < sortedEntries.length; i++) {
      _cache.remove(sortedEntries[i].key);
    }
  }

  /// Get cache statistics
  CacheStats getStats() {
    int expired = 0;
    int valid = 0;
    DateTime? oldestAccess;
    DateTime? newestAccess;

    for (final item in _cache.values) {
      if (item.isExpired) {
        expired++;
      } else {
        valid++;
        if (oldestAccess == null || item.lastAccessed.isBefore(oldestAccess)) {
          oldestAccess = item.lastAccessed;
        }
        if (newestAccess == null || item.lastAccessed.isAfter(newestAccess)) {
          newestAccess = item.lastAccessed;
        }
      }
    }

    return CacheStats(
      totalItems: _cache.length,
      validItems: valid,
      expiredItems: expired,
      oldestAccess: oldestAccess,
      newestAccess: newestAccess,
      maxItems: _maxItems,
    );
  }
}

/// Cached item wrapper
class CachedItem<T> {
  final T data;
  final DateTime createdAt;
  final Duration expiry;
  DateTime lastAccessed;

  CachedItem({required this.data, required this.expiry})
    : createdAt = DateTime.now(),
      lastAccessed = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(createdAt.add(expiry));
}

/// Cache statistics
class CacheStats {
  final int totalItems;
  final int validItems;
  final int expiredItems;
  final DateTime? oldestAccess;
  final DateTime? newestAccess;
  final int maxItems;

  CacheStats({
    required this.totalItems,
    required this.validItems,
    required this.expiredItems,
    this.oldestAccess,
    this.newestAccess,
    required this.maxItems,
  });

  double get hitRate => totalItems > 0 ? validItems / totalItems : 0.0;
  double get usagePercentage => totalItems / maxItems;
}

/// Specialized file content cache
class FileContentCache {
  static final FileContentCache _instance = FileContentCache._internal();
  factory FileContentCache() => _instance;
  FileContentCache._internal();

  final CacheService<String> _contentCache = CacheService<String>(
    defaultExpiry: const Duration(hours: 2),
    maxItems: 50,
  );

  final CacheService<Map<String, dynamic>> _metadataCache =
      CacheService<Map<String, dynamic>>(
        defaultExpiry: const Duration(hours: 24),
        maxItems: 100,
      );

  /// Get file content from cache
  String? getContent(String fileId) {
    return _contentCache.get(fileId);
  }

  /// Cache file content
  void cacheContent(String fileId, String content) {
    _contentCache.put(fileId, content);
  }

  /// Get file metadata from cache
  Map<String, dynamic>? getMetadata(String fileId) {
    return _metadataCache.get(fileId);
  }

  /// Cache file metadata
  void cacheMetadata(String fileId, Map<String, dynamic> metadata) {
    _metadataCache.put(fileId, metadata);
  }

  /// Remove file from cache
  void removeFile(String fileId) {
    _contentCache.remove(fileId);
    _metadataCache.remove(fileId);
  }

  /// Clear all caches
  void clear() {
    _contentCache.clear();
    _metadataCache.clear();
  }

  /// Get cache statistics
  Map<String, CacheStats> getStats() {
    return {
      'content': _contentCache.getStats(),
      'metadata': _metadataCache.getStats(),
    };
  }
}

/// AI response cache
class AIResponseCache {
  static final AIResponseCache _instance = AIResponseCache._internal();
  factory AIResponseCache() => _instance;
  AIResponseCache._internal();

  final CacheService<Map<String, dynamic>> _responseCache =
      CacheService<Map<String, dynamic>>(
        defaultExpiry: const Duration(hours: 6),
        maxItems: 200,
      );

  /// Generate cache key for AI request
  String _generateKey(String prompt, String model) {
    // Simple hash of prompt + model
    final combined = '$prompt:$model';
    return combined.hashCode.toString();
  }

  /// Get cached AI response
  Map<String, dynamic>? getResponse(String prompt, String model) {
    final key = _generateKey(prompt, model);
    return _responseCache.get(key);
  }

  /// Cache AI response
  void cacheResponse(
    String prompt,
    String model,
    Map<String, dynamic> response,
  ) {
    final key = _generateKey(prompt, model);
    _responseCache.put(key, response);
  }

  /// Clear AI response cache
  void clear() {
    _responseCache.clear();
  }

  /// Get cache statistics
  CacheStats getStats() {
    return _responseCache.getStats();
  }
}
