import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'dart:collection';

import 'package:jisu_fund_analyzer/src/core/performance/monitors/device_performance_detector.dart';
import 'package:jisu_fund_analyzer/src/core/performance/monitors/memory_pressure_monitor.dart';
import 'package:jisu_fund_analyzer/src/core/performance/managers/advanced_memory_manager.dart';
import 'package:jisu_fund_analyzer/src/core/performance/processors/smart_batch_processor.dart';
import 'package:jisu_fund_analyzer/src/core/performance/processors/backpressure_controller.dart';
import 'package:jisu_fund_analyzer/src/core/performance/processors/adaptive_batch_sizer.dart';
import 'package:jisu_fund_analyzer/src/core/performance/services/low_overhead_monitor.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';

// 从AdvancedMemoryManager导入类型定义
import 'package:jisu_fund_analyzer/src/core/performance/managers/advanced_memory_manager.dart'
    show MemoryInfo, MemoryPressureLevel;

// 类型定义，用于测试
enum DevicePerformanceTier {
  low_end,
  mid_range,
  high_end,
  ultimate,
}

/// 性能测试基类
abstract class PerformanceTestBase {
  late DeviceCapabilityDetector mockDeviceDetector;
  late MemoryPressureMonitor mockMemoryMonitor;
  late AdvancedMemoryManager mockMemoryManager;
  late SmartBatchProcessor<String> batchProcessor;
  late BackpressureController backpressureController;
  late AdaptiveBatchSizer adaptiveBatchSizer;
  late LowOverheadMonitor lowOverheadMonitor;

  /// 性能测试配置
  static const Duration defaultTimeout = Duration(minutes: 5);
  static const Duration shortTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(minutes: 10);

  /// 设置测试环境
  Future<void> setUp() async {
    // 创建Mock对象
    mockDeviceDetector = MockDeviceCapabilityDetector();
    mockMemoryMonitor = MockMemoryPressureMonitor();
    mockMemoryManager = MockAdvancedMemoryManager();

    // 初始化组件
    batchProcessor = SmartBatchProcessor(
      deviceDetector: mockDeviceDetector,
      memoryManager: mockMemoryManager,
    );

    backpressureController = BackpressureController(
      memoryManager: mockMemoryManager,
      memoryMonitor: mockMemoryMonitor,
      deviceDetector: mockDeviceDetector,
    );

    adaptiveBatchSizer = AdaptiveBatchSizer(
      deviceDetector: mockDeviceDetector,
      memoryManager: mockMemoryManager,
      memoryMonitor: mockMemoryMonitor,
    );

    lowOverheadMonitor = LowOverheadMonitor(
      memoryManager: mockMemoryManager,
      memoryMonitor: mockMemoryMonitor,
      deviceDetector: mockDeviceDetector,
    );

    // 初始化组件
    await Future.wait([
      batchProcessor.initialize(),
      backpressureController.initialize(),
      adaptiveBatchSizer.initialize(),
      lowOverheadMonitor.initialize(),
    ]);

    // 启动监控
    await lowOverheadMonitor.startMonitoring();
  }

  /// 清理测试环境
  Future<void> tearDown() async {
    // 停止监控
    await lowOverheadMonitor.stopMonitoring();

    // 清理组件
    await Future.wait([
      batchProcessor.dispose(),
      backpressureController.dispose(),
      adaptiveBatchSizer.dispose(),
      lowOverheadMonitor.dispose(),
    ]);
  }

  /// 模拟设备性能信息
  DevicePerformanceInfo createMockDevicePerformanceInfo({
    int performanceScore = 75,
    int totalMemoryMB = 8192,
    int availableMemoryMB = 4096,
    DevicePerformanceTier tier = DevicePerformanceTier.high_end,
  }) {
    return DevicePerformanceInfo(
      deviceModel: 'Test Device',
      operatingSystem: 'Windows',
      operatingSystemVersion: '11.0',
      cpuCores: 8,
      totalMemoryMB: totalMemoryMB,
      availableMemoryMB: availableMemoryMB,
      cpuFrequencyGHz: 2.4,
      performanceScore: performanceScore,
      tier: tier,
    );
  }

