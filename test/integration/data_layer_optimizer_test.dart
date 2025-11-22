import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/core/data/optimization/data_layer_optimizer.dart';

void main() {
  group('DataLayerOptimizer 配置测试', () {
    test('应该支持默认配置', () {
      final defaultConfig = DataLayerOptimizationConfig.defaultConfig();
      expect(defaultConfig.optimizationInterval, const Duration(minutes: 10));
      expect(defaultConfig.minCacheHitRate, 0.7);
      expect(defaultConfig.maxResponseTime, 100.0);
      expect(defaultConfig.maxMemoryCacheSize, 2000);
    });

    test('应该支持激进配置', () {
      final aggressiveConfig = DataLayerOptimizationConfig.aggressive();
      expect(aggressiveConfig.optimizationInterval, const Duration(minutes: 5));
      expect(aggressiveConfig.minCacheHitRate, 0.8);
      expect(aggressiveConfig.maxResponseTime, 50.0);
      expect(aggressiveConfig.maxMemoryCacheSize, 1000);
    });

    test('应该支持保守配置', () {
      final conservativeConfig = DataLayerOptimizationConfig.conservative();
      expect(
          conservativeConfig.optimizationInterval, const Duration(minutes: 30));
      expect(conservativeConfig.minCacheHitRate, 0.6);
      expect(conservativeConfig.maxResponseTime, 200.0);
      expect(conservativeConfig.maxMemoryCacheSize, 5000);
    });

    test('应该支持自定义配置', () {
      const customConfig = DataLayerOptimizationConfig(
        optimizationInterval: Duration(minutes: 15),
        minCacheHitRate: 0.85,
        maxResponseTime: 75.0,
        maxMemoryCacheSize: 1500,
        targetMemoryCacheSize: 750,
        dataRetentionPeriod: Duration(hours: 18),
        maxTrendPoints: 75,
        maxOptimizationHistory: 40,
      );

      expect(customConfig.optimizationInterval, const Duration(minutes: 15));
      expect(customConfig.minCacheHitRate, 0.85);
      expect(customConfig.maxResponseTime, 75.0);
      expect(customConfig.maxMemoryCacheSize, 1500);
      expect(customConfig.targetMemoryCacheSize, 750);
      expect(customConfig.dataRetentionPeriod, const Duration(hours: 18));
      expect(customConfig.maxTrendPoints, 75);
      expect(customConfig.maxOptimizationHistory, 40);
    });
  });

  group('DataLayerOptimizationConfig 数据类测试', () {
    test('配置应该具有正确的默认值', () {
      const config = DataLayerOptimizationConfig();
      expect(config.optimizationInterval, const Duration(minutes: 10));
      expect(config.minCacheHitRate, 0.7);
      expect(config.maxResponseTime, 100.0);
      expect(config.maxMemoryCacheSize, 2000);
      expect(config.targetMemoryCacheSize, 1000);
      expect(config.dataRetentionPeriod, const Duration(hours: 24));
      expect(config.maxTrendPoints, 100);
      expect(config.maxOptimizationHistory, 50);
    });
  });

  group('OptimizationSuggestion 数据类测试', () {
    test('优化建议应该包含正确的信息', () {
      const suggestion = OptimizationSuggestion(
        type: 'cache_hit_rate',
        priority: 'high',
        description: '缓存命中率较低，建议预热常用数据',
        expectedImprovement: '提升15-30%命中率',
      );

      expect(suggestion.type, 'cache_hit_rate');
      expect(suggestion.priority, 'high');
      expect(suggestion.description, '缓存命中率较低，建议预热常用数据');
      expect(suggestion.expectedImprovement, '提升15-30%命中率');
    });

    test('应该支持不同类型的优化建议', () {
      final suggestions = [
        const OptimizationSuggestion(
          type: 'cache_hit_rate',
          priority: 'high',
          description: '缓存命中率优化',
          expectedImprovement: '提升性能',
        ),
        const OptimizationSuggestion(
          type: 'response_time',
          priority: 'medium',
          description: '响应时间优化',
          expectedImprovement: '减少延迟',
        ),
        const OptimizationSuggestion(
          type: 'memory_usage',
          priority: 'low',
          description: '内存使用优化',
          expectedImprovement: '节省内存',
        ),
        const OptimizationSuggestion(
          type: 'health_issues',
          priority: 'critical',
          description: '健康问题修复',
          expectedImprovement: '恢复稳定',
        ),
      ];

      expect(suggestions, hasLength(4));

      final types = suggestions.map((s) => s.type).toList();
      expect(types, contains('cache_hit_rate'));
      expect(types, contains('response_time'));
      expect(types, contains('memory_usage'));
      expect(types, contains('health_issues'));

      final priorities = suggestions.map((s) => s.priority).toList();
      expect(priorities, contains('high'));
      expect(priorities, contains('medium'));
      expect(priorities, contains('low'));
      expect(priorities, contains('critical'));
    });
  });

  group('OptimizationResult 数据类测试', () {
    test('优化结果应该包含执行信息', () {
      const result = OptimizationResult(
        optimizationsPerformed: ['cache_hit_rate', 'response_time'],
        duration: Duration(milliseconds: 150),
        success: true,
        errors: [],
      );

      expect(result.optimizationsPerformed, hasLength(2));
      expect(result.optimizationsPerformed, contains('cache_hit_rate'));
      expect(result.optimizationsPerformed, contains('response_time'));
      expect(result.duration, const Duration(milliseconds: 150));
      expect(result.success, isTrue);
      expect(result.errors, isEmpty);
    });

    test('失败的优化结果应该包含错误信息', () {
      const result = OptimizationResult(
        optimizationsPerformed: [],
        duration: Duration(milliseconds: 50),
        success: false,
        errors: ['缓存清理失败: 权限不足'],
      );

      expect(result.optimizationsPerformed, isEmpty);
      expect(result.duration, const Duration(milliseconds: 50));
      expect(result.success, isFalse);
      expect(result.errors, hasLength(1));
      expect(result.errors.first, '缓存清理失败: 权限不足');
    });

    test('部分成功的优化结果应该包含成功和失败信息', () {
      const result = OptimizationResult(
        optimizationsPerformed: ['cache_hit_rate'],
        duration: Duration(milliseconds: 200),
        success: false,
        errors: ['response_time: 网络超时'],
      );

      expect(result.optimizationsPerformed, hasLength(1));
      expect(result.optimizationsPerformed.first, 'cache_hit_rate');
      expect(result.duration, const Duration(milliseconds: 200));
      expect(result.success, isFalse);
      expect(result.errors, hasLength(1));
      expect(result.errors.first, 'response_time: 网络超时');
    });
  });

  group('OptimizationRecord 数据类测试', () {
    test('优化记录应该包含完整信息', () {
      final timestamp = DateTime.now();
      final record = OptimizationRecord(
        optimizations: ['cache_hit_rate'],
        duration: const Duration(milliseconds: 100),
        success: true,
        timestamp: timestamp,
      );

      expect(record.optimizations, hasLength(1));
      expect(record.optimizations.first, 'cache_hit_rate');
      expect(record.duration, const Duration(milliseconds: 100));
      expect(record.success, isTrue);
      expect(record.timestamp, timestamp);
      expect(record.error, isNull);
    });

    test('失败的优化记录应该包含错误信息', () {
      final timestamp = DateTime.now();
      final record = OptimizationRecord(
        optimizations: ['memory_usage'],
        duration: const Duration(milliseconds: 75),
        success: false,
        timestamp: timestamp,
        error: '内存不足',
      );

      expect(record.optimizations, hasLength(1));
      expect(record.optimizations.first, 'memory_usage');
      expect(record.duration, const Duration(milliseconds: 75));
      expect(record.success, isFalse);
      expect(record.timestamp, timestamp);
      expect(record.error, '内存不足');
    });
  });

  group('PerformanceTrend 数据类测试', () {
    test('性能趋势应该正确记录数据点', () {
      final trend = PerformanceTrend(metric: 'cache_hit_rate');
      final timestamp = DateTime.now();

      expect(trend.metric, 'cache_hit_rate');
      expect(trend.points, isEmpty);

      // 添加数据点
      trend.addPoint(0.8, timestamp);
      expect(trend.points, hasLength(1));
      expect(trend.points.first.value, 0.8);
      expect(trend.points.first.timestamp, timestamp);

      // 添加更多数据点
      trend.addPoint(0.85, timestamp.add(const Duration(seconds: 1)));
      trend.addPoint(0.9, timestamp.add(const Duration(seconds: 2)));

      expect(trend.points, hasLength(3));
      expect(trend.points.last.value, 0.9);
    });

    test('趋势方向应该基于数据点计算', () {
      final trend = PerformanceTrend(metric: 'response_time');
      final baseTime = DateTime.now();

      // 添加递增的数据点（性能恶化）
      trend.addPoint(50.0, baseTime);
      trend.addPoint(75.0, baseTime.add(const Duration(seconds: 1)));
      trend.addPoint(100.0, baseTime.add(const Duration(seconds: 2)));

      expect(trend.getDirection(), TrendDirection.increasing);

      // 清空并添加递减的数据点（性能改善）
      trend.points.clear();
      trend.addPoint(100.0, baseTime);
      trend.addPoint(75.0, baseTime.add(const Duration(seconds: 1)));
      trend.addPoint(50.0, baseTime.add(const Duration(seconds: 2)));

      expect(trend.getDirection(), TrendDirection.decreasing);
    });

    test('稳定数据应该返回稳定趋势', () {
      final trend = PerformanceTrend(metric: 'memory_usage');
      final baseTime = DateTime.now();

      // 添加非常相似的数据点（变化极小）
      trend.addPoint(500.0, baseTime);
      trend.addPoint(500.01, baseTime.add(const Duration(seconds: 1)));
      trend.addPoint(500.005, baseTime.add(const Duration(seconds: 2)));

      expect(trend.getDirection(), TrendDirection.stable);
    });

    test('数据点不足时应该返回稳定趋势', () {
      final trend = PerformanceTrend(metric: 'test_metric');

      // 空数据
      expect(trend.getDirection(), TrendDirection.stable);

      // 单个数据点
      trend.addPoint(1.0, DateTime.now());
      expect(trend.getDirection(), TrendDirection.stable);
    });
  });

  group('TrendPoint 数据类测试', () {
    test('趋势点应该正确存储值和时间戳', () {
      final timestamp = DateTime.now();
      final point = TrendPoint(
        value: 0.85,
        timestamp: timestamp,
      );

      expect(point.value, 0.85);
      expect(point.timestamp, timestamp);
    });
  });

  group('TrendDirection 枚举测试', () {
    test('应该包含所有期望的趋势方向', () {
      const directions = TrendDirection.values;
      expect(directions, hasLength(3));
      expect(directions, contains(TrendDirection.increasing));
      expect(directions, contains(TrendDirection.decreasing));
      expect(directions, contains(TrendDirection.stable));
    });
  });

  // OptimizationReport 测试需要复杂的数据对象，暂时跳过
// 在实际项目中，需要完整的依赖注入来测试完整的报告功能
}
