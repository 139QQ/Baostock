import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

import 'package:jisu_fund_analyzer/src/services/unified_api_service.dart';
import 'package:jisu_fund_analyzer/src/services/security/security_middleware.dart';
import 'package:jisu_fund_analyzer/src/services/security/security_utils.dart';

import 'unified_api_service_test.mocks.dart';

@GenerateMocks([
  Dio,
  SecurityMiddleware,
])
void main() {
  group('UnifiedApiService - Story R.2 测试套件', () {
    late UnifiedApiService service;
    late MockDio mockDio;
    late MockSecurityMiddleware mockSecurityMiddleware;

    setUp(() {
      mockDio = MockDio();
      mockSecurityMiddleware = MockSecurityMiddleware();

      service = UnifiedApiService();
    });

    group('API请求基础功能测试', () {
      test('应该正确初始化API服务', () {
        expect(service, isNotNull);
        expect(service.baseUrl, equals('http://154.44.25.92:8080'));
      });

      test('应该正确设置请求头', () {
        final headers = service.getDefaultHeaders();

        expect(headers['Accept'], equals('application/json'));
        expect(headers['Content-Type'], equals('application/json'));
        expect(headers['User-Agent'], equals('jisu-fund-analyzer/2.0.0'));
      });

      test('应该正确配置超时设置', () {
        expect(service.connectTimeout, equals(const Duration(seconds: 30)));
        expect(service.receiveTimeout, equals(const Duration(seconds: 120)));
        expect(service.sendTimeout, equals(const Duration(seconds: 30)));
      });
    });

    group('GET请求测试', () {
      test('应该成功执行GET请求', () async {
        final mockResponse = Response(
          data: {'status': 'success', 'data': 'test'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => mockResponse);

        final result = await service.get('/test');

        expect(result.statusCode, equals(200));
        expect(result.data['status'], equals('success'));
        verify(mockDio.get('/test',
                queryParameters: anyNamed('queryParameters')))
            .called(1);
      });

      test('应该正确处理查询参数', () async {
        final queryParams = {'page': 1, 'limit': 20};
        final mockResponse = Response(
          data: {'data': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => mockResponse);

        await service.get('/test', queryParameters: queryParams);

        verify(mockDio.get('/test', queryParameters: queryParams)).called(1);
      });

      test('应该处理GET请求错误', () async {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenThrow(dioException);

        expect(() => service.get('/test'), throwsA(isA<DioException>()));
      });
    });

    group('POST请求测试', () {
      test('应该成功执行POST请求', () async {
        final postData = {'name': 'test', 'value': 123};
        final mockResponse = Response(
          data: {'status': 'success', 'id': 1},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        final result = await service.post('/test', data: postData);

        expect(result.statusCode, equals(201));
        expect(result.data['id'], equals(1));
        verify(mockDio.post('/test', data: postData)).called(1);
      });

      test('应该正确处理JSON数据', () async {
        final jsonData = {
          'complex': {'nested': 'data'},
          'array': [1, 2, 3]
        };
        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        await service.post('/test', data: jsonData);

        verify(mockDio.post('/test', data: jsonData)).called(1);
      });

      test('应该处理POST请求错误', () async {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/test'),
            data: {'error': 'Bad request'},
          ),
        );

        when(mockDio.post(any, data: anyNamed('data'))).thenThrow(dioException);

        expect(() => service.post('/test', data: {}),
            throwsA(isA<DioException>()));
      });
    });

    group('PUT请求测试', () {
      test('应该成功执行PUT请求', () async {
        final putData = {'name': 'updated'};
        final mockResponse = Response(
          data: {'status': 'updated'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test/1'),
        );

        when(mockDio.put(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        final result = await service.put('/test/1', data: putData);

        expect(result.statusCode, equals(200));
        expect(result.data['status'], equals('updated'));
        verify(mockDio.put('/test/1', data: putData)).called(1);
      });
    });

    group('DELETE请求测试', () {
      test('应该成功执行DELETE请求', () async {
        final mockResponse = Response(
          data: {'status': 'deleted'},
          statusCode: 204,
          requestOptions: RequestOptions(path: '/test/1'),
        );

        when(mockDio.delete(any)).thenAnswer((_) async => mockResponse);

        final result = await service.delete('/test/1');

        expect(result.statusCode, equals(204));
        verify(mockDio.delete('/test/1')).called(1);
      });
    });

    group('错误处理测试', () {
      test('应该正确处理网络错误', () async {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Network error',
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenThrow(dioException);

        expect(() => service.get('/test'), throwsA(isA<DioException>()));
      });

      test('应该正确处理服务器错误', () async {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/test'),
            data: {'error': 'Internal server error'},
          ),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenThrow(dioException);

        expect(() => service.get('/test'), throwsA(isA<DioException>()));
      });

      test('应该正确处理超时错误', () async {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
          message: 'Receive timeout',
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenThrow(dioException);

        expect(() => service.get('/test'), throwsA(isA<DioException>()));
      });
    });

    group('安全功能测试', () {
      test('应该添加安全头信息', () {
        final secureHeaders = service.getSecureHeaders();

        expect(secureHeaders['X-Content-Type-Options'], equals('nosniff'));
        expect(secureHeaders['X-Frame-Options'], equals('DENY'));
        expect(secureHeaders['X-XSS-Protection'], equals('1; mode=block'));
        expect(secureHeaders['Strict-Transport-Security'],
            contains('max-age=31536000'));
      });

      test('应该生成API签名', () {
        final method = 'GET';
        final path = '/api/test';
        final params = {'param1': 'value1'};
        final timestamp = DateTime.now().toIso8601String();
        final requestId = 'test-request-id';

        final signature = service.generateApiSignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
        );

        expect(signature, isNotNull);
        expect(signature.length, greaterThan(0));
        expect(signature, isA<String>());
      });

      test('应该验证API签名', () {
        final method = 'GET';
        final path = '/api/test';
        final params = {'param1': 'value1'};
        final timestamp = DateTime.now().toIso8601String();
        final requestId = 'test-request-id';

        final signature = service.generateApiSignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
        );

        final isValid = service.verifyApiSignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
          signature: signature,
        );

        expect(isValid, isTrue);
      });

      test('应该拒绝无效签名', () {
        final method = 'GET';
        final path = '/api/test';
        final params = {'param1': 'value1'};
        final timestamp = DateTime.now().toIso8601String();
        final requestId = 'test-request-id';
        final invalidSignature = 'invalid-signature';

        final isValid = service.verifyApiSignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
          signature: invalidSignature,
        );

        expect(isValid, isFalse);
      });

      test('应该验证时间戳有效性', () {
        final validTimestamp = DateTime.now().toIso8601String();
        final expiredTimestamp =
            DateTime.now().subtract(Duration(minutes: 10)).toIso8601String();

        expect(service.isValidTimestamp(validTimestamp), isTrue);
        expect(service.isValidTimestamp(expiredTimestamp), isFalse);
      });
    });

    group('重试机制测试', () {
      test('应该在失败时自动重试', () async {
        int callCount = 0;
        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async {
          callCount++;
          if (callCount < 3) {
            throw DioException(
              requestOptions: RequestOptions(path: '/test'),
              type: DioExceptionType.connectionTimeout,
            );
          }
          return mockResponse;
        });

        final result = await service.getWithRetry('/test', maxRetries: 3);

        expect(result.statusCode, equals(200));
        expect(callCount, equals(3));
        verify(mockDio.get('/test',
                queryParameters: anyNamed('queryParameters')))
            .called(3);
      });

      test('应该在达到最大重试次数后失败', () async {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenThrow(dioException);

        expect(() => service.getWithRetry('/test', maxRetries: 3),
            throwsA(isA<DioException>()));

        verify(mockDio.get('/test',
                queryParameters: anyNamed('queryParameters')))
            .called(3); // 初始调用 + 2次重试
      });
    });

    group('缓存功能测试', () {
      test('应该缓存GET请求结果', () async {
        final mockResponse = Response(
          data: {'data': 'cached'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // 第一次请求
        final result1 = await service.getWithCache('/test');

        // 第二次请求（应该从缓存返回）
        final result2 = await service.getWithCache('/test');

        expect(result1.data, equals(result2.data));
        verify(mockDio.get('/test',
                queryParameters: anyNamed('queryParameters')))
            .called(1); // 只应该调用一次API
      });

      test('应该正确处理缓存过期', () async {
        final mockResponse = Response(
          data: {'data': 'updated'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // 第一次请求
        await service.getWithCache('/test',
            cacheDuration: Duration(milliseconds: 100));

        // 等待缓存过期
        await Future.delayed(Duration(milliseconds: 150));

        // 第二次请求（缓存已过期）
        await service.getWithCache('/test',
            cacheDuration: Duration(milliseconds: 100));

        verify(mockDio.get('/test',
                queryParameters: anyNamed('queryParameters')))
            .called(2); // 应该调用两次API
      });
    });

    group('并发请求测试', () {
      test('应该支持并发GET请求', () async {
        final mockResponse = Response(
          data: {'data': 'test'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => mockResponse);

        final futures = List.generate(10, (index) => service.get('/test'));
        final results = await Future.wait(futures);

        expect(results.length, equals(10));
        for (final result in results) {
          expect(result.statusCode, equals(200));
        }
        verify(mockDio.get('/test',
                queryParameters: anyNamed('queryParameters')))
            .called(10);
      });

      test('应该支持并发不同类型的请求', () async {
        final mockGetResponse = Response(
          data: {'data': 'get'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );
        final mockPostResponse = Response(
          data: {'data': 'post'},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => mockGetResponse);
        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockPostResponse);

        final futures = [
          service.get('/test'),
          service.post('/test', data: {'test': 'data'}),
          service.get('/test'),
        ];
        final results = await Future.wait(futures);

        expect(results.length, equals(3));
        expect(results[0].statusCode, equals(200));
        expect(results[1].statusCode, equals(201));
        expect(results[2].statusCode, equals(200));
      });
    });

    group('性能测试', () {
      test('应该在合理时间内完成请求', () async {
        final mockResponse = Response(
          data: {'data': 'performance test'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          return mockResponse;
        });

        final stopwatch = Stopwatch()..start();
        await service.get('/test');
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });

      test('应该支持大量并发请求', () async {
        final mockResponse = Response(
          data: {'data': 'concurrent test'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 10));
          return mockResponse;
        });

        final stopwatch = Stopwatch()..start();
        final futures = List.generate(100, (index) => service.get('/test'));
        await Future.wait(futures);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 100个请求应该在2秒内完成
      });
    });

    tearDown(() {
      // 清理资源
    });
  });
}
