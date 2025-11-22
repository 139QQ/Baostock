import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../../lib/src/core/performance/monitors/memory_leak_detector.dart';
import '../../lib/src/core/performance/processors/smart_batch_processor.dart';
import '../../lib/src/core/performance/processors/backpressure_controller.dart';
import '../../lib/src/core/performance/processors/adaptive_batch_sizer.dart';
import '../../lib/src/core/performance/services/low_overhead_monitor.dart';
import '../../lib/src/core/performance/managers/advanced_memory_manager.dart';
import '../../lib/src/core/performance/monitors/device_performance_detector.dart';
import '../../lib/src/core/performance/monitors/memory_pressure_monitor.dart';
import '../../lib/src/core/utils/logger.dart';

/// 性能回归测试套件
///
/// 用于检测性能优化组件是否在代码变更后出现性能退化
class PerformanceRegressionTestSuite {
  static const String _baselineDataPath = 'test/performance/baselines';
  static const String _resultsPath = 'test/performance/results';
  static const Duration _defaultTestTimeout = Duration(minutes: 10);

  /// 运行完整的性能回归测试套件
  static Future<void> runFullSuite() async {
    AppLogger.business('开始性能回归测试套件');

    try {
      // 确保目录存在
      await _ensureDirectoriesExist();

      // 加载基准数据
      final baseline = await _loadBaselineData();

      // 运行性能测试
      final results = await _runPerformanceTests();

      // 比较结果
      final comparison = _compareWithBaseline(results, baseline);

      // 生成报告
      await _generateReport(results, comparison);

      // 验证是否通过回归测试
      _validateRegressionTest(comparison);

      AppLogger.business('性能回归测试套件完成');
    } catch (e) {
      AppLogger.error('性能回归测试套件失败', e);
      rethrow;
    }
  }

  /// 运行内存管理器性能回归测试
  static Future<PerformanceTestResult> runMemoryManagerRegression() async {
    AppLogger.business('开始内存管理器性能回归测试');

    final result = PerformanceTestResult(
      testName: 'MemoryManager Regression',
      startTime: DateTime.now(),
    );

    try {
      final memoryManager = AdvancedMemoryManager();
      await memoryManager.initialize();

      // 测试1: 内存分配性能
      result.addMetric(
          'memory_allocation_time', await _testMemoryAllocation(memoryManager));

      // 测试2: 缓存性能
      result.addMetric(
          'cache_access_time', await _testCachePerformance(memoryManager));

      // 测试3: 内存清理性能
      result.addMetric('cleanup_time', await _testMemoryCleanup(memoryManager));

      // 测试4: 内存泄漏检测
      result.addMetric(
          'leak_detection_time', await _testLeakDetection(memoryManager));

      await memoryManager.dispose();

      result.endTime = DateTime.now();
      result.success = true;
    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();
      AppLogger.error('内存管理器性能回归测试失败', e);
    }

    return result;
  }

  /// 运行批次处理器性能回归测试
  static Future<PerformanceTestResult> runBatchProcessorRegression() async {
    AppLogger.business('开始批次处理器性能回归测试');

    final result = PerformanceTestResult(
      testName: 'BatchProcessor Regression',
      startTime: DateTime.now(),
    );

    try {
      final batchProcessor = SmartBatchProcessor<String>();
      await batchProcessor.initialize();

      // 测试1: 小批次处理性能
      result.addMetric('small_batch_processing_time',
          await _testBatchProcessing(batchProcessor, 50, 10));

      // 测试2: 大批次处理性能
      result.addMetric('large_batch_processing_time',
          await _testBatchProcessing(batchProcessor, 500, 100));

      // 测试3: 自适应性能
      result.addMetric('adaptive_performance_time',
          await _testAdaptiveBatchProcessing(batchProcessor));

      // 测试4: 并发处理性能
      result.addMetric('concurrent_processing_time',
          await _testConcurrentBatchProcessing(batchProcessor));

      await batchProcessor.dispose();

      result.endTime = DateTime.now();
      result.success = true;
    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();
      AppLogger.error('批次处理器性能回归测试失败', e);
    }

    return result;
  }

  /// 运行背压控制器性能回归测试
  static Future<PerformanceTestResult>
      runBackpressureControllerRegression() async {
    AppLogger.business('开始背压控制器性能回归测试');

    final result = PerformanceTestResult(
      testName: 'BackpressureController Regression',
      startTime: DateTime.now(),
    );

    try {
      final backpressureController = BackpressureController();
      await backpressureController.initialize();

      // 测试1: 背压检测性能
      result.addMetric('pressure_detection_time',
          await _testPressureDetection(backpressureController));

      // 测试2: 策略选择性能
      result.addMetric('strategy_selection_time',
          await _testStrategySelection(backpressureController));

      // 测试3: 节流控制性能
      result.addMetric('throttling_control_time',
          await _testThrottlingControl(backpressureController));

      // 测试4: 适应性能
      result.addMetric('adaptation_time',
          await _testBackpressureAdaptation(backpressureController));

      await backpressureController.dispose();

      result.endTime = DateTime.now();
      result.success = true;
    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();
      AppLogger.error('背压控制器性能回归测试失败', e);
    }

    return result;
  }

  /// 运行自适应批次大小调整器性能回归测试
  static Future<PerformanceTestResult> runAdaptiveBatchSizerRegression() async {
    AppLogger.business('开始自适应批次大小调整器性能回归测试');

    final result = PerformanceTestResult(
      testName: 'AdaptiveBatchSizer Regression',
      startTime: DateTime.now(),
    );

    try {
      final batchSizer = AdaptiveBatchSizer();
      await batchSizer.initialize();

      // 测试1: 批次大小调整性能
      result.addMetric('batch_sizing_time', await _testBatchSizing(batchSizer));

      // 测试2: 负载适应性能
      result.addMetric(
          'load_adaptation_time', await _testLoadAdaptation(batchSizer));

      // 测试3: 预测性能
      result.addMetric(
          'prediction_time', await _testSizingPrediction(batchSizer));

      // 测试4: 历史分析性能
      result.addMetric(
          'history_analysis_time', await _testHistoryAnalysis(batchSizer));

      await batchSizer.dispose();

      result.endTime = DateTime.now();
      result.success = true;
    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();
      AppLogger.error('自适应批次大小调整器性能回归测试失败', e);
    }

    return result;
  }

  /// 运行低开销监控器性能回归测试
  static Future<PerformanceTestResult> runLowOverheadMonitorRegression() async {
    AppLogger.business('开始低开销监控器性能回归测试');

    final result = PerformanceTestResult(
      testName: 'LowOverheadMonitor Regression',
      startTime: DateTime.now(),
    );

    try {
      final monitor = LowOverheadMonitor();
      await monitor.initialize();

      // 测试1: 监控启动性能
      result.addMetric(
          'monitoring_startup_time', await _testMonitoringStartup(monitor));

      // 测试2: 数据收集性能
      result.addMetric(
          'data_collection_time', await _testDataCollection(monitor));

      // 测试3: 智能采样性能
      result.addMetric(
          'intelligent_sampling_time', await _testIntelligentSampling(monitor));

      // 测试4: 开销控制性能
      result.addMetric(
          'overhead_control_time', await _testOverheadControl(monitor));

      await monitor.dispose();

      result.endTime = DateTime.now();
      result.success = true;
    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();
      AppLogger.error('低开销监控器性能回归测试失败', e);
    }

    return result;
  }

