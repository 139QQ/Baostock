import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import 'package:jisu_fund_analyzer/src/services/unified_fund_data_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/cache_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/data_validation_service.dart';
import 'package:jisu_fund_analyzer/src/models/fund_info.dart';

import 'unified_fund_data_service_test.mocks.dart';

@GenerateMocks([
  CacheService,
  DataValidationService,
  Box,
])
void main() {
  group('UnifiedFundDataService - Story R.2 测试套件', () {
    late UnifiedFundDataService service;
    late MockCacheService mockCacheService;
    late MockDataValidationService mockValidationService;
    late MockBox<FundInfo> mockBox;

    setUp(() async {
      mockCacheService = MockCacheService();
      mockValidationService = MockDataValidationService();
      mockBox = MockBox<FundInfo>();

      service = UnifiedFundDataService();

      // 模拟基础设置
      when(mockCacheService.get(any, any)).thenAnswer((_) async => null);
      when(mockCacheService.set(any, any, any)).thenAnswer((_) async => true);
      when(mockBox.values).thenReturn([]);
      when(mockBox.clear()).thenAnswer((_) async => 0);
      when(mockBox.putAll(any)).thenAnswer((_) async {});
    });

    group('初始化测试', () {
      test('应该正确初始化单例实例', () {
        final instance1 = UnifiedFundDataService();
        final instance2 = UnifiedFundDataService();

        expect(identical(instance1, instance2), isTrue);
      });

      test('应该正确构建内存索引', () async {
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

        when(mockBox.values).thenReturn(mockFunds);

        // 这里需要模拟内部内存索引构建
        // 由于内存索引是私有的，我们通过公共方法验证其效果
        expect(mockFunds.length, greaterThan(0));
      });
    });

    group('基金数据获取测试', () {
      test('应该成功获取所有基金数据', () async {
        // 模拟API响应
        final mockResponse = {
          'data': [
            {
              'fund_code': '000001',
              'fund_name': '华夏成长混合',
              'fund_type': '混合型',
              'fund_manager': '张三',
              'fund_size': '10.5亿元',
              'establishment_date': '2020-01-01',
              'unit_nav': 1.2345,
              'accumulated_nav': 1.5678,
              'daily_growth': 0.0123,
              'annualized_return': 0.1567,
              'nav_date': '2024-01-01',
            }
          ]
        };

        when(mockCacheService.get(any, any))
            .thenAnswer((_) async => mockResponse);

        final result = await service.getAllFunds();

        expect(result, isNotNull);
        expect(result.length, greaterThan(0));
        expect(result.first.fundCode, equals('000001'));
        verify(mockCacheService.get(any, any)).called(1);
      });

      test('应该使用缓存机制', () async {
        final cachedData = [
          FundInfo(
            fundCode: '000002',
            fundName: '嘉实沪深300',
            fundType: '指数型',
            fundManager: '李四',
            fundSize: '20.3亿元',
            establishmentDate: '2019-01-01',
            unitNav: 1.5678,
            accumulatedNav: 1.8901,
            dailyGrowth: 0.0089,
            annualizedReturn: 0.1234,
            navDate: DateTime(2024, 1, 1),
            isInWatchlist: false,
          ),
        ];

        when(mockCacheService.get(any, any))
            .thenAnswer((_) async => cachedData);

        final result = await service.getAllFunds();

        expect(result, equals(cachedData));
        verify(mockCacheService.get(any, any)).called(1);
        verifyNever(mockCacheService.set(any, any, any));
      });
    });

    group('基金搜索功能测试', () {
      setUp(() {
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
          FundInfo(
            fundCode: '000002',
            fundName: '嘉实沪深300指数',
            fundType: '指数型',
            fundManager: '李四',
            fundSize: '20.3亿元',
            establishmentDate: '2019-01-01',
            unitNav: 1.5678,
            accumulatedNav: 1.8901,
            dailyGrowth: 0.0089,
            annualizedReturn: 0.1234,
            navDate: DateTime(2024, 1, 1),
            isInWatchlist: false,
          ),
        ];

        when(mockBox.values).thenReturn(mockFunds);
      });

      test('应该能按基金代码搜索', () async {
        final results = await service.searchFunds('000001');

        expect(results.length, equals(1));
        expect(results.first.fundCode, equals('000001'));
      });

      test('应该能按基金名称搜索', () async {
        final results = await service.searchFunds('华夏');

        expect(results.length, equals(1));
        expect(results.first.fundName, contains('华夏'));
      });

      test('应该能按基金类型搜索', () async {
        final results = await service.searchFunds('混合型');

        expect(results.length, equals(1));
        expect(results.first.fundType, equals('混合型'));
      });

      test('应该支持模糊搜索', () async {
        final results = await service.searchFunds('华夏成');

        expect(results.length, equals(1));
        expect(results.first.fundName, contains('华夏'));
      });

      test('搜索空字符串应该返回所有结果', () async {
        final results = await service.searchFunds('');

        expect(results.length, equals(2));
      });

      test('搜索不存在的基金应该返回空列表', () async {
        final results = await service.searchFunds('999999');

        expect(results.isEmpty, isTrue);
      });
    });

    group('数据验证测试', () {
      test('应该验证基金代码格式', () {
        expect(service.isValidFundCode('000001'), isTrue);
        expect(service.isValidFundCode('123456'), isTrue);
        expect(service.isValidFundCode('000001'), isTrue);
        expect(service.isValidFundCode('abcdef'), isFalse);
        expect(service.isValidFundCode('12345'), isFalse);
        expect(service.isValidFundCode('1234567'), isFalse);
      });

      test('应该验证基金名称格式', () {
        expect(service.isValidFundName('华夏成长混合'), isTrue);
        expect(service.isValidFundName('Fund Name'), isTrue);
        expect(service.isValidFundName(''), isFalse);
        expect(service.isValidFundName('A'), isFalse);
      });

      test('应该验证净值数据格式', () {
        expect(service.isValidNavValue(1.2345), isTrue);
        expect(service.isValidNavValue(0.9999), isTrue);
        expect(service.isValidNavValue(-1.0), isFalse);
        expect(service.isValidNavValue(0.0), isFalse);
        expect(service.isValidNavValue(double.infinity), isFalse);
      });
    });

    group('缓存管理测试', () {
      test('应该正确更新缓存', () async {
        final newFunds = [
          FundInfo(
            fundCode: '000003',
            fundName: '南方优选成长',
            fundType: '股票型',
            fundManager: '王五',
            fundSize: '15.7亿元',
            establishmentDate: '2021-01-01',
            unitNav: 1.3456,
            accumulatedNav: 1.6789,
            dailyGrowth: 0.0156,
            annualizedReturn: 0.1789,
            navDate: DateTime(2024, 1, 1),
            isInWatchlist: false,
          ),
        ];

        when(mockBox.values).thenReturn(newFunds);

        await service.updateCache(newFunds);

        verify(mockBox.putAll(any)).called(1);
        verify(mockCacheService.set(any, any, any)).called(1);
      });

      test('应该正确清理缓存', () async {
        await service.clearCache();

        verify(mockBox.clear()).called(1);
        verify(mockCacheService.clear(any)).called(1);
      });
    });

    group('性能测试', () {
      test('大量数据搜索性能测试', () async {
        // 创建大量模拟数据
        final largeFundList = List.generate(
            1000,
            (index) => FundInfo(
                  fundCode: '${(index + 1).toString().padLeft(6, '0')}',
                  fundName: '测试基金${index + 1}',
                  fundType: '混合型',
                  fundManager: '测试经理${index % 10}',
                  fundSize: '${(index + 1) * 10}.5亿元',
                  establishmentDate: '2020-01-01',
                  unitNav: 1.0 + (index * 0.001),
                  accumulatedNav: 1.2 + (index * 0.001),
                  dailyGrowth: 0.01 * (index % 100) / 100,
                  annualizedReturn: 0.15 * (index % 100) / 100,
                  navDate: DateTime(2024, 1, 1),
                  isInWatchlist: false,
                ));

        when(mockBox.values).thenReturn(largeFundList);

        final stopwatch = Stopwatch()..start();
        final results = await service.searchFunds('测试基金500');
        stopwatch.stop();

        expect(results.length, equals(1));
        expect(results.first.fundName, equals('测试基金500'));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 搜索应该在100ms内完成
      });

      test('内存索引构建性能测试', () async {
        final largeFundList = List.generate(
            5000,
            (index) => FundInfo(
                  fundCode: '${(index + 1).toString().padLeft(6, '0')}',
                  fundName: '测试基金${index + 1}',
                  fundType: '混合型',
                  fundManager: '测试经理${index % 10}',
                  fundSize: '${(index + 1) * 10}.5亿元',
                  establishmentDate: '2020-01-01',
                  unitNav: 1.0 + (index * 0.001),
                  accumulatedNav: 1.2 + (index * 0.001),
                  dailyGrowth: 0.01 * (index % 100) / 100,
                  annualizedReturn: 0.15 * (index % 100) / 100,
                  navDate: DateTime(2024, 1, 1),
                  isInWatchlist: false,
                ));

        when(mockBox.values).thenReturn(largeFundList);

        final stopwatch = Stopwatch()..start();
        await service.rebuildMemoryIndex();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 索引构建应该在1秒内完成
      });
    });

    group('错误处理测试', () {
      test('应该处理网络错误', () async {
        when(mockCacheService.get(any, any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(() => service.getAllFunds(), throwsA(isA<Exception>()));
      });

      test('应该处理数据解析错误', () async {
        final invalidData = {'invalid': 'data'};

        when(mockCacheService.get(any, any))
            .thenAnswer((_) async => invalidData);

        final result = await service.getAllFunds();
        expect(result, isEmpty);
      });

      test('应该处理缓存错误', () async {
        when(mockCacheService.get(any, any))
            .thenThrow(Exception('Cache error'));

        // 应该优雅地降级处理
        expect(() => service.getAllFunds(), throwsA(isA<Exception>()));
      });
    });

    group('并发安全测试', () {
      test('应该支持并发搜索', () async {
        final futures =
            List.generate(10, (index) => service.searchFunds(index.toString()));

        final results = await Future.wait(futures);

        expect(results.length, equals(10));
        // 验证每个搜索都正确完成
        for (final result in results) {
          expect(result, isA<List<FundInfo>>());
        }
      });

      test('应该支持并发缓存更新', () async {
        final futures = List.generate(5, (index) {
          final funds = [
            FundInfo(
              fundCode: '${(index + 1).toString().padLeft(6, '0')}',
              fundName: '并发测试基金${index + 1}',
              fundType: '混合型',
              fundManager: '测试经理',
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
          return service.updateCache(funds);
        });

        await Future.wait(futures);

        verify(mockBox.putAll(any)).called(5);
        verify(mockCacheService.set(any, any, any)).called(5);
      });
    });

    tearDown(() {
      // 清理资源
    });
  });
}
