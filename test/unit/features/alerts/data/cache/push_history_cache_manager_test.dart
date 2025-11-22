import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/alerts/data/cache/push_history_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/data/models/push_history_record.dart';

@GenerateMocks([])
void main() {
  group('PushHistoryCacheManager', () {
    late PushHistoryCacheManager cacheManager;

    setUp(() {
      // 获取单例实例
      cacheManager = PushHistoryCacheManager.instance;
    });

    group('初始化测试', () {
      test('应该是单例模式', () {
        final anotherInstance = PushHistoryCacheManager.instance;
        expect(identical(cacheManager, anotherInstance), isTrue);
      });

      test('初始状态应该正确', () {
        expect(cacheManager.isInitialized, isFalse);
      });
    });

    group('基本功能测试', () {
      test('应该能够获取单例实例', () {
        final instance = PushHistoryCacheManager.instance;
        expect(instance, isNotNull);
        expect(instance, isA<PushHistoryCacheManager>());
      });

      test('应该提供正确的类名', () {
        expect(cacheManager.runtimeType.toString(),
            contains('PushHistoryCacheManager'));
      });
    });

    group('PushHistoryRecord 测试', () {
      test('应该正确创建实例', () {
        final record = _createTestPushHistoryRecord();

        expect(record.id, equals('test-id'));
        expect(record.title, equals('Test Title'));
        expect(record.content, equals('Test Content'));
        expect(record.pushType, equals('market_change'));
        expect(record.priority, equals('high'));
        expect(record.isRead, isFalse);
        expect(record.isClicked, isFalse);
        expect(record.deliverySuccess, isTrue);
      });

      test('应该正确序列化为JSON', () {
        final record = _createTestPushHistoryRecord();
        final json = record.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['title'], equals('Test Title'));
        expect(json['content'], equals('Test Content'));
        expect(json['pushType'], equals('market_change'));
        expect(json['priority'], equals('high'));
        expect(json['isRead'], isFalse);
        expect(json['isClicked'], isFalse);
        expect(json['deliverySuccess'], isTrue);
      });

      test('应该正确从JSON反序列化', () {
        final json = {
          'id': 'test-id-2',
          'pushType': 'fund_update',
          'priority': 'medium',
          'title': 'Another Test',
          'content': 'Another Content',
          'timestamp': DateTime.now().toIso8601String(),
          'isRead': true,
          'isClicked': false,
          'deliverySuccess': true,
        };

        final record = PushHistoryRecord.fromJson(json);

        expect(record.id, equals('test-id-2'));
        expect(record.pushType, equals('fund_update'));
        expect(record.priority, equals('medium'));
        expect(record.title, equals('Another Test'));
        expect(record.content, equals('Another Content'));
        expect(record.isRead, isTrue);
        expect(record.isClicked, isFalse);
        expect(record.deliverySuccess, isTrue);
      });

      test('copyWith方法应该正确工作', () {
        final original = _createTestPushHistoryRecord();

        final updated = original.copyWith(
          isRead: true,
          isClicked: true,
          userFeedback: 'like',
        );

        expect(updated.id, equals(original.id));
        expect(updated.title, equals(original.title));
        expect(updated.content, equals(original.content));
        expect(updated.isRead, isTrue);
        expect(updated.isClicked, isTrue);
        expect(updated.userFeedback, equals('like'));
      });

      test('状态计算方法应该正确工作', () {
        final now = DateTime.now();
        final record = _createTestPushHistoryRecord(
          timestamp: now.subtract(const Duration(minutes: 30)),
        );

        expect(record.isRecent, isTrue);
        expect(record.isHighPriority, isTrue);
        expect(record.ageInMinutes, equals(30));
        expect(record.ageInHours, equals(0));
        expect(record.ageInDays, equals(0));
      });

      test('状态描述方法应该正确工作', () {
        final record = _createTestPushHistoryRecord(
          isRead: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        expect(record.statusDescription, equals('未读'));
        expect(record.ageDescription, equals('30分钟前'));
      });

      test('操作方法应该返回新实例', () {
        final record = _createTestPushHistoryRecord();

        final readRecord = record.markAsRead();
        expect(readRecord.isRead, isTrue);
        expect(readRecord.readAt, isNotNull);

        final clickedRecord = record.markAsClicked();
        expect(clickedRecord.isClicked, isTrue);
        expect(clickedRecord.clickedAt, isNotNull);

        final feedbackRecord = record.withUserFeedback('dislike');
        expect(feedbackRecord.userFeedback, equals('dislike'));
        expect(feedbackRecord.feedbackAt, isNotNull);
      });

      test('相等性比较应该正确工作', () {
        final record1 = _createTestPushHistoryRecord(id: 'same-id');
        final record2 = _createTestPushHistoryRecord(id: 'same-id');
        final record3 = _createTestPushHistoryRecord(id: 'different-id');

        expect(record1, equals(record2));
        expect(record1, isNot(equals(record3)));
      });

      test('toString方法应该包含关键信息', () {
        final record = _createTestPushHistoryRecord();
        final stringRepresentation = record.toString();

        expect(stringRepresentation, contains('PushHistoryRecord'));
        expect(stringRepresentation, contains('test-id'));
        expect(stringRepresentation, contains('Test Title'));
      });
    });

    group('边界条件测试', () {
      test('应该处理空字符串', () {
        final record = PushHistoryRecord(
          id: 'empty-test',
          pushType: 'test',
          priority: 'low',
          title: '',
          content: '',
          timestamp: DateTime.now(),
          isRead: false,
          isClicked: false,
          deliverySuccess: true,
          relatedEventIds: [],
          relatedFundCodes: [],
          relatedIndexCodes: [],
          channel: 'notification',
          personalizationScore: 0.0,
          effectivenessScore: 0.0,
          processingTimeMs: 0,
          networkStatus: 'unknown',
          userActivityState: 'unknown',
          deviceInfo: {},
          metadata: {},
        );

        expect(record.title, equals(''));
        expect(record.content, equals(''));
      });

      test('应该处理极端时间戳', () {
        final veryOldRecord = _createTestPushHistoryRecord(
          timestamp: DateTime.now().subtract(const Duration(days: 365)),
        );
        final veryRecentRecord = _createTestPushHistoryRecord(
          timestamp: DateTime.now(),
        );

        expect(veryOldRecord.ageInDays, equals(365));
        expect(veryRecentRecord.ageInDays, equals(0));
        expect(veryOldRecord.isRecent, isFalse);
        expect(veryRecentRecord.isRecent, isTrue);
      });

      test('应该处理不同的优先级', () {
        final lowPriority = _createTestPushHistoryRecord(priority: 'low');
        final mediumPriority = _createTestPushHistoryRecord(priority: 'medium');
        final highPriority = _createTestPushHistoryRecord(priority: 'high');

        expect(lowPriority.isHighPriority, isFalse);
        expect(mediumPriority.isHighPriority, isFalse);
        expect(highPriority.isHighPriority, isTrue);
      });
    });
  });
}

PushHistoryRecord _createTestPushHistoryRecord({
  String? id,
  String? pushType,
  String? priority,
  String? title,
  String? content,
  DateTime? timestamp,
  bool? isRead,
  bool? isClicked,
  bool? deliverySuccess,
  String? userFeedback,
}) {
  return PushHistoryRecord(
    id: id ?? 'test-id',
    pushType: pushType ?? 'market_change',
    priority: priority ?? 'high',
    title: title ?? 'Test Title',
    content: content ?? 'Test Content',
    timestamp: timestamp ?? DateTime.now(),
    isRead: isRead ?? false,
    isClicked: isClicked ?? false,
    deliverySuccess: deliverySuccess ?? true,
    userFeedback: userFeedback,
    relatedEventIds: ['event-1', 'event-2'],
    relatedFundCodes: ['000001', '000002'],
    relatedIndexCodes: ['000001', '000999'],
    channel: 'notification',
    personalizationScore: 0.8,
    effectivenessScore: 0.7,
    processingTimeMs: 150,
    networkStatus: 'wifi',
    userActivityState: 'active',
    deviceInfo: {'deviceId': 'test-device', 'platform': 'android'},
    metadata: {'test': true},
  );
}
