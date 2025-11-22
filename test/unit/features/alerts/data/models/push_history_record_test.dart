import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/features/alerts/data/models/push_history_record.dart';

void main() {
  group('PushHistoryRecord', () {
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

    test('应该正确序列化和反序列化', () {
      final original = _createTestPushHistoryRecord();
      final json = original.toJson();
      final restored = PushHistoryRecord.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.content, equals(original.content));
      expect(restored.pushType, equals(original.pushType));
      expect(restored.priority, equals(original.priority));
      expect(restored.isRead, equals(original.isRead));
      expect(restored.isClicked, equals(original.isClicked));
      expect(restored.deliverySuccess, equals(original.deliverySuccess));
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

    test('状态方法应该正确工作', () {
      final record = _createTestPushHistoryRecord(
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(record.isRecent, isTrue);
      expect(record.isHighPriority, isTrue);
      expect(record.ageInMinutes, equals(30));
      expect(record.ageInHours, equals(0));
      expect(record.ageInDays, equals(0));

      expect(record.statusDescription, equals('未读'));
      expect(record.ageDescription, equals('30分钟前'));
    });

    test('操作方法应该返回正确的新实例', () {
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

    test('应该正确处理不同优先级', () {
      final highRecord = _createTestPushHistoryRecord(priority: 'high');
      final mediumRecord = _createTestPushHistoryRecord(priority: 'medium');
      final lowRecord = _createTestPushHistoryRecord(priority: 'low');

      expect(highRecord.isHighPriority, isTrue);
      expect(mediumRecord.isHighPriority, isFalse);
      expect(lowRecord.isHighPriority, isFalse);
    });

    test('应该正确计算年龄描述', () {
      final now = DateTime.now();

      final oneMinuteRecord = _createTestPushHistoryRecord(
        timestamp: now.subtract(const Duration(minutes: 1)),
      );
      expect(oneMinuteRecord.ageDescription, equals('1分钟前'));

      final oneHourRecord = _createTestPushHistoryRecord(
        timestamp: now.subtract(const Duration(hours: 1)),
      );
      expect(oneHourRecord.ageDescription, equals('1小时前'));

      final oneDayRecord = _createTestPushHistoryRecord(
        timestamp: now.subtract(const Duration(days: 1)),
      );
      expect(oneDayRecord.ageDescription, equals('1天前'));
    });

    test('应该正确处理不同的状态', () {
      final unreadRecord = _createTestPushHistoryRecord(isRead: false);
      expect(unreadRecord.statusDescription, equals('未读'));

      final readRecord =
          _createTestPushHistoryRecord(isRead: true, isClicked: false);
      expect(readRecord.statusDescription, equals('已读'));

      final clickedRecord =
          _createTestPushHistoryRecord(isRead: true, isClicked: true);
      expect(clickedRecord.statusDescription, equals('已点击'));
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
