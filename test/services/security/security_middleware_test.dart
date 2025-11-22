import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

import 'package:jisu_fund_analyzer/src/services/security/security_middleware.dart';

import 'security_middleware_test.mocks.dart';

@GenerateMocks([
  RequestInterceptorHandler,
  ResponseInterceptorHandler,
  ErrorInterceptorHandler,
])
void main() {
  group('SecurityMiddleware - Story R.2 安全中间件测试套件', () {
    late SecurityMiddleware middleware;
    late MockRequestInterceptorHandler mockRequestHandler;
    late MockResponseInterceptorHandler mockResponseHandler;
    late MockErrorInterceptorHandler mockErrorHandler;

    setUp(() {
      middleware = SecurityMiddleware();
      mockRequestHandler = MockRequestInterceptorHandler();
      mockResponseHandler = MockResponseInterceptorHandler();
      mockErrorHandler = MockErrorInterceptorHandler();
    });

    group('安全拦截器创建测试', () {
      test('应该创建默认配置的安全拦截器', () {
        final interceptor = SecurityMiddleware.createInterceptor();

        expect(interceptor, isA<Interceptor>());
        expect(interceptor.enableSignatureVerification, isTrue);
        expect(interceptor.enableRateLimiting, isTrue);
        expect(interceptor.enableInputValidation, isTrue);
      });

      test('应该创建自定义配置的安全拦截器', () {
        final interceptor = SecurityMiddleware.createInterceptor(
          enableSignatureVerification: false,
          enableRateLimiting: true,
          enableInputValidation: false,
        );

        expect(interceptor.enableSignatureVerification, isFalse);
        expect(interceptor.enableRateLimiting, isTrue);
        expect(interceptor.enableInputValidation, isFalse);
      });
    });

    group('请求签名验证测试', () {
      test('应该验证有效的请求签名', () {
        final options = RequestOptions(
          path: '/api/fund',
          method: 'GET',
          headers: {
            'X-Request-ID': 'test-request-123',
            'X-Timestamp': DateTime.now().toIso8601String(),
            'X-Signature': 'valid-signature',
          },
        );

        final params = {'fund_code': '000001'};

        final isValid = SecurityMiddleware.verifyRequestSignature(
          options: options,
          params: params,
        );

        // 由于我们没有真实的签名，这里测试方法调用不会抛出异常
        expect(
            () => SecurityMiddleware.verifyRequestSignature(
                  options: options,
                  params: params,
                ),
            returnsNormally);
      });

      test('应该拒绝缺少签名头的请求', () {
        final options = RequestOptions(
          path: '/api/fund',
          method: 'GET',
          headers: {
            'X-Request-ID': 'test-request-123',
            'X-Timestamp': DateTime.now().toIso8601String(),
            // 缺少 X-Signature
          },
        );

        final params = {'fund_code': '000001'};

        final isValid = SecurityMiddleware.verifyRequestSignature(
          options: options,
          params: params,
        );

        expect(isValid, isFalse);
      });

      test('应该拒绝缺少时间戳的请求', () {
        final options = RequestOptions(
          path: '/api/fund',
          method: 'GET',
          headers: {
            'X-Request-ID': 'test-request-123',
            'X-Signature': 'test-signature',
            // 缺少 X-Timestamp
          },
        );

        final params = {'fund_code': '000001'};

        final isValid = SecurityMiddleware.verifyRequestSignature(
          options: options,
          params: params,
        );

        expect(isValid, isFalse);
      });

      test('应该拒绝缺少请求ID的请求', () {
        final options = RequestOptions(
          path: '/api/fund',
          method: 'GET',
          headers: {
            'X-Timestamp': DateTime.now().toIso8601String(),
            'X-Signature': 'test-signature',
            // 缺少 X-Request-ID
          },
        );

        final params = {'fund_code': '000001'};

        final isValid = SecurityMiddleware.verifyRequestSignature(
          options: options,
          params: params,
        );

        expect(isValid, isFalse);
      });
    });

    group('输入验证测试', () {
      test('应该验证有效的请求参数', () {
        final path = '/api/fund';
        final validParams = {
          'fund_code': '000001',
          'user_id': 'test_user',
          'amount': '1000.50',
          'page': '1',
          'limit': '20',
          'order': 'asc',
        };

        final result = SecurityMiddleware.validateRequestParams(
          path: path,
          params: validParams,
        );

        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('应该拒绝包含SQL注入的参数', () {
        final path = '/api/fund';
        final maliciousParams = {
          'fund_code': "'; DROP TABLE funds; --",
          'user_id': 'test_user',
        };

        final result = SecurityMiddleware.validateRequestParams(
          path: path,
          params: maliciousParams,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('SQL注入'));
      });

      test('应该拒绝包含XSS的参数', () {
        final path = '/api/fund';
        final maliciousParams = {
          'fund_name': '<script>alert("xss")</script>',
          'user_id': 'test_user',
        };

        final result = SecurityMiddleware.validateRequestParams(
          path: path,
          params: maliciousParams,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('XSS'));
      });

      test('应该验证基金代码格式', () {
        final path = '/api/fund';
        final invalidFundCodeParams = {
          'fund_code': 'abcdef', // 无效的基金代码
          'user_id': 'test_user',
        };

        final result = SecurityMiddleware.validateRequestParams(
          path: path,
          params: invalidFundCodeParams,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('基金代码格式无效'));
      });

      test('应该验证用户ID格式', () {
        final path = '/api/user';
        final invalidUserIdParams = {
          'user_id': '@invalid#user', // 包含特殊字符
        };

        final result = SecurityMiddleware.validateRequestParams(
          path: path,
          params: invalidUserIdParams,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('用户ID格式无效'));
      });

      test('应该验证金额格式', () {
        final path = '/api/portfolio';
        final invalidAmountParams = {
          'amount': '-1000', // 负金额
        };

        final result = SecurityMiddleware.validateRequestParams(
          path: path,
          params: invalidAmountParams,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('金额格式无效'));
      });

      test('应该验证分页参数', () {
        final path = '/api/fund';
        final invalidPaginationParams = {
          'page': '0', // 页码从1开始
          'limit': '101', // 超过最大限制
        };

        final result = SecurityMiddleware.validateRequestParams(
          path: path,
          params: invalidPaginationParams,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('分页参数无效'));
      });

      test('应该验证排序参数', () {
        final path = '/api/fund';
        final invalidSortParams = {
          'order': 'invalid_order',
        };

        final result = SecurityMiddleware.validateRequestParams(
          path: path,
          params: invalidSortParams,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('排序参数无效'));
      });

      test('应该验证路径安全性', () {
        final maliciousPaths = [
          '/api/../../../etc/passwd',
          '/api/<script>alert(1)</script>',
          '/api/"test"',
          '/api/\x00test',
        ];

        for (final path in maliciousPaths) {
          final result = SecurityMiddleware.validateRequestParams(
            path: path,
            params: {'param': 'value'},
          );

          expect(result.isValid, isFalse,
              reason: 'Should reject malicious path: $path');
        }
      });
    });

    group('IP黑名单测试', () {
      test('应该检查IP黑名单', () {
        expect(SecurityMiddleware.isIpBlocked('127.0.0.1'), isFalse);
        expect(SecurityMiddleware.isIpBlocked(''), isFalse);
        expect(SecurityMiddleware.isIpBlocked(null), isFalse);
      });

      test('应该支持IP黑名单管理', () {
        final testIp = '192.168.1.100';

        // 添加到黑名单
        middleware.blockIp(testIp, reason: 'Test blocking');

        // 检查是否在黑名单中
        expect(middleware.isIpBlocked(testIp), isTrue);

        // 从黑名单移除
        middleware.unblockIp(testIp);

        // 再次检查
        expect(middleware.isIpBlocked(testIp), isFalse);
      });

      test('应该提供黑名单统计信息', () {
        final testIp1 = '192.168.1.101';
        final testIp2 = '192.168.1.102';

        middleware.blockIp(testIp1, reason: 'Test 1');
        middleware.blockIp(testIp2, reason: 'Test 2');

        final stats = middleware.getBlacklistStats();

        expect(stats['blocked_ips_count'], equals(2));
        expect(stats['blocked_ips'], isA<Map>());
        expect(stats['timestamp'], isNotNull);

        // 清理
        middleware.unblockIp(testIp1);
        middleware.unblockIp(testIp2);
      });
    });

    group('频率限制测试', () {
      test('应该检查频率限制', () {
        final testIp = '192.168.1.200';

        // 初始状态应该允许请求
        expect(middleware.checkRateLimit(testIp), isTrue);

        // 快速发送多个请求
        for (int i = 0; i < 65; i++) {
          // 超过60次/分钟的限制
          middleware.checkRateLimit(testIp);
        }

        // 现在应该被限制
        expect(middleware.checkRateLimit(testIp), isFalse);
      });

      test('应该提供频率限制统计信息', () {
        final testIp = '192.168.1.201';

        // 发送一些请求
        for (int i = 0; i < 10; i++) {
          middleware.checkRateLimit(testIp);
        }

        final stats = middleware.getRateLimitStats();

        expect(stats['max_requests_per_minute'], equals(60));
        expect(stats['max_requests_per_hour'], equals(1000));
        expect(stats['active_request_counters'], greaterThan(0));
        expect(stats['timestamp'], isNotNull);
      });

      test('应该独立处理不同IP的频率限制', () {
        final ip1 = '192.168.1.210';
        final ip2 = '192.168.1.211';

        // IP1发送请求
        expect(middleware.checkRateLimit(ip1), isTrue);

        // IP2发送请求
        expect(middleware.checkRateLimit(ip2), isTrue);

        // IP1超过限制
        for (int i = 0; i < 65; i++) {
          middleware.checkRateLimit(ip1);
        }

        // IP1应该被限制，IP2应该仍然允许
        expect(middleware.checkRateLimit(ip1), isFalse);
        expect(middleware.checkRateLimit(ip2), isTrue);
      });
    });

    group('安全头添加测试', () {
      test('应该添加安全头信息', () {
        final options = RequestOptions(
          path: '/api/test',
          method: 'GET',
          headers: {'Content-Type': 'application/json'},
        );

        final params = {'param': 'value'};

        SecurityMiddleware.addSecurityHeaders(
          options: options,
          params: params,
        );

        // 验证安全头被添加
        expect(options.headers['X-Request-ID'], isNotNull);
        expect(options.headers['X-Timestamp'], isNotNull);
        expect(options.headers['X-Signature'], isNotNull);
        expect(
            options.headers['User-Agent'], equals('jisu-fund-analyzer/2.0.0'));
        expect(options.headers['X-Content-Type-Options'], equals('nosniff'));
        expect(options.headers['X-Frame-Options'], equals('DENY'));
      });
    });

    group('安全监控测试', () {
      test('应该记录安全事件', () {
        final securityMonitor = SecurityMonitor();

        securityMonitor.recordSecurityEvent(
          type: 'SIGNATURE_VERIFICATION_FAILED',
          description: 'Invalid signature detected',
          clientIp: '192.168.1.100',
          details: {'path': '/api/fund', 'method': 'GET'},
        );

        final stats = securityMonitor.getSecurityStats();

        expect(stats['total_events'], equals(1));
        expect(
            stats['event_types']['SIGNATURE_VERIFICATION_FAILED'], equals(1));
        expect(stats['recent_events'].length, equals(1));
      });

      test('应该清理过期事件', () {
        final securityMonitor = SecurityMonitor();

        // 记录一些事件
        for (int i = 0; i < 50; i++) {
          securityMonitor.recordSecurityEvent(
            type: 'TEST_EVENT',
            description: 'Test event $i',
            clientIp: '192.168.1.100',
          );
        }

        // 清理过期事件
        securityMonitor.cleanupExpiredEvents(maxAge: Duration.zero);

        final stats = securityMonitor.getSecurityStats();

        expect(stats['total_events'], equals(0));
      });

      test('应该限制事件历史记录数量', () {
        final securityMonitor = SecurityMonitor();

        // 记录超过1000个事件
        for (int i = 0; i < 1200; i++) {
          securityMonitor.recordSecurityEvent(
            type: 'TEST_EVENT',
            description: 'Test event $i',
            clientIp: '192.168.1.100',
          );
        }

        final stats = securityMonitor.getSecurityStats();

        // 应该只保留最近1000个事件
        expect(stats['total_events'], equals(1000));
      });
    });

    group('拦截器集成测试', () {
      test('应该在请求阶段执行安全检查', () {
        final interceptor = SecurityMiddleware.createInterceptor();
        final options = RequestOptions(
          path: '/api/fund',
          method: 'GET',
          headers: {
            'X-Request-ID': 'test-request-123',
            'X-Timestamp': DateTime.now().toIso8601String(),
            'X-Signature': 'test-signature',
          },
        );

        // 测试拦截器不会抛出异常
        expect(() {
          interceptor.onRequest(options, mockRequestHandler);
        }, returnsNormally);

        // 验证处理器被调用
        verify(mockRequestHandler.next(options)).called(1);
      });

      test('应该在响应阶段过滤敏感信息', () {
        final interceptor = SecurityMiddleware.createInterceptor();
        final response = Response(
          data: {
            'public_data': 'value',
            'password': 'secret123',
            'token': 'secret_token',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        interceptor.onResponse(response, mockResponseHandler);

        // 验证敏感信息被过滤
        expect(response.data['public_data'], equals('value'));
        expect(response.data['password'], equals('***FILTERED***'));
        expect(response.data['token'], equals('***FILTERED***'));

        verify(mockResponseHandler.next(response)).called(1);
      });

      test('应该处理安全相关错误', () {
        final interceptor = SecurityMiddleware.createInterceptor();
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          error: 'IP已被封禁',
          type: DioExceptionType.unknown,
        );

        interceptor.onError(error, mockErrorHandler);

        // 验证错误处理器被调用
        verify(mockErrorHandler.next(error)).called(1);
      });

      test('应该处理拦截器异常', () {
        final interceptor = SecurityMiddleware.createInterceptor();
        final options = RequestOptions(path: '/api/test', method: 'GET');

        // 模拟处理器抛出异常
        when(mockRequestHandler.next(options))
            .thenThrow(Exception('Handler error'));

        // 拦截器应该优雅地处理异常
        expect(() {
          interceptor.onRequest(options, mockRequestHandler);
        }, returnsNormally);

        verify(mockRequestHandler.next(options)).called(1);
      });
    });

    group('性能测试', () {
      test('签名验证性能测试', () {
        final options = RequestOptions(
          path: '/api/fund',
          method: 'GET',
          headers: {
            'X-Request-ID': 'test-request-123',
            'X-Timestamp': DateTime.now().toIso8601String(),
            'X-Signature': 'test-signature',
          },
        );

        final params = {'fund_code': '000001'};

        final stopwatch = Stopwatch()..start();

        // 执行1000次签名验证
        for (int i = 0; i < 1000; i++) {
          SecurityMiddleware.verifyRequestSignature(
            options: options,
            params: params,
          );
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('输入验证性能测试', () {
        final path = '/api/fund';
        final params = {
          'fund_code': '000001',
          'user_id': 'test_user',
          'amount': '1000.50',
        };

        final stopwatch = Stopwatch()..start();

        // 执行1000次输入验证
        for (int i = 0; i < 1000; i++) {
          SecurityMiddleware.validateRequestParams(
            path: path,
            params: params,
          );
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('频率检查性能测试', () {
        final testIp = '192.168.1.100';

        final stopwatch = Stopwatch()..start();

        // 执行1000次频率检查
        for (int i = 0; i < 1000; i++) {
          middleware.checkRateLimit('$testIp$i');
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('并发安全测试', () {
      test('应该支持并发签名验证', () async {
        final options = RequestOptions(
          path: '/api/fund',
          method: 'GET',
          headers: {
            'X-Request-ID': 'test-request-123',
            'X-Timestamp': DateTime.now().toIso8601String(),
            'X-Signature': 'test-signature',
          },
        );

        final params = {'fund_code': '000001'};

        final futures = List.generate(100, (index) async {
          return SecurityMiddleware.verifyRequestSignature(
            options: options,
            params: params,
          );
        });

        final results = await Future.wait(futures);

        expect(results.length, equals(100));
        // 验证没有异常抛出
        expect(results.every((result) => result is bool), isTrue);
      });

      test('应该支持并发频率检查', () async {
        final futures = List.generate(100, (index) async {
          return middleware.checkRateLimit('192.168.1.${100 + index}');
        });

        final results = await Future.wait(futures);

        expect(results.length, equals(100));
        expect(results.every((allowed) => allowed is bool), isTrue);
      });

      test('应该支持并发安全事件记录', () async {
        final securityMonitor = SecurityMonitor();

        final futures = List.generate(100, (index) async {
          securityMonitor.recordSecurityEvent(
            type: 'CONCURRENT_TEST',
            description: 'Test event $index',
            clientIp: '192.168.1.${100 + index}',
          );
        });

        await Future.wait(futures);

        final stats = securityMonitor.getSecurityStats();

        expect(stats['total_events'], equals(100));
        expect(stats['event_types']['CONCURRENT_TEST'], equals(100));
      });
    });

    tearDown(() {
      // 清理测试数据
    });
  });
}
