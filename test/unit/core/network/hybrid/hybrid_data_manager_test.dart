import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_type.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_fetch_strategy.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/hybrid_data_manager.dart';

// 简化的Mock实现，避免使用build_runner
class MockDataFetchStrategy implements DataFetchStrategy {
  @override
  final String name;
  @override
  final int priority;
  @override
  final List<DataType> supportedDataTypes;
  bool _isAvailable = true;
  final List<FetchResult> _results = [];
  final Map<DataType, StreamController<DataItem>> _streamControllers = {};

  MockDataFetchStrategy({
    required this.name,
    required this.priority,
    required this.supportedDataTypes,
    bool isAvailable = true,
  }) : _isAvailable = isAvailable;

  void setAvailability(bool available) {
    _isAvailable = available;
  }

  void addResult(FetchResult result) {
    _results.add(result);
  }

  void addDataToStream(DataType type, DataItem data) {
    if (!_streamControllers.containsKey(type)) {
      _streamControllers[type] = StreamController<DataItem>.broadcast();
    }
    _streamControllers[type]!.add(data);
  }

  @override
  bool isAvailable() => _isAvailable;

  @override
  Stream<DataItem> getDataStream(DataType type,
      {Map<String, dynamic>? parameters}) {
    if (!_streamControllers.containsKey(type)) {
      _streamControllers[type] = StreamController<DataItem>.broadcast();
    }
    return _streamControllers[type]!.stream;
  }

  @override
  Future<FetchResult> fetchData(DataType type,
      {Map<String, dynamic>? parameters}) async {
    if (_results.isNotEmpty) {
      return _results.removeAt(0);
    }
    return const FetchResult.failure('No mock result available');
  }

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'strategy': name,
      'healthy': _isAvailable,
      'priority': priority,
      'supportedDataTypes': supportedDataTypes.map((t) => t.code).toList(),
    };
  }

  @override
  Future<void> start() async {
    // Mock implementation
  }

  @override
  Future<void> stop() async {
    for (final controller in _streamControllers.values) {
      await controller.close();
    }
    _streamControllers.clear();
  }

  @override
  Duration? getDefaultPollingInterval(DataType type) {
    return supportedDataTypes.contains(type)
        ? type.defaultUpdateInterval
        : null;
  }

  @override
  bool supportsDataType(DataType type) {
    return supportedDataTypes.contains(type);
  }

  @override
  Map<String, dynamic> getConfig() {
    return {
      'name': name,
      'priority': priority,
      'supportedDataTypes': supportedDataTypes.map((t) => t.code).toList(),
    };
  }
}

