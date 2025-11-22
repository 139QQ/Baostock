import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_type.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_fetch_strategy.dart';

/// Story 2.1基础测试
///
/// 验证混合数据获取连接管理的核心功能
/// 简化测试，专注于验证核心数据结构和类型定义

void main() {
  group('Story 2.1: 混合数据获取连接管理 - 基础验证', () {
    group('AC1: 分层数据获取机制验证', () {
      test('应该支持多种数据类型的定义', () {
        // 验证关键数据类型存在
        expect(DataType.fundNetValue, isNotNull);
        expect(DataType.marketIndex, isNotNull);
        expect(DataType.connectionStatus, isNotNull);
        expect(DataType.historicalPerformance, isNotNull);

        // 验证数据类型优先级
        expect(DataType.connectionStatus.priority.value,
            DataPriority.critical.value);
        expect(DataType.marketIndex.priority.value, DataPriority.high.value);
        expect(DataType.fundNetValue.priority.value, DataPriority.medium.value);
        expect(DataType.historicalPerformance.priority.value,
            DataPriority.low.value);
      });

      test('应该正确识别数据类型特性', () {
        // 验证实时数据类型
        expect(DataType.connectionStatus.isRealtime, isTrue);
        expect(DataType.marketIndex.isRealtime, isTrue);

        // 验证准实时数据类型
        expect(DataType.fundNetValue.isQuasiRealtime, isTrue);
        expect(DataType.fundBasicInfo.isQuasiRealtime, isTrue);

        // 验证按需数据类型
        expect(DataType.historicalPerformance.isOnDemand, isTrue);
        expect(DataType.fundHoldingDetails.isOnDemand, isTrue);
      });

      test('应该提供正确的API端点', () {
        expect(DataType.fundNetValue.apiEndpoint, '/api/fund/nav');
        expect(DataType.marketIndex.apiEndpoint, '/api/stock/realtime');
        expect(DataType.connectionStatus.apiEndpoint, '/api/system/status');
        expect(DataType.historicalPerformance.apiEndpoint,
            '/api/fund/performance');
      });

      test('应该支持数据类型代码解析', () {
        expect(DataType.fromCode('fund_net_value'), DataType.fundNetValue);
        expect(DataType.fromCode('market_index'), DataType.marketIndex);
        expect(
            DataType.fromCode('connection_status'), DataType.connectionStatus);
        expect(DataType.fromCode('unknown_type'), isNull);
      });
    });

    group('AC2: 数据配置系统验证', () {
      test('应该创建默认数据获取配置', () {
        final config = DataFetchConfig.defaultForType(DataType.fundNetValue);

        expect(config.dataType, DataType.fundNetValue);
        expect(config.autoFetchEnabled, isTrue);
        expect(config.strategyPreference, FetchStrategyPreference.auto);
        expect(config.maxRetries, 3);
        expect(config.cacheEnabled, isTrue);
      });

      test('应该支持自定义配置', () {
        final customConfig = DataFetchConfig(
          dataType: DataType.marketIndex,
          autoFetchEnabled: false,
          customInterval: const Duration(minutes: 5),
          strategyPreference: FetchStrategyPreference.websocket,
          maxRetries: 5,
          timeout: const Duration(seconds: 60),
        );

        expect(customConfig.dataType, DataType.marketIndex);
        expect(customConfig.autoFetchEnabled, isFalse);
        expect(customConfig.effectiveInterval, const Duration(minutes: 5));
        expect(
            customConfig.strategyPreference, FetchStrategyPreference.websocket);
        expect(customConfig.maxRetries, 5);
      });

      test('应该支持配置序列化和反序列化', () {
        final originalConfig = DataFetchConfig(
          dataType: DataType.fundNetValue,
          autoFetchEnabled: false,
          customInterval: const Duration(minutes: 10),
          maxRetries: 5,
        );

        final json = originalConfig.toJson();
        final restoredConfig = DataFetchConfig.fromJson(json);

        expect(restoredConfig.dataType, originalConfig.dataType);
        expect(
            restoredConfig.autoFetchEnabled, originalConfig.autoFetchEnabled);
        expect(restoredConfig.customInterval, originalConfig.customInterval);
        expect(restoredConfig.maxRetries, originalConfig.maxRetries);
      });
    });

    group('AC3: 数据质量系统验证', () {
      test('应该支持数据质量级别定义', () {
        expect(DataQualityLevel.excellent.value, 5);
        expect(DataQualityLevel.good.value, 4);
        expect(DataQualityLevel.fair.value, 3);
        expect(DataQualityLevel.poor.value, 2);
        expect(DataQualityLevel.unknown.value, 1);
      });

      test('应该支持从数值创建质量级别', () {
        expect(DataQualityLevel.fromValue(5), DataQualityLevel.excellent);
        expect(DataQualityLevel.fromValue(4), DataQualityLevel.good);
        expect(DataQualityLevel.fromValue(1), DataQualityLevel.unknown);
        expect(DataQualityLevel.fromValue(0), DataQualityLevel.unknown);
      });
    });

    group('AC4: 数据来源验证', () {
      test('应该支持多种数据来源', () {
        final sources = DataSource.values;
        expect(sources, contains(DataSource.websocket));
        expect(sources, contains(DataSource.httpPolling));
        expect(sources, contains(DataSource.httpOnDemand));
        expect(sources, contains(DataSource.http));
        expect(sources, contains(DataSource.cache));
        expect(sources, contains(DataSource.unknown));
      });

      test('应该提供数据来源描述', () {
        expect(DataSource.websocket.description, 'WebSocket实时数据');
        expect(DataSource.httpPolling.description, 'HTTP轮询数据');
        expect(DataSource.httpOnDemand.description, 'HTTP按需请求');
        expect(DataSource.http.description, 'HTTP请求数据');
        expect(DataSource.cache.description, '缓存数据');
        expect(DataSource.unknown.description, '未知来源');
      });
    });

    group('AC5: 数据项模型验证', () {
      test('应该创建数据项并支持基本操作', () {
        final dataItem = DataItem(
          dataType: DataType.fundNetValue,
          data: {'fundCode': '000001', 'netValue': 1.2345},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'test-data-item-1',
        );

        expect(dataItem.dataType, DataType.fundNetValue);
        expect(dataItem.data, {'fundCode': '000001', 'netValue': 1.2345});
        expect(dataItem.quality, DataQualityLevel.good);
        expect(dataItem.source, DataSource.httpPolling);
        expect(dataItem.isExpired, isFalse);
        expect(dataItem.dataKey, 'default');
        expect(dataItem.metadata, isNull);
      });

      test('应该支持数据项过期检查', () {
        final freshData = DataItem(
          dataType: DataType.fundNetValue,
          data: {'value': 1.23},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'fresh-data',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        final expiredData = DataItem(
          dataType: DataType.fundNetValue,
          data: {'value': 1.23},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'expired-data',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(freshData.isExpired, isFalse);
        expect(expiredData.isExpired, isTrue);
      });

      test('应该支持数据项序列化', () {
        final originalData = DataItem(
          dataType: DataType.marketIndex,
          data: {'index': '000001', 'value': 3000.0},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.excellent,
          source: DataSource.websocket,
          id: 'serialization-test',
          dataKey: 'index-000001',
          metadata: {'source': 'exchange', 'version': '1.0'},
        );

        final json = originalData.toJson();
        final deserializedData = DataItem.fromJson(json);

        expect(deserializedData.dataType, originalData.dataType);
        expect(deserializedData.data, originalData.data);
        expect(deserializedData.quality, originalData.quality);
        expect(deserializedData.source, originalData.source);
        expect(deserializedData.dataKey, originalData.dataKey);
        expect(deserializedData.metadata, originalData.metadata);
      });
    });

    group('AC6-AC8: 数据获取策略结果验证', () {
      test('应该创建成功的获取结果', () {
        final dataItem = DataItem(
          dataType: DataType.fundNetValue,
          data: {'fundCode': '000001', 'netValue': 1.2345},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'success-result',
        );

        final result = FetchResult.success(dataItem);

        expect(result.success, isTrue);
        expect(result.dataItem, dataItem);
        expect(result.errorMessage, isNull);
        expect(result.shouldRetry, isFalse);
        expect(result.retryDelay, isNull);
      });

      test('应该创建失败的获取结果', () {
        const result = FetchResult.failure('Network timeout');

        expect(result.success, isFalse);
        expect(result.dataItem, isNull);
        expect(result.errorMessage, 'Network timeout');
        expect(result.shouldRetry, isTrue);
        expect(result.retryDelay, const Duration(seconds: 5));
      });
    });

    group('集成验证', () {
      test('应该支持完整的数据类型生命周期', () {
        // 1. 创建数据类型配置
        final config = DataFetchConfig.defaultForType(DataType.fundNetValue);
        expect(config.autoFetchEnabled, isTrue);

        // 2. 创建数据项
        final dataItem = DataItem(
          dataType: DataType.fundNetValue,
          data: {'fundCode': '000001', 'netValue': 1.2345},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'lifecycle-test',
        );

        // 3. 序列化数据项
        final json = dataItem.toJson();
        expect(json['dataType'], 'fund_net_value');
        expect(json['quality'], 'good');
        expect(json['source'], 'httpPolling');

        // 4. 反序列化数据项
        final restoredDataItem = DataItem.fromJson(json);
        expect(restoredDataItem.dataType, dataItem.dataType);
        expect(restoredDataItem.data, dataItem.data);

        // 5. 验证数据年龄计算
        final age = restoredDataItem.age;
        expect(age.inMilliseconds, lessThanOrEqualTo(1000)); // 应该在1秒内
      });

      test('应该验证所有核心数据类型的完整性', () {
        final allDataTypes = DataType.values;

        for (final dataType in allDataTypes) {
          // 验证数据类型定义完整
          expect(dataType.code, isNotEmpty);
          expect(dataType.priority.value, isA<int>());
          expect(dataType.defaultUpdateInterval, isA<Duration>());
          expect(dataType.description, isNotEmpty);
          expect(dataType.apiEndpoint, isNotEmpty);

          // 验证默认配置可创建
          final config = DataFetchConfig.defaultForType(dataType);
          expect(config.dataType, dataType);

          // 验证可创建对应的数据项
          final dataItem = DataItem(
            dataType: dataType,
            data: {'test': 'data'},
            timestamp: DateTime.now(),
            quality: DataQualityLevel.good,
            source: DataSource.http,
            id: 'test-${dataType.code}',
          );
          expect(dataItem.dataType, dataType);
        }
      });
    });
  });
}
