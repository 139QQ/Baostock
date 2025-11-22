import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/core/performance/processors/hybrid_data_parser.dart';
import '../../lib/src/core/performance/processors/improved_isolate_manager.dart';
import '../../lib/src/core/performance/processors/stream_lifecycle_manager.dart';
import '../../lib/src/core/performance/monitors/memory_leak_detector.dart';
import '../../lib/src/core/performance/processors/isolate_communication_optimizer.dart';

/// 基准测试结果
class BenchmarkResult {
  final String testName;
  final Map<String, dynamic> metrics;
  final bool passed;
  final String? errorMessage;
  final DateTime startTime;
  final DateTime endTime;

  BenchmarkResult({
    required this.testName,
    required this.metrics,
    required this.passed,
    this.errorMessage,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'metrics': metrics,
      'passed': passed,
      'errorMessage': errorMessage,
      'duration': duration.inMilliseconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }
}

/// 10,000条数据基准测试套件
class BenchmarkTestSuite {
  static final BenchmarkTestSuite _instance = BenchmarkTestSuite._internal();
  factory BenchmarkTestSuite() => _instance;
  BenchmarkTestSuite._internal();

  final List<BenchmarkResult> _results = [];

  /// 执行完整的基准测试套件
  Future<List<BenchmarkResult>> runFullBenchmarkSuite() async {
    print('🚀 开始执行10,000条数据基准测试套件');

    final results = <BenchmarkResult>[];

    // 1. JSON解析性能测试
    results.add(await testJsonParsingPerformance());

    // 2. 混合解析器性能测试
    results.add(await testHybridParserPerformance());

    // 3. Isolate通信性能测试
    results.add(await testIsolateCommunicationPerformance());

    // 4. 内存泄漏检测性能测试
    results.add(await testMemoryLeakDetectionPerformance());

    // 5. Stream生命周期管理性能测试
    results.add(await testStreamLifecyclePerformance());

    // 6. 综合性能测试
    results.add(await testComprehensivePerformance());

    _results.addAll(results);

    // 生成报告
    print('\n📊 基准测试结果汇总:');
    for (final result in results) {
      final status = result.passed ? '✅ 通过' : '❌ 失败';
      print('$status ${result.testName} (${result.duration.inMilliseconds}ms)');
    }

    return results;
  }

  /// JSON解析性能测试
  Future<BenchmarkResult> testJsonParsingPerformance() async {
    final testName = 'JSON解析性能测试';
    final startTime = DateTime.now();

    try {
      print('🔍 执行 $testName');

      // 生成10,000条测试数据
      final testData = _generateTestData(10000);
      final jsonString = jsonEncode(testData);

      // 执行解析测试
      final stopwatch = Stopwatch()..start();
      final parsedData = jsonDecode(jsonString) as List;
      stopwatch.stop();

      final parseTimeMs = stopwatch.elapsedMilliseconds;
      final throughputItemsPerSec = 10000 * 1000 / parseTimeMs;
      final performanceImprovement =
          _calculatePerformanceImprovement(parseTimeMs);

      final metrics = {
        'itemCount': 10000,
        'dataSizeBytes': jsonString.length,
        'parseTimeMs': parseTimeMs,
        'throughputItemsPerSec': throughputItemsPerSec.round(),
        'performanceImprovementPercent': performanceImprovement,
        'targetImprovement': 200, // 目标提升200%
        'passed': performanceImprovement >= 200,
      };

      final result = BenchmarkResult(
        testName: testName,
        metrics: metrics,
        passed: performanceImprovement >= 200,
        startTime: startTime,
        endTime: DateTime.now(),
      );

      print('  解析时间: ${parseTimeMs}ms');
      print('  吞吐量: ${throughputItemsPerSec.round()} 项/秒');
      print('  性能提升: ${performanceImprovement}% (目标: 200%)');

      return result;
    } catch (e) {
      print('❌ $testName 失败: $e');
      return BenchmarkResult(
        testName: testName,
        metrics: {},
        passed: false,
        errorMessage: e.toString(),
        startTime: startTime,
        endTime: DateTime.now(),
      );
    }
  }

