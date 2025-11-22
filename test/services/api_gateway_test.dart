import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

import 'package:jisu_fund_analyzer/src/services/api_gateway.dart';
import 'package:jisu_fund_analyzer/src/services/interfaces/service_interfaces.dart';

import 'api_gateway_test.mocks.dart';

@GenerateMocks([
  IApiService,
  IFundDataService,
  IPortfolioService,
])
void main() {
  group('ApiGateway - Story R.2 测试套件', () {
    late ApiGateway gateway;
    late MockIApiService mockApiService;
    late MockIFundDataService mockFundService;
    late MockIPortfolioService mockPortfolioService;

    setUp(() {
      mockApiService = MockIApiService();
      mockFundService = MockIFundDataService();
      mockPortfolioService = MockIPortfolioService();

      gateway = ApiGateway();

      // 注册服务
      gateway.registerService('api', mockApiService);
      gateway.registerService('fund', mockFundService);
      gateway.registerService('portfolio', mockPortfolioService);
    });

    group('服务注册和管理测试', () {
      test('应该正确注册服务', () {
        final success = gateway.registerService('test', mockApiService);

        expect(success, isTrue);
        expect(gateway.isServiceRegistered('test'), isTrue);
      });

      test('应该拒绝重复注册相同名称的服务', () {
        gateway.registerService('duplicate', mockApiService);
        final success = gateway.registerService('duplicate', mockFundService);

        expect(success, isFalse);
      });

      test('应该正确注销服务', () {
        gateway.registerService('temp', mockApiService);
        final success = gateway.unregisterService('temp');

        expect(success, isTrue);
        expect(gateway.isServiceRegistered('temp'), isFalse);
      });

      test('应该获取已注册的服务', () {
        final service = gateway.getService('api');

        expect(service, isNotNull);
        expect(service, equals(mockApiService));
      });

      test('应该处理获取未注册的服务', () {
        final service = gateway.getService('nonexistent');

        expect(service, isNull);
      });

      test('应该列出所有已注册的服务', () {
        final services = gateway.getRegisteredServices();

        expect(services.length, equals(3));
        expect(services, contains('api'));
        expect(services, contains('fund'));
        expect(services, contains('portfolio'));
      });
    });

    group('请求路由测试', () {
      test('应该正确路由到API服务', () async {
        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        when(mockApiService.get('/test')).thenAnswer((_) async => mockResponse);

        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/api/test',
          serviceName: 'api',
        );

        expect(result.statusCode, equals(200));
        expect(result.data['status'], equals('success'));
        verify(mockApiService.get('/test')).called(1);
      });

      test('应该正确路由到基金服务', () async {
        final mockFunds = [
          {'fund_code': '000001', 'fund_name': 'Test Fund'},
        ];

        when(mockFundService.getAllFunds()).thenAnswer((_) async => mockFunds);

        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/fund/all',
          serviceName: 'fund',
        );

        expect(result.data, equals(mockFunds));
        verify(mockFundService.getAllFunds()).called(1);
      });

      test('应该正确路由到投资组合服务', () async {
        final mockHoldings = [
          {'fund_code': '000001', 'shares': 1000.0},
        ];

        when(mockPortfolioService.getUserHoldings('test-user'))
            .thenAnswer((_) async => mockHoldings);

        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/portfolio/holdings',
          serviceName: 'portfolio',
          queryParams: {'user_id': 'test-user'},
        );

        expect(result.data, equals(mockHoldings));
        verify(mockPortfolioService.getUserHoldings('test-user')).called(1);
      });

      test('应该处理路由到未注册的服务', () async {
        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/test',
          serviceName: 'nonexistent',
        );

        expect(result.statusCode, equals(404));
        expect(result.data['error'], contains('Service not found'));
      });

      test('应该根据路径自动路由服务', () async {
        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        when(mockApiService.get('/test')).thenAnswer((_) async => mockResponse);

        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/api/test',
        );

        expect(result.statusCode, equals(200));
        verify(mockApiService.get('/test')).called(1);
      });
    });

    group('负载均衡测试', () {
      test('应该在多个服务实例间进行负载均衡', () async {
        // 创建多个mock服务实例
        final mockService1 = MockUnifiedApiService();
        final mockService2 = MockUnifiedApiService();

        final mockResponse1 = Response(
          data: {'server': 'server1'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );
        final mockResponse2 = Response(
          data: {'server': 'server2'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockService1.get('/test')).thenAnswer((_) async => mockResponse1);
        when(mockService2.get('/test')).thenAnswer((_) async => mockResponse2);

        // 注册多个服务实例
        gateway.registerServiceInstance('load_balanced', mockService1);
        gateway.registerServiceInstance('load_balanced', mockService2);

        // 发送多个请求
        final results = await Future.wait([
          gateway.routeRequest(
              method: 'GET', path: '/test', serviceName: 'load_balanced'),
          gateway.routeRequest(
              method: 'GET', path: '/test', serviceName: 'load_balanced'),
          gateway.routeRequest(
              method: 'GET', path: '/test', serviceName: 'load_balanced'),
          gateway.routeRequest(
              method: 'GET', path: '/test', serviceName: 'load_balanced'),
        ]);

        expect(results.length, equals(4));
        // 验证负载均衡器在工作
        verify(mockService1.get('/test')).called(greaterThan(0));
        verify(mockService2.get('/test')).called(greaterThan(0));
      });

      test('应该支持轮询负载均衡策略', () async {
        gateway.setLoadBalancingStrategy('round_robin');

        final mockService1 = MockUnifiedApiService();
        final mockService2 = MockUnifiedApiService();

        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockService1.get('/test')).thenAnswer((_) async => mockResponse);
        when(mockService2.get('/test')).thenAnswer((_) async => mockResponse);

        gateway.registerServiceInstance('round_robin_test', mockService1);
        gateway.registerServiceInstance('round_robin_test', mockService2);

        // 发送两个请求
        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'round_robin_test');
        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'round_robin_test');

        // 验证轮询策略
        verify(mockService1.get('/test')).called(1);
        verify(mockService2.get('/test')).called(1);
      });
    });

    group('熔断器测试', () {
      test('应该在连续失败后触发熔断', () async {
        final mockService = MockUnifiedApiService();

        when(mockService.get('/test')).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        ));

        gateway.registerService('circuit_breaker_test', mockService);
        gateway.configureCircuitBreaker('circuit_breaker_test',
            failureThreshold: 3, timeout: Duration(seconds: 1));

        // 发送失败的请求
        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'circuit_breaker_test');
        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'circuit_breaker_test');
        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'circuit_breaker_test');

        // 第四个请求应该被熔断器拦截
        final result = await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'circuit_breaker_test');

        expect(result.statusCode, equals(503));
        expect(result.data['error'], contains('Circuit breaker is open'));
        verify(mockService.get('/test')).called(3); // 只调用3次，第4次被熔断器拦截
      });

      test('应该在超时后自动恢复熔断器', () async {
        final mockService = MockUnifiedApiService();

        when(mockService.get('/test')).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        ));

        gateway.registerService('circuit_breaker_recovery', mockService);
        gateway.configureCircuitBreaker('circuit_breaker_recovery',
            failureThreshold: 2, timeout: Duration(milliseconds: 100));

        // 触发熔断器
        await gateway.routeRequest(
            method: 'GET',
            path: '/test',
            serviceName: 'circuit_breaker_recovery');
        await gateway.routeRequest(
            method: 'GET',
            path: '/test',
            serviceName: 'circuit_breaker_recovery');

        // 等待熔断器超时
        await Future.delayed(Duration(milliseconds: 150));

        // 熔断器应该恢复到半开状态
        expect(gateway.getCircuitBreakerState('circuit_breaker_recovery'),
            equals('half_open'));
      });
    });

    group('限流测试', () {
      test('应该限制请求频率', () async {
        final mockService = MockUnifiedApiService();

        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockService.get('/test')).thenAnswer((_) async => mockResponse);

        gateway.registerService('rate_limited', mockService);
        gateway.configureRateLimit('rate_limited', requestsPerSecond: 2);

        // 快速发送多个请求
        final results = await Future.wait([
          gateway.routeRequest(
              method: 'GET', path: '/test', serviceName: 'rate_limited'),
          gateway.routeRequest(
              method: 'GET', path: '/test', serviceName: 'rate_limited'),
          gateway.routeRequest(
              method: 'GET', path: '/test', serviceName: 'rate_limited'),
          gateway.routeRequest(
              method: 'GET', path: '/test', serviceName: 'rate_limited'),
        ]);

        // 部分请求应该被限流
        final rejectedCount = results.where((r) => r.statusCode == 429).length;
        expect(rejectedCount, greaterThan(0));
      });

      test('应该支持不同服务的独立限流配置', () async {
        final mockService1 = MockUnifiedApiService();
        final mockService2 = MockUnifiedApiService();

        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockService1.get('/test')).thenAnswer((_) async => mockResponse);
        when(mockService2.get('/test')).thenAnswer((_) async => mockResponse);

        gateway.registerService('service1', mockService1);
        gateway.registerService('service2', mockService2);

        gateway.configureRateLimit('service1', requestsPerSecond: 1);
        gateway.configureRateLimit('service2', requestsPerSecond: 10);

        // 验证限流配置独立性
        final service1Stats = gateway.getRateLimitStats('service1');
        final service2Stats = gateway.getRateLimitStats('service2');

        expect(service1Stats['requestsPerSecond'], equals(1));
        expect(service2Stats['requestsPerSecond'], equals(10));
      });
    });

    group('健康检查测试', () {
      test('应该检查服务健康状态', () async {
        final mockService = MockUnifiedApiService();

        when(mockService.healthCheck()).thenAnswer((_) async => {
              'status': 'healthy',
              'timestamp': DateTime.now().toIso8601String()
            });

        gateway.registerService('healthy_service', mockService);

        final healthStatus =
            await gateway.checkServiceHealth('healthy_service');

        expect(healthStatus['status'], equals('healthy'));
        expect(healthStatus['isHealthy'], isTrue);
      });

      test('应该检测不健康的服务', () async {
        final mockService = MockUnifiedApiService();

        when(mockService.healthCheck())
            .thenThrow(Exception('Service unavailable'));

        gateway.registerService('unhealthy_service', mockService);

        final healthStatus =
            await gateway.checkServiceHealth('unhealthy_service');

        expect(healthStatus['status'], equals('unhealthy'));
        expect(healthStatus['isHealthy'], isFalse);
        expect(healthStatus['error'], isNotNull);
      });

      test('应该检查所有已注册服务的健康状态', () async {
        final mockService1 = MockUnifiedApiService();
        final mockService2 = MockUnifiedApiService();

        when(mockService1.healthCheck())
            .thenAnswer((_) async => {'status': 'healthy'});
        when(mockService2.healthCheck())
            .thenAnswer((_) async => {'status': 'healthy'});

        gateway.registerService('service1', mockService1);
        gateway.registerService('service2', mockService2);

        final overallHealth = await gateway.checkOverallHealth();

        expect(overallHealth['overall_status'], equals('healthy'));
        expect(overallHealth['healthy_services'], equals(2));
        expect(overallHealth['unhealthy_services'], equals(0));
      });
    });

    group('监控和统计测试', () {
      test('应该收集请求统计信息', () async {
        final mockService = MockUnifiedApiService();

        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockService.get('/test')).thenAnswer((_) async => mockResponse);

        gateway.registerService('monitored_service', mockService);

        // 发送一些请求
        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'monitored_service');
        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'monitored_service');

        final stats = gateway.getServiceStats('monitored_service');

        expect(stats['total_requests'], equals(2));
        expect(stats['successful_requests'], equals(2));
        expect(stats['failed_requests'], equals(0));
      });

      test('应该跟踪响应时间', () async {
        final mockService = MockUnifiedApiService();

        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockService.get('/test')).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return mockResponse;
        });

        gateway.registerService('timing_service', mockService);

        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'timing_service');

        final stats = gateway.getServiceStats('timing_service');

        expect(stats['average_response_time'], greaterThan(90)); // 至少100ms
        expect(stats['average_response_time'], lessThan(200)); // 不超过200ms
      });

      test('应该提供网关整体统计信息', () async {
        final gatewayStats = gateway.getGatewayStats();

        expect(gatewayStats['registered_services'], equals(3));
        expect(gatewayStats['total_requests'], greaterThanOrEqualTo(0));
        expect(gatewayStats['uptime'], greaterThan(0));
      });
    });

    group('错误处理和恢复测试', () {
      test('应该优雅处理服务异常', () async {
        final mockService = MockUnifiedApiService();

        when(mockService.get('/test')).thenThrow(Exception('Service error'));

        gateway.registerService('failing_service', mockService);

        final result = await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'failing_service');

        expect(result.statusCode, equals(502));
        expect(result.data['error'], contains('Service error'));
      });

      test('应该支持服务热重载', () async {
        final oldService = MockUnifiedApiService();
        final newService = MockUnifiedApiService();

        final oldResponse = Response(
          data: {'version': 'old'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );
        final newResponse = Response(
          data: {'version': 'new'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(oldService.get('/test')).thenAnswer((_) async => oldResponse);
        when(newService.get('/test')).thenAnswer((_) async => newResponse);

        gateway.registerService('reloadable', oldService);

        // 使用旧服务
        final result1 = await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'reloadable');
        expect(result1.data['version'], equals('old'));

        // 热重载服务
        final reloadSuccess = gateway.reloadService('reloadable', newService);
        expect(reloadSuccess, isTrue);

        // 使用新服务
        final result2 = await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'reloadable');
        expect(result2.data['version'], equals('new'));
      });
    });

    group('性能测试', () {
      test('应该支持高并发请求', () async {
        final mockService = MockUnifiedApiService();

        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockService.get('/test')).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 10));
          return mockResponse;
        });

        gateway.registerService('performance_service', mockService);

        final stopwatch = Stopwatch()..start();

        // 发送100个并发请求
        final futures = List.generate(
            100,
            (index) => gateway.routeRequest(
                method: 'GET',
                path: '/test',
                serviceName: 'performance_service'));

        final results = await Future.wait(futures);
        stopwatch.stop();

        // 验证所有请求都成功
        expect(results.length, equals(100));
        expect(results.every((r) => r.statusCode == 200), isTrue);

        // 验证性能
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 应该在2秒内完成

        final stats = gateway.getServiceStats('performance_service');
        expect(stats['total_requests'], equals(100));
        expect(stats['successful_requests'], equals(100));
      });

      test('应该在合理时间内处理路由', () async {
        final mockService = MockUnifiedApiService();

        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockService.get('/test')).thenAnswer((_) async => mockResponse);

        gateway.registerService('routing_service', mockService);

        final stopwatch = Stopwatch()..start();
        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'routing_service');
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // 路由应该在50ms内完成
      });
    });

    tearDown(() {
      // 清理资源
      gateway.shutdown();
    });
  });
}
