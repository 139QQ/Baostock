import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:jisu_fund_analyzer/src/features/alerts/data/processors/market_change_detector.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/processors/push_priority_manager.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/managers/push_history_manager.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/market_change_event.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/push_preferences.dart'
    hide PushPriority;
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/change_category.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/change_severity.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/push_priority.dart';

void main() {
  group('端到端推送流程测试', () {
    late MarketChangeDetector changeDetector;
    late PushPriorityManager priorityManager;
    late PushHistoryManager historyManager;

    setUpAll(() async {
      // 初始化Hive测试环境
      try {
        await Hive.initFlutter();
      } catch (e) {
        Hive.init('test_temp');
      }
    });

    setUp(() async {
      // 初始化所有组件
      changeDetector = MarketChangeDetector();
      priorityManager = PushPriorityManager();
      historyManager = PushHistoryManager.instance;

      await historyManager.initialize();
    });

    tearDown(() async {
      // 清理测试数据
      try {
        await historyManager.cleanupExpiredData(retentionPeriod: Duration.zero);
      } catch (e) {
        // 忽略清理错误
      }
    });

    tearDownAll(() async {
      await Hive.close();
    });

    group('完整推送流程测试', () {
      test('应该完成从市场变化检测到推送历史记录的完整流程', () async {
        // 1. 创建市场变化事件
        final changeEvent = MarketChangeEvent(
          id: 'test-event-1',
          type: MarketChangeType.fundNav,
          entityId: '000001',
          entityName: '华夏成长混合',
          category: ChangeCategory.priceChange,
          severity: ChangeSeverity.high,
          importance: 85.0,
          changeRate: 0.0473, // 4.73% 变化
          currentValue: '2.456',
          previousValue: '2.345',
          timestamp: DateTime.now(),
          metadata: {'source': 'test', 'version': '1.0'},
          relatedFunds: ['000001'],
        );

        // 2. 计算推送优先级
        final pushPriority =
            await priorityManager.calculatePriority(changeEvent);
        expect(pushPriority.priority, equals(PushPriorityLevel.high));
        expect(pushPriority.score, greaterThan(80.0));

        // 3. 创建用户偏好设置
        final userPreferences = UserPreferences(
          userId: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 4. 记录推送历史（模拟推送完成后的记录）
        final historyRecorded = await historyManager.recordPushHistory(
          id: 'test-push-1',
          pushType: 'market_change',
          priority: pushPriority.priority.name,
          title: '${changeEvent.entityName} 价格变化提醒',
          content:
              '${changeEvent.entityName} 净值${changeEvent.trend} ${changeEvent.changeDescription}，当前净值：${changeEvent.currentValue}',
          channel: 'notification',
          relatedEventIds: [changeEvent.id],
          relatedFundCodes: [changeEvent.entityId],
          processingTimeMs: 150,
          personalizationScore: 0.85,
        );

        expect(historyRecorded, isTrue);

        // 5. 验证推送历史记录
        final recordedHistory =
            await historyManager.getPushHistory('test-push-1');
        expect(recordedHistory, isNotNull);
        expect(recordedHistory!.title, contains('华夏成长混合'));
        expect(recordedHistory.content, contains('4.73%'));
        expect(recordedHistory.priority, equals('high'));
        expect(recordedHistory.relatedFundCodes, contains('000001'));
      });

      test('应该处理多个市场变化的批量推送流程', () async {
        // 创建多个市场变化事件
        final changeEvents = [
          MarketChangeEvent(
            id: 'batch-event-1',
            type: MarketChangeType.fundNav,
            entityId: '000001',
            entityName: '华夏成长混合',
            category: ChangeCategory.priceChange,
            severity: ChangeSeverity.high,
            importance: 85.0,
            changeRate: 0.0473,
            currentValue: '2.456',
            previousValue: '2.345',
            timestamp: DateTime.now(),
            metadata: {'batch': 'test'},
          ),
          MarketChangeEvent(
            id: 'batch-event-2',
            type: MarketChangeType.fundNav,
            entityId: '110022',
            entityName: '易方达消费行业',
            category: ChangeCategory.priceChange,
            severity: ChangeSeverity.medium,
            importance: 65.0,
            changeRate: 0.0234,
            currentValue: '1.234',
            previousValue: '1.206',
            timestamp: DateTime.now(),
            metadata: {'batch': 'test'},
          ),
          MarketChangeEvent(
            id: 'batch-event-3',
            type: MarketChangeType.fundNav,
            entityId: '161725',
            entityName: '招商中证白酒',
            category: ChangeCategory.priceChange,
            severity: ChangeSeverity.medium,
            importance: 60.0,
            changeRate: -0.0156,
            currentValue: '0.987',
            previousValue: '1.003',
            timestamp: DateTime.now(),
            metadata: {'batch': 'test'},
          ),
        ];

        final recordedHistory = <String>[];
        final priorities = <PushPriority>[];

        for (int i = 0; i < changeEvents.length; i++) {
          final changeEvent = changeEvents[i];

          // 计算优先级
          final priority = await priorityManager.calculatePriority(changeEvent);
          priorities.add(priority);

          // 记录历史
          final historyId = 'batch-push-${i + 1}';
          final historyResult = await historyManager.recordPushHistory(
            id: historyId,
            pushType: 'market_change',
            priority: priority.priority.name,
            title:
                '${changeEvent.entityName} ${changeEvent.categoryDescription}',
            content:
                '${changeEvent.entityName} ${changeEvent.trend} ${changeEvent.changeDescription}',
            channel: 'notification',
            relatedEventIds: [changeEvent.id],
            relatedFundCodes: [changeEvent.entityId],
            processingTimeMs: 120,
            personalizationScore: priority.score / 100.0,
          );

          if (historyResult) {
            recordedHistory.add(historyId);
          }
        }

        // 验证批量推送结果
        expect(recordedHistory.length, equals(3));
        expect(priorities.length, equals(3));

        // 验证不同优先级的分布
        final highPriorityCount = priorities
            .where((p) => p.priority == PushPriorityLevel.high)
            .length;
        final mediumPriorityCount = priorities
            .where((p) => p.priority == PushPriorityLevel.medium)
            .length;

        expect(highPriorityCount, equals(1)); // 只有4.73%变化的那个
        expect(mediumPriorityCount, equals(2)); // 其他两个

        // 验证推送历史统计
        final stats = await historyManager.getPushStatistics();
        expect(stats.totalPushes, greaterThanOrEqualTo(3));
      });

      test('应该正确处理不同严重程度的变化事件', () async {
        final severityTests = [
          {
            'severity': ChangeSeverity.high,
            'changeRate': 0.08,
            'expectedLevel': PushPriorityLevel.high,
          },
          {
            'severity': ChangeSeverity.medium,
            'changeRate': 0.03,
            'expectedLevel': PushPriorityLevel.medium,
          },
          {
            'severity': ChangeSeverity.low,
            'changeRate': 0.005,
            'expectedLevel': PushPriorityLevel.low,
          },
        ];

        for (int i = 0; i < severityTests.length; i++) {
          final test = severityTests[i];
          final changeEvent = MarketChangeEvent(
            id: 'severity-test-$i',
            type: MarketChangeType.fundNav,
            entityId: 'TEST001',
            entityName: '测试基金',
            category: ChangeCategory.priceChange,
            severity: test['severity'] as ChangeSeverity,
            importance: (test['changeRate'] as double) * 1000,
            changeRate: test['changeRate'] as double,
            currentValue: '1.000',
            previousValue: '${1.0 - (test['changeRate'] as double)}',
            timestamp: DateTime.now(),
            metadata: {'severity_test': true},
          );

          final priority = await priorityManager.calculatePriority(changeEvent);
          expect(priority.priority, equals(test['expectedLevel']));

          // 记录历史
          final historyId = 'severity-push-$i';
          final historyResult = await historyManager.recordPushHistory(
            id: historyId,
            pushType: 'market_change',
            priority: priority.priority.name,
            title: '严重程度测试 - ${test['severity']}',
            content: '测试变化率：${test['changeRate']}',
            channel: 'notification',
            relatedEventIds: [changeEvent.id],
            relatedFundCodes: [changeEvent.entityId],
          );

          expect(historyResult, isTrue);
        }

        // 验证历史记录
        final stats = await historyManager.getPushStatistics();
        expect(stats.totalPushes, greaterThanOrEqualTo(3));
      });
    });

    group('性能和可靠性测试', () {
      test('应该在指定时间内完成推送流程', () async {
        final startTime = DateTime.now();

        // 模拟推送流程
        final changeEvent = MarketChangeEvent(
          id: 'perf-test',
          type: MarketChangeType.fundNav,
          entityId: 'PERF001',
          entityName: '性能测试基金',
          category: ChangeCategory.priceChange,
          severity: ChangeSeverity.high,
          importance: 90.0,
          changeRate: 0.05,
          currentValue: '2.500',
          previousValue: '2.381',
          timestamp: DateTime.now(),
          metadata: {'performance_test': true},
        );

        final priority = await priorityManager.calculatePriority(changeEvent);

        await historyManager.recordPushHistory(
          id: 'perf-push',
          pushType: 'market_change',
          priority: priority.priority.name,
          title: '性能测试推送',
          content: '性能测试 - ${changeEvent.changeDescription}',
          channel: 'notification',
          relatedEventIds: [changeEvent.id],
          relatedFundCodes: [changeEvent.entityId],
          processingTimeMs: 50,
        );

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // 整个推送流程应该在5秒内完成（技术要求：推送通知延迟 < 10秒）
        expect(duration.inMilliseconds, lessThan(5000));
      });

      test('应该正确处理并发推送记录', () async {
        const concurrentCount = 10;
        final futures = <Future<bool>>[];

        // 创建多个并发推送记录请求
        for (int i = 0; i < concurrentCount; i++) {
          futures.add(historyManager.recordPushHistory(
            id: 'concurrent-push-$i',
            pushType: 'market_change',
            priority: 'medium',
            title: '并发测试推送 $i',
            content: '并发测试内容 $i',
            channel: 'notification',
            relatedFundCodes: ['CONCURRENT$i'],
            processingTimeMs: 100,
          ));
        }

        // 等待所有推送记录完成
        final results = await Future.wait(futures);

        // 验证所有推送记录都成功
        expect(results.length, equals(concurrentCount));
        expect(results.every((result) => result), isTrue);

        // 验证历史记录完整性
        final stats = await historyManager.getPushStatistics();
        expect(stats.totalPushes, greaterThanOrEqualTo(concurrentCount));
      });
    });

    group('数据完整性测试', () {
      test('应该保持推送数据的一致性和完整性', () async {
        final originalEvent = MarketChangeEvent(
          id: 'consistency-test',
          type: MarketChangeType.marketIndex,
          entityId: '000001',
          entityName: '上证指数',
          category: ChangeCategory.trendChange,
          severity: ChangeSeverity.high,
          importance: 95.0,
          changeRate: 0.0256,
          currentValue: '3125.67',
          previousValue: '3047.58',
          timestamp: DateTime.now(),
          metadata: {'test': 'consistency', 'version': '1.0'},
          relatedFunds: ['000001', '110022', '161725'],
        );

        final priority = await priorityManager.calculatePriority(originalEvent);

        // 执行推送历史记录
        final historyResult = await historyManager.recordPushHistory(
          id: 'consistency-push',
          pushType: 'market_change',
          priority: priority.priority.name,
          title:
              '${originalEvent.entityName} ${originalEvent.categoryDescription}',
          content:
              '${originalEvent.entityName} ${originalEvent.trend} ${originalEvent.changeDescription}',
          channel: 'notification',
          relatedEventIds: [originalEvent.id],
          relatedFundCodes: originalEvent.relatedFunds,
          relatedIndexCodes: [originalEvent.entityId],
          metadata: originalEvent.metadata,
          processingTimeMs: 200,
          personalizationScore: 0.95,
        );

        expect(historyResult, isTrue);

        // 验证数据完整性
        final recordedHistory =
            await historyManager.getPushHistory('consistency-push');
        expect(recordedHistory, isNotNull);
        expect(recordedHistory!.relatedFundCodes,
            equals(originalEvent.relatedFunds));
        expect(recordedHistory.relatedIndexCodes,
            equals([originalEvent.entityId]));
        expect(recordedHistory.metadata, equals(originalEvent.metadata));
        expect(recordedHistory.pushType, equals('market_change'));
        expect(recordedHistory.personalizationScore, equals(0.95));
        expect(recordedHistory.processingTimeMs, equals(200));
      });

      test('应该正确处理历史数据的查询和统计', () async {
        // 创建一些测试数据
        final testEvents = [
          {
            'id': 'query-test-1',
            'type': 'fund_update',
            'priority': 'high',
            'fundCode': '000001',
          },
          {
            'id': 'query-test-2',
            'type': 'market_change',
            'priority': 'medium',
            'fundCode': '110022',
          },
          {
            'id': 'query-test-3',
            'type': 'fund_update',
            'priority': 'low',
            'fundCode': '161725',
          },
        ];

        // 记录测试数据
        for (final event in testEvents) {
          await historyManager.recordPushHistory(
            id: event['id'] as String,
            pushType: event['type'] as String,
            priority: event['priority'] as String,
            title: '查询测试 - ${event['fundCode']}',
            content: '查询测试内容',
            channel: 'notification',
            relatedFundCodes: [event['fundCode'] as String],
          );
        }

        // 测试按类型查询
        final fundUpdates =
            await historyManager.getPushHistoryByType('fund_update');
        expect(fundUpdates.length, equals(2));

        final marketChanges =
            await historyManager.getPushHistoryByType('market_change');
        expect(marketChanges.length, equals(1));

        // 测试按优先级查询
        final highPriority =
            await historyManager.getPushHistoryByPriority('high');
        expect(highPriority.length, equals(1));

        final mediumPriority =
            await historyManager.getPushHistoryByPriority('medium');
        expect(mediumPriority.length, equals(1));

        final lowPriority =
            await historyManager.getPushHistoryByPriority('low');
        expect(lowPriority.length, equals(1));

        // 测试统计信息
        final stats = await historyManager.getPushStatistics();
        expect(stats.totalPushes, greaterThanOrEqualTo(3));

        // 测试时间范围查询
        final now = DateTime.now();
        final recentRecords = await historyManager.getPushHistoryByTimeRange(
          startTime: now.subtract(const Duration(minutes: 5)),
          endTime: now.add(const Duration(minutes: 5)),
        );
        expect(recentRecords.length, equals(3));
      });
    });
  });
}
