import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/market_change_event.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/change_category.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/change_severity.dart';

void main() {
  group('MarketChangeEvent Tests', () {
    late MarketChangeEvent testEvent;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime.now();
      testEvent = MarketChangeEvent(
        id: 'test-event-001',
        type: MarketChangeType.fundNav,
        entityId: '000001',
        entityName: '华夏成长混合',
        category: ChangeCategory.priceChange,
        severity: ChangeSeverity.medium,
        importance: 75.5,
        changeRate: 2.85,
        currentValue: '2.5680',
        previousValue: '2.4979',
        timestamp: testTimestamp,
        metadata: {
          'source': 'fund_provider',
          'confidence': 0.95,
        },
        relatedFunds: ['000001', '000002'],
      );
    });

    test('应该正确创建市场变化事件', () {
      expect(testEvent.id, equals('test-event-001'));
      expect(testEvent.entityId, equals('000001'));
      expect(testEvent.entityName, equals('华夏成长混合'));
      expect(testEvent.type, equals(MarketChangeType.fundNav));
      expect(testEvent.category, equals(ChangeCategory.priceChange));
      expect(testEvent.severity, equals(ChangeSeverity.medium));
      expect(testEvent.importance, equals(75.5));
      expect(testEvent.changeRate, equals(2.85));
      expect(testEvent.isPushed, isFalse);
      expect(testEvent.relatedFunds, contains('000001'));
    });

    test('应该正确使用copyWith方法', () {
      final updatedEvent = testEvent.copyWith(
        severity: ChangeSeverity.high,
        importance: 85.0,
        isPushed: true,
      );

      expect(updatedEvent.id, equals(testEvent.id));
      expect(updatedEvent.entityId, equals(testEvent.entityId));
      expect(updatedEvent.severity, equals(ChangeSeverity.high));
      expect(updatedEvent.importance, equals(85.0));
      expect(updatedEvent.isPushed, isTrue);
      expect(updatedEvent.pushedAt, isNotNull);
    });

    test('应该正确标记为已推送', () {
      expect(testEvent.isPushed, isFalse);
      expect(testEvent.pushedAt, isNull);

      final pushedEvent = testEvent.markAsPushed();

      expect(pushedEvent.isPushed, isTrue);
      expect(pushedEvent.pushedAt, isNotNull);
      expect(
          pushedEvent.pushedAt!
              .isAfter(testTimestamp.subtract(const Duration(seconds: 1))),
          isTrue);
    });

    test('应该正确计算变化描述', () {
      final positiveEvent = testEvent.copyWith(changeRate: 3.25);
      expect(positiveEvent.changeDescription, equals('+3.25%'));

      final negativeEvent = testEvent.copyWith(changeRate: -1.75);
      expect(negativeEvent.changeDescription, equals('-1.75%'));

      final zeroEvent = testEvent.copyWith(changeRate: 0.0);
      expect(zeroEvent.changeDescription, equals('+0.00%'));
    });

    test('应该正确判断趋势', () {
      final positiveEvent = testEvent.copyWith(changeRate: 2.5);
      expect(positiveEvent.trend, equals('上涨'));

      final negativeEvent = testEvent.copyWith(changeRate: -3.1);
      expect(negativeEvent.trend, equals('下跌'));

      final zeroEvent = testEvent.copyWith(changeRate: 0.0);
      expect(zeroEvent.trend, equals('持平'));
    });

    test('应该正确获取实体类型描述', () {
      final fundNavEvent = testEvent.copyWith(type: MarketChangeType.fundNav);
      expect(fundNavEvent.entityTypeDescription, equals('基金净值'));

      final marketIndexEvent =
          testEvent.copyWith(type: MarketChangeType.marketIndex);
      expect(marketIndexEvent.entityTypeDescription, equals('市场指数'));
    });

    test('应该正确获取变化类别描述', () {
      final priceChangeEvent =
          testEvent.copyWith(category: ChangeCategory.priceChange);
      expect(priceChangeEvent.categoryDescription, equals('价格变化'));

      final trendChangeEvent =
          testEvent.copyWith(category: ChangeCategory.trendChange);
      expect(trendChangeEvent.categoryDescription, equals('趋势变化'));

      final abnormalEvent =
          testEvent.copyWith(category: ChangeCategory.abnormalEvent);
      expect(abnormalEvent.categoryDescription, equals('异常事件'));
    });

    test('应该正确获取严重程度描述', () {
      final highSeverityEvent =
          testEvent.copyWith(severity: ChangeSeverity.high);
      expect(highSeverityEvent.severityDescription, equals('高'));

      final mediumSeverityEvent =
          testEvent.copyWith(severity: ChangeSeverity.medium);
      expect(mediumSeverityEvent.severityDescription, equals('中'));

      final lowSeverityEvent = testEvent.copyWith(severity: ChangeSeverity.low);
      expect(lowSeverityEvent.severityDescription, equals('低'));
    });

    test('应该正确序列化为JSON', () {
      final json = testEvent.toJson();

      expect(json['id'], equals('test-event-001'));
      expect(json['type'], equals('fundNav'));
      expect(json['entityId'], equals('000001'));
      expect(json['entityName'], equals('华夏成长混合'));
      expect(json['category'], equals('priceChange'));
      expect(json['severity'], equals('medium'));
      expect(json['importance'], equals(75.5));
      expect(json['changeRate'], equals(2.85));
      expect(json['currentValue'], equals('2.5680'));
      expect(json['previousValue'], equals('2.4979'));
      expect(json['isPushed'], isFalse);
      expect(json['metadata'], isA<Map>());
      expect(json['relatedFunds'], contains('000001'));
    });

    test('应该正确从JSON反序列化', () {
      final json = testEvent.toJson();
      final deserializedEvent = MarketChangeEvent.fromJson(json);

      expect(deserializedEvent.id, equals(testEvent.id));
      expect(deserializedEvent.entityId, equals(testEvent.entityId));
      expect(deserializedEvent.entityName, equals(testEvent.entityName));
      expect(deserializedEvent.type, equals(testEvent.type));
      expect(deserializedEvent.category, equals(testEvent.category));
      expect(deserializedEvent.severity, equals(testEvent.severity));
      expect(deserializedEvent.importance, equals(testEvent.importance));
      expect(deserializedEvent.changeRate, equals(testEvent.changeRate));
      expect(deserializedEvent.currentValue, equals(testEvent.currentValue));
      expect(deserializedEvent.previousValue, equals(testEvent.previousValue));
      expect(deserializedEvent.metadata, equals(testEvent.metadata));
      expect(deserializedEvent.relatedFunds, equals(testEvent.relatedFunds));
    });

    test('应该正确处理JSON中的缺失字段', () {
      final incompleteJson = {
        'id': 'incomplete-event',
        'type': 'fundNav',
        'entityId': '000002',
        'entityName': '测试基金',
        'category': 'priceChange',
        'severity': 'low',
        'importance': 50.0,
        'changeRate': 1.5,
        'currentValue': '1.500',
        'previousValue': '1.477',
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': {},
        'isPushed': false,
      };

      final event = MarketChangeEvent.fromJson(incompleteJson);

      expect(event.id, equals('incomplete-event'));
      expect(event.relatedFunds, isEmpty); // 默认空列表
      expect(event.pushedAt, isNull); // 默认null
    });

    test('应该正确实现equals和hashCode', () {
      final sameEvent = MarketChangeEvent(
        id: 'test-event-001',
        type: testEvent.type,
        entityId: testEvent.entityId,
        entityName: testEvent.entityName,
        category: testEvent.category,
        severity: testEvent.severity,
        importance: testEvent.importance,
        changeRate: testEvent.changeRate,
        currentValue: testEvent.currentValue,
        previousValue: testEvent.previousValue,
        timestamp: testEvent.timestamp,
        metadata: testEvent.metadata,
        relatedFunds: testEvent.relatedFunds,
      );

      final differentEvent = testEvent.copyWith(id: 'different-event');

      expect(testEvent, equals(sameEvent));
      expect(testEvent, isNot(equals(differentEvent)));
      expect(testEvent.hashCode, equals(sameEvent.hashCode));
    });

    test('应该正确生成toString', () {
      final stringRepresentation = testEvent.toString();

      expect(stringRepresentation, contains('test-event-001'));
      expect(stringRepresentation, contains('华夏成长混合'));
      expect(stringRepresentation, contains('+2.85%'));
      expect(stringRepresentation, contains('medium'));
      expect(stringRepresentation, contains('MarketChangeEvent'));
    });

    test('应该正确处理空的相关基金列表', () {
      final eventWithoutFunds = testEvent.copyWith(relatedFunds: []);

      expect(eventWithoutFunds.relatedFunds, isEmpty);
    });

    test('应该正确处理空的元数据', () {
      final eventWithoutMetadata = testEvent.copyWith(metadata: {});

      expect(eventWithoutMetadata.metadata, isEmpty);
    });

    test('应该正确处理空的推送时间', () {
      expect(testEvent.pushedAt, isNull);

      final pushedEvent = testEvent.markAsPushed();
      expect(pushedEvent.pushedAt, isNotNull);
    });

    test('应该正确处理边界值', () {
      final zeroImportanceEvent = testEvent.copyWith(importance: 0.0);
      expect(zeroImportanceEvent.importance, equals(0.0));

      final maxImportanceEvent = testEvent.copyWith(importance: 100.0);
      expect(maxImportanceEvent.importance, equals(100.0));

      final maxChangeRateEvent = testEvent.copyWith(changeRate: 999.99);
      expect(maxChangeRateEvent.changeRate, equals(999.99));
    });
  });

  group('MarketChangeType Tests', () {
    test('应该包含所有预期的市场变化类型', () {
      final allTypes = MarketChangeType.values;

      expect(allTypes, contains(MarketChangeType.fundNav));
      expect(allTypes, contains(MarketChangeType.marketIndex));
      expect(allTypes.length, equals(2));
    });

    test('枚举名称应该正确', () {
      expect(MarketChangeType.fundNav.name, equals('fundNav'));
      expect(MarketChangeType.marketIndex.name, equals('marketIndex'));
    });
  });

  group('ChangeCategory Tests', () {
    test('应该包含所有预期的变化类别', () {
      final allCategories = ChangeCategory.values;

      expect(allCategories, contains(ChangeCategory.priceChange));
      expect(allCategories, contains(ChangeCategory.trendChange));
      expect(allCategories, contains(ChangeCategory.abnormalEvent));
      expect(allCategories.length, equals(3));
    });

    test('枚举名称应该正确', () {
      expect(ChangeCategory.priceChange.name, equals('priceChange'));
      expect(ChangeCategory.trendChange.name, equals('trendChange'));
      expect(ChangeCategory.abnormalEvent.name, equals('abnormalEvent'));
    });
  });

  group('ChangeSeverity Tests', () {
    test('应该包含所有预期的严重程度', () {
      final allSeverities = ChangeSeverity.values;

      expect(allSeverities, contains(ChangeSeverity.low));
      expect(allSeverities, contains(ChangeSeverity.medium));
      expect(allSeverities, contains(ChangeSeverity.high));
      expect(allSeverities.length, equals(3));
    });

    test('枚举名称应该正确', () {
      expect(ChangeSeverity.low.name, equals('low'));
      expect(ChangeSeverity.medium.name, equals('medium'));
      expect(ChangeSeverity.high.name, equals('high'));
    });
  });
}