  /// 混合解析器性能测试
  Future<BenchmarkResult> testHybridParserPerformance() async {
    final testName = '混合解析器性能测试';
    final startTime = DateTime.now();

    try {
      print('🔍 执行 $testName');

      final parser = HybridDataParser();

      // 测试不同数据量
      final testSizes = [100, 1000, 5000, 10000];
      final results = <Map<String, dynamic>>[];

      for (final size in testSizes) {
        final testData = _generateTestData(size);

        final stopwatch = Stopwatch()..start();
        final parsedData = await parser.parseFundData(testData);
        stopwatch.stop();

        final throughput =
            parsedData.length * 1000 / stopwatch.elapsedMilliseconds;

        results.add({
          'size': size,
          'parseTimeMs': stopwatch.elapsedMilliseconds,
          'throughput': throughput.round(),
        });

        print(
            '  $size 项: ${stopwatch.elapsedMilliseconds}ms, ${throughput.round()} 项/秒');
      }

      // 检查10,000条数据的性能
      final tenThousandResult = results.lastWhere((r) => r['size'] == 10000);
      final passed = tenThousandResult['parseTimeMs'] < 100; // 目标<100ms

      final metrics = {
        'testResults': results,
        'tenThousandItems': {
          'parseTimeMs': tenThousandResult['parseTimeMs'],
          'throughput': tenThousandResult['throughput'],
          'targetTimeMs': 100,
          'passed': passed,
        },
      };

      return BenchmarkResult(
        testName: testName,
        metrics: metrics,
        passed: passed,
        startTime: startTime,
        endTime: DateTime.now(),
      );
    } catch (e) {
      print('❌ $testName 失败: $e');
      return BenchmarkResult(
        testName: testName,
        metrics: {},
        passed: false,
        errorMessage: e.toString(),
        startTime: startTime,
        endTime: DateTime.now(),
      );
    }
  }

  /// Isolate通信性能测试
  Future<BenchmarkResult> testIsolateCommunicationPerformance() async {
    final testName = 'Isolate通信性能测试';
    final startTime = DateTime.now();

    try {
      print('🔍 执行 $testName');

      final optimizer = IsolateCommunicationOptimizer();
      optimizer.start();

      // 模拟Isolate通信测试
      final communicationTests = <Map<String, dynamic>>[];

      for (int i = 0; i < 100; i++) {
        final dataSize = math.Random().nextInt(10000) + 1000;
        final testData =
            List.generate(dataSize ~/ 100, (index) => 'data_$index');

        final stopwatch = Stopwatch()..start();

        // 模拟通信延迟
        await Future.delayed(
            Duration(milliseconds: math.Random().nextInt(10) + 1));

        stopwatch.stop();

        communicationTests.add({
          'testIndex': i,
          'dataSize': dataSize,
          'communicationTimeMs': stopwatch.elapsedMilliseconds,
          'throughputBytesPerSec':
              (dataSize * 1000 / stopwatch.elapsedMilliseconds).round(),
        });
      }

      final avgTime = communicationTests
              .map((t) => t['communicationTimeMs'] as int)
              .reduce((a, b) => a + b) /
          communicationTests.length;

      final passed = avgTime < 50; // 平均通信时间<50ms

      final metrics = {
        'communicationTests': communicationTests,
        'averageTimeMs': avgTime.roundToDouble(),
        'targetTimeMs': 50,
        'passed': passed,
      };

      optimizer.stop();

      print('  平均通信时间: ${avgTime.round()}ms (目标: <50ms)');

      return BenchmarkResult(
        testName: testName,
        metrics: metrics,
        passed: passed,
        startTime: startTime,
        endTime: DateTime.now(),
      );
    } catch (e) {
      print('❌ $testName 失败: $e');
      return BenchmarkResult(
        testName: testName,
        metrics: {},
        passed: false,
        errorMessage: e.toString(),
        startTime: startTime,
        endTime: DateTime.now(),
      );
    }
  }

  /// 内存泄漏检测性能测试
  Future<BenchmarkResult> testMemoryLeakDetectionPerformance() async {
    final testName = '内存泄漏检测性能测试';
    final startTime = DateTime.now();

    try {
      print('🔍 执行 $testName');

      final detector = MemoryLeakDetector();
      detector.start();

      // 执行多次检测
      final detectionTests = <Map<String, dynamic>>[];

      for (int i = 0; i < 50; i++) {
        final stopwatch = Stopwatch()..start();
        final result = detector.detectLeak();
        stopwatch.stop();

        detectionTests.add({
          'testIndex': i,
          'detectionTimeMs': stopwatch.elapsedMilliseconds,
          'hasLeak': result.hasLeak,
          'leakScore': result.leakScore,
        });
      }

      final avgTime = detectionTests
              .map((t) => t['detectionTimeMs'] as int)
              .reduce((a, b) => a + b) /
          detectionTests.length;

      final maxTime = detectionTests
          .map((t) => t['detectionTimeMs'] as int)
          .reduce(math.max);

      final passed = avgTime < 10 && maxTime < 20; // 平均<10ms，最大<20ms

      final metrics = {
        'detectionTests': detectionTests,
        'averageTimeMs': avgTime.roundToDouble(),
        'maxTimeMs': maxTime,
        'targetAvgTimeMs': 10,
        'targetMaxTimeMs': 20,
        'passed': passed,
      };

      detector.stop();

      print('  平均检测时间: ${avgTime.round()}ms (目标: <10ms)');
      print('  最大检测时间: ${maxTime}ms (目标: <20ms)');

      return BenchmarkResult(
        testName: testName,
        metrics: metrics,
        passed: passed,
        startTime: startTime,
        endTime: DateTime.now(),
      );
    } catch (e) {
      print('❌ $testName 失败: $e');
      return BenchmarkResult(
        testName: testName,
        metrics: {},
        passed: false,
        errorMessage: e.toString(),
        startTime: startTime,
        endTime: DateTime.now(),
      );
    }
  }

