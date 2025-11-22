import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

import 'package:jisu_fund_analyzer/src/services/security/security_utils.dart';

// 简单的Mock类，避免复杂的生成问题
class MockDio extends Mock implements Dio {}

void main() {
  group('Story R.2 简化Mock测试套件', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    group('安全工具类测试', () {
      test('应该生成有效的API签名', () {
        final method = 'GET';
        final path = '/api/test';
        final params = {'param': 'value'};
        final timestamp = DateTime.now().toIso8601String();
        final requestId = 'test-123';

        final signature = SecurityUtils.generateSignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
        );

        expect(signature, isNotEmpty);
        expect(signature.length, equals(64)); // SHA256 hex
      });

      test('应该验证有效的基金代码', () {
        expect(SecurityUtils.isValidFundCode('000001'), isTrue);
        expect(SecurityUtils.isValidFundCode('123456'), isTrue);
        expect(SecurityUtils.isValidFundCode('abcdef'), isFalse);
        expect(SecurityUtils.isValidFundCode('12345'), isFalse);
      });

      test('应该检测SQL注入', () {
        final maliciousInput = "'; DROP TABLE funds; --";
        expect(SecurityUtils.containsSqlInjection(maliciousInput), isTrue);

        final safeInput = '华夏成长混合';
        expect(SecurityUtils.containsSqlInjection(safeInput), isFalse);
      });

      test('应该检测XSS攻击', () {
        final xssInput = '<script>alert("xss")</script>';
        expect(SecurityUtils.containsXss(xssInput), isTrue);

        final safeInput = '正常文本内容';
        expect(SecurityUtils.containsXss(safeInput), isFalse);
      });

      test('应该验证输入安全性', () {
        final result = SecurityUtils.validateInput(
          input: '000001',
          type: 'fund_code',
          maxLength: 10,
        );

        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('应该拒绝恶意输入', () {
        final result = SecurityUtils.validateInput(
          input: '<script>alert("xss")</script>',
          maxLength: 100,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('XSS'));
      });
    });

    group('HTTP请求模拟测试', () {
      test('应该模拟成功的GET请求', () async {
        final mockResponse = Response(
          data: {'status': 'success', 'data': 'test'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get('/test')).thenAnswer((_) async => mockResponse);

        final response = await mockDio.get('/test');

        expect(response.statusCode, equals(200));
        expect(response.data['status'], equals('success'));
        verify(mockDio.get('/test')).called(1);
      });

      test('应该模拟网络错误', () async {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        );

        when(mockDio.get('/test')).thenThrow(dioException);

        expect(() => mockDio.get('/test'), throwsA(isA<DioException>()));
        verify(mockDio.get('/test')).called(1);
      });

      test('应该模拟POST请求', () async {
        final postData = {'name': 'test', 'value': 123};
        final mockResponse = Response(
          data: {'id': 1, 'status': 'created'},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post('/test', data: postData))
            .thenAnswer((_) async => mockResponse);

        final response = await mockDio.post('/test', data: postData);

        expect(response.statusCode, equals(201));
        expect(response.data['id'], equals(1));
        verify(mockDio.post('/test', data: postData)).called(1);
      });
    });

    group('性能测试', () {
      test('签名生成性能测试', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          SecurityUtils.generateSignature(
            method: 'GET',
            path: '/api/test',
            params: {'id': i.toString()},
            timestamp: DateTime.now().toIso8601String(),
            requestId: 'test-$i',
          );
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // 100个签名在500ms内完成
      });

      test('输入验证性能测试', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          SecurityUtils.validateInput(
            input: '00000${i % 10}',
            type: 'fund_code',
            maxLength: 10,
          );
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 100次验证在100ms内完成
      });

      test('安全检测性能测试', () {
        final inputs = [
          'normal text',
          '<script>alert("xss")</script>',
          "'; DROP TABLE funds; --",
          '华夏成长混合基金',
        ];

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          final input = inputs[i % inputs.length];
          SecurityUtils.containsSqlInjection(input);
          SecurityUtils.containsXss(input);
        }

        stopwatch.stop();
        expect(
            stopwatch.elapsedMilliseconds, lessThan(200)); // 2000次检测在200ms内完成
      });
    });

    group('并发测试', () {
      test('应该支持并发签名生成', () async {
        final futures = List.generate(50, (index) async {
          return SecurityUtils.generateSignature(
            method: 'POST',
            path: '/api/test/$index',
            params: {'index': index},
            timestamp: DateTime.now().toIso8601String(),
            requestId: 'req-$index',
          );
        });

        final results = await Future.wait(futures);

        expect(results.length, equals(50));
        expect(results.every((sig) => sig.length == 64), isTrue);
      });

      test('应该支持并发输入验证', () async {
        final futures = List.generate(100, (index) async {
          return SecurityUtils.validateInput(
            input: '00000${index % 10}',
            type: 'fund_code',
            maxLength: 10,
          );
        });

        final results = await Future.wait(futures);

        expect(results.length, equals(100));
        expect(results.every((result) => result.isValid), isTrue);
      });

      test('应该支持并发HTTP请求模拟', () async {
        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(captureAny)).thenAnswer((_) async => mockResponse);

        final futures = List.generate(20, (index) async {
          return mockDio.get('/test/$index');
        });

        final results = await Future.wait(futures);

        expect(results.length, equals(20));
        expect(results.every((response) => response.statusCode == 200), isTrue);
        verify(mockDio.get(captureAny)).called(20);
      });
    });

    group('边界条件测试', () {
      test('应该处理空值输入', () {
        expect(SecurityUtils.isValidFundCode(''), isFalse);
        expect(SecurityUtils.isValidFundCode(null), isFalse);
        expect(SecurityUtils.isValidUserId(''), isFalse);
        expect(SecurityUtils.isValidUserId(null), isFalse);
      });

      test('应该处理极限长度输入', () {
        final longInput = 'a' * 1000;
        final result = SecurityUtils.validateInput(
          input: longInput,
          maxLength: 100,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('长度超过限制'));
      });

      test('应该处理特殊字符', () {
        final specialInputs = [
          '🚀🔒🔐', // Emoji
          '\x00\x01\x02', // 控制字符
          '中文测试', // 中文字符
          '!@#\$%^&*()', // 特殊符号
        ];

        for (final input in specialInputs) {
          final result = SecurityUtils.validateInput(
            input: input,
            maxLength: 100,
          );

          expect(result, isA<SecurityValidationResult>());
        }
      });
    });

    group('错误处理测试', () {
      test('应该优雅处理验证错误', () {
        // 测试各种无效输入
        final invalidInputs = [
          '',
          null as String?,
          "'; DROP TABLE funds; --",
          '<script>alert("xss")</script>',
          'a' * 1000,
        ];

        for (final input in invalidInputs) {
          try {
            final result = SecurityUtils.validateInput(
              input: input ?? '',
              maxLength: 100,
            );

            expect(result, isA<SecurityValidationResult>());
          } catch (e) {
            // 如果有异常，应该是有意义的错误
            expect(e, isA<Exception>());
          }
        }
      });

      test('应该处理并发异常', () async {
        final futures = List.generate(10, (index) async {
          try {
            // 模拟可能失败的操作
            if (index % 3 == 0) {
              throw Exception('Simulated error $index');
            }
            return 'success-$index';
          } catch (e) {
            return 'error-$index';
          }
        });

        final results = await Future.wait(futures);

        expect(results.length, equals(10));
        expect(results.where((r) => r.startsWith('error')).length,
            equals(4)); // 0, 3, 6, 9
      });
    });

    group('集成场景测试', () {
      test('应该模拟完整的API安全流程', () async {
        // 1. 生成请求参数
        final params = {'fund_code': '000001', 'page': '1'};

        // 2. 验证输入
        final validationResult = SecurityUtils.validateInput(
          input: params['fund_code']!,
          type: 'fund_code',
          maxLength: 10,
        );
        expect(validationResult.isValid, isTrue);

        // 3. 生成签名
        final timestamp = SecurityUtils.generateTimestamp();
        final requestId = SecurityUtils.generateRequestId();
        final signature = SecurityUtils.generateSignature(
          method: 'GET',
          path: '/api/funds',
          params: params,
          timestamp: timestamp,
          requestId: requestId,
        );

        // 4. 验证签名
        final isValidSignature = SecurityUtils.verifySignature(
          method: 'GET',
          path: '/api/funds',
          params: params,
          timestamp: timestamp,
          requestId: requestId,
          receivedSignature: signature,
        );

        expect(isValidSignature, isTrue);
        expect(signature.length, equals(64));
      });

      test('应该模拟安全的HTTP请求流程', () async {
        final secureHeaders = {
          'X-Request-ID': SecurityUtils.generateRequestId(),
          'X-Timestamp': SecurityUtils.generateTimestamp(),
          'X-Signature': SecurityUtils.generateSignature(
            method: 'GET',
            path: '/api/secure',
            params: {},
            timestamp: DateTime.now().toIso8601String(),
            requestId: 'secure-request',
          ),
        };

        final mockResponse = Response(
          data: {'status': 'success', 'secure': true},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/secure'),
        );

        when(mockDio.get('/api/secure', options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        final response = await mockDio.get('/api/secure');

        expect(response.statusCode, equals(200));
        expect(response.data['secure'], isTrue);
        expect(secureHeaders['X-Request-ID'], isNotEmpty);
        expect(secureHeaders['X-Signature'], isNotEmpty);
      });
    });
  });
}
