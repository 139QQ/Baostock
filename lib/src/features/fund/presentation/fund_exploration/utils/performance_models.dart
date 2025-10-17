import 'dart:math' as math;

/// 性能指标
class PerformanceMetrics {
  final String operation;
  int totalCalls = 0;
  int totalTime = 0; // 毫秒
  int minTime = 0;
  int maxTime = 0;
  int cacheHits = 0;
  int errors = 0;

  PerformanceMetrics(this.operation);

  double get averageTime => totalCalls > 0 ? totalTime / totalCalls : 0.0;
  double get cacheHitRate => totalCalls > 0 ? cacheHits / totalCalls : 0.0;
  double get errorRate => totalCalls > 0 ? errors / totalCalls : 0.0;

  void recordCall(int timeMs, {bool cached = false, bool error = false}) {
    totalCalls++;
    totalTime += timeMs;

    if (totalCalls == 1) {
      minTime = maxTime = timeMs;
    } else {
      minTime = math.min(minTime, timeMs);
      maxTime = math.max(maxTime, timeMs);
    }

    if (cached) cacheHits++;
    if (error) errors++;
  }

  Map<String, dynamic> toJson() => {
        'operation': operation,
        'totalCalls': totalCalls,
        'averageTime': averageTime.toStringAsFixed(2),
        'minTime': minTime,
        'maxTime': maxTime,
        'cacheHitRate': '${(cacheHitRate * 100).toStringAsFixed(1)}%',
        'errorRate': '${(errorRate * 100).toStringAsFixed(1)}%',
      };
}

/// 性能事件
class PerformanceEvent {
  final String type;
  final String operation;
  final int duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceEvent({
    required this.type,
    required this.operation,
    required this.duration,
    required this.metadata,
  }) : timestamp = DateTime.now();
}