  /// 确保测试目录存在
  static Future<void> _ensureDirectoriesExist() async {
    for (final dirPath in [_baselineDataPath, _resultsPath]) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  /// 加载基准数据
  static Future<Map<String, dynamic>> _loadBaselineData() async {
    final baselineFile =
        File(path.join(_baselineDataPath, 'performance_baseline.json'));

    if (!await baselineFile.exists()) {
      AppLogger.warning('基准数据文件不存在，将创建新的基准数据');
      return {};
    }

    try {
      final content = await baselineFile.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('加载基准数据失败', e);
      return {};
    }
  }

  /// 运行所有性能测试
  static Future<Map<String, PerformanceTestResult>>
      _runPerformanceTests() async {
    final results = <String, PerformanceTestResult>{};

    // 并行运行测试以提高效率
    final futures = <Future<void>>[];

    futures.add(runMemoryManagerRegression()
        .then((result) => results['memory_manager'] = result));

    futures.add(runBatchProcessorRegression()
        .then((result) => results['batch_processor'] = result));

    futures.add(runBackpressureControllerRegression()
        .then((result) => results['backpressure_controller'] = result));

    futures.add(runAdaptiveBatchSizerRegression()
        .then((result) => results['adaptive_batch_sizer'] = result));

    futures.add(runLowOverheadMonitorRegression()
        .then((result) => results['low_overhead_monitor'] = result));

    await Future.wait(futures);

    return results;
  }

  /// 与基准数据比较
  static PerformanceComparison _compareWithBaseline(
    Map<String, PerformanceTestResult> results,
    Map<String, dynamic> baseline,
  ) {
    final comparison = PerformanceComparison();

    for (final entry in results.entries) {
      final testName = entry.key;
      final testResult = entry.value;

      final baselineMetrics = baseline[testName] as Map<String, dynamic>?;

      if (baselineMetrics != null) {
        for (final metricEntry in testResult.metrics.entries) {
          final metricName = metricEntry.key;
          final currentValue = metricEntry.value;
          final baselineValue = baselineMetrics[metricName];

          if (baselineValue != null) {
            final change = _calculateChange(currentValue, baselineValue);
            comparison.addChange(testName, metricName, change);
          }
        }
      }
    }

    return comparison;
  }

  /// 计算性能变化
  static PerformanceChange _calculateChange(double current, double baseline) {
    final percentageChange = ((current - baseline) / baseline) * 100;

    PerformanceChangeType type;
    if (percentageChange.abs() < 5) {
      type = PerformanceChangeType.stable;
    } else if (percentageChange > 0) {
      type = percentageChange > 20
          ? PerformanceChangeType.majorRegression
          : PerformanceChangeType.minorRegression;
    } else {
      type = percentageChange < -20
          ? PerformanceChangeType.majorImprovement
          : PerformanceChangeType.minorImprovement;
    }

    return PerformanceChange(
      currentValue: current,
      baselineValue: baseline,
      percentageChange: percentageChange,
      type: type,
    );
  }

  /// 生成测试报告
  static Future<void> _generateReport(
    Map<String, PerformanceTestResult> results,
    PerformanceComparison comparison,
  ) async {
    final report = StringBuffer();
    report.writeln('# 性能回归测试报告');
    report.writeln('生成时间: ${DateTime.now()}');
    report.writeln('');

    // 测试结果摘要
    report.writeln('## 测试结果摘要');
    var passedCount = 0;
    var totalCount = results.length;

    for (final result in results.values) {
      if (result.success) {
        passedCount++;
        report.writeln(
            '- ${result.testName}: ✅ 通过 (${result.duration.inMilliseconds}ms)');
      } else {
        report.writeln('- ${result.testName}: ❌ 失败 (${result.error})');
      }
    }

    report.writeln('');
    report.writeln(
        '通过率: $passedCount/$totalCount (${(passedCount / totalCount * 100).toStringAsFixed(1)}%)');
    report.writeln('');

    // 性能变化分析
    report.writeln('## 性能变化分析');
    final changes = comparison.getAllChanges();

    for (final testName in changes.keys) {
      report.writeln('### $testName');
      final testChanges = changes[testName]!;

      for (final change in testChanges.values) {
        final status = switch (change.type) {
          PerformanceChangeType.majorRegression => '🔴 主要退化',
          PerformanceChangeType.minorRegression => '🟡 轻微退化',
          PerformanceChangeType.stable => '🟢 稳定',
          PerformanceChangeType.minorImprovement => '🔵 轻微改善',
          PerformanceChangeType.majorImprovement => '🟦 主要改善',
        };

        report.writeln(
            '- ${status}: ${change.percentageChange.toStringAsFixed(1)}% '
            '(基线: ${change.baselineValue.toStringAsFixed(2)}, '
            '当前: ${change.currentValue.toStringAsFixed(2)})');
      }
      report.writeln('');
    }

    // 详细性能指标
    report.writeln('## 详细性能指标');
    for (final result in results.values) {
      report.writeln('### ${result.testName}');
      for (final metric in result.metrics.entries) {
        report.writeln('- ${metric.key}: ${metric.value.toStringAsFixed(2)}');
      }
      report.writeln('');
    }

    // 保存报告
    final reportFile = File(path.join(_resultsPath,
        'performance_report_${DateTime.now().millisecondsSinceEpoch}.md'));
    await reportFile.writeAsString(report.toString());

    // 保存结果数据
    final resultsData = {
      'timestamp': DateTime.now().toIso8601String(),
      'results': results.map((key, value) => MapEntry(key, value.toJson())),
      'comparison': comparison.toJson(),
    };

    final resultsFile = File(path.join(_resultsPath,
        'performance_results_${DateTime.now().millisecondsSinceEpoch}.json'));
    await resultsFile.writeAsString(jsonEncode(resultsData));
  }

  /// 验证回归测试结果
  static void _validateRegressionTest(PerformanceComparison comparison) {
    final changes = comparison.getAllChanges();
    var regressionCount = 0;
    var majorRegressionCount = 0;

    for (final testChanges in changes.values) {
      for (final change in testChanges.values) {
        switch (change.type) {
          case PerformanceChangeType.majorRegression:
            majorRegressionCount++;
            regressionCount++;
            break;
          case PerformanceChangeType.minorRegression:
            regressionCount++;
            break;
          default:
            break;
        }
      }
    }

    if (majorRegressionCount > 0) {
      throw Exception('检测到 $majorRegressionCount 个主要性能退化，测试失败');
    }

    if (regressionCount > 3) {
      throw Exception('检测到 $regressionCount 个性能退化，测试失败');
    }

    AppLogger.business('性能回归测试通过，检测到 $regressionCount 个轻微退化');
  }

  // 具体测试方法实现

  static Future<double> _testMemoryAllocation(
      AdvancedMemoryManager memoryManager) async {
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < 1000; i++) {
      final data = List.generate(100, (index) => index);
      memoryManager.cacheData('test_$i', data);
    }

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1000.0;
  }

