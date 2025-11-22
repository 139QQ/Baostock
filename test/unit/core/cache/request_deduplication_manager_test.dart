import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/request_deduplication_manager.dart';

void main() {
  group('RequestDeduplicationManager Timeout Tests', () {
    late RequestDeduplicationManager manager;

    setUp(() {
      manager = RequestDeduplicationManager();
      manager.initialize();
    });

    tearDown(() {
      manager.dispose();
    });

    test('应该在合理时间内完成正常请求', () async {
      final result = await manager.getOrExecute<String>(
        'fast_request',
        executor: () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'success';
        },
        timeout: const Duration(seconds: 5),
      );

      expect(result, equals('success'));

      final stats = manager.getStats();
      expect(stats.totalRequests, equals(1));
      expect(stats.successfulRequests, equals(1));
      expect(stats.timeoutRequests, equals(0));
    });

    test('应该正确处理超时异常', () async {
      try {
        await manager.getOrExecute<String>(
          'slow_request',
          executor: () async {
            await Future.delayed(const Duration(seconds: 15));
            return 'success';
          },
          timeout: const Duration(seconds: 2),
        );
        fail('应该抛出TimeoutException');
      } catch (e) {
        expect(e, isA<TimeoutException>());
      }

      final stats = manager.getStats();
      expect(stats.totalRequests, equals(1));
      expect(stats.failedRequests, equals(1)); // 超时请求也算失败请求
      expect(stats.timeoutRequests, equals(1));
      expect(stats.timeoutRate, equals(1.0));
    });

    test('应该正确处理请求去重超时', () async {
      // 启动第一个慢请求
      final future1 = manager.getOrExecute<String>(
        'duplicate_request',
        executor: () async {
          await Future.delayed(const Duration(seconds: 15));
          return 'first';
        },
        timeout: const Duration(seconds: 20),
      );

      // 启动第二个请求，应该等待第一个请求但超时
      try {
        await manager.getOrExecute<String>(
          'duplicate_request',
          executor: () async {
            return 'second';
          },
          timeout: const Duration(seconds: 2),
        );
        fail('应该抛出TimeoutException');
      } catch (e) {
        expect(e, isA<TimeoutException>());
      }

      // 第二个请求应该被移除，第三个请求应该正常执行
      final result3 = await manager.getOrExecute<String>(
        'duplicate_request',
        executor: () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'third';
        },
        timeout: const Duration(seconds: 5),
      );

      expect(result3, equals('third'));
    });

    test('应该记录超时统计信息', () async {
      // 执行几个不同结果的请求
      await manager.getOrExecute<String>(
        'success_request',
        executor: () async => 'success',
        timeout: const Duration(seconds: 5),
      );

      try {
        await manager.getOrExecute<String>(
          'timeout_request',
          executor: () async {
            await Future.delayed(const Duration(seconds: 15));
            return 'success';
          },
          timeout: const Duration(seconds: 2),
        );
      } catch (e) {
        // 忽略预期的超时异常
      }

      final stats = manager.getStats();
      expect(stats.totalRequests, equals(2));
      expect(stats.successfulRequests, equals(1));
      expect(stats.failedRequests, equals(1)); // 超时请求也算失败请求
      expect(stats.timeoutRequests, equals(1));
      expect(stats.timeoutRate, equals(0.5));

      // 验证toString包含超时信息
      final statsString = stats.toString();
      expect(statsString, contains('timeout: 1'));
      expect(statsString, contains('timeoutRate: 50.0%'));
    });

    test('应该使用正确的默认超时时间', () async {
      final startTime = DateTime.now();

      try {
        await manager.getOrExecute<String>('default_timeout_test',
            executor: () async {
          await Future.delayed(const Duration(seconds: 20));
          return 'success';
        });
        fail('应该抛出TimeoutException');
      } catch (e) {
        expect(e, isA<TimeoutException>());
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // 应该在大约10秒超时（允许一些误差）
      expect(duration.inSeconds, lessThanOrEqualTo(12));
      expect(duration.inSeconds, greaterThanOrEqualTo(8));
    });
  });
}
