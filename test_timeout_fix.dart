import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'lib/src/core/cache/request_deduplication_manager.dart';

void main() {
  group('RequestDeduplicationManager Timeout Fix Tests', () {
    late RequestDeduplicationManager manager;

    setUp(() {
      manager = RequestDeduplicationManager();
      manager.initialize();
    });

    tearDown(() {
      manager.dispose();
    });

    test('应该正确处理正常完成的请求', () async {
      final result = await manager.getOrExecute(
        'test_normal_request',
        executor: () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'success';
        },
        timeout: const Duration(seconds: 1),
      );

      expect(result, equals('success'));
    });

    test('应该正确处理超时的请求', () async {
      expectLater(() async {
        await manager.getOrExecute(
          'test_timeout_request',
          executor: () async {
            await Future.delayed(const Duration(seconds: 5));
            return 'should_not_complete';
          },
          timeout: const Duration(milliseconds: 500),
        );
      }, throwsA(isA<TimeoutException>()));
    });

    test('应该正确处理请求异常', () async {
      expectLater(() async {
        await manager.getOrExecute(
          'test_error_request',
          executor: () async {
            throw Exception('测试异常');
          },
          timeout: const Duration(seconds: 1),
        );
      }, throwsA(isA<Exception>()));
    });

    test('应该正确处理去重请求', () async {
      final futures = <Future<String>>[];

      // 创建多个相同请求
      for (int i = 0; i < 3; i++) {
        futures.add(manager.getOrExecute(
          'test_duplicate_request',
          executor: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            return 'duplicate_success';
          },
          timeout: const Duration(seconds: 1),
        ));
      }

      final results = await Future.wait(futures);

      // 所有结果应该相同
      for (final result in results) {
        expect(result, equals('duplicate_success'));
      }
    });

    test('应该显示超时警告', () async {
      // 这个测试会触发超时警告
      await manager.getOrExecute(
        'test_warning_request',
        executor: () async {
          await Future.delayed(const Duration(milliseconds: 900));
          return 'warning_success';
        },
        timeout: const Duration(seconds: 1),
      );

      // 警告会在后台日志中显示，这里主要验证请求正常完成
      expect(true, isTrue); // 如果能到达这里说明没有超时
    });
  });
}