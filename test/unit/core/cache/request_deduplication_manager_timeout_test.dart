import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'dart:io';
import 'package:jisu_fund_analyzer/src/core/cache/request_deduplication_manager.dart';

void main() {
  group('RequestDeduplicationManager 超时处理测试', () {
    late RequestDeduplicationManager manager;

    setUp(() {
      manager = RequestDeduplicationManager();
    });

    tearDown(() async {
      await manager.cancelAllRequests();
    });

    test('应该正确处理 TimeoutException 并提供详细错误信息', () async {
      final requestKey = 'fund_test_timeout_request';

      try {
        await manager.executeRequest<String>(
          requestKey: requestKey,
          executor: () async {
            // 模拟一个长时间运行的任务
            await Future.delayed(Duration(seconds: 10));
            return '完成';
          },
          timeout: Duration(seconds: 2), // 设置较短超时时间
        );
        fail('应该抛出 TimeoutException');
      } catch (e) {
        expect(e, isA<TimeoutException>());
        final timeoutException = e as TimeoutException;

        // 验证错误信息包含有用的上下文
        expect(timeoutException.message, contains(requestKey));
        expect(timeoutException.message, contains('设定超时'));
        expect(timeoutException.message, contains('建议'));

        print('✅ 超时异常测试通过: ${timeoutException.message}');
      }
    });

    test('应该对数据密集型请求使用更长的超时时间', () async {
      final rankingRequestKey = 'fund_all_ranking_data';
      final normalRequestKey = 'simple_fund_request';

      // 记录开始时间
      final startTime = DateTime.now();

      try {
        await manager.executeRequest<String>(
          requestKey: rankingRequestKey,
          executor: () async {
            await Future.delayed(Duration(seconds: 8)); // 超过默认5秒，但在数据密集型20秒内
            return '排行数据';
          },
        );

        final duration = DateTime.now().difference(startTime);

        // 如果使用了延长超时，请求应该成功完成
        expect(duration.inSeconds, greaterThanOrEqualTo(8));
        print('✅ 数据密集型请求延长超时测试通过，耗时: ${duration.inSeconds}秒');
      } catch (e) {
        fail('数据密集型请求应该成功完成: $e');
      }
    });

    test('应该正确处理网络错误', () async {
      final requestKey = 'fund_network_error_test';

      try {
        await manager.executeRequest<String>(
          requestKey: requestKey,
          executor: () async {
            // 模拟网络错误
            throw SocketException('Connection refused');
          },
        );
        fail('应该抛出 SocketException');
      } catch (e) {
        expect(e, isA<SocketException>());
        final socketException = e as SocketException;

        // 验证错误信息包含有用的上下文
        expect(socketException.message, contains(requestKey));
        expect(socketException.message, contains('网络连接错误'));
        expect(socketException.message, contains('建议'));

        print('✅ 网络错误处理测试通过: ${socketException.message}');
      }
    });

    test('应该正确处理 HTTP 错误', () async {
      final requestKey = 'fund_http_error_test';

      try {
        await manager.executeRequest<String>(
          requestKey: requestKey,
          executor: () async {
            // 模拟 HTTP 错误
            throw HttpException('404 Not Found',
                uri: Uri.parse('http://test.com'));
          },
        );
        fail('应该抛出 HttpException');
      } catch (e) {
        expect(e, isA<HttpException>());
        final httpException = e as HttpException;

        // 验证错误信息包含有用的上下文
        expect(httpException.message, contains(requestKey));
        expect(httpException.message, contains('HTTP请求错误'));
        expect(httpException.message, contains('建议'));

        print('✅ HTTP错误处理测试通过: ${httpException.message}');
      }
    });

    test('应该正确处理一般错误', () async {
      final requestKey = 'fund_general_error_test';
      final originalError = '数据解析失败';

      try {
        await manager.executeRequest<String>(
          requestKey: requestKey,
          executor: () async {
            throw Exception(originalError);
          },
        );
        fail('应该抛出 Exception');
      } catch (e) {
        expect(e, isA<Exception>());
        final exception = e as Exception;

        // 验证错误信息包含有用的上下文
        expect(exception.toString(), contains(requestKey));
        expect(exception.toString(), contains('请求执行失败'));
        expect(exception.toString(), contains(originalError));

        print('✅ 一般错误处理测试通过: ${exception.toString()}');
      }
    });

    test('应该正确处理请求去重', () async {
      final requestKey = 'fund_duplicate_request';
      final startTime = DateTime.now();

      // 启动两个相同的请求
      final future1 = manager.executeRequest<String>(
        requestKey: requestKey,
        executor: () async {
          await Future.delayed(Duration(seconds: 2));
          return '结果1';
        },
      );

      final future2 = manager.executeRequest<String>(
        requestKey: requestKey,
        executor: () async {
          await Future.delayed(Duration(seconds: 2));
          return '结果2';
        },
      );

      // 等待两个请求完成
      final results = await Future.wait([future1, future2]);

      final duration = DateTime.now().difference(startTime);

      // 由于去重，两个请求应该几乎同时完成（大约2秒，而不是4秒）
      expect(duration.inSeconds, lessThanOrEqualTo(3));
      expect(results[0], equals(results[1])); // 结果应该相同

      print('✅ 请求去重测试通过，耗时: ${duration.inSeconds}秒');
    });
  });
}
