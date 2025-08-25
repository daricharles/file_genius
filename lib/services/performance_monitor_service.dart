import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Service for monitoring application performance
class PerformanceMonitorService extends ChangeNotifier {
  static final PerformanceMonitorService _instance =
      PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _measurements = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, List<Duration>> _responseTimes = {};

  bool _isEnabled = true;
  int _maxMeasurements = 100;

  // Performance thresholds
  static const Duration _slowOperationThreshold = Duration(milliseconds: 500);
  static const Duration _verySlowOperationThreshold = Duration(
    milliseconds: 2000,
  );

  /// Enable/disable performance monitoring
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Start timing an operation
  void startTimer(String operationName) {
    if (!_isEnabled) return;

    _timers[operationName] = Stopwatch()..start();
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;
  }

  /// Stop timing an operation and record the measurement
  void stopTimer(String operationName) {
    if (!_isEnabled) return;

    final timer = _timers.remove(operationName);
    if (timer == null) return;

    timer.stop();
    final duration = timer.elapsed;

    // Record measurement
    if (!_measurements.containsKey(operationName)) {
      _measurements[operationName] = [];
    }

    final measurements = _measurements[operationName]!;
    measurements.add(duration);

    // Keep only the most recent measurements
    if (measurements.length > _maxMeasurements) {
      measurements.removeRange(0, measurements.length - _maxMeasurements);
    }

    // Log slow operations
    if (duration > _verySlowOperationThreshold) {
      developer.log(
        '🚨 VERY SLOW OPERATION: $operationName took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
        level: 1000, // Error level
      );
    } else if (duration > _slowOperationThreshold) {
      developer.log(
        '⚠️ SLOW OPERATION: $operationName took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
        level: 800, // Warning level
      );
    }

    // Record response time for network operations
    if (operationName.contains('network') || operationName.contains('api')) {
      if (!_responseTimes.containsKey(operationName)) {
        _responseTimes[operationName] = [];
      }
      _responseTimes[operationName]!.add(duration);

      // Keep only recent response times
      if (_responseTimes[operationName]!.length > _maxMeasurements) {
        _responseTimes[operationName]!.removeRange(
          0,
          _responseTimes[operationName]!.length - _maxMeasurements,
        );
      }
    }
  }

  /// Measure a synchronous operation
  T measureOperation<T>(String operationName, T Function() operation) {
    if (!_isEnabled) return operation();

    startTimer(operationName);
    try {
      final result = operation();
      stopTimer(operationName);
      return result;
    } catch (e) {
      stopTimer(operationName);
      rethrow;
    }
  }

  /// Measure an asynchronous operation
  Future<T> measureAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!_isEnabled) return operation();

    startTimer(operationName);
    try {
      final result = await operation();
      stopTimer(operationName);
      return result;
    } catch (e) {
      stopTimer(operationName);
      rethrow;
    }
  }

  /// Get performance statistics for an operation
  PerformanceStats getOperationStats(String operationName) {
    final measurements = _measurements[operationName] ?? [];
    final count = _operationCounts[operationName] ?? 0;

    if (measurements.isEmpty) {
      return PerformanceStats(
        operationName: operationName,
        totalCount: count,
        averageTime: Duration.zero,
        minTime: Duration.zero,
        maxTime: Duration.zero,
        slowOperationCount: 0,
        verySlowOperationCount: 0,
      );
    }

    final totalTime = measurements.fold<Duration>(
      Duration.zero,
      (total, duration) => total + duration,
    );

    final averageTime = Duration(
      microseconds: totalTime.inMicroseconds ~/ measurements.length,
    );

    final minTime = measurements.reduce((a, b) => a < b ? a : b);
    final maxTime = measurements.reduce((a, b) => a > b ? a : b);

    final slowOperationCount =
        measurements
            .where((duration) => duration > _slowOperationThreshold)
            .length;

    final verySlowOperationCount =
        measurements
            .where((duration) => duration > _verySlowOperationThreshold)
            .length;

    return PerformanceStats(
      operationName: operationName,
      totalCount: count,
      averageTime: averageTime,
      minTime: minTime,
      maxTime: maxTime,
      slowOperationCount: slowOperationCount,
      verySlowOperationCount: verySlowOperationCount,
    );
  }

  /// Get all performance statistics
  Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};

    for (final operationName in _measurements.keys) {
      stats[operationName] = getOperationStats(operationName);
    }

    return stats;
  }

  /// Get response time statistics for network operations
  NetworkPerformanceStats getNetworkStats() {
    final allResponseTimes = <Duration>[];
    final operationStats = <String, List<Duration>>{};

    for (final entry in _responseTimes.entries) {
      allResponseTimes.addAll(entry.value);
      operationStats[entry.key] = List.from(entry.value);
    }

    if (allResponseTimes.isEmpty) {
      return NetworkPerformanceStats(
        totalRequests: 0,
        averageResponseTime: Duration.zero,
        minResponseTime: Duration.zero,
        maxResponseTime: Duration.zero,
        slowResponseCount: 0,
        operationBreakdown: {},
      );
    }

    final totalTime = allResponseTimes.fold<Duration>(
      Duration.zero,
      (total, duration) => total + duration,
    );

    final averageResponseTime = Duration(
      microseconds: totalTime.inMicroseconds ~/ allResponseTimes.length,
    );

    final minResponseTime = allResponseTimes.reduce((a, b) => a < b ? a : b);
    final maxResponseTime = allResponseTimes.reduce((a, b) => a > b ? a : b);

    final slowResponseCount =
        allResponseTimes
            .where((duration) => duration > _slowOperationThreshold)
            .length;

    return NetworkPerformanceStats(
      totalRequests: allResponseTimes.length,
      averageResponseTime: averageResponseTime,
      minResponseTime: minResponseTime,
      maxResponseTime: maxResponseTime,
      slowResponseCount: slowResponseCount,
      operationBreakdown: operationStats,
    );
  }

  /// Clear all performance data
  void clearData() {
    _timers.clear();
    _measurements.clear();
    _operationCounts.clear();
    _responseTimes.clear();
  }

  /// Generate performance report
  String generateReport() {
    final stats = getAllStats();
    final networkStats = getNetworkStats();

    final buffer = StringBuffer();
    buffer.writeln('📊 PERFORMANCE REPORT');
    buffer.writeln('=' * 50);

    // Overall statistics
    buffer.writeln('\n🔍 OVERALL STATISTICS:');
    final totalOperations = stats.values.fold<int>(
      0,
      (sum, stat) => sum + stat.totalCount,
    );
    buffer.writeln('Total Operations: $totalOperations');

    // Operation breakdown
    buffer.writeln('\n📈 OPERATION BREAKDOWN:');
    for (final stat in stats.values) {
      buffer.writeln('${stat.operationName}:');
      buffer.writeln('  Count: ${stat.totalCount}');
      buffer.writeln('  Average: ${stat.averageTime.inMilliseconds}ms');
      buffer.writeln(
        '  Range: ${stat.minTime.inMilliseconds}ms - ${stat.maxTime.inMilliseconds}ms',
      );
      buffer.writeln('  Slow: ${stat.slowOperationCount}');
      buffer.writeln('  Very Slow: ${stat.verySlowOperationCount}');
      buffer.writeln();
    }

    // Network statistics
    buffer.writeln('🌐 NETWORK PERFORMANCE:');
    buffer.writeln('Total Requests: ${networkStats.totalRequests}');
    buffer.writeln(
      'Average Response: ${networkStats.averageResponseTime.inMilliseconds}ms',
    );
    buffer.writeln(
      'Response Range: ${networkStats.minResponseTime.inMilliseconds}ms - ${networkStats.maxResponseTime.inMilliseconds}ms',
    );
    buffer.writeln('Slow Responses: ${networkStats.slowResponseCount}');

    return buffer.toString();
  }

  /// Export performance data as JSON
  Map<String, dynamic> exportData() {
    final stats = getAllStats();
    final networkStats = getNetworkStats();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'enabled': _isEnabled,
      'maxMeasurements': _maxMeasurements,
      'operationStats': stats.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'networkStats': networkStats.toJson(),
      'operationCounts': _operationCounts,
    };
  }

  // Public accessor for max measurements (avoid using private field in tests)
  int get maxMeasurements => _maxMeasurements;
  void setMaxMeasurements(int value) {
    if (value > 0) {
      _maxMeasurements = value;
    }
  }
}

/// Performance statistics for a single operation
class PerformanceStats {
  final String operationName;
  final int totalCount;
  final Duration averageTime;
  final Duration minTime;
  final Duration maxTime;
  final int slowOperationCount;
  final int verySlowOperationCount;

  const PerformanceStats({
    required this.operationName,
    required this.totalCount,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.slowOperationCount,
    required this.verySlowOperationCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationName': operationName,
      'totalCount': totalCount,
      'averageTimeMs': averageTime.inMilliseconds,
      'minTimeMs': minTime.inMilliseconds,
      'maxTimeMs': maxTime.inMilliseconds,
      'slowOperationCount': slowOperationCount,
      'verySlowOperationCount': verySlowOperationCount,
    };
  }
}

/// Network performance statistics
class NetworkPerformanceStats {
  final int totalRequests;
  final Duration averageResponseTime;
  final Duration minResponseTime;
  final Duration maxResponseTime;
  final int slowResponseCount;
  final Map<String, List<Duration>> operationBreakdown;

  const NetworkPerformanceStats({
    required this.totalRequests,
    required this.averageResponseTime,
    required this.minResponseTime,
    required this.maxResponseTime,
    required this.slowResponseCount,
    required this.operationBreakdown,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'averageResponseTimeMs': averageResponseTime.inMilliseconds,
      'minResponseTimeMs': minResponseTime.inMilliseconds,
      'maxResponseTimeMs': maxResponseTime.inMilliseconds,
      'slowResponseCount': slowResponseCount,
      'operationBreakdown': operationBreakdown.map(
        (key, value) =>
            MapEntry(key, value.map((d) => d.inMilliseconds).toList()),
      ),
    };
  }
}
