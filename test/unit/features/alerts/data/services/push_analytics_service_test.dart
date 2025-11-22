import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:jisu_fund_analyzer/src/features/alerts/data/services/push_analytics_service.dart';

void main() {
  group('PushAnalyticsService', () {
    late PushAnalyticsService analyticsService;

    setUp(() async {
      // 初始化Hive测试环境
      try {
        await Hive.initFlutter();
      } catch (e) {
        Hive.init('test_temp');
      }

      // 获取服务实例（单例模式）
      analyticsService = PushAnalyticsService.instance;
    });

    tearDown(() async {
      await Hive.close();
    });

    group('初始化测试', () {
      test('应该成功初始化', () async {
        await analyticsService.initialize();
        expect(analyticsService.isInitialized, isTrue);
      });

      test('多次初始化应该安全', () async {
        await analyticsService.initialize();
        await analyticsService.initialize(); // 第二次调用
        expect(analyticsService.isInitialized, isTrue);
      });

      test('服务应该是单例', () {
        final anotherInstance = PushAnalyticsService.instance;
        expect(identical(analyticsService, anotherInstance), isTrue);
      });
    });

    group('基本功能测试', () {
      test('应该生成推送效果报告', () async {
        await analyticsService.initialize();

        final report = await analyticsService.getEffectivenessReport(days: 7);

        expect(report, isNotNull);
        expect(report.periodInDays, equals(7));
        expect(report.statistics, isNotNull);
        expect(report.dailyStats, isNotNull);
        expect(report.trends, isNotNull);
        expect(report.insights, isNotNull);
        expect(report.recommendations, isNotNull);
        expect(report.behaviorAnalysis, isNotNull);
        expect(report.contentAnalysis, isNotNull);
      });

      test('应该生成用户参与分析', () async {
        await analyticsService.initialize();

        final analysis =
            await analyticsService.getUserEngagementAnalysis(days: 30);

        expect(analysis, isNotNull);
        expect(analysis.periodInDays, equals(30));
        expect(analysis.totalUsers, greaterThanOrEqualTo(0));
        expect(analysis.activeUsers, greaterThanOrEqualTo(0));
      });

      test('应该生成内容效果分析', () async {
        await analyticsService.initialize();

        final analysis =
            await analyticsService.getContentEffectivenessAnalysis(days: 30);

        expect(analysis, isNotNull);
        expect(analysis.periodInDays, equals(30));
      });

      test('应该生成最佳时间推荐', () async {
        await analyticsService.initialize();

        final recommendations =
            await analyticsService.getOptimalTimingRecommendations(days: 30);

        expect(recommendations, isNotNull);
        expect(recommendations.periodInDays, equals(30));
      });
    });

    group('预测功能测试', () {
      test('应该预测推送效果', () async {
        await analyticsService.initialize();

        final prediction = await analyticsService.predictPushEffectiveness(
          pushType: 'market_change',
          priority: 'high',
          title: '测试标题',
          content: '测试推送内容',
        );

        expect(prediction, isNotNull);
        expect(prediction.predictedClickRate, greaterThanOrEqualTo(0.0));
        expect(prediction.predictedClickRate, lessThanOrEqualTo(1.0));
        expect(prediction.predictedReadRate, greaterThanOrEqualTo(0.0));
        expect(prediction.predictedReadRate, lessThanOrEqualTo(1.0));
      });
    });

    group('错误处理和边界条件测试', () {
      test('未初始化时应该返回空结果', () async {
        // 创建新的服务实例
        final newService = PushAnalyticsService.instance;

        // 即使没有显式初始化，也应该能够正常工作
        expect(newService.isInitialized, isFalse);

        final report = await newService.getEffectivenessReport(days: 7);
        expect(report, isNotNull);
      });

      test('应该处理无效的天数参数', () async {
        await analyticsService.initialize();

        // 测试负数天数
        final report1 = await analyticsService.getEffectivenessReport(days: -1);
        expect(report1, isNotNull);

        // 测试零天数
        final report2 = await analyticsService.getEffectivenessReport(days: 0);
        expect(report2, isNotNull);

        // 测试很大的天数
        final report3 =
            await analyticsService.getEffectivenessReport(days: 1000);
        expect(report3, isNotNull);
      });

      test('应该处理空数据情况', () async {
        await analyticsService.initialize();

        // 分析很短的时间范围，可能没有数据
        final report = await analyticsService.getEffectivenessReport(days: 1);
        expect(report, isNotNull);
        expect(report.statistics.totalPushes, equals(0));
      });

      test('应该处理极长时间范围', () async {
        await analyticsService.initialize();

        // 分析很长的时间范围
        final report = await analyticsService.getEffectivenessReport(days: 365);
        expect(report, isNotNull);
        expect(report.statistics.totalPushes, greaterThanOrEqualTo(0));
      });
    });

    tearDownAll(() async {
      // 清理资源
      await analyticsService.dispose();
    });
  });
}
