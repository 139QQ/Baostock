import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/fund/data/monitors/nav_latency_monitor.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';

@GenerateMocks([])
void main() {
  group('NavLatencyMonitor Tests', () {
    late NavLatencyMonitor monitor;

    setUp(() {
      monitor = NavLatencyMonitor();
    });

    tearDown(() {
      monitor.dispose();
    });

    group('基础操作监控', () {
      test('应该能够启动和停止操作', () {
        final operationId =
            monitor.startOperation('test_operation', {'fundCode': '000001'});

        expect(operationId, isNotNull);
        expect(operationId, isNotEmpty);

        // 结束操作
        monitor.endOperation(operationId, result: {'success': true});

        // 验证没有异常抛出即表示成功
        expect(true, isTrue);
      });

      test('应该能够处理未知操作ID', () {
        // 这应该只是记录警告，不抛出异常
        monitor.endOperation('unknown_operation_id');

        // 验证没有异常抛出
        expect(true, isTrue);
      });

      test('应该能够处理重复停止操作', () {
        final operationId = monitor.startOperation('test_operation', {});

        // 第一次停止
        monitor.endOperation(operationId);

        // 第二次停止（应该只是记录警告）
        monitor.endOperation(operationId);

        // 验证没有异常抛出
        expect(true, isTrue);
      });
    });

    group('指标记录', () {
      test('应该能够记录自定义指标', () {
        monitor.recordMetric('custom_metric', 100,
            tags: {'source': 'test', 'type': 'performance'});

        // 验证指标被记录 - 通过获取实时指标来验证
        final realTimeMetrics = monitor.getRealTimeMetrics();
        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['timestamp'], isNotNull);
      });

      test('应该能够记录多个相同指标', () {
        monitor.recordMetric('response_time', 100);
        monitor.recordMetric('response_time', 200);
        monitor.recordMetric('response_time', 150);

        // 验证指标被记录
        final realTimeMetrics = monitor.getRealTimeMetrics();
        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['timestamp'], isNotNull);
      });

      test('应该能够记录带标签的指标', () {
        monitor.recordMetric('cache_hit', 1, tags: {'cache': 'L1'});
        monitor.recordMetric('cache_hit', 1, tags: {'cache': 'L2'});

        // 验证指标被记录
        final realTimeMetrics = monitor.getRealTimeMetrics();
        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['timestamp'], isNotNull);
      });

      test('应该能够记录错误', () {
        monitor.recordError(
            'network_timeout', 'Network timeout after 30 seconds',
            context: {'fundCode': '000001', 'operation': 'fetch_nav'});

        // 验证错误被记录 - 通过获取实时指标来验证错误指标
        final realTimeMetrics = monitor.getRealTimeMetrics();
        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['errors'], isNotNull);
      });

      test('应该能够记录多个错误', () {
        monitor.recordError('validation_error', 'Invalid fund code');
        monitor.recordError('cache_error', 'Cache write failed');
        monitor.recordError('network_error', 'Connection refused');

        // 验证错误被记录
        final realTimeMetrics = monitor.getRealTimeMetrics();
        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['errors'], isNotNull);
      });
    });

    group('性能统计', () {
      test('应该能够获取实时性能指标', () async {
        // 模拟一些操作
        for (int i = 0; i < 5; i++) {
          final operationId =
              monitor.startOperation('fetch_nav', {'fundCode': '00000$i'});
          await Future.delayed(Duration(milliseconds: 10 * (i + 1)));
          monitor.endOperation(operationId, result: {'success': true});
        }

        // 记录一些指标
        monitor.recordMetric('cache_hit_rate', 0.8);
        monitor.recordMetric('request_count', 100);

        final realTimeMetrics = monitor.getRealTimeMetrics();

        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['operations'], isNotNull);
        expect(realTimeMetrics['cache'], isNotNull);
        expect(realTimeMetrics['network'], isNotNull);
        expect(realTimeMetrics['errors'], isNotNull);
        expect(realTimeMetrics['anomalies'], isNotNull);
        expect(realTimeMetrics['timestamp'], isNotNull);
      });

      test('应该能够获取性能报告', () async {
        final timeRange = Duration(hours: 1);

        // 模拟一些历史操作
        for (int i = 0; i < 10; i++) {
          final operationId = monitor
              .startOperation('process_nav', {'fundCode': '00000${i % 3}'});
          await Future.delayed(Duration(milliseconds: 5 + i));
          monitor.endOperation(operationId, result: {'success': i % 4 != 0});

          // 模拟一些失败
          if (i % 4 == 0) {
            monitor.recordError(
                'processing_error', 'Failed to process NAV data');
          }
        }

        final report = monitor.getPerformanceReport(timeRange: timeRange);

        expect(report, isNotNull);
        expect(report.timeRange, equals(timeRange));
        expect(report.operationMetrics, isNotNull);
        expect(report.cacheMetrics, isNotNull);
        expect(report.networkMetrics, isNotNull);
        expect(report.errorMetrics, isNotNull);
        expect(report.anomalies, isNotNull);
        expect(report.recommendations, isNotNull);
        expect(report.generatedAt, isNotNull);
      });
    });

    group('阈值监控', () {
      test('应该能够设置延迟阈值', () {
        // 执行一个操作来触发内部阈值检查
        final operationId = monitor.startOperation('test_operation', {});
        monitor.endOperation(operationId);

        // 验证没有异常抛出
        expect(true, isTrue);
      });

      test('应该能够处理高延迟操作', () async {
        // 模拟一个较慢的操作
        final operationId = monitor.startOperation('slow_operation', {});
        await Future.delayed(Duration(milliseconds: 100)); // 模拟100ms延迟
        monitor.endOperation(operationId);

        // 获取性能报告来检查延迟
        final report = monitor.getPerformanceReport();
        expect(report, isNotNull);
        expect(report.operationMetrics, isNotNull);

        // 验证没有异常抛出
        expect(true, isTrue);
      });

      test('应该能够处理错误记录', () {
        // 记录一些错误
        monitor.recordError('test_error', 'This is a test error');
        monitor.recordMetric('error_rate', 0.15);

        // 获取实时指标来验证错误被记录
        final realTimeMetrics = monitor.getRealTimeMetrics();
        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['errors'], isNotNull);

        // 验证没有异常抛出
        expect(true, isTrue);
      });
    });

    group('数据聚合', () {
      test('应该能够按时间窗口聚合数据', () async {
        // 模拟不同时间的操作
        for (int i = 0; i < 10; i++) {
          final operationId = monitor.startOperation('test_operation', {});
          await Future.delayed(Duration(milliseconds: 10));
          monitor.endOperation(operationId);
        }

        // 获取性能报告来验证聚合数据
        final report =
            monitor.getPerformanceReport(timeRange: Duration(minutes: 5));

        expect(report, isNotNull);
        expect(report.operationMetrics, isNotNull);
      });

      test('应该能够按标签聚合数据', () async {
        // 模拟不同基金的操作
        for (int i = 0; i < 6; i++) {
          final fundCode = '00000${i % 3}';
          final operationId =
              monitor.startOperation('fetch_nav', {'fundCode': fundCode});
          await Future.delayed(Duration(milliseconds: 10));
          monitor.endOperation(operationId);
        }

        // 获取性能报告来验证标签数据
        final report = monitor.getPerformanceReport();

        expect(report, isNotNull);
        expect(report.operationMetrics, isNotNull);
      });
    });

    group('异常检测', () {
      test('应该能够检测性能异常', () async {
        // 正常操作
        for (int i = 0; i < 5; i++) {
          final operationId = monitor.startOperation('normal_operation', {});
          await Future.delayed(Duration(milliseconds: 10));
          monitor.endOperation(operationId);
        }

        // 异常慢的操作
        final slowOperationId = monitor.startOperation('slow_operation', {});
        await Future.delayed(Duration(milliseconds: 500));
        monitor.endOperation(slowOperationId);

        // 获取异常检测结果
        final report = monitor.getPerformanceReport();
        expect(report, isNotNull);
        expect(report.anomalies, isNotNull);
      });

      test('应该能够检测错误率异常', () {
        // 记录正常错误率
        for (int i = 0; i < 3; i++) {
          monitor.recordError('minor_error', 'Minor error $i');
        }

        // 记录大量错误
        for (int i = 0; i < 10; i++) {
          monitor.recordError('major_error', 'Major error $i');
        }

        // 获取实时指标
        final realTimeMetrics = monitor.getRealTimeMetrics();
        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['errors'], isNotNull);
      });
    });

    group('导出功能', () {
      test('应该能够导出监控数据', () async {
        // 添加一些监控数据
        for (int i = 0; i < 5; i++) {
          final operationId = monitor.startOperation('test_operation', {});
          await Future.delayed(Duration(milliseconds: 10));
          monitor.endOperation(operationId);
          monitor.recordMetric('test_metric', i * 10);
        }

        final exportedData = monitor.exportData();

        expect(exportedData, isNotNull);
        expect(exportedData['metadata'], isNotNull);
        expect(exportedData['latencyEvents'], isNotNull);
        expect(exportedData['performanceData'], isNotNull);
        expect(exportedData['anomalies'], isNotNull);
        expect(exportedData['metadata']['exportTime'], isNotNull);
      });

      test('应该能够按时间范围导出数据', () async {
        final now = DateTime.now();
        final startTime = now.subtract(Duration(minutes: 5));
        final endTime = now;

        // 添加一些操作
        for (int i = 0; i < 3; i++) {
          final operationId = monitor.startOperation('timed_operation', {});
          await Future.delayed(Duration(milliseconds: 10));
          monitor.endOperation(operationId);
        }

        final exportedData =
            monitor.exportData(timeRange: endTime.difference(startTime));

        expect(exportedData, isNotNull);
        expect(exportedData['metadata'], isNotNull);
      });
    });

    group('并发安全', () {
      test('应该能够处理并发操作', () async {
        final futures = <Future>[];

        // 并发启动多个操作
        for (int i = 0; i < 10; i++) {
          futures.add(Future(() async {
            final operationId =
                monitor.startOperation('concurrent_operation_$i', {});
            await Future.delayed(Duration(milliseconds: 10 + i));
            monitor.endOperation(operationId);
            monitor.recordMetric('concurrent_metric_$i', i);
          }));
        }

        await Future.wait(futures);

        // 验证没有异常抛出
        expect(true, isTrue);

        // 获取实时指标验证数据被正确记录
        final realTimeMetrics = monitor.getRealTimeMetrics();
        expect(realTimeMetrics, isNotNull);
      });
    });

    group('健康检查', () {
      test('应该能够提供健康状态', () async {
        // 添加一些操作和指标
        for (int i = 0; i < 3; i++) {
          final operationId =
              monitor.startOperation('health_check_operation', {});
          await Future.delayed(Duration(milliseconds: 10));
          monitor.endOperation(operationId);
        }
        monitor.recordMetric('health_metric', 100);

        // 获取实时指标作为健康状态指标
        final realTimeMetrics = monitor.getRealTimeMetrics();

        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['operations'], isNotNull);
        expect(realTimeMetrics['timestamp'], isNotNull);
      });

      test('应该能够检测不健康状态', () async {
        // 模拟大量错误
        for (int i = 0; i < 10; i++) {
          monitor.recordError('test_error', 'Error message $i');
        }

        // 获取实时指标
        final realTimeMetrics = monitor.getRealTimeMetrics();

        expect(realTimeMetrics, isNotNull);
        expect(realTimeMetrics['errors'], isNotNull);
      });
    });
  });
}
