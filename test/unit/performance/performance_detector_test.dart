import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:jisu_fund_analyzer/src/core/performance/performance_detector.dart';

void main() {
  group('性能检测器测试', () {
    late SmartPerformanceDetector detector;

    setUp(() {
      detector = SmartPerformanceDetector.instance;
      detector.clearCache();
    });

    tearDown(() {
      detector.dispose();
    });

    test('单例模式测试', () {
      final detector1 = SmartPerformanceDetector.instance;
      final detector2 = SmartPerformanceDetector.instance;
      expect(identical(detector1, detector2), true);
    });

    test('性能等级扩展测试', () {
      expect(PerformanceLevel.excellent.displayName, equals('优秀'));
      expect(PerformanceLevel.good.displayName, equals('良好'));
      expect(PerformanceLevel.fair.displayName, equals('一般'));
      expect(PerformanceLevel.poor.displayName, equals('较差'));

      expect(PerformanceLevel.excellent.shouldEnableAnimations, true);
      expect(PerformanceLevel.poor.shouldEnableAnimations, false);

      expect(PerformanceLevel.excellent.recommendedAnimationLevel, 3);
      expect(PerformanceLevel.poor.recommendedAnimationLevel, 0);
    });

    test('性能检测基本功能测试', () async {
      final result = await detector.detectPerformance();

      expect(result.score, greaterThanOrEqualTo(0));
      expect(result.score, lessThanOrEqualTo(100));
      expect(result.metrics.isNotEmpty, true);
      expect(result.recommendations.isNotEmpty, true);
      expect(
          result.timestamp
              .isBefore(DateTime.now().add(const Duration(seconds: 1))),
          true);
    });

    test('缓存功能测试', () async {
      final startTime = DateTime.now();
      final result1 = await detector.detectPerformance();
      final firstDetectionTime = DateTime.now();

      // 第二次检测应该使用缓存
      final result2 = await detector.detectPerformance();
      final secondDetectionTime = DateTime.now();

      expect(result1.score, equals(result2.score));
      expect(result1.level, equals(result2.level));

      // 验证缓存生效（第二次检测应该很快）
      final firstDetectionDuration = firstDetectionTime.difference(startTime);
      final secondDetectionDuration =
          secondDetectionTime.difference(firstDetectionTime);

      debugPrint('首次检测耗时: ${firstDetectionDuration.inMilliseconds}ms');
      debugPrint('缓存检测耗时: ${secondDetectionDuration.inMilliseconds}ms');

      // 缓存检测应该快很多
      expect(secondDetectionDuration.inMilliseconds,
          lessThan(firstDetectionDuration.inMilliseconds));
    });

    test('强制刷新测试', () async {
      final result1 = await detector.detectPerformance();
      final result2 = await detector.detectPerformance(forceRefresh: true);

      // 强制刷新应该重新检测
      expect(result1.timestamp.isBefore(result2.timestamp), true);
    });

    test('监控状态测试', () {
      final status = detector.getMonitoringStatus();

      expect(status['isMonitoring'], false);
      expect(status['hasLastResult'], false);
      expect(status['listenersCount'], 0);
    });

    test('自适应管理器测试', () {
      final manager = PerformanceAdaptiveManager.instance;
      final config = manager.getRecommendedPerformanceConfig();

      expect(config.containsKey('level'), true);
      expect(config.containsKey('animationsEnabled'), true);
      expect(config.containsKey('highQualityEnabled'), true);
      expect(config.containsKey('glassmorphismLevel'), true);

      manager.dispose();
    });

    test('性能指标验证测试', () async {
      final result = await detector.detectPerformance();

      // 验证必要的指标存在
      expect(result.metrics.containsKey('cpu_score'), true);
      expect(result.metrics.containsKey('memory_score'), true);
      expect(result.metrics.containsKey('gpu_score'), true);

      // 验证指标值在合理范围内
      final cpuScore = result.metrics['cpu_score'] as double;
      final memoryScore = result.metrics['memory_score'] as double;
      final gpuScore = result.metrics['gpu_score'] as double;

      expect(cpuScore, greaterThanOrEqualTo(0));
      expect(cpuScore, lessThanOrEqualTo(100));
      expect(memoryScore, greaterThanOrEqualTo(0));
      expect(memoryScore, lessThanOrEqualTo(100));
      expect(gpuScore, greaterThanOrEqualTo(0));
      expect(gpuScore, lessThanOrEqualTo(100));
    });
  });
}