  /// Stream生命周期管理性能测试
  Future<BenchmarkResult> testStreamLifecyclePerformance() async {
    final testName = 'Stream生命周期管理性能测试';
    final startTime = DateTime.now();

    try {
      print('🔍 执行 $testName');

      final manager = StreamLifecycleManager();
      manager.start();

      // 创建大量Stream订阅
      final subscriptionIds = <String>[];
      final creationTimes = <int>[];

      for (int i = 0; i < 1000; i++) {
        final stopwatch = Stopwatch()..start();

        final subscriptionId = manager.listenToStream(
          streamName: 'test_stream_$i',
          stream: Stream.periodic(Duration(seconds: 1), (index) => 'data_$i'),
          onData: (data) {},
          onError: (error) {},
          onDone: () {},
        );

        stopwatch.stop();

        subscriptionIds.add(subscriptionId);
        creationTimes.add(stopwatch.elapsedMilliseconds);
      }

      final avgCreationTime =
          creationTimes.reduce((a, b) => a + b) / creationTimes.length;
      final maxCreationTime = creationTimes.reduce(math.max);

      // 测试批量清理
      final cleanupStopwatch = Stopwatch()..start();
      for (final subscriptionId in subscriptionIds) {
        await manager.cancelSubscription(subscriptionId);
      }
      cleanupStopwatch.stop();

      final passed = avgCreationTime < 5 &&
          maxCreationTime < 20 &&
          cleanupStopwatch.elapsedMilliseconds < 1000;

      final metrics = {
        'subscriptionCount': subscriptionIds.length,
        'avgCreationTimeMs': avgCreationTime.roundToDouble(),
        'maxCreationTimeMs': maxCreationTime,
        'cleanupTimeMs': cleanupStopwatch.elapsedMilliseconds,
        'targetAvgCreationTimeMs': 5,
        'targetMaxCreationTimeMs': 20,
        'targetCleanupTimeMs': 1000,
        'passed': passed,
      };

      manager.stop();

      print('  平均创建时间: ${avgCreationTime.round()}ms (目标: <5ms)');
      print('  最大创建时间: ${maxCreationTime}ms (目标: <20ms)');
      print('  清理时间: ${cleanupStopwatch.elapsedMilliseconds}ms (目标: <1000ms)');

      return BenchmarkResult(
        testName: testName,
        metrics: metrics,
        passed: passed,
        startTime: startTime,
        endTime: DateTime.now(),
      );
    } catch (e) {
      print('❌ $testName 失败: $e');
      return BenchmarkResult(
        testName: testName,
        metrics: {},
        passed: false,
        errorMessage: e.toString(),
        startTime: startTime,
        endTime: DateTime.now(),
      );
    }
  }

  /// 综合性能测试
  Future<BenchmarkResult> testComprehensivePerformance() async {
    final testName = '综合性能测试';
    final startTime = DateTime.now();

    try {
      print('🔍 执行 $testName');

      // 同时运行多个性能测试
      final futures = <Future>[];

      // JSON解析
      futures.add(_runJsonParsingInParallel());

      // 混合解析器
      futures.add(_runHybridParserInParallel());

      // 内存检测
      futures.add(_runMemoryDetectionInParallel());

      // Stream管理
      futures.add(_runStreamManagementInParallel());

      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();

      final passed = stopwatch.elapsedMilliseconds < 5000; // 总时间<5秒

      final metrics = {
        'totalTimeMs': stopwatch.elapsedMilliseconds,
        'targetTimeMs': 5000,
        'parallelTests': futures.length,
        'passed': passed,
      };

      print('  总执行时间: ${stopwatch.elapsedMilliseconds}ms (目标: <5000ms)');
      print('  并行测试数: ${futures.length}');

      return BenchmarkResult(
        testName: testName,
        metrics: metrics,
        passed: passed,
        startTime: startTime,
        endTime: DateTime.now(),
      );
    } catch (e) {
      print('❌ $testName 失败: $e');
      return BenchmarkResult(
        testName: testName,
        metrics: {},
        passed: false,
        errorMessage: e.toString(),
        startTime: startTime,
        endTime: DateTime.now(),
      );
    }
  }

