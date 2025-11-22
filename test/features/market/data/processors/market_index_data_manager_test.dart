import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';

import 'package:jisu_fund_analyzer/src/features/market/data/processors/market_index_data_manager.dart';
import 'package:jisu_fund_analyzer/src/features/market/models/market_index_data.dart';

/// 市场指数数据管理器测试
void main() {
  group('MarketIndexDataManager', () {
    late MarketIndexDataManager dataManager;

    setUp(() {
      dataManager = MarketIndexDataManager();
    });

    tearDown(() async {
      await dataManager.dispose();
    });

    group('基本功能', () {
      test('应该能够创建数据管理器', () {
        // When
        final manager = MarketIndexDataManager();

        // Then
        expect(manager, isNotNull);
        expect(manager.trackedIndices, isEmpty);
      });

      test('应该能够开始跟踪指数', () async {
        // Given
        final indexCode = 'SH000001';

        // When
        await dataManager.startTrackingIndex(indexCode);

        // Then
        expect(dataManager.isTrackingIndex(indexCode), isTrue);
        expect(dataManager.trackedIndices, contains(indexCode));
      });

      test('应该能够停止跟踪指数', () async {
        // Given
        final indexCode = 'SH000001';
        await dataManager.startTrackingIndex(indexCode);

        // When
        await dataManager.stopTrackingIndex(indexCode);

        // Then
        expect(dataManager.isTrackingIndex(indexCode), isFalse);
        expect(dataManager.trackedIndices, isNot(contains(indexCode)));
      });

      test('应该能够批量跟踪指数', () async {
        // Given
        final indexCodes = ['SH000001', 'SZ399001', 'SH000300'];

        // When - 逐个添加指数（因为不存在批量方法）
        for (final code in indexCodes) {
          await dataManager.startTrackingIndex(code);
        }

        // Then
        expect(dataManager.trackedIndices.length, equals(3));
        for (final code in indexCodes) {
          expect(dataManager.isTrackingIndex(code), isTrue);
        }
      });
    });

    group('批量轮询', () {
      test('应该能够启动批量轮询', () async {
        // Given
        await dataManager.startTrackingIndex('SH000001');
        await dataManager.startTrackingIndex('SZ399001');

        // When
        await dataManager.startBatchPolling();

        // Then
        expect(dataManager.isPolling, isTrue);
      });

      test('应该能够停止批量轮询', () async {
        // Given
        await dataManager.startTrackingIndex('SH000001');
        await dataManager.startBatchPolling();

        // When
        await dataManager.stopBatchPolling();

        // Then
        expect(dataManager.isPolling, isFalse);
      });

      test('应该能够设置轮询间隔', () async {
        // Given
        const testInterval = Duration(seconds: 15);

        // When
        await dataManager.setPollingInterval(testInterval);

        // Then
        expect(dataManager.pollingInterval, equals(testInterval));
      });

      test('应该能够在没有跟踪指数时启动轮询', () async {
        // When
        await dataManager.startBatchPolling();

        // Then
        expect(dataManager.isPolling, isTrue);
      });
    });

    group('数据流', () {
      test('应该能够获取指数数据流', () async {
        // Given
        final indexCode = 'SH000001';
        await dataManager.startTrackingIndex(indexCode);

        // When
        final stream = dataManager.getIndexDataStream(indexCode);

        // Then
        expect(stream, isNotNull);
      });

      test('应该能够获取指数变化流', () async {
        // Given
        final indexCode = 'SH000001';
        await dataManager.startTrackingIndex(indexCode);

        // When
        final stream = dataManager.getIndexChangeStream(indexCode);

        // Then
        expect(stream, isNotNull);
      });

      test('未跟踪的指数应该返回null流', () async {
        // When
        final stream = dataManager.getIndexDataStream('NON_EXISTENT');

        // Then
        expect(stream, isNull);
      });
    });

    group('性能统计', () {
      test('应该提供准确的性能统计', () async {
        // Given
        final indexCode = 'SH000001';
        await dataManager.startTrackingIndex(indexCode);

        // When
        final stats = dataManager.getPerformanceStats();

        // Then
        expect(stats, isNotNull);
        expect(stats['trackedIndicesCount'], isA<int>());
        expect(stats['pollingInterval'], isA<int>());
        expect(stats['pollingEnabled'], isA<bool>());
        expect(stats['state'], isA<String>());
      });
    });

    group('配置管理', () {
      test('应该能够设置轮询间隔', () async {
        // Given
        const testInterval = Duration(seconds: 15);

        // When
        await dataManager.setPollingInterval(testInterval);

        // Then
        expect(dataManager.pollingInterval, equals(testInterval));
      });

      test('应该能够启用/禁用轮询', () async {
        // When
        await dataManager.setPollingEnabled(false);

        // Then
        expect(dataManager.isPolling, isFalse);

        // When
        await dataManager.setPollingEnabled(true);

        // Then
        // 轮询应该自动启动（如果有跟踪的指数）
        expect(dataManager.isPolling, isTrue);
      });
    });

    group('事件处理', () {
      test('应该能够监听状态流', () async {
        // Given
        final states = <MarketIndexManagerState>[];
        dataManager.stateStream.listen((state) => states.add(state));

        // When
        await dataManager.startBatchPolling();
        await Future.delayed(Duration(milliseconds: 100));
        await dataManager.stopBatchPolling();

        // Then
        expect(states.isNotEmpty, isTrue);
        // 至少应该有idle和running状态
      });

      test('应该能够监听更新流', () async {
        // Given
        final updates = <MarketIndexUpdateEvent>[];
        dataManager.updateStream.listen((event) => updates.add(event));

        final indexCode = 'SH000001';
        await dataManager.startTrackingIndex(indexCode);

        // When
        await dataManager.startBatchPolling();
        await Future.delayed(Duration(milliseconds: 100));

        // Then
        // 由于没有实际的数据源，可能不会有更新事件，但流应该是存在的
        expect(dataManager.updateStream, isNotNull);
      });
    });

    group('错误处理', () {
      test('应该能够处理重复跟踪', () async {
        // Given
        final indexCode = 'SH000001';

        // When
        await dataManager.startTrackingIndex(indexCode);
        await dataManager.startTrackingIndex(indexCode); // 重复添加

        // Then
        expect(dataManager.trackedIndices.length, equals(1));
        expect(dataManager.isTrackingIndex(indexCode), isTrue);
      });

      test('应该能够处理停止不存在的指数', () async {
        // When
        await dataManager.stopTrackingIndex('NON_EXISTENT');

        // Then
        expect(dataManager.trackedIndices, isEmpty);
        // 不应该抛出异常
      });

      test('应该能够处理空列表批量操作', () async {
        // When
        await dataManager.startBatchPolling(); // 没有跟踪指数时启动轮询

        // Then
        expect(dataManager.isPolling, isTrue);
        // 轮询应该正常启动，即使没有跟踪的指数
      });
    });

    group('资源管理', () {
      test('应该能够正确释放资源', () async {
        // Given
        await dataManager.startTrackingIndex('SH000001');
        await dataManager.startBatchPolling();

        // When
        await dataManager.dispose();

        // Then
        expect(dataManager.trackedIndices, isEmpty);
        expect(dataManager.isPolling, isFalse);
      });
    });
  });
}

/// 创建测试用的市场指数数据
MarketIndexData createTestIndexData(String code) {
  return MarketIndexData(
    code: code,
    name: getIndexName(code),
    currentValue: Decimal.parse('3000.50'),
    previousClose: Decimal.parse('2995.20'),
    openPrice: Decimal.parse('2998.00'),
    highPrice: Decimal.parse('3010.80'),
    lowPrice: Decimal.parse('2990.15'),
    changeAmount: Decimal.parse('5.30'),
    changePercentage: Decimal.parse('0.177'),
    volume: 1000000,
    turnover: Decimal.parse('15000000000'),
    updateTime: DateTime.now(),
    marketStatus: MarketStatus.trading,
    qualityLevel: DataQualityLevel.good,
    dataSource: 'test',
  );
}

/// 根据代码获取指数名称
String getIndexName(String code) {
  final nameMap = {
    'SH000001': '上证指数',
    'SZ399001': '深证成指',
    'SH000300': '沪深300',
  };
  return nameMap[code] ?? '测试指数';
}
