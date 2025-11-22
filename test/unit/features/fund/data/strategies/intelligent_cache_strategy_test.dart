import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/fund/data/strategies/intelligent_cache_strategy.dart';
import 'package:jisu_fund_analyzer/src/features/fund/models/fund_nav_data.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import 'package:decimal/decimal.dart';

import '../../../../../mocks/mock_services.dart';

@GenerateMocks([])
void main() {
  group('IntelligentCacheStrategy Tests', () {
    late IntelligentCacheStrategy strategy;

    setUp(() {
      strategy = IntelligentCacheStrategy();
    });

    tearDown(() async {
      await strategy.dispose();
    });

    group('策略注册和管理', () {
      test('应该能够注册基金缓存策略', () {
        final cacheStrategy = CacheStrategy(
          name: 'test_strategy',
          updateInterval: Duration(minutes: 30),
          prefetchEnabled: true,
          compressionEnabled: false,
          priority: 0.8,
        );

        strategy.registerFundStrategy('000001', cacheStrategy);

        final retrievedStrategy = strategy.getFundStrategy('000001');
        expect(retrievedStrategy, isNotNull);
        expect(retrievedStrategy!.name, equals('test_strategy'));
        expect(retrievedStrategy.updateInterval, equals(Duration(minutes: 30)));
        expect(retrievedStrategy.prefetchEnabled, isTrue);
        expect(retrievedStrategy.priority, equals(0.8));
      });

      test('应该能够覆盖现有策略', () {
        final strategy1 = CacheStrategy(
          name: 'strategy1',
          updateInterval: Duration(minutes: 30),
          priority: 0.5,
        );

        final strategy2 = CacheStrategy(
          name: 'strategy2',
          updateInterval: Duration(minutes: 15),
          priority: 0.9,
        );

        strategy.registerFundStrategy('000001', strategy1);
        strategy.registerFundStrategy('000001', strategy2);

        final retrievedStrategy = strategy.getFundStrategy('000001');
        expect(retrievedStrategy!.name, equals('strategy2'));
        expect(retrievedStrategy.updateInterval, equals(Duration(minutes: 15)));
        expect(retrievedStrategy.priority, equals(0.9));
      });

      test('应该能够获取推荐更新时间', () {
        final cacheStrategy = CacheStrategy(
          name: 'test_strategy',
          updateInterval: Duration(minutes: 30),
        );

        strategy.registerFundStrategy('000001', cacheStrategy);

        final recommendedTime = strategy.getRecommendedUpdateTime('000001');
        expect(recommendedTime, isNotNull);
        expect(recommendedTime!.isAfter(DateTime.now()), isTrue);
        expect(recommendedTime.difference(DateTime.now()),
            equals(Duration(minutes: 30)));
      });

      test('未注册基金应该返回null', () {
        final unregisteredStrategy = strategy.getFundStrategy('999999');
        expect(unregisteredStrategy, isNull);

        final unregisteredTime = strategy.getRecommendedUpdateTime('999999');
        expect(unregisteredTime, isNull);
      });
    });

    group('更新判断逻辑', () {
      test('应该正确判断需要更新', () {
        final cacheStrategy = CacheStrategy(
          name: 'test_strategy',
          updateInterval: Duration(minutes: 30),
        );

        strategy.registerFundStrategy('000001', cacheStrategy);

        // 模拟2小时前的最后更新
        final lastUpdate = DateTime.now().subtract(Duration(hours: 2));

        final shouldUpdate =
            strategy.shouldUpdate('000001', lastUpdate: lastUpdate);
        expect(shouldUpdate, isTrue);
      });

      test('应该正确判断不需要更新', () {
        final cacheStrategy = CacheStrategy(
          name: 'test_strategy',
          updateInterval: Duration(hours: 1),
        );

        strategy.registerFundStrategy('000001', cacheStrategy);

        // 模拟10分钟前的最后更新
        final lastUpdate = DateTime.now().subtract(Duration(minutes: 10));

        final shouldUpdate =
            strategy.shouldUpdate('000001', lastUpdate: lastUpdate);
        expect(shouldUpdate, isFalse);
      });

      test('未注册基金应该不需要更新', () {
        final shouldUpdate = strategy.shouldUpdate('999999');
        expect(shouldUpdate, isFalse);
      });
    });

    group('动态频率调整', () {
      test('应该能够增加更新频率', () {
        final originalStrategy = CacheStrategy(
          name: 'test_strategy',
          updateInterval: Duration(minutes: 30),
        );

        strategy.registerFundStrategy('000001', originalStrategy);

        strategy.adjustUpdateFrequency('000001', increase: true);

        final adjustedStrategy = strategy.getFundStrategy('000001');
        expect(
            adjustedStrategy!.updateInterval, lessThan(Duration(minutes: 30)));
      });

      test('应该能够降低更新频率', () {
        final originalStrategy = CacheStrategy(
          name: 'test_strategy',
          updateInterval: Duration(minutes: 30),
        );

        strategy.registerFundStrategy('000001', originalStrategy);

        strategy.adjustUpdateFrequency('000001', increase: false);

        final adjustedStrategy = strategy.getFundStrategy('000001');
        expect(adjustedStrategy!.updateInterval,
            greaterThan(Duration(minutes: 30)));
      });

      test('应该能够设置自定义间隔', () {
        final originalStrategy = CacheStrategy(
          name: 'test_strategy',
          updateInterval: Duration(minutes: 30),
        );

        strategy.registerFundStrategy('000001', originalStrategy);

        final customInterval = Duration(minutes: 45);
        strategy.adjustUpdateFrequency('000001',
            customInterval: customInterval);

        final adjustedStrategy = strategy.getFundStrategy('000001');
        expect(adjustedStrategy!.updateInterval, equals(customInterval));
      });

      test('应该限制频率调整范围', () {
        final originalStrategy = CacheStrategy(
          name: 'test_strategy',
          updateInterval: Duration(minutes: 30),
        );

        strategy.registerFundStrategy('000001', originalStrategy);

        // 尝试设置过短的间隔
        strategy.adjustUpdateFrequency('000001',
            customInterval: Duration(seconds: 5));
        final adjustedStrategy1 = strategy.getFundStrategy('000001');
        expect(adjustedStrategy1!.updateInterval,
            greaterThanOrEqualTo(Duration(seconds: 10)));

        // 尝试设置过长的间隔
        strategy.adjustUpdateFrequency('000001',
            customInterval: Duration(hours: 5));
        final adjustedStrategy2 = strategy.getFundStrategy('000001');
        expect(adjustedStrategy2!.updateInterval,
            lessThanOrEqualTo(Duration(hours: 1)));
      });
    });

    group('预取建议', () {
      test('应该能够获取预取建议', () {
        final suggestions = strategy.getPrefetchSuggestions(limit: 5);

        expect(suggestions, isNotNull);
        expect(suggestions.length, lessThanOrEqualTo(5));
      });

      test('应该能够限制预取建议数量', () {
        final suggestions = strategy.getPrefetchSuggestions(limit: 10);

        expect(suggestions, isNotNull);
        expect(suggestions.length, lessThanOrEqualTo(10));
      });

      test('默认限制应该合理', () {
        final suggestions = strategy.getPrefetchSuggestions();

        expect(suggestions, isNotNull);
        expect(suggestions.length, lessThanOrEqualTo(10)); // 默认限制
      });
    });

    group('策略统计', () {
      test('应该能够获取策略统计信息', () {
        // 注册几个不同类型的策略
        strategy.registerFundStrategy('000001', CacheStrategy.highFrequency);
        strategy.registerFundStrategy('000002', CacheStrategy.balanced);
        strategy.registerFundStrategy('000003', CacheStrategy.lowFrequency);
        strategy.registerFundStrategy('000004', CacheStrategy.highFrequency);

        final statistics = strategy.getStrategyStatistics();

        expect(statistics, isNotNull);
        expect(statistics['totalStrategies'], equals(4));
        expect(statistics['strategyDistribution'], isNotNull);
        expect(statistics['strategyDistribution']['highFrequency'], equals(2));
        expect(statistics['strategyDistribution']['balanced'], equals(1));
        expect(statistics['strategyDistribution']['lowFrequency'], equals(1));
        expect(statistics['averageUpdateInterval'], isNotNull);
        expect(statistics['performanceMetrics'], isNotNull);
        expect(statistics['statistics'], isNotNull);
        expect(statistics['lastOptimized'], isNotNull);
      });

      test('空策略应该返回正确统计', () {
        final statistics = strategy.getStrategyStatistics();

        expect(statistics['totalStrategies'], equals(0));
        expect(statistics['strategyDistribution'], isEmpty);
        expect(statistics['averageUpdateInterval'], equals(Duration.zero));
      });
    });

    group('批量策略更新', () {
      test('应该能够批量更新策略', () async {
        final fundCodes = ['000001', '000002', '000003', '000004', '000005'];

        // 注册初始策略
        for (final fundCode in fundCodes) {
          strategy.registerFundStrategy(fundCode, CacheStrategy.balanced);
        }

        // 批量更新策略
        await strategy.batchUpdateStrategies(fundCodes);

        // 验证策略仍然存在（可能被优化为不同类型）
        for (final fundCode in fundCodes) {
          final updatedStrategy = strategy.getFundStrategy(fundCode);
          expect(updatedStrategy, isNotNull);
        }
      });

      test('批量更新应该处理空列表', () async {
        // 应该不抛出异常
        await strategy.batchUpdateStrategies([]);
      });

      test('批量更新应该处理不存在的基金', () async {
        final fundCodes = ['999999', '888888']; // 不存在的基金

        // 应该不抛出异常
        await strategy.batchUpdateStrategies(fundCodes);
      });
    });

    group('策略分析和优化', () {
      test('应该能够分析和更新策略', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        // 注册初始策略
        strategy.registerFundStrategy('000001', CacheStrategy.balanced);

        // 分析并更新策略
        await strategy.analyzeAndUpdateStrategy('000001', navData: navData);

        // 验证策略仍然存在且可能已优化
        final updatedStrategy = strategy.getFundStrategy('000001');
        expect(updatedStrategy, isNotNull);
      });

      test('应该能够处理分析错误', () async {
        // 注册策略
        strategy.registerFundStrategy('000001', CacheStrategy.balanced);

        // 分析不存在的基金（应该不抛出异常）
        await strategy.analyzeAndUpdateStrategy('999999');
      });
    });

    group('访问模式分析', () {
      test('应该能够分析访问模式', () {
        // 注册策略
        strategy.registerFundStrategy('000001', CacheStrategy.balanced);

        // 模拟访问
        for (int i = 0; i < 10; i++) {
          strategy.recordAccess('000001', 1024);
        }

        // 这里的测试需要实际的访问模式分析器实现
        // 由于当前实现中没有公开recordAccess方法，这个测试是概念性的
        final currentStrategy = strategy.getFundStrategy('000001');
        expect(currentStrategy, isNotNull);
      });
    });

    group('配置管理', () {
      test('应该能够更新配置', () {
        final newConfig = StrategyConfig(
          maxQueueSize: 2000,
          optimizationInterval: Duration(minutes: 10),
          priorityThreshold: 0.8,
          maxRecentAccesses: 100,
        );

        strategy.updateConfig(newConfig);

        // 验证配置已更新（通过检查配置是否反映在操作中）
        expect(strategy.config.maxQueueSize, equals(2000));
        expect(strategy.config.optimizationInterval,
            equals(Duration(minutes: 10)));
        expect(strategy.config.priorityThreshold, equals(0.8));
        expect(strategy.config.maxRecentAccesses, equals(100));
      });

      test('应该能够重置配置', () {
        // 修改配置
        final customConfig = StrategyConfig(
          maxQueueSize: 500,
          optimizationInterval: Duration(minutes: 1),
          priorityThreshold: 0.5,
          maxRecentAccesses: 25,
        );
        strategy.updateConfig(customConfig);

        // 重置为默认配置
        strategy.resetConfig();

        // 验证配置已重置
        expect(strategy.config.maxQueueSize, equals(1000));
        expect(
            strategy.config.optimizationInterval, equals(Duration(minutes: 5)));
        expect(strategy.config.priorityThreshold, equals(0.7));
        expect(strategy.config.maxRecentAccesses, equals(50));
      });
    });

    group('性能监控', () {
      test('应该能够提供性能指标', () async {
        // 执行一些操作
        strategy.registerFundStrategy('000001', CacheStrategy.highFrequency);
        strategy.registerFundStrategy('000002', CacheStrategy.balanced);

        await strategy.analyzeAndUpdateStrategy('000001');
        await strategy.analyzeAndUpdateStrategy('000002');

        final performanceMetrics = strategy.getPerformanceMetrics();

        expect(performanceMetrics, isNotNull);
        expect(performanceMetrics['strategyOptimizations'], isNotNull);
        expect(performanceMetrics['updateQueueSize'], isNotNull);
        expect(performanceMetrics['activeTasks'], isNotNull);
        expect(performanceMetrics['memoryUsage'], isNotNull);
      });

      test('应该能够监控更新队列', () {
        final queueSize = strategy.getUpdateQueueSize();
        expect(queueSize, greaterThanOrEqualTo(0));
      });

      test('应该能够获取活跃任务数量', () {
        final activeTasks = strategy.getActiveTasksCount();
        expect(activeTasks, greaterThanOrEqualTo(0));
      });
    });

    group('预定义策略', () {
      test('高频策略应该有正确的配置', () {
        final highFreqStrategy = CacheStrategy.highFrequency;

        expect(highFreqStrategy.name, equals('highFrequency'));
        expect(
            highFreqStrategy.updateInterval, lessThan(Duration(minutes: 15)));
        expect(highFreqStrategy.prefetchEnabled, isTrue);
        expect(highFreqStrategy.priority, greaterThan(0.7));
      });

      test('均衡策略应该有正确的配置', () {
        final balancedStrategy = CacheStrategy.balanced;

        expect(balancedStrategy.name, equals('balanced'));
        expect(balancedStrategy.updateInterval, equals(Duration(minutes: 30)));
        expect(balancedStrategy.prefetchEnabled, isTrue);
        expect(balancedStrategy.priority, equals(0.5));
      });

      test('低频策略应该有正确的配置', () {
        final lowFreqStrategy = CacheStrategy.lowFrequency;

        expect(lowFreqStrategy.name, equals('lowFrequency'));
        expect(lowFreqStrategy.updateInterval, greaterThan(Duration(hours: 1)));
        expect(lowFreqStrategy.prefetchEnabled, isFalse);
        expect(lowFreqStrategy.priority, lessThan(0.3));
      });

      test('自适应策略应该有正确的配置', () {
        final adaptiveStrategy = CacheStrategy.adaptive;

        expect(adaptiveStrategy.name, equals('adaptive'));
        expect(adaptiveStrategy.updateInterval, equals(Duration(minutes: 30)));
        expect(adaptiveStrategy.prefetchEnabled, isTrue);
        expect(adaptiveStrategy.compressionEnabled, isTrue);
        expect(adaptiveStrategy.priority, equals(0.6));
      });
    });

    group('错误处理', () {
      test('应该能够处理无效的基金代码', () {
        final shouldUpdate = strategy.shouldUpdate('');
        expect(shouldUpdate, isFalse);

        strategy.adjustUpdateFrequency('', increase: true);
        // 应该不抛出异常
      });

      test('应该能够处理null值', () {
        final shouldUpdate = strategy.shouldUpdate('000001', lastUpdate: null);
        expect(shouldUpdate, isFalse);
      });

      test('应该能够处理配置错误', () {
        // 设置无效配置
        final invalidConfig = StrategyConfig(
          maxQueueSize: -1, // 无效值
          optimizationInterval: Duration.zero,
          priorityThreshold: 2.0, // 超出范围
          maxRecentAccesses: -10,
        );

        strategy.updateConfig(invalidConfig);
        // 应该不抛出异常，系统应该使用默认值或修正值
      });
    });

    group('资源管理', () {
      test('应该能够正确释放资源', () async {
        // 注册一些策略
        for (int i = 0; i < 10; i++) {
          strategy.registerFundStrategy(
              '00000${i.toString().padLeft(3, '0')}', CacheStrategy.balanced);
        }

        // 释放资源
        await strategy.dispose();

        // 验证资源已释放
        final statistics = strategy.getStrategyStatistics();
        expect(statistics['totalStrategies'], equals(0));
      });

      test('重复释放应该是安全的', () async {
        await strategy.dispose();
        await strategy.dispose(); // 应该不抛出异常
      });
    });

    group('并发安全', () {
      test('应该能够处理并发策略注册', () async {
        final futures = <Future>[];

        for (int i = 0; i < 20; i++) {
          futures.add(Future(() {
            final fundCode = '00000${i.toString().padLeft(3, '0')}';
            strategy.registerFundStrategy(fundCode, CacheStrategy.balanced);
          }));
        }

        await Future.wait(futures);

        final statistics = strategy.getStrategyStatistics();
        expect(statistics['totalStrategies'], equals(20));
      });

      test('应该能够处理并发频率调整', () async {
        final fundCode = '000001';
        strategy.registerFundStrategy(fundCode, CacheStrategy.balanced);

        final futures = <Future>[];

        for (int i = 0; i < 10; i++) {
          futures.add(Future(() {
            strategy.adjustUpdateFrequency(fundCode, increase: i % 2 == 0);
          }));
        }

        await Future.wait(futures);

        // 验证策略仍然存在
        final adjustedStrategy = strategy.getFundStrategy(fundCode);
        expect(adjustedStrategy, isNotNull);
      });
    });
  });
}
