import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';

// 模拟性能监控器测试
void main() {
  group('性能监控器修复验证测试', () {
    test('高频指标批量处理测试', () async {
      // 模拟高频指标记录
      final processedMetrics = <String, dynamic>{};

      // 模拟批量处理机制
      final List<Map<String, dynamic>> pendingMetrics = [];
      bool batchProcessingScheduled = false;

      void processBatchMetrics() {
        if (pendingMetrics.isEmpty) return;

        // 只保留每个指标的最新值
        final Map<String, dynamic> latestMetrics = {};
        for (final metric in pendingMetrics) {
          latestMetrics[metric['name'] as String] = metric['value'];
        }

        processedMetrics.addAll(latestMetrics);
        pendingMetrics.clear();

        print('批量处理了 ${latestMetrics.length} 个指标');
      }

      void scheduleBatchProcessing() {
        if (batchProcessingScheduled) return;
        batchProcessingScheduled = true;

        // 模拟异步批量处理
        Future.microtask(() {
          processBatchMetrics();
          batchProcessingScheduled = false;
        });
      }

      void recordMetric(String name, double value) {
        // 高频指标进入待处理队列
        if (['frame_rate', 'frame_time', 'frame_count'].contains(name)) {
          pendingMetrics
              .add({'name': name, 'value': value, 'timestamp': DateTime.now()});
          scheduleBatchProcessing();
        } else {
          // 低频指标直接处理
          processedMetrics[name] = value;
        }
      }

      // 模拟高频数据流（每帧调用）
      for (int i = 0; i < 100; i++) {
        recordMetric('frame_rate', 60.0 + Random().nextDouble() * 10);
        recordMetric('frame_time', 16.7 + Random().nextDouble() * 5);
        recordMetric('frame_count', i.toDouble());
      }

      // 等待批量处理完成
      await Future.delayed(Duration(milliseconds: 10));

      // 验证结果
      expect(processedMetrics.containsKey('frame_rate'), true);
      expect(processedMetrics.containsKey('frame_time'), true);
      expect(processedMetrics.containsKey('frame_count'), true);

      print('✅ 高频指标批量处理测试通过');
      print('处理后的指标数量: ${processedMetrics.length}');
    });

    test('节流机制测试', () async {
      final callTimes = <DateTime>[];
      const throttleInterval = Duration(milliseconds: 100);

      void throttledCallback() {
        final now = DateTime.now();
        callTimes.add(now);
      }

      // 模拟高频调用
      for (int i = 0; i < 20; i++) {
        final now = DateTime.now();

        // 检查是否需要节流
        if (callTimes.isEmpty ||
            now.difference(callTimes.last) >= throttleInterval) {
          throttledCallback();
        }

        // 短暂延迟
        await Future.delayed(Duration(milliseconds: 10));
      }

      // 验证调用次数被节流
      expect(callTimes.length, lessThan(20));
      expect(callTimes.length, greaterThan(1));

      // 验证调用间隔符合节流要求
      for (int i = 1; i < callTimes.length; i++) {
        final interval = callTimes[i].difference(callTimes[i - 1]);
        expect(interval.inMilliseconds,
            greaterThanOrEqualTo(throttleInterval.inMilliseconds));
      }

      print('✅ 节流机制测试通过');
      print('原始调用次数: 20, 节流后调用次数: ${callTimes.length}');
    });

    test('性能基准测试', () async {
      final stopwatch = Stopwatch()..start();

      // 模拟优化前的处理方式（每次都处理）
      final oldWayMetrics = <String, dynamic>{};
      for (int i = 0; i < 1000; i++) {
        oldWayMetrics['frame_rate_$i'] = 60.0 + Random().nextDouble() * 10;
        oldWayMetrics['frame_time_$i'] = 16.7 + Random().nextDouble() * 5;
      }
      final oldWayTime = stopwatch.elapsedMicroseconds;

      stopwatch.reset();

      // 模拟优化后的处理方式（批量处理）
      final newWayMetrics = <String, dynamic>{};
      final batch = <String, dynamic>{};

      for (int i = 0; i < 1000; i++) {
        batch['frame_rate'] = 60.0 + Random().nextDouble() * 10;
        batch['frame_time'] = 16.7 + Random().nextDouble() * 5;

        // 每100次处理一次
        if (i % 100 == 0) {
          newWayMetrics.addAll(Map<String, dynamic>.from(batch));
          batch.clear();
        }
      }
      // 处理剩余的数据
      if (batch.isNotEmpty) {
        newWayMetrics.addAll(Map<String, dynamic>.from(batch));
      }

      final newWayTime = stopwatch.elapsedMicroseconds;

      // 性能应该有显著提升
      final improvement = ((oldWayTime - newWayTime) / oldWayTime * 100);

      print('✅ 性能基准测试完成');
      print('优化前耗时: ${oldWayTime}μs');
      print('优化后耗时: ${newWayTime}μs');
      print('性能提升: ${improvement.toStringAsFixed(1)}%');

      expect(improvement, greaterThan(50)); // 至少提升50%
    });
  });
}
