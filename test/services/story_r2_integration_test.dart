import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

import 'package:jisu_fund_analyzer/src/services/unified_fund_data_service.dart';
import 'package:jisu_fund_analyzer/src/services/unified_api_service.dart';
import 'package:jisu_fund_analyzer/src/services/unified_portfolio_service.dart';
import 'package:jisu_fund_analyzer/src/services/api_gateway.dart';
import 'package:jisu_fund_analyzer/src/services/security/security_middleware.dart';
import 'package:jisu_fund_analyzer/src/services/security/security_utils.dart';
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/cache_service.dart';
import 'package:jisu_fund_analyzer/src/models/fund_info.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';

import 'story_r2_integration_test.mocks.dart';

@GenerateMocks([
  CacheService,
  Dio,
])
void main() {
  group('Story R.2 服务层重构集成测试套件', () {
    late MockCacheService mockCacheService;
    late MockDio mockDio;
    late UnifiedFundDataService fundService;
    late UnifiedApiService apiService;
    late UnifiedPortfolioService portfolioService;
    late ApiGateway gateway;

    setUp(() async {
      mockCacheService = MockCacheService();
      mockDio = MockDio();

      // 设置默认的mock行为
      when(mockCacheService.get(any, any)).thenAnswer((_) async => null);
      when(mockCacheService.set(any, any, any)).thenAnswer((_) async => true);
      when(mockCacheService.clear(any)).thenAnswer((_) async => true);

      // 初始化服务
      fundService = UnifiedFundDataService();
      apiService = UnifiedApiService();
      portfolioService =
          UnifiedPortfolioService(cacheService: mockCacheService);
      gateway = ApiGateway();

      // 注册服务到网关
      gateway.registerService('fund', fundService);
      gateway.registerService('api', apiService);
      gateway.registerService('portfolio', portfolioService);
    });

    group('服务协作集成测试', () {
      test('应该通过网关协调多个服务', () async {
        // 模拟基金数据
        final mockFunds = [
          FundInfo(
            fundCode: '000001',
            fundName: '华夏成长混合',
            fundType: '混合型',
            fundManager: '张三',
            fundSize: '10.5亿元',
            establishmentDate: '2020-01-01',
            unitNav: 1.2345,
            accumulatedNav: 1.5678,
            dailyGrowth: 0.0123,
            annualizedReturn: 0.1567,
            navDate: DateTime(2024, 1, 1),
            isInWatchlist: false,
          ),
        ];

        // 模拟API响应
        final mockResponse = Response(
          data: mockFunds
              .map((f) => {
                    'fund_code': f.fundCode,
                    'fund_name': f.fundName,
                    'fund_type': f.fundType,
                    'unit_nav': f.unitNav,
                    'accumulated_nav': f.accumulatedNav,
                  })
              .toList(),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/funds'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // 通过网关获取基金数据
        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/fund/all',
          serviceName: 'fund',
        );

        expect(result.statusCode, equals(200));
        expect(result.data, isA<List>());
        expect(result.data.length, greaterThan(0));
      });

      test('应该处理跨服务的数据流转', () async {
        // 模拟完整的业务流程：获取基金 -> 添加到投资组合 -> 计算收益

        final mockFund = FundInfo(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          fundManager: '张三',
          fundSize: '10.5亿元',
          establishmentDate: '2020-01-01',
          unitNav: 1.2345,
          accumulatedNav: 1.5678,
          dailyGrowth: 0.0123,
          annualizedReturn: 0.1567,
          navDate: DateTime(2024, 1, 1),
          isInWatchlist: false,
        );

        final mockResponse = Response(
          data: {
            'fund_code': mockFund.fundCode,
            'fund_name': mockFund.fundName,
            'unit_nav': mockFund.unitNav,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/fund/000001'),
        );

        when(mockDio.get(any)).thenAnswer((_) async => mockResponse);

        // 步骤1: 通过网关获取基金数据
        final fundResult = await gateway.routeRequest(
          method: 'GET',
          path: '/fund/search',
          serviceName: 'fund',
          queryParams: {'query': '华夏成长'},
        );

        expect(fundResult.statusCode, equals(200));

        // 步骤2: 添加到投资组合
        final holding = PortfolioHolding(
          userId: 'test-user',
          fundCode: '000001',
          fundName: '华夏成长混合',
          shares: 1000.0,
          averageCost: 1.2345,
          currentPrice: 1.3456,
          marketValue: 1345.60,
          totalCost: 1234.50,
          profit: 111.10,
          profitRate: 0.09,
          purchaseDate: DateTime(2024, 1, 1),
          lastUpdated: DateTime.now(),
        );

        when(mockCacheService.set(any, any, any)).thenAnswer((_) async => true);

        final addResult = await gateway.routeRequest(
          method: 'POST',
          path: '/portfolio/holding',
          serviceName: 'portfolio',
          data: holding.toJson(),
        );

        expect(addResult.statusCode, equals(201));

        // 验证缓存调用
        verify(mockCacheService.set(any, any, any)).called(1);
      });
    });

    group('安全集成测试', () {
      test('应该在所有服务中应用安全验证', () async {
        // 配置网关安全策略
        gateway.configureSecurity(
          enableSignatureVerification: true,
          enableRateLimiting: true,
          enableInputValidation: true,
        );

        // 创建带有安全头的请求
        final secureHeaders = {
          'X-Request-ID': SecurityUtils.generateRequestId(),
          'X-Timestamp': SecurityUtils.generateTimestamp(),
          'X-Signature': SecurityUtils.generateSignature(
            method: 'GET',
            path: '/api/funds',
            params: {},
            timestamp: DateTime.now().toIso8601String(),
            requestId: 'test-request',
          ),
        };

        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/funds'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // 发送安全请求
        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/api/funds',
          serviceName: 'api',
          headers: secureHeaders,
        );

        expect(result.statusCode, equals(200));
      });

      test('应该阻止恶意请求', () async {
        // 配置网关安全策略
        gateway.configureSecurity(
          enableSignatureVerification: true,
          enableRateLimiting: true,
          enableInputValidation: true,
        );

        // 发送恶意请求（包含SQL注入）
        final maliciousParams = {
          'fund_code': "'; DROP TABLE funds; --",
        };

        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/api/funds',
          serviceName: 'api',
          queryParams: maliciousParams,
        );

        expect(result.statusCode, equals(400));
        expect(result.data['error'], contains('输入验证失败'));
      });

      test('应该实施频率限制', () async {
        // 配置严格的频率限制
        gateway.configureRateLimit('api', requestsPerSecond: 1);

        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        when(mockDio.get(any)).thenAnswer((_) async => mockResponse);

        // 快速发送多个请求
        final results = await Future.wait([
          gateway.routeRequest(
              method: 'GET', path: '/api/test', serviceName: 'api'),
          gateway.routeRequest(
              method: 'GET', path: '/api/test', serviceName: 'api'),
          gateway.routeRequest(
              method: 'GET', path: '/api/test', serviceName: 'api'),
        ]);

        // 部分请求应该被限制
        final rejectedCount = results.where((r) => r.statusCode == 429).length;
        expect(rejectedCount, greaterThan(0));
      });
    });

    group('性能集成测试', () {
      test('应该在高并发下保持性能', () async {
        final mockResponse = Response(
          data: {'status': 'success', 'data': 'test'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        when(mockDio.get(any)).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 10));
          return mockResponse;
        });

        final stopwatch = Stopwatch()..start();

        // 并发发送100个请求到不同服务
        final futures = [
          ...List.generate(
              33,
              (index) => gateway.routeRequest(
                  method: 'GET', path: '/fund/test', serviceName: 'fund')),
          ...List.generate(
              33,
              (index) => gateway.routeRequest(
                  method: 'GET', path: '/api/test', serviceName: 'api')),
          ...List.generate(
              34,
              (index) => gateway.routeRequest(
                  method: 'GET',
                  path: '/portfolio/test',
                  serviceName: 'portfolio')),
        ];

        final results = await Future.wait(futures);
        stopwatch.stop();

        // 验证所有请求都成功
        expect(results.length, equals(100));
        expect(results.every((r) => r.statusCode == 200), isTrue);

        // 验证性能指标
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 3秒内完成

        final gatewayStats = gateway.getGatewayStats();
        expect(gatewayStats['total_requests'], greaterThanOrEqualTo(100));
      });

      test('应该在服务故障时优雅降级', () async {
        // 模拟一个服务故障
        when(mockDio.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          type: DioExceptionType.connectionTimeout,
        ));

        // 配置熔断器
        gateway.configureCircuitBreaker('api', failureThreshold: 2);

        // 发送请求触发故障
        final result1 = await gateway.routeRequest(
          method: 'GET',
          path: '/api/test',
          serviceName: 'api',
        );

        final result2 = await gateway.routeRequest(
          method: 'GET',
          path: '/api/test',
          serviceName: 'api',
        );

        final result3 = await gateway.routeRequest(
          method: 'GET',
          path: '/api/test',
          serviceName: 'api',
        );

        // 前两个请求失败，第三个请求应该被熔断器拦截
        expect(result1.statusCode, equals(502));
        expect(result2.statusCode, equals(502));
        expect(result3.statusCode, equals(503)); // 熔断器开启
      });
    });

    group('数据一致性测试', () {
      test('应该保持跨服务数据一致性', () async {
        // 模拟基金数据更新场景
        final updatedFundData = {
          'fund_code': '000001',
          'fund_name': '华夏成长混合（更新）',
          'unit_nav': 1.3456,
          'accumulated_nav': 1.6789,
        };

        final mockResponse = Response(
          data: updatedFundData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/fund/000001'),
        );

        when(mockDio.get(any)).thenAnswer((_) async => mockResponse);
        when(mockCacheService.set(any, any, any)).thenAnswer((_) async => true);

        // 通过网关更新基金数据
        final updateResult = await gateway.routeRequest(
          method: 'PUT',
          path: '/fund/000001',
          serviceName: 'fund',
          data: updatedFundData,
        );

        expect(updateResult.statusCode, equals(200));

        // 验证缓存被更新
        verify(mockCacheService.set(any, any, any)).called(1);

        // 验证数据在所有服务中保持一致
        final fetchResult = await gateway.routeRequest(
          method: 'GET',
          path: '/fund/000001',
          serviceName: 'fund',
        );

        expect(fetchResult.statusCode, equals(200));
        expect(fetchResult.data['fund_name'], equals('华夏成长混合（更新）'));
      });

      test('应该处理数据同步失败', () async {
        // 模拟缓存同步失败
        when(mockCacheService.set(any, any, any))
            .thenThrow(Exception('Cache sync failed'));

        final fundData = {
          'fund_code': '000002',
          'fund_name': '嘉实沪深300',
        };

        // 即使缓存失败，服务也应该继续工作
        final result = await gateway.routeRequest(
          method: 'POST',
          path: '/fund',
          serviceName: 'fund',
          data: fundData,
        );

        expect(result.statusCode, equals(201));
      });
    });

    group('错误传播和处理测试', () {
      test('应该正确传播服务间错误', () async {
        // 模拟API服务错误
        when(mockDio.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/api/test'),
            data: {'error': 'Resource not found'},
          ),
        ));

        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/api/test',
          serviceName: 'api',
        );

        expect(result.statusCode, equals(404));
        expect(result.data['error'], equals('Resource not found'));
      });

      test('应该处理级联失败', () async {
        // 模拟依赖服务失败
        when(mockDio.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/external/service'),
          type: DioExceptionType.connectionError,
        ));

        // 基金服务依赖外部API
        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/fund/external-data',
          serviceName: 'fund',
        );

        expect(result.statusCode, equals(502)); // Bad Gateway
        expect(result.data['error'], contains('connection error'));
      });

      test('应该提供详细的错误诊断信息', () async {
        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/nonexistent/service',
          serviceName: 'nonexistent',
        );

        expect(result.statusCode, equals(404));
        expect(result.data['error'], contains('Service not found'));
        expect(result.data['available_services'], isA<List>());
      });
    });

    group('扩展性测试', () {
      test('应该支持动态服务注册', () async {
        // 创建新的测试服务
        final newServiceResponse = Response(
          data: {'service': 'new', 'status': 'active'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/new/test'),
        );

        when(mockDio.get(any)).thenAnswer((_) async => newServiceResponse);

        // 动态注册新服务
        final newService = UnifiedApiService();
        gateway.registerService('new-service', newService);

        // 通过新注册的服务处理请求
        final result = await gateway.routeRequest(
          method: 'GET',
          path: '/new/test',
          serviceName: 'new-service',
        );

        expect(result.statusCode, equals(200));
        expect(result.data['service'], equals('new'));

        // 验证服务在网关统计中
        final stats = gateway.getGatewayStats();
        expect(stats['registered_services'], greaterThan(3));
      });

      test('应该支持服务热重载', () async {
        final oldServiceResponse = Response(
          data: {'version': '1.0'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        final newServiceResponse = Response(
          data: {'version': '2.0'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any)).thenAnswer((_) async => oldServiceResponse);

        // 初始请求
        final result1 = await gateway.routeRequest(
          method: 'GET',
          path: '/test',
          serviceName: 'api',
        );

        expect(result1.data['version'], equals('1.0'));

        // 热重载服务
        final newService = UnifiedApiService();
        when(mockDio.get(any)).thenAnswer((_) async => newServiceResponse);

        final reloadSuccess = gateway.reloadService('api', newService);
        expect(reloadSuccess, isTrue);

        // 重载后的请求
        final result2 = await gateway.routeRequest(
          method: 'GET',
          path: '/test',
          serviceName: 'api',
        );

        expect(result2.data['version'], equals('2.0'));
      });
    });

    group('监控和诊断测试', () {
      test('应该提供全面的性能指标', () async {
        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any)).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          return mockResponse;
        });

        // 发送一些请求
        for (int i = 0; i < 10; i++) {
          await gateway.routeRequest(
            method: 'GET',
            path: '/test',
            serviceName: 'api',
          );
        }

        // 检查各服务的统计信息
        final apiStats = gateway.getServiceStats('api');
        final fundStats = gateway.getServiceStats('fund');
        final portfolioStats = gateway.getServiceStats('portfolio');

        expect(apiStats['total_requests'], equals(10));
        expect(apiStats['successful_requests'], equals(10));
        expect(apiStats['average_response_time'], greaterThan(40));

        expect(fundStats['total_requests'], equals(0)); // 没有请求
        expect(portfolioStats['total_requests'], equals(0)); // 没有请求

        // 检查网关整体统计
        final gatewayStats = gateway.getGatewayStats();
        expect(gatewayStats['total_requests'], equals(10));
        expect(gatewayStats['registered_services'], equals(3));
        expect(gatewayStats['uptime'], greaterThan(0));
      });

      test('应该支持健康检查', () async {
        final overallHealth = await gateway.checkOverallHealth();

        expect(overallHealth['overall_status'], isA<String>());
        expect(overallHealth['healthy_services'], greaterThanOrEqualTo(0));
        expect(overallHealth['unhealthy_services'], greaterThanOrEqualTo(0));
        expect(overallHealth['timestamp'], isNotNull);
      });

      test('应该记录关键操作日志', () async {
        final mockResponse = Response(
          data: {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get(any)).thenAnswer((_) async => mockResponse);

        // 执行一些操作
        await gateway.routeRequest(
            method: 'GET', path: '/test', serviceName: 'api');
        await gateway.routeRequest(
            method: 'POST',
            path: '/test',
            serviceName: 'fund',
            data: {'test': 'data'});

        // 验证操作被记录（通过统计信息）
        final apiStats = gateway.getServiceStats('api');
        final fundStats = gateway.getServiceStats('fund');

        expect(apiStats['total_requests'], equals(1));
        expect(fundStats['total_requests'], equals(1));
      });
    });

    tearDown(() {
      // 清理资源
      gateway.shutdown();
    });
  });
}