  /// 模拟内存信息
  MemoryInfo createMockMemoryInfo({
    int totalMemoryMB = 8192,
    int availableMemoryMB = 4096,
    int cachedMemoryMB = 2048,
    double pressureScore = 0.3,
  }) {
    return MemoryInfo(
      totalMemoryMB: totalMemoryMB,
      availableMemoryMB: availableMemoryMB,
      cachedMemoryMB: cachedMemoryMB,
    );
  }

  /// 测量执行时间
  Future<T> measureExecutionTime<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      if (operationName != null) {
        print(
            'Operation: $operationName, Time: ${stopwatch.elapsedMilliseconds}ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();

      if (operationName != null) {
        print(
            'Operation: $operationName, Time: ${stopwatch.elapsedMilliseconds}ms (ERROR)');
      }

      rethrow;
    }
  }

  /// 批量操作测试数据生成器
  List<String> generateTestBatchData(int size, {String prefix = 'test'}) {
    return List.generate(size, (index) => '${prefix}_${index}');
  }

  /// 性能断言助手
  void expectPerformance(
    dynamic actual,
    dynamic expected, {
    String? metricName,
    double tolerance = 0.1,
  }) {
    if (actual is num && expected is num) {
      final actualNum = actual.toDouble();
      final expectedNum = expected.toDouble();
      final difference = (actualNum - expectedNum).abs();
      final toleranceAmount = expectedNum * tolerance;

      if (difference > toleranceAmount) {
        fail('Performance assertion failed for ${metricName ?? 'metric'}:\n'
            'Expected: $expected (±${tolerance * 100}%)\n'
            'Actual: $actual\n'
            'Difference: $difference');
      }
    } else {
      expect(actual, expected);
    }
  }

  /// 性能基准断言
  void expectPerformanceAbove(
    dynamic actual,
    dynamic minimum, {
    String? metricName,
  }) {
    if (actual is num && minimum is num) {
      final actualNum = actual.toDouble();
      final minimumNum = minimum.toDouble();

      if (actualNum < minimumNum) {
        fail('Performance assertion failed for ${metricName ?? 'metric'}:\n'
            'Expected: >= $minimum\n'
            'Actual: $actual');
      }
    } else {
      expect(actual, greaterThanOrEqualTo(minimum));
    }
  }

  /// 性能基准断言（最大值）
  void expectPerformanceBelow(
    dynamic actual,
    dynamic maximum, {
    String? metricName,
  }) {
    if (actual is num && maximum is num) {
      final actualNum = actual.toDouble();
      final maximumNum = maximum.toDouble();

      if (actualNum > maximumNum) {
        fail('Performance assertion failed for ${metricName ?? 'metric'}:\n'
            'Expected: <= $maximum\n'
            'Actual: $actual');
      }
    } else {
      expect(actual, lessThanOrEqualTo(maximum));
    }
  }

  /// 吞吐量测试辅助函数
  Future<double> measureThroughput<T>({
    required Future<T> Function() operation,
    required int iterations,
    Duration warmupTime = const Duration(seconds: 1),
  }) async {
    // 预热
    if (warmupTime.inMilliseconds > 0) {
      await Future.delayed(warmupTime);
      await operation(); // 预热操作
    }

    final stopwatch = Stopwatch()..start();

    // 执行测试迭代
    for (int i = 0; i < iterations; i++) {
      await operation();
    }

    stopwatch.stop();

    final totalTimeSeconds = stopwatch.elapsedMilliseconds / 1000.0;
    return iterations / totalTimeSeconds;
  }