void main() {
  group('HybridDataManager', () {
    late HybridDataManager manager;
    late MockDataFetchStrategy mockStrategy1;
    late MockDataFetchStrategy mockStrategy2;

    setUp(() {
      manager = HybridDataManager();

      mockStrategy1 = MockDataFetchStrategy(
        name: 'MockStrategy1',
        priority: 100,
        supportedDataTypes: [DataType.fundNetValue],
        isAvailable: true,
      );

      mockStrategy2 = MockDataFetchStrategy(
        name: 'MockStrategy2',
        priority: 80,
        supportedDataTypes: [DataType.fundNetValue, DataType.marketIndex],
        isAvailable: true,
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    group('初始化和状态管理', () {
      test('应该正确初始化并达到ready状态', () async {
        expect(manager.state, ManagerState.ready);
      });

      test('应该正确更新管理器状态', () async {
        final states = <ManagerState>[];
        final subscription = manager.stateStream.listen(states.add);

        await manager.start();
        await manager.stop();

        expect(states, contains(ManagerState.ready));
        expect(states, contains(ManagerState.running));
        expect(states, contains(ManagerState.stopped));

        await subscription.cancel();
      });
    });

    group('策略注册和管理', () {
      test('应该正确注册数据获取策略', () {
        manager.registerStrategy(mockStrategy1);

        expect(manager.state, ManagerState.ready);
      });

      test('应该正确注销数据获取策略', () {
        manager.registerStrategy(mockStrategy1);
        manager.unregisterStrategy('MockStrategy1');

        expect(manager.state, ManagerState.ready);
      });

      test('应该支持多种数据类型的策略', () {
        manager.registerStrategy(mockStrategy2);

        expect(
            mockStrategy2.supportedDataTypes, contains(DataType.fundNetValue));
        expect(
            mockStrategy2.supportedDataTypes, contains(DataType.marketIndex));
      });
    });

    group('数据获取功能', () {
      test('应该能够获取混合数据流', () {
        final stream = manager.getMixedDataStream(DataType.fundNetValue);
        expect(stream, isNotNull);
        expect(stream, isA<Stream<DataItem>>());
      });

      test('应该能够获取数据并优先使用缓存', () async {
        final testDataItem = DataItem(
          dataType: DataType.fundNetValue,
          data: {'value': 1.23},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'test-123',
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        );

        mockStrategy1.addResult(FetchResult.success(testDataItem));
        manager.registerStrategy(mockStrategy1);

        final result = await manager.getData(DataType.fundNetValue);

        expect(result, isNotNull);
        expect(result!.dataType, DataType.fundNetValue);
        expect(result.data, {'value': 1.23});
      });

      test('当没有可用策略时应该返回null', () async {
        final result = await manager.getData(DataType.fundNetValue);
        expect(result, isNull);
      });

      test('应该处理数据获取失败的情况', () async {
        mockStrategy1.addResult(const FetchResult.failure('Network error'));
        manager.registerStrategy(mockStrategy1);

        final result = await manager.getData(DataType.fundNetValue);
        expect(result, isNull);
      });

      test('应该支持参数化数据获取', () async {
        final testDataItem = DataItem(
          dataType: DataType.fundNetValue,
          data: {'fundCode': '000001', 'value': 2.34},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'test-param-456',
        );

        mockStrategy1.addResult(FetchResult.success(testDataItem));
        manager.registerStrategy(mockStrategy1);

        final parameters = {'fundCode': '000001'};
        final result = await manager.getData(DataType.fundNetValue,
            parameters: parameters);

        expect(result, isNotNull);
        expect(result!.data['fundCode'], '000001');
      });
    });

    group('性能监控', () {
      test('应该正确记录延迟指标', () async {
        final testDataItem = DataItem(
          dataType: DataType.fundNetValue,
          data: {'value': 1.23},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'test-latency-003',
        );

        mockStrategy1.addResult(FetchResult.success(testDataItem));
        manager.registerStrategy(mockStrategy1);
        await manager.getData(DataType.fundNetValue);

        final metrics = manager.getPerformanceMetrics();
        expect(metrics, isNotNull);
        expect(metrics.containsKey('fund_net_value'), isTrue);
        expect(metrics['fund_net_value']['requestCount'], greaterThan(0));
      });

      test('应该正确计算错误率', () async {
        mockStrategy1.addResult(const FetchResult.failure('Network error'));
        manager.registerStrategy(mockStrategy1);

        // 尝试多次获取数据以产生错误
        for (int i = 0; i < 3; i++) {
          await manager.getData(DataType.fundNetValue);
        }

        final metrics = manager.getPerformanceMetrics();
        expect(metrics['fund_net_value']['errorCount'], greaterThan(0));
        expect(metrics['fund_net_value']['errorRate'], greaterThan(0.0));
      });

      test('应该提供完整的性能指标', () {
        final metrics = manager.getPerformanceMetrics();

        // 验证所有数据类型都有指标
        for (final dataType in DataType.values) {
          expect(metrics.containsKey(dataType.code), isTrue);
          expect(metrics[dataType.code], contains('averageLatency'));
          expect(metrics[dataType.code], contains('errorCount'));
          expect(metrics[dataType.code], contains('requestCount'));
          expect(metrics[dataType.code], contains('errorRate'));
        }
      });
    });

    group('配置管理', () {
      test('应该正确更新数据获取配置', () {
        final customConfig = DataFetchConfig(
          dataType: DataType.fundNetValue,
          autoFetchEnabled: false,
          customInterval: const Duration(minutes: 30),
          maxRetries: 5,
        );

        manager.updateConfig(DataType.fundNetValue, customConfig);

        final retrievedConfig = manager.getConfig(DataType.fundNetValue);
        expect(retrievedConfig, isNotNull);
        expect(retrievedConfig!.autoFetchEnabled, isFalse);
        expect(retrievedConfig.customInterval, const Duration(minutes: 30));
        expect(retrievedConfig.maxRetries, 5);
      });

      test('应该返回默认配置当没有设置自定义配置时', () {
        final defaultConfig = manager.getConfig(DataType.marketIndex);
        expect(defaultConfig, isNotNull);
        expect(defaultConfig!.autoFetchEnabled, isTrue);
        expect(defaultConfig.customInterval, isNull);
        expect(defaultConfig.maxRetries, 3);
      });
    });

    group('健康状态检查', () {
      test('应该提供完整的系统健康状态', () async {
        manager.registerStrategy(mockStrategy1);

        final healthStatus = await manager.getHealthStatus();

        expect(healthStatus.containsKey('manager'), isTrue);
        expect(healthStatus.containsKey('performance'), isTrue);
        expect(healthStatus.containsKey('cache'), isTrue);
        expect(healthStatus.containsKey('strategies'), isTrue);

        expect(healthStatus['manager']['state'], ManagerState.ready.name);
        expect(healthStatus['strategies']['MockStrategy1']['healthy'], isTrue);
      });
    });

    group('启动和停止管理', () {
      test('应该正确启动所有策略', () async {
        manager.registerStrategy(mockStrategy1);
        manager.registerStrategy(mockStrategy2);

        await manager.start();
        expect(manager.state, ManagerState.running);
      });

      test('应该正确停止所有策略', () async {
        manager.registerStrategy(mockStrategy1);
        manager.registerStrategy(mockStrategy2);

        await manager.start();
        await manager.stop();
        expect(manager.state, ManagerState.stopped);
      });
    });

    group('缓存健康状态', () {
      test('应该正确计算缓存健康度', () async {
        final cacheHealth = await manager.getCacheHealthStatus();

        expect(cacheHealth.containsKey('hiveAdapter'), isTrue);
        expect(cacheHealth.containsKey('memoryCache'), isTrue);
        expect(cacheHealth.containsKey('overallHealth'), isTrue);

        expect(cacheHealth['memoryCache']['size'], isA<int>());
        expect(cacheHealth['memoryCache']['maxSize'], 1000);
        expect(cacheHealth['overallHealth'], isA<double>());
      });
    });
  });

  group('DataItem', () {
    test('应该正确检查数据是否过期', () {
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

    test('应该正确计算数据年龄', () {
      final data = DataItem(
        dataType: DataType.fundNetValue,
        data: {'value': 1.23},
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        quality: DataQualityLevel.good,
        source: DataSource.httpPolling,
        id: 'age-test',
      );

      expect(data.age.inMinutes, 5);
    });

    test('应该正确序列化和反序列化', () {
      final originalData = DataItem(
        dataType: DataType.fundNetValue,
        data: {'value': 1.23, 'fundCode': '000001'},
        timestamp: DateTime.now(),
        quality: DataQualityLevel.excellent,
        source: DataSource.websocket,
        id: 'serialization-test',
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      final json = originalData.toJson();
      final deserializedData = DataItem.fromJson(json);

      expect(deserializedData.dataType, originalData.dataType);
      expect(deserializedData.data, originalData.data);
      expect(deserializedData.quality, originalData.quality);
      expect(deserializedData.source, originalData.source);
      expect(deserializedData.id, originalData.id);
      expect(deserializedData.expiresAt, originalData.expiresAt);
    });
  });

  group('FetchResult', () {
    test('应该正确创建成功结果', () {
      final dataItem = DataItem(
        dataType: DataType.fundNetValue,
        data: {'value': 1.23},
        timestamp: DateTime.now(),
        quality: DataQualityLevel.good,
        source: DataSource.httpPolling,
        id: 'success-test',
      );

      final result = FetchResult.success(dataItem);

      expect(result.success, isTrue);
      expect(result.dataItem, dataItem);
      expect(result.errorMessage, isNull);
      expect(result.shouldRetry, isFalse);
      expect(result.retryDelay, isNull);
    });

    test('应该正确创建失败结果', () {
      const result = FetchResult.failure('Network error');

      expect(result.success, isFalse);
      expect(result.dataItem, isNull);
      expect(result.errorMessage, 'Network error');
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, const Duration(seconds: 5));
    });
  });

  group('DataType', () {
    test('应该正确识别数据类型优先级', () {
      expect(DataType.connectionStatus.priority, DataPriority.critical.value);
      expect(DataType.marketIndex.priority, DataPriority.high.value);
      expect(DataType.fundNetValue.priority, DataPriority.medium.value);
      expect(DataType.historicalPerformance.priority, DataPriority.low.value);
    });

    test('应该正确识别实时数据类型', () {
      expect(DataType.connectionStatus.isRealtime, isTrue);
      expect(DataType.marketIndex.isRealtime, isTrue);
      expect(DataType.fundNetValue.isQuasiRealtime, isTrue);
      expect(DataType.historicalPerformance.isOnDemand, isTrue);
    });

    test('应该提供正确的API端点', () {
      expect(DataType.fundNetValue.apiEndpoint, '/api/fund/nav');
      expect(DataType.marketIndex.apiEndpoint, '/api/stock/realtime');
      expect(DataType.connectionStatus.apiEndpoint, '/api/system/status');
    });

    test('应该正确从代码解析数据类型', () {
      expect(DataType.fromCode('fund_net_value'), DataType.fundNetValue);
      expect(DataType.fromCode('market_index'), DataType.marketIndex);
      expect(DataType.fromCode('unknown_type'), isNull);
    });
  });

  group('DataFetchConfig', () {
    test('应该正确创建默认配置', () {
      final config = DataFetchConfig.defaultForType(DataType.fundNetValue);

      expect(config.dataType, DataType.fundNetValue);
      expect(config.autoFetchEnabled, isTrue);
      expect(config.strategyPreference, FetchStrategyPreference.auto);
      expect(config.maxRetries, 3);
      expect(config.timeout, const Duration(seconds: 30));
      expect(config.cacheEnabled, isTrue);
    });

    test('应该正确计算有效更新间隔', () {
      final defaultConfig =
          DataFetchConfig.defaultForType(DataType.fundNetValue);
      expect(defaultConfig.effectiveInterval,
          DataType.fundNetValue.defaultUpdateInterval);

      final customConfig = DataFetchConfig(
        dataType: DataType.fundNetValue,
        customInterval: const Duration(minutes: 30),
      );
      expect(customConfig.effectiveInterval, const Duration(minutes: 30));
    });

    test('应该正确序列化和反序列化配置', () {
      final originalConfig = DataFetchConfig(
        dataType: DataType.fundNetValue,
        autoFetchEnabled: false,
        customInterval: const Duration(minutes: 20),
        strategyPreference: FetchStrategyPreference.websocket,
        maxRetries: 5,
        timeout: const Duration(seconds: 60),
        cacheEnabled: false,
        cacheExpiration: const Duration(hours: 2),
      );

      final json = originalConfig.toJson();
      final deserializedConfig = DataFetchConfig.fromJson(json);

      expect(deserializedConfig.dataType, originalConfig.dataType);
      expect(
          deserializedConfig.autoFetchEnabled, originalConfig.autoFetchEnabled);
      expect(deserializedConfig.customInterval, originalConfig.customInterval);
      expect(deserializedConfig.strategyPreference,
          originalConfig.strategyPreference);
      expect(deserializedConfig.maxRetries, originalConfig.maxRetries);
      expect(deserializedConfig.timeout, originalConfig.timeout);
      expect(deserializedConfig.cacheEnabled, originalConfig.cacheEnabled);
      expect(
          deserializedConfig.cacheExpiration, originalConfig.cacheExpiration);
    });
  });
}
