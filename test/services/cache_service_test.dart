import 'package:flutter_test/flutter_test.dart';
import 'package:file_genius/services/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService<String> cacheService;

    setUp(() {
      cacheService = CacheService<String>(
        defaultExpiry: const Duration(hours: 1),
        maxItems: 5,
      );
    });

    group('Basic operations', () {
      test('should put and get item', () {
        cacheService.put('key1', 'value1');
        final result = cacheService.get('key1');

        expect(result, equals('value1'));
        expect(cacheService.size, equals(1));
      });

      test('should return null for non-existent key', () {
        final result = cacheService.get('non-existent');
        expect(result, isNull);
      });

      test('should check if key exists', () {
        cacheService.put('key1', 'value1');

        expect(cacheService.contains('key1'), isTrue);
        expect(cacheService.contains('non-existent'), isFalse);
      });

      test('should remove item', () {
        cacheService.put('key1', 'value1');
        expect(cacheService.contains('key1'), isTrue);

        cacheService.remove('key1');
        expect(cacheService.contains('key1'), isFalse);
        expect(cacheService.size, equals(0));
      });

      test('should clear all items', () {
        cacheService.put('key1', 'value1');
        cacheService.put('key2', 'value2');
        expect(cacheService.size, equals(2));

        cacheService.clear();
        expect(cacheService.size, equals(0));
        expect(cacheService.get('key1'), isNull);
        expect(cacheService.get('key2'), isNull);
      });
    });

    group('Expiry handling', () {
      test('should expire items after expiry time', () async {
        cacheService = CacheService<String>(
          defaultExpiry: const Duration(milliseconds: 100),
          maxItems: 5,
        );

        cacheService.put('key1', 'value1');
        expect(cacheService.get('key1'), equals('value1'));

        // Wait for expiry
        await Future.delayed(const Duration(milliseconds: 150));

        final result = cacheService.get('key1');
        expect(result, isNull);
        expect(cacheService.size, equals(0));
      });

      test('should handle custom expiry time', () async {
        cacheService.put(
          'key1',
          'value1',
          expiry: const Duration(milliseconds: 200),
        );
        cacheService.put(
          'key2',
          'value2',
          expiry: const Duration(milliseconds: 100),
        );

        expect(cacheService.get('key1'), equals('value1'));
        expect(cacheService.get('key2'), equals('value2'));

        // Wait for first expiry
        await Future.delayed(const Duration(milliseconds: 150));

        expect(cacheService.get('key1'), equals('value1')); // Still valid
        expect(cacheService.get('key2'), isNull); // Expired

        // Wait for second expiry
        await Future.delayed(const Duration(milliseconds: 100));

        expect(cacheService.get('key1'), isNull); // Now expired
      });

      test('should cleanup expired items automatically', () async {
        cacheService = CacheService<String>(
          defaultExpiry: const Duration(milliseconds: 50),
          maxItems: 5,
        );

        cacheService.put('key1', 'value1');
        cacheService.put('key2', 'value2');

        // Wait for expiry
        await Future.delayed(const Duration(milliseconds: 100));

        // Access any key to trigger cleanup
        cacheService.get('key1');

        expect(cacheService.size, equals(0));
      });
    });

    group('Max items handling', () {
      test('should respect max items limit', () {
        cacheService = CacheService<String>(maxItems: 3);

        cacheService.put('key1', 'value1');
        cacheService.put('key2', 'value2');
        cacheService.put('key3', 'value3');
        cacheService.put('key4', 'value4');

        expect(cacheService.size, lessThanOrEqualTo(3));
        expect(cacheService.get('key1'), isNull); // Should be removed (LRU)
        expect(
          cacheService.get('key4'),
          equals('value4'),
        ); // Should still exist
      });

      test('should remove least recently used items when limit exceeded', () {
        cacheService = CacheService<String>(maxItems: 3);

        // Add items
        cacheService.put('key1', 'value1');
        cacheService.put('key2', 'value2');
        cacheService.put('key3', 'value3');

        // Access key1 to make it most recently used
        cacheService.get('key1');

        // Add new item, should remove key2 (least recently used)
        cacheService.put('key4', 'value4');

        expect(cacheService.get('key1'), equals('value1')); // Still exists
        expect(cacheService.get('key2'), isNull); // Removed
        expect(cacheService.get('key3'), equals('value3')); // Still exists
        expect(cacheService.get('key4'), equals('value4')); // New item
      });
    });

    group('Cache statistics', () {
      test('should provide accurate cache statistics', () {
        cacheService.put('key1', 'value1');
        cacheService.put('key2', 'value2');

        final stats = cacheService.getStats();

        expect(stats.totalItems, equals(2));
        expect(stats.validItems, equals(2));
        expect(stats.expiredItems, equals(0));
        expect(stats.maxItems, equals(5));
        expect(stats.hitRate, equals(1.0));
        expect(stats.usagePercentage, equals(0.4));
      });

      test('should handle expired items in statistics', () async {
        cacheService = CacheService<String>(
          defaultExpiry: const Duration(milliseconds: 100),
          maxItems: 5,
        );

        cacheService.put('key1', 'value1');
        cacheService.put('key2', 'value2');

        // Wait for expiry
        await Future.delayed(const Duration(milliseconds: 150));

        final stats = cacheService.getStats();

        expect(stats.totalItems, equals(0));
        expect(stats.validItems, equals(0));
        expect(stats.expiredItems, equals(0));
        expect(stats.hitRate, equals(0.0));
        expect(stats.usagePercentage, equals(0.0));
      });
    });

    group('Edge cases', () {
      test('should handle empty cache operations', () {
        expect(cacheService.size, equals(0));
        expect(cacheService.get('any'), isNull);
        expect(cacheService.contains('any'), isFalse);

        cacheService.remove('any'); // Should not crash
        cacheService.clear(); // Should not crash
      });

      test('should handle null values', () {
        cacheService.put('key1', 'value1');
        cacheService.put('key2', 'value2');

        // Remove all items
        cacheService.remove('key1');
        cacheService.remove('key2');

        expect(cacheService.size, equals(0));
        expect(cacheService.keys, isEmpty);
      });

      test('should handle very short expiry times', () async {
        cacheService = CacheService<String>(
          defaultExpiry: const Duration(milliseconds: 1),
          maxItems: 5,
        );

        cacheService.put('key1', 'value1');

        // Even with very short expiry, should be able to get immediately
        expect(cacheService.get('key1'), equals('value1'));

        // Wait a bit and it should expire
        await Future.delayed(const Duration(milliseconds: 10));
        expect(cacheService.get('key1'), isNull);
      });
    });
  });

  group('FileContentCache', () {
    late FileContentCache fileCache;

    setUp(() {
      fileCache = FileContentCache();
    });

    test('should cache and retrieve file content', () {
      fileCache.cacheContent('file1', 'content1');
      fileCache.cacheMetadata('file1', {'size': 100, 'type': 'pdf'});

      expect(fileCache.getContent('file1'), equals('content1'));
      expect(
        fileCache.getMetadata('file1'),
        equals({'size': 100, 'type': 'pdf'}),
      );
    });

    test('should remove file from all caches', () {
      fileCache.cacheContent('file1', 'content1');
      fileCache.cacheMetadata('file1', {'size': 100});

      fileCache.removeFile('file1');

      expect(fileCache.getContent('file1'), isNull);
      expect(fileCache.getMetadata('file1'), isNull);
    });

    test('should clear all caches', () {
      fileCache.cacheContent('file1', 'content1');
      fileCache.cacheMetadata('file1', {'size': 100});

      fileCache.clear();

      expect(fileCache.getContent('file1'), isNull);
      expect(fileCache.getMetadata('file1'), isNull);
    });

    test('should provide cache statistics', () {
      fileCache.cacheContent('file1', 'content1');
      fileCache.cacheMetadata('file1', {'size': 100});

      final stats = fileCache.getStats();

      expect(stats['content'], isNotNull);
      expect(stats['metadata'], isNotNull);
      expect(stats['content']!.totalItems, equals(1));
      expect(stats['metadata']!.totalItems, equals(1));
    });
  });

  group('AIResponseCache', () {
    late AIResponseCache aiCache;

    setUp(() {
      aiCache = AIResponseCache();
    });

    test('should cache and retrieve AI responses', () {
      final response = {'answer': 'test response', 'confidence': 0.9};
      aiCache.cacheResponse('test prompt', 'gemini-1.5-flash', response);

      final cached = aiCache.getResponse('test prompt', 'gemini-1.5-flash');
      expect(cached, equals(response));
    });

    test('should generate different keys for different prompts', () {
      final response1 = {'answer': 'response 1'};
      final response2 = {'answer': 'response 2'};

      aiCache.cacheResponse('prompt 1', 'model1', response1);
      aiCache.cacheResponse('prompt 2', 'model1', response2);

      expect(aiCache.getResponse('prompt 1', 'model1'), equals(response1));
      expect(aiCache.getResponse('prompt 2', 'model1'), equals(response2));
    });

    test('should generate different keys for different models', () {
      final response = {'answer': 'test response'};

      aiCache.cacheResponse('same prompt', 'model1', response);
      aiCache.cacheResponse('same prompt', 'model2', response);

      expect(aiCache.getResponse('same prompt', 'model1'), equals(response));
      expect(aiCache.getResponse('same prompt', 'model2'), equals(response));
    });

    test('should clear cache', () {
      final response = {'answer': 'test response'};
      aiCache.cacheResponse('test prompt', 'model1', response);

      aiCache.clear();

      expect(aiCache.getResponse('test prompt', 'model1'), isNull);
    });

    test('should provide cache statistics', () {
      final response = {'answer': 'test response'};
      aiCache.cacheResponse('test prompt', 'model1', response);

      final stats = aiCache.getStats();

      expect(stats.totalItems, equals(1));
      expect(stats.validItems, equals(1));
    });
  });
}