  /// 内存使用监控辅助函数
  Future<MemoryInfo> monitorMemoryUsage<T>(
    Future<T> Function() operation, {
    MemoryInfo? before,
  }) async {
    final beforeMemory = before ?? createMockMemoryInfo();

    final result = await operation();

    final afterMemory = createMockMemoryInfo();

    print('Memory usage change: '
        '${(beforeMemory.availableMemoryMB - afterMemory.availableMemoryMB)}MB');

    return afterMemory;
  }

  /// 并发性能测试辅助函数
  Future<List<T>> measureConcurrentPerformance<T>({
    required List<Future<T> Function()> operations,
    int? maxConcurrency,
  }) async {
    final concurrency = maxConcurrency ?? operations.length;
    final semaphore = _Semaphore(concurrency);

    final futures =
        operations.map((op) => _executeWithSemaphore(op, semaphore));

    return Future.wait(futures);
  }

  /// 带信号量的执行
  Future<T> _executeWithSemaphore<T>(
    Future<T> Function() operation,
    _Semaphore semaphore,
  ) async {
    await semaphore.acquire();
    try {
      return await operation();
    } finally {
      semaphore.release();
    }
  }

  /// 随机数据生成器
  List<T> generateRandomData<T>({
    required int size,
    required T Function() generator,
  }) {
    return List.generate(size, (_) => generator());
  }

  /// 压力测试辅助函数
  Future<void> runStressTest({
    required Future<void> Function() testOperation,
    Duration duration = const Duration(minutes: 2),
    int? checkInterval,
  }) async {
    final interval = checkInterval ?? duration.inSeconds ~/ 10;
    final stopwatch = Stopwatch()..start();

    print('Starting stress test for ${duration.inMinutes} minutes...');

    int iteration = 0;
    while (stopwatch.elapsed < duration) {
      await testOperation();

      iteration++;
      if (iteration % interval == 0) {
        print('Stress test progress: '
            '${stopwatch.elapsed.inMinutes}min ${stopwatch.elapsed.inSeconds % 60}s, '
            'iterations: $iteration');
      }

      // 防止过度占用CPU
      await Future.delayed(const Duration(milliseconds: 1));
    }

    stopwatch.stop();
    print('Stress test completed. Total iterations: $iteration, '
        'Time: ${stopwatch.elapsed.inMinutes}min');
  }

  /// 负载测试辅助函数
  Future<Map<String, dynamic>> runLoadTest({
    required Map<String, int> loadLevels,
    required Future<void> Function(int loadLevel) loadOperation,
    Duration durationPerLevel = const Duration(seconds: 30),
  }) async {
    final results = <String, dynamic>{};

    for (final entry in loadLevels.entries) {
      final loadName = entry.key;
      final loadLevel = entry.value;

      print('Running load test: $loadName (Level: $loadLevel)');

      final stopwatch = Stopwatch()..start();

      try {
        await loadOperation(loadLevel);
        stopwatch.stop();

        results[loadName] = {
          'loadLevel': loadLevel,
          'duration': stopwatch.elapsedMilliseconds,
          'success': true,
        };

        print(
            'Load test completed: $loadName, Time: ${stopwatch.elapsedMilliseconds}ms');
      } catch (e) {
        stopwatch.stop();

        results[loadName] = {
          'loadLevel': loadLevel,
          'duration': stopwatch.elapsedMilliseconds,
          'success': false,
          'error': e.toString(),
        };

        print('Load test failed: $loadName, Error: $e');
      }

      // 负载级别间的休息时间
      await Future.delayed(const Duration(seconds: 5));
    }

    return results;
  }
}

/// 简单信号量实现
class _Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  _Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}

/// Mock类
class MockDeviceCapabilityDetector extends Mock
    implements DeviceCapabilityDetector {}

class MockMemoryPressureMonitor extends Mock implements MemoryPressureMonitor {}

class MockAdvancedMemoryManager extends Mock implements AdvancedMemoryManager {
  @override
  MemoryInfo getMemoryInfo() => MemoryInfo(
        totalMemoryMB: 8192,
        availableMemoryMB: 4096,
        cachedMemoryMB: 2048,
      );
}