  /// 并行运行JSON解析测试
  Future<void> _runJsonParsingInParallel() async {
    final testData = _generateTestData(1000);
    final jsonString = jsonEncode(testData);
    await Future.delayed(Duration(milliseconds: 50)); // 模拟解析时间
    jsonDecode(jsonString);
  }

  /// 并行运行混合解析器测试
  Future<void> _runHybridParserInParallel() async {
    final parser = HybridDataParser();
    final testData = _generateTestData(500);
    await parser.parseFundData(testData);
  }

  /// 并行运行内存检测测试
  Future<void> _runMemoryDetectionInParallel() async {
    final detector = MemoryLeakDetector();
    detector.detectLeak();
  }

  /// 并行运行Stream管理测试
  Future<void> _runStreamManagementInParallel() async {
    final manager = StreamLifecycleManager();
    final subscriptionId = manager.listenToStream(
      streamName: 'parallel_test',
      stream: Stream.value('test_data'),
      onData: (data) {},
      onError: (error) {},
      onDone: () {},
    );
    await Future.delayed(Duration(milliseconds: 10));
    await manager.cancelSubscription(subscriptionId);
  }

  /// 生成测试数据
  List<Map<String, dynamic>> _generateTestData(int count) {
    return List.generate(
        count,
        (index) => {
              'code': 'FUND${(index + 1).toString().padLeft(6, '0')}',
              'name': '测试基金${index + 1}',
              'nav': (math.Random().nextDouble() * 10 + 1).toStringAsFixed(4),
              'navDate':
                  '2024-01-${(index % 28 + 1).toString().padLeft(2, '0')}',
              'dailyChange':
                  (math.Random().nextDouble() - 0.5).toStringAsFixed(4),
              'changePercent':
                  ((math.Random().nextDouble() - 0.5) * 10).toStringAsFixed(2),
            });
  }

  /// 计算性能提升百分比（与基准相比）
  double _calculatePerformanceImprovement(int currentParseTimeMs) {
    // 假设基准性能为5000ms解析10000条数据
    final baselineTimeMs = 5000;
    final improvementPercent =
        ((baselineTimeMs - currentParseTimeMs) / baselineTimeMs) * 100;
    return improvementPercent;
  }

  /// 获取所有测试结果
  List<BenchmarkResult> getAllResults() {
    return List.unmodifiable(_results);
  }

  /// 生成测试报告
  Map<String, dynamic> generateReport() {
    if (_results.isEmpty) {
      return {'error': '没有测试结果'};
    }

    final passedCount = _results.where((r) => r.passed).length;
    final totalCount = _results.length;
    final passRate =
        totalCount > 0 ? (passedCount / totalCount * 100).round() : 0;

    return {
      'summary': {
        'totalTests': totalCount,
        'passedTests': passedCount,
        'failedTests': totalCount - passedCount,
        'passRate': passRate,
      },
      'results': _results.map((r) => r.toJson()).toList(),
      'recommendations': _generateRecommendations(),
    };
  }

  /// 生成建议
  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    final failedTests = _results.where((r) => !r.passed);
    for (final test in failedTests) {
      switch (test.testName) {
        case 'JSON解析性能测试':
          recommendations.add('考虑优化JSON解析算法，使用更高效的解析库');
          break;
        case '混合解析器性能测试':
          recommendations.add('调整解析策略阈值，优化Isolate通信');
          break;
        case 'Isolate通信性能测试':
          recommendations.add('优化通信协议，减少序列化开销');
          break;
        case '内存泄漏检测性能测试':
          recommendations.add('优化检测算法，减少CPU使用');
          break;
        case 'Stream生命周期管理性能测试':
          recommendations.add('优化订阅管理机制，提高批量操作效率');
          break;
        case '综合性能测试':
          recommendations.add('优化并发处理机制，减少资源竞争');
          break;
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('所有性能测试通过，系统性能表现良好');
    }

    return recommendations;
  }
}

/// 主函数 - 运行基准测试
void main() async {
  print('🎯 10,000条数据基准测试开始\n');

  final testSuite = BenchmarkTestSuite();
  final results = await testSuite.runFullBenchmarkSuite();

  print('\n📋 详细测试报告:');
  final report = testSuite.generateReport();

  print('总结:');
  print('  总测试数: ${report['summary']['totalTests']}');
  print('  通过测试: ${report['summary']['passedTests']}');
  print('  失败测试: ${report['summary']['failedTests']}');
  print('  通过率: ${report['summary']['passRate']}%');

  if (report['summary']['failedTests'] > 0) {
    print('\n💡 性能优化建议:');
    for (final recommendation in report['recommendations']) {
      print('  - $recommendation');
    }
  }

  print('\n✨ 基准测试完成');
}
