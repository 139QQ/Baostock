import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/features/alerts/data/models/market_change_event.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/change_category.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/change_severity.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/processors/change_impact_assessor.dart';

void main() {
  group('Task 3 核心功能验证', () {
    late MarketChangeEvent testEvent;
    late ChangeImpactAssessor impactAssessor;

    setUp(() {
      impactAssessor = ChangeImpactAssessor();

      testEvent = MarketChangeEvent(
        id: 'test-event-1',
        type: MarketChangeType.marketIndex,
        entityId: 'SH000001',
        entityName: '上证指数',
        category: ChangeCategory.priceChange,
        severity: ChangeSeverity.medium,
        importance: 75.0,
        changeRate: 2.5,
        currentValue: '3000.0',
        previousValue: '2926.83',
        timestamp: DateTime.now(),
        metadata: {'source': 'test'},
      );
    });

    test('ChangeImpactAssessor 可以实例化并执行基础评估', () async {
      expect(impactAssessor, isNotNull);

      final impact = await impactAssessor.assessImpact(
        testEvent,
        relatedFunds: ['fund1', 'fund2'],
        userPortfolioExposure: '10.5',
      );

      expect(impact, isNotNull);
      expect(impact.eventId, equals('test-event-1'));
      expect(impact.impactScore, greaterThan(0.0));
      expect(impact.impactScore, lessThanOrEqualTo(100.0));
      expect(impact.affectedFunds, contains('fund1'));
      expect(impact.affectedFunds, contains('fund2'));
    });

    test('MarketChangeEvent 模型完整性', () {
      expect(testEvent.id, equals('test-event-1'));
      expect(testEvent.type, equals(MarketChangeType.marketIndex));
      expect(testEvent.entityId, equals('SH000001'));
      expect(testEvent.entityName, equals('上证指数'));
      expect(testEvent.category, equals(ChangeCategory.priceChange));
      expect(testEvent.severity, equals(ChangeSeverity.medium));
      expect(testEvent.changeRate, equals(2.5));

      // 测试计算属性
      expect(testEvent.changeDescription, equals('+2.50%'));
      expect(testEvent.trend, equals('上涨'));
      expect(testEvent.entityTypeDescription, equals('市场指数'));
      expect(testEvent.categoryDescription, equals('价格变化'));
      expect(testEvent.severityDescription, equals('中'));
    });

    test('JSON 序列化和反序列化', () {
      final json = testEvent.toJson();
      expect(json, isNotEmpty);
      expect(json['id'], equals('test-event-1'));
      expect(json['type'], equals('marketIndex'));
      expect(json['entityId'], equals('SH000001'));
      expect(json['changeRate'], equals(2.5));

      final restoredEvent = MarketChangeEvent.fromJson(json);
      expect(restoredEvent.id, equals(testEvent.id));
      expect(restoredEvent.type, equals(testEvent.type));
      expect(restoredEvent.entityId, equals(testEvent.entityId));
      expect(restoredEvent.changeRate, equals(testEvent.changeRate));
    });

    test('copyWith 功能', () {
      final copiedEvent = testEvent.copyWith(
        changeRate: -1.5,
        severity: ChangeSeverity.high,
      );

      expect(copiedEvent.id, equals(testEvent.id));
      expect(copiedEvent.changeRate, equals(-1.5));
      expect(copiedEvent.severity, equals(ChangeSeverity.high));
      expect(copiedEvent.trend, equals('下跌'));
    });

    test('影响评估基于变化严重程度', () async {
      // 高严重程度变化
      final highSeverityEvent = testEvent.copyWith(
        id: 'test-event-high',
        severity: ChangeSeverity.high,
        changeRate: 8.0,
      );

      final highSeverityImpact = await impactAssessor.assessImpact(
        highSeverityEvent,
        relatedFunds: ['fund1'],
        userPortfolioExposure: '5.0',
      );

      // 低严重程度变化
      final lowSeverityEvent = testEvent.copyWith(
        id: 'test-event-low',
        severity: ChangeSeverity.low,
        changeRate: 0.5,
      );

      final lowSeverityImpact = await impactAssessor.assessImpact(
        lowSeverityEvent,
        relatedFunds: ['fund1'],
        userPortfolioExposure: '5.0',
      );

      expect(highSeverityImpact.impactScore,
          greaterThan(lowSeverityImpact.impactScore));
    });

    test('影响评估包含完整信息', () async {
      final impact = await impactAssessor.assessImpact(
        testEvent,
        relatedFunds: ['fund1', 'fund2', 'fund3'],
        userPortfolioExposure: '15.5',
      );

      expect(impact.eventId, equals('test-event-1'));
      expect(impact.affectedFunds.length, equals(3));
      expect(impact.userImpact, isNotNull);
      expect(impact.marketImpact, isNotNull);
      expect(impact.analysis, isNotEmpty);
    });

    test('文件结构和导入验证', () {
      // 验证可以成功导入Task 3相关的核心类
      expect(() => ChangeCategory.values, returnsNormally);
      expect(() => ChangeSeverity.values, returnsNormally);
      expect(() => MarketChangeType.values, returnsNormally);
      expect(() => ChangeImpactAssessor(), returnsNormally);

      // 验证MarketChangeEvent可以正常实例化
      final testEvent = MarketChangeEvent(
        id: 'test-verify',
        type: MarketChangeType.fundNav,
        entityId: 'TEST',
        entityName: 'Test',
        category: ChangeCategory.priceChange,
        severity: ChangeSeverity.low,
        importance: 10.0,
        changeRate: 0.1,
        currentValue: '1.0',
        previousValue: '0.9',
        timestamp: DateTime.now(),
        metadata: {},
      );
      expect(testEvent, isNotNull);
    });

    test('边界条件处理', () async {
      final minimalEvent = MarketChangeEvent(
        id: 'minimal-event',
        type: MarketChangeType.fundNav,
        entityId: 'MIN001',
        entityName: '最小变化基金',
        category: ChangeCategory.priceChange,
        severity: ChangeSeverity.low,
        importance: 10.0,
        changeRate: 0.01,
        currentValue: '1.0001',
        previousValue: '1.0000',
        timestamp: DateTime.now(),
        metadata: {'source': 'test'},
      );

      final minimalImpact = await impactAssessor.assessImpact(
        minimalEvent,
        relatedFunds: [],
        userPortfolioExposure: '0.1',
      );

      expect(minimalImpact, isNotNull);
      expect(minimalImpact.impactScore, greaterThan(0.0));
      expect(minimalImpact.impactScore, lessThan(50.0));
    });

    test('Task 3 功能完整性验证', () async {
      // 验证Task 3的核心功能组件
      final testEvents = [
        // 价格变化事件
        MarketChangeEvent(
          id: 'price-1',
          type: MarketChangeType.fundNav,
          entityId: 'FUND001',
          entityName: '基金1',
          category: ChangeCategory.priceChange,
          severity: ChangeSeverity.medium,
          importance: 60.0,
          changeRate: 1.5,
          currentValue: '1.5000',
          previousValue: '1.4778',
          timestamp: DateTime.now(),
          metadata: {'source': 'test'},
        ),
        // 趋势变化事件
        MarketChangeEvent(
          id: 'trend-1',
          type: MarketChangeType.marketIndex,
          entityId: 'SH000002',
          entityName: '深证成指',
          category: ChangeCategory.trendChange,
          severity: ChangeSeverity.high,
          importance: 85.0,
          changeRate: -4.2,
          currentValue: '9500.0',
          previousValue: '9917.4',
          timestamp: DateTime.now(),
          metadata: {'source': 'test'},
        ),
      ];

      // 验证所有事件都能正常评估
      for (final event in testEvents) {
        final impact = await impactAssessor.assessImpact(
          event,
          relatedFunds: ['fund1', 'fund2'],
          userPortfolioExposure: '8.5',
        );

        expect(impact, isNotNull);
        expect(impact.eventId, equals(event.id));
        expect(impact.impactScore, greaterThan(0.0));
        expect(impact.affectedFunds, contains('fund1'));
        expect(impact.affectedFunds, contains('fund2'));
        expect(impact.userImpact, isNotNull);
        expect(impact.marketImpact, isNotNull);
        expect(impact.analysis, isNotEmpty);
      }
    });
  });
}