  static Future<double> _testCachePerformance(
      AdvancedMemoryManager memoryManager) async {
    // 预填充缓存
    for (int i = 0; i < 100; i++) {
      final data = List.generate(50, (index) => index);
      memoryManager.cacheData('cache_test_$i', data);
    }

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < 1000; i++) {
      final key = 'cache_test_${i % 100}';
      memoryManager.getCachedData(key);
    }

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1000.0;
  }

  static Future<double> _testMemoryCleanup(
      AdvancedMemoryManager memoryManager) async {
    final stopwatch = Stopwatch()..start();

    await memoryManager.performCleanup();

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testLeakDetection(
      AdvancedMemoryManager memoryManager) async {
    final stopwatch = Stopwatch()..start();

    // 模拟内存泄漏检测
    memoryManager.detectMemoryLeaks();

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testBatchProcessing(
    SmartBatchProcessor<String> processor,
    int totalItems,
    int batchSize,
  ) async {
    final items = List.generate(totalItems, (i) => 'item_$i');

    final stopwatch = Stopwatch()..start();

    await processor.processBatches(items, (batch) async {
      // 模拟处理
      await Future.delayed(Duration(microseconds: 100));
    });

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testAdaptiveBatchProcessing(
      SmartBatchProcessor<String> processor) async {
    final items = List.generate(200, (i) => 'adaptive_item_$i');

    final stopwatch = Stopwatch()..start();

    await processor.processBatches(items, (batch) async {
      // 模拟变化的处理时间
      final delay = Duration(microseconds: 50 + (batch.length * 10));
      await Future.delayed(delay);
    });

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testConcurrentBatchProcessing(
      SmartBatchProcessor<String> processor) async {
    final futures = <Future<void>>[];

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < 5; i++) {
      final items = List.generate(50, (j) => 'concurrent_${i}_$j');
      futures.add(processor.processBatches(items, (batch) async {
        await Future.delayed(Duration(microseconds: 200));
      }));
    }

    await Future.wait(futures);
    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testPressureDetection(
      BackpressureController controller) async {
    final stopwatch = Stopwatch()..start();

    await controller.detectPressure();

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testStrategySelection(
      BackpressureController controller) async {
    final stopwatch = Stopwatch()..start();

    // 模拟压力检测和策略选择
    final pressure = await controller.detectPressure();
    await controller.selectStrategy(pressure);

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testThrottlingControl(
      BackpressureController controller) async {
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < 100; i++) {
      await controller.shouldProceed();
    }

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 100.0;
  }

  static Future<double> _testBackpressureAdaptation(
      BackpressureController controller) async {
    final stopwatch = Stopwatch()..start();

    await controller.startAdaptiveControl();
    await Future.delayed(Duration(milliseconds: 100));
    await controller.stopAdaptiveControl();

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testBatchSizing(AdaptiveBatchSizer sizer) async {
    final stopwatch = Stopwatch()..start();

    await sizer.performAdjustment();

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testLoadAdaptation(AdaptiveBatchSizer sizer) async {
    final stopwatch = Stopwatch()..start();

    // 模拟不同的负载条件
    for (int i = 0; i < 10; i++) {
      sizer.updatePerformanceMetrics(
        throughput: 500.0 + (i * 100),
        errorRate: 0.1 - (i * 0.01),
      );
      await sizer.performAdjustment();
    }

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 10.0;
  }

  static Future<double> _testSizingPrediction(AdaptiveBatchSizer sizer) async {
    final stopwatch = Stopwatch()..start();

    sizer.getRecommendedBatchSize();

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testHistoryAnalysis(AdaptiveBatchSizer sizer) async {
    final stopwatch = Stopwatch()..start();

    sizer.getPerformanceSummary();

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testMonitoringStartup(
      LowOverheadMonitor monitor) async {
    final stopwatch = Stopwatch()..start();

    await monitor.startMonitoring();

    stopwatch.stop();
    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testDataCollection(LowOverheadMonitor monitor) async {
    await monitor.startMonitoring();

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < 10; i++) {
      monitor.getCurrentMetrics();
      await Future.delayed(Duration(milliseconds: 10));
    }

    stopwatch.stop();
    await monitor.stopMonitoring();

    return stopwatch.elapsedMicroseconds / 10.0;
  }

  static Future<double> _testIntelligentSampling(
      LowOverheadMonitor monitor) async {
    await monitor.startMonitoring();

    final stopwatch = Stopwatch()..start();

    // 等待智能采样适应
    await Future.delayed(Duration(milliseconds: 500));

    stopwatch.stop();
    await monitor.stopMonitoring();

    return stopwatch.elapsedMicroseconds / 1.0;
  }

  static Future<double> _testOverheadControl(LowOverheadMonitor monitor) async {
    await monitor.startMonitoring();

    final stopwatch = Stopwatch()..start();

    monitor.getCurrentOverhead();

    stopwatch.stop();
    await monitor.stopMonitoring();

    return stopwatch.elapsedMicroseconds / 1.0;
  }
}

/// 性能测试结果
class PerformanceTestResult {
  final String testName;
  final DateTime startTime;
  DateTime? endTime;
  bool success = false;
  String? error;
  final Map<String, double> metrics = {};

  PerformanceTestResult({
    required this.testName,
    required this.startTime,
  });

  void addMetric(String name, double value) {
    metrics[name] = value;
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'success': success,
      'error': error,
      'durationMs': duration.inMilliseconds,
      'metrics': metrics,
    };
  }
}

/// 性能变化
class PerformanceChange {
  final double currentValue;
  final double baselineValue;
  final double percentageChange;
  final PerformanceChangeType type;

  PerformanceChange({
    required this.currentValue,
    required this.baselineValue,
    required this.percentageChange,
    required this.type,
  });
}

/// 性能变化类型
enum PerformanceChangeType {
  majorRegression,
  minorRegression,
  stable,
  minorImprovement,
  majorImprovement,
}

/// 性能比较结果
class PerformanceComparison {
  final Map<String, Map<String, PerformanceChange>> changes = {};

  void addChange(String testName, String metricName, PerformanceChange change) {
    if (!changes.containsKey(testName)) {
      changes[testName] = {};
    }
    changes[testName]![metricName] = change;
  }

  Map<String, Map<String, PerformanceChange>> getAllChanges() => changes;

  Map<String, dynamic> toJson() {
    return changes.map((testName, testChanges) => MapEntry(
          testName,
          testChanges.map((metricName, change) => MapEntry(
                metricName,
                {
                  'currentValue': change.currentValue,
                  'baselineValue': change.baselineValue,
                  'percentageChange': change.percentageChange,
                  'type': change.type.name,
                },
              )),
        ));
  }
}
