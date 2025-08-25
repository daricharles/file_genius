import 'package:flutter_test/flutter_test.dart';
import 'package:file_genius/services/performance_monitor_service.dart';

void main() {
  group('PerformanceMonitorService', () {
    late PerformanceMonitorService performanceMonitor;

    setUp(() {
      performanceMonitor = PerformanceMonitorService();
      performanceMonitor.clearData();
    });

    group('Basic functionality', () {
      test('should be enabled by default', () {
        expect(performanceMonitor, isNotNull);
      });

      test('should enable/disable monitoring', () {
        performanceMonitor.setEnabled(false);
        performanceMonitor.startTimer('test');
        performanceMonitor.stopTimer('test');

        final stats = performanceMonitor.getOperationStats('test');
        expect(stats.totalCount, equals(0));

        performanceMonitor.setEnabled(true);
        performanceMonitor.startTimer('test');
        performanceMonitor.stopTimer('test');

        final stats2 = performanceMonitor.getOperationStats('test');
        expect(stats2.totalCount, equals(1));
      });
    });

    group('Timer operations', () {
      test('should start and stop timer correctly', () {
        performanceMonitor.startTimer('test_operation');
        performanceMonitor.stopTimer('test_operation');

        final stats = performanceMonitor.getOperationStats('test_operation');
        expect(stats.totalCount, equals(1));
        expect(stats.averageTime.inMilliseconds, greaterThan(0));
      });

      test('should handle multiple timer starts', () {
        performanceMonitor.startTimer('test_operation');
        performanceMonitor.startTimer(
          'test_operation',
        ); // Should replace previous

        performanceMonitor.stopTimer('test_operation');

        final stats = performanceMonitor.getOperationStats('test_operation');
        expect(stats.totalCount, equals(1));
      });

      test('should handle stop timer without start', () {
        // Should not crash
        performanceMonitor.stopTimer('non_existent');

        final stats = performanceMonitor.getOperationStats('non_existent');
        expect(stats.totalCount, equals(0));
      });
    });

    group('Measure operations', () {
      test('should measure synchronous operation', () {
        final result = performanceMonitor.measureOperation('sync_op', () {
          // Simulate some work
          return 'result';
        });

        expect(result, equals('result'));

        final stats = performanceMonitor.getOperationStats('sync_op');
        expect(stats.totalCount, equals(1));
        expect(stats.averageTime.inMilliseconds, greaterThan(0));
      });

      test('should measure asynchronous operation', () async {
        final result = await performanceMonitor.measureAsyncOperation(
          'async_op',
          () async {
            // Simulate async work
            await Future.delayed(const Duration(milliseconds: 10));
            return 'async_result';
          },
        );

        expect(result, equals('async_result'));

        final stats = performanceMonitor.getOperationStats('async_op');
        expect(stats.totalCount, equals(1));
        expect(stats.averageTime.inMilliseconds, greaterThanOrEqualTo(10));
      });

      test('should handle exceptions in synchronous operations', () {
        expect(() {
          performanceMonitor.measureOperation('error_op', () {
            throw Exception('Test error');
          });
        }, throwsException);

        final stats = performanceMonitor.getOperationStats('error_op');
        expect(stats.totalCount, equals(1));
      });

      test('should handle exceptions in asynchronous operations', () async {
        expect(() async {
          await performanceMonitor.measureAsyncOperation(
            'async_error_op',
            () async {
              throw Exception('Async test error');
            },
          );
        }, throwsException);

        final stats = performanceMonitor.getOperationStats('async_error_op');
        expect(stats.totalCount, equals(1));
      });
    });

    group('Performance statistics', () {
      test('should provide accurate statistics for single operation', () {
        performanceMonitor.startTimer('test_op');
        performanceMonitor.stopTimer('test_op');

        final stats = performanceMonitor.getOperationStats('test_op');
        expect(stats.operationName, equals('test_op'));
        expect(stats.totalCount, equals(1));
        expect(stats.averageTime.inMilliseconds, greaterThan(0));
        expect(stats.minTime.inMilliseconds, greaterThan(0));
        expect(stats.maxTime.inMilliseconds, greaterThan(0));
        expect(stats.slowOperationCount, equals(0));
        expect(stats.verySlowOperationCount, equals(0));
      });

      test('should provide accurate statistics for multiple operations', () {
        for (int i = 0; i < 5; i++) {
          performanceMonitor.startTimer('multi_op');
          performanceMonitor.stopTimer('multi_op');
        }

        final stats = performanceMonitor.getOperationStats('multi_op');
        expect(stats.totalCount, equals(5));
        expect(stats.averageTime.inMilliseconds, greaterThan(0));
      });

      test('should handle operations with no measurements', () {
        final stats = performanceMonitor.getOperationStats('no_measurements');
        expect(stats.totalCount, equals(0));
        expect(stats.averageTime, equals(Duration.zero));
        expect(stats.minTime, equals(Duration.zero));
        expect(stats.maxTime, equals(Duration.zero));
        expect(stats.slowOperationCount, equals(0));
        expect(stats.verySlowOperationCount, equals(0));
      });
    });

    group('Network operations', () {
      test('should track network operation response times', () {
        performanceMonitor.startTimer('network_api_call');
        performanceMonitor.stopTimer('network_api_call');

        final networkStats = performanceMonitor.getNetworkStats();
        expect(networkStats.totalRequests, equals(1));
        expect(networkStats.averageResponseTime.inMilliseconds, greaterThan(0));
      });

      test('should track multiple network operations', () {
        for (int i = 0; i < 3; i++) {
          performanceMonitor.startTimer('network_api_call');
          performanceMonitor.stopTimer('network_api_call');
        }

        final networkStats = performanceMonitor.getNetworkStats();
        expect(networkStats.totalRequests, equals(3));
        expect(networkStats.operationBreakdown['network_api_call'], isNotNull);
        expect(
          networkStats.operationBreakdown['network_api_call']!.length,
          equals(3),
        );
      });

      test('should not track non-network operations', () {
        performanceMonitor.startTimer('file_operation');
        performanceMonitor.stopTimer('file_operation');

        final networkStats = performanceMonitor.getNetworkStats();
        expect(networkStats.totalRequests, equals(0));
      });
    });

    group('Slow operation detection', () {
      test('should detect slow operations', () async {
        await performanceMonitor.measureAsyncOperation('slow_op', () async {
          await Future.delayed(const Duration(milliseconds: 600));
        });

        final stats = performanceMonitor.getOperationStats('slow_op');
        expect(stats.slowOperationCount, equals(1));
        expect(stats.verySlowOperationCount, equals(0));
      });

      test('should detect very slow operations', () async {
        await performanceMonitor.measureAsyncOperation(
          'very_slow_op',
          () async {
            await Future.delayed(const Duration(milliseconds: 2500));
          },
        );

        final stats = performanceMonitor.getOperationStats('very_slow_op');
        expect(stats.slowOperationCount, equals(1));
        expect(stats.verySlowOperationCount, equals(1));
      });
    });

    group('Data management', () {
      test('should clear all data', () {
        performanceMonitor.startTimer('test_op');
        performanceMonitor.stopTimer('test_op');

        performanceMonitor.clearData();

        final stats = performanceMonitor.getOperationStats('test_op');
        expect(stats.totalCount, equals(0));

        final networkStats = performanceMonitor.getNetworkStats();
        expect(networkStats.totalRequests, equals(0));
      });

      test('should limit measurements to max count', () {
        const maxMeasurements = 5;
        performanceMonitor.setMaxMeasurements(maxMeasurements);

        for (int i = 0; i < maxMeasurements + 3; i++) {
          performanceMonitor.startTimer('limited_op');
          performanceMonitor.stopTimer('limited_op');
        }

        final stats = performanceMonitor.getOperationStats('limited_op');
        expect(stats.totalCount, equals(maxMeasurements + 3));
        // The actual measurements should be limited
        expect(stats.averageTime.inMilliseconds, greaterThan(0));
      });
    });

    group('Report generation', () {
      test('should generate performance report', () {
        performanceMonitor.startTimer('test_op');
        performanceMonitor.stopTimer('test_op');

        final report = performanceMonitor.generateReport();
        expect(report, contains('📊 PERFORMANCE REPORT'));
        expect(report, contains('test_op'));
        expect(report, contains('Count: 1'));
      });

      test('should export data as JSON', () {
        performanceMonitor.startTimer('test_op');
        performanceMonitor.stopTimer('test_op');

        final data = performanceMonitor.exportData();
        expect(data['timestamp'], isNotNull);
        expect(data['enabled'], isTrue);
        expect(data['operationStats'], isNotNull);
        expect(data['operationCounts'], isNotNull);
      });
    });

    group('Edge cases', () {
      test('should handle very short operations', () {
        performanceMonitor.startTimer('instant_op');
        performanceMonitor.stopTimer('instant_op');

        final stats = performanceMonitor.getOperationStats('instant_op');
        expect(stats.totalCount, equals(1));
        expect(stats.averageTime.inMilliseconds, greaterThanOrEqualTo(0));
      });

      test('should handle disabled monitoring', () {
        performanceMonitor.setEnabled(false);

        performanceMonitor.startTimer('disabled_op');
        performanceMonitor.stopTimer('disabled_op');

        final stats = performanceMonitor.getOperationStats('disabled_op');
        expect(stats.totalCount, equals(0));
      });

      test('should handle multiple operations with same name', () {
        performanceMonitor.startTimer('same_name');
        performanceMonitor.stopTimer('same_name');

        performanceMonitor.startTimer('same_name');
        performanceMonitor.stopTimer('same_name');

        final stats = performanceMonitor.getOperationStats('same_name');
        expect(stats.totalCount, equals(2));
      });
    });
  });
}
