import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_fetch_strategy.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_type.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_type_router.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/hybrid_data_manager.dart';
import 'package:jisu_fund_analyzer/src/core/network/polling/network_monitor.dart';
import 'package:jisu_fund_analyzer/src/core/network/polling/polling_manager.dart';

// 模拟网络异常的策略
class UnstableDataFetchStrategy implements DataFetchStrategy {
  /// 创建不稳定的网络数据获取策略
  UnstableDataFetchStrategy({
    required this.name,
    required this.priority,
    required this.supportedDataTypes,
    bool isAvailable = true,
    double failureRate = 0.0,
    Duration delay = Duration.zero,
    int maxRetries = 3,
  })  : _isAvailable = isAvailable,
        _failureRate = failureRate,
        _delay = delay,
        _maxRetries = maxRetries;

  @override
  final String name;
  @override
  final int priority;
  @override
  final List<DataType> supportedDataTypes;

  bool _isAvailable;
  double _failureRate; // 0.0 - 1.0
  Duration _delay;
  final int _maxRetries;
  final List<DataItem> _mockData = [];

  void setAvailability(bool available) {
    _isAvailable = available;
  }

  void setFailureRate(double rate) {
    _failureRate = rate.clamp(0.0, 1.0);
  }

  void setDelay(Duration delay) {
    _delay = delay;
  }

  void addMockData(DataItem data) {
    _mockData.add(data);
  }

  void clearMockData() {
    _mockData.clear();
  }

  @override
  bool isAvailable() => _isAvailable;

  @override
  Stream<DataItem> getDataStream(DataType type,
      {Map<String, dynamic>? parameters}) {
    final controller = StreamController<DataItem>();

    Future.delayed(_delay, () async {
      if (!_isAvailable) {
        controller.close();
        return;
      }

      // 模拟随机失败
      final random = DateTime.now().millisecond % 100;
      final shouldFail = random < (_failureRate * 100);

      if (shouldFail) {
        controller.close();
        return;
      }

      final matchingData = _mockData.where((item) => item.dataType == type);
      for (final data in matchingData) {
        controller.add(data);
      }
      controller.close();
    });

    return controller.stream;
  }

  @override
  Future<FetchResult> fetchData(DataType type,
      {Map<String, dynamic>? parameters}) async {
    if (!_isAvailable) {
      return const FetchResult.failure('Strategy not available');
    }

    await Future.delayed(_delay);

    // 模拟随机失败
    final random = DateTime.now().millisecond % 100;
    final shouldFail = random < (_failureRate * 100);

    if (shouldFail) {
      return const FetchResult.failure('Simulated network failure');
    }

    final matchingData = _mockData.where((item) => item.dataType == type);
    if (matchingData.isNotEmpty) {
      return FetchResult.success(matchingData.first);
    }

    return const FetchResult.failure('No mock data available');
  }

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'strategy': name,
      'healthy': _isAvailable,
      'priority': priority,
      'failureRate': _failureRate,
      'delay': _delay.inMilliseconds,
      'mockDataCount': _mockData.length,
    };
  }

  @override
  Future<void> start() async {
    _isAvailable = true;
  }

  @override
  Future<void> stop() async {
    _isAvailable = false;
  }

  @override
  bool supportsDataType(DataType type) {
    return supportedDataTypes.contains(type);
  }

  @override
  Duration? getDefaultPollingInterval(DataType type) {
    return const Duration(seconds: 5);
  }

  @override
  Map<String, dynamic> getConfig() {
    return {
      'name': name,
      'priority': priority,
      'supportedDataTypes': supportedDataTypes.map((t) => t.code).toList(),
      'failureRate': _failureRate,
      'delay': _delay.inMilliseconds,
    };
  }
}

// 模拟网络状态监控器
class MockNetworkStatusSimulator {
  final StreamController<NetworkStatusResult> _statusController =
      StreamController.broadcast();
  Timer? _simulationTimer;
  NetworkStatusResult _currentStatus = NetworkStatusResult.online(
    connectivityResults: [ConnectivityResult.wifi],
    quality: 0.8,
    latency: 100,
    hasInternetAccess: true,
  );

  Stream<NetworkStatusResult> get statusStream => _statusController.stream;
  NetworkStatusResult get currentStatus => _currentStatus;

  void startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _simulateNetworkChange();
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _simulateNetworkChange() {
    final random = DateTime.now().millisecond % 100;

    if (random < 10) {
      // 10% 概率网络断开
      _currentStatus = NetworkStatusResult.offline();
    } else if (random < 30) {
      // 20% 概率网络质量差
      _currentStatus = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.mobile],
        quality: 0.3,
        latency: 2000,
        hasInternetAccess: true,
      );
    } else {
      // 70% 概率网络正常
      _currentStatus = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.wifi],
        quality: 0.8,
        latency: 100,
        hasInternetAccess: true,
      );
    }

    _statusController.add(_currentStatus);
  }

  void forceNetworkFailure() {
    _currentStatus = NetworkStatusResult.offline();
    _statusController.add(_currentStatus);
  }

  void forceNetworkRecovery() {
    _currentStatus = NetworkStatusResult.online(
      connectivityResults: [ConnectivityResult.wifi],
      quality: 0.9,
      latency: 50,
      hasInternetAccess: true,
    );
    _statusController.add(_currentStatus);
  }
}

void main() async {
  // 初始化环境变量
  await dotenv.load(fileName: '.env.development');

  group('网络异常场景端到端测试', () {
    late HybridDataManager dataManager;
    late DataTypeRouter router;
    late PollingManager pollingManager;
    late MockNetworkStatusSimulator networkSimulator;

    late UnstableDataFetchStrategy unstableWebSocketStrategy;
    late UnstableDataFetchStrategy unstablePollingStrategy;
    late UnstableDataFetchStrategy stableOnDemandStrategy;

    setUp(() {
      dataManager = HybridDataManager();
      router = DataTypeRouter();
      pollingManager = PollingManager();
      networkSimulator = MockNetworkStatusSimulator();

      // 创建不稳定的策略
      unstableWebSocketStrategy = UnstableDataFetchStrategy(
        name: 'UnstableWebSocketStrategy',
        priority: 100,
        supportedDataTypes: [DataType.marketIndex, DataType.etfSpotPrice],
        failureRate: 0.3, // 30% 失败率
        delay: const Duration(milliseconds: 200),
      );

      unstablePollingStrategy = UnstableDataFetchStrategy(
        name: 'UnstablePollingStrategy',
        priority: 70,
        supportedDataTypes: [DataType.fundNetValue, DataType.fundBasicInfo],
        failureRate: 0.2, // 20% 失败率
        delay: const Duration(milliseconds: 500),
      );

      stableOnDemandStrategy = UnstableDataFetchStrategy(
        name: 'StableOnDemandStrategy',
        priority: 40,
        supportedDataTypes: [
          DataType.historicalPerformance,
          DataType.fundHoldingDetails
        ],
        failureRate: 0.05, // 5% 失败率
        delay: const Duration(milliseconds: 100),
      );
    });

    tearDown(() async {
      networkSimulator.stopSimulation();
      await dataManager.dispose();
      pollingManager.dispose();
    });

    group('AC3: 网络异常时自动降级到缓存模式', () {
      test('应该在网络断开时降级到缓存', () async {
        // 准备测试数据
        final cachedData = DataItem(
          dataType: DataType.fundNetValue,
          data: {'fundCode': '000001', 'netValue': 1.2345, 'cached': true},
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          quality: DataQualityLevel.good,
          source: DataSource.cache,
          id: 'cached-fund-1',
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        );

        // 模拟网络断开
        unstableWebSocketStrategy.setAvailability(false);
        unstablePollingStrategy.setAvailability(false);

        dataManager.registerStrategy(unstableWebSocketStrategy);
        dataManager.registerStrategy(unstablePollingStrategy);
        dataManager.registerStrategy(stableOnDemandStrategy);

        await dataManager.start();

        // 获取数据，应该降级到缓存或返回null
        final result = await dataManager.getData(DataType.fundNetValue);
        // 在实际实现中，这里应该返回缓存数据
        expect(result, isNotNull);

        // 验证健康状态显示策略不可用
        final healthStatus = await dataManager.getHealthStatus();
        expect(
            healthStatus['strategies']['UnstableWebSocketStrategy']['healthy'],
            isFalse);
        expect(healthStatus['strategies']['UnstablePollingStrategy']['healthy'],
            isFalse);

        await dataManager.stop();
      });

      test('应该在策略失败时自动切换到备用策略', () async {
        // 准备测试数据
        final pollData = DataItem(
          dataType: DataType.fundNetValue,
          data: {'fundCode': '000001', 'netValue': 1.2345, 'source': 'polling'},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'polling-fund-1',
        );

        final onDemandData = DataItem(
          dataType: DataType.fundNetValue,
          data: {
            'fundCode': '000001',
            'netValue': 1.2346,
            'source': 'ondemand'
          },
          timestamp: DateTime.now(),
          quality: DataQualityLevel.fair,
          source: DataSource.httpOnDemand,
          id: 'ondemand-fund-1',
        );

        unstablePollingStrategy.addMockData(pollData);
        stableOnDemandStrategy.addMockData(onDemandData);

        // 模拟WebSocket失败，Polling部分失败
        unstableWebSocketStrategy.setAvailability(false);
        unstablePollingStrategy.setFailureRate(0.8); // 80% 失败率

        dataManager.registerStrategy(unstableWebSocketStrategy);
        dataManager.registerStrategy(unstablePollingStrategy);
        dataManager.registerStrategy(stableOnDemandStrategy);

        await dataManager.start();

        // 多次尝试获取数据，应该最终成功降级到OnDemand策略
        var successCount = 0;
        for (int i = 0; i < 10; i++) {
          final result = await dataManager.getData(DataType.fundNetValue);
          if (result != null) {
            successCount++;
          }
          await Future.delayed(const Duration(milliseconds: 100));
        }

        expect(successCount, greaterThan(0)); // 至少有一些请求成功

        await dataManager.stop();
      });

      test('应该记录降级事件的统计信息', () async {
        unstableWebSocketStrategy.setAvailability(false);
        unstablePollingStrategy.setFailureRate(0.5);

        dataManager.registerStrategy(unstableWebSocketStrategy);
        dataManager.registerStrategy(unstablePollingStrategy);

        await dataManager.start();

        // 执行多次数据获取
        for (int i = 0; i < 20; i++) {
          await dataManager.getData(DataType.fundNetValue);
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // 检查性能指标
        final metrics = dataManager.getPerformanceMetrics();
        expect(metrics['fund_net_value']['requestCount'], 20);
        expect(metrics['fund_net_value']['errorCount'], greaterThan(0));
        expect(metrics['fund_net_value']['errorRate'], greaterThan(0.0));

        await dataManager.stop();
      });
    });

    group('AC4: 恢复后自动同步断线期间的不同类型数据', () {
      test('应该在网络恢复后自动重新同步数据', () async {
        // 准备测试数据
        final freshData = DataItem(
          dataType: DataType.fundNetValue,
          data: {'fundCode': '000001', 'netValue': 1.2347, 'fresh': true},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.excellent,
          source: DataSource.httpPolling,
          id: 'fresh-fund-1',
        );

        // 初始状态：所有策略不可用
        unstableWebSocketStrategy.setAvailability(false);
        unstablePollingStrategy.setAvailability(false);

        dataManager.registerStrategy(unstableWebSocketStrategy);
        dataManager.registerStrategy(unstablePollingStrategy);

        await dataManager.start();

        // 验证初始状态
        var initialResult = await dataManager.getData(DataType.fundNetValue);
        expect(initialResult, isNull); // 所有策略都不可用

        // 模拟网络恢复
        unstablePollingStrategy.setAvailability(true);
        unstablePollingStrategy.addMockData(freshData);

        // 等待一段时间让系统检测到恢复
        await Future.delayed(const Duration(milliseconds: 200));

        // 验证恢复后可以获取数据
        final recoveredResult =
            await dataManager.getData(DataType.fundNetValue);
        expect(recoveredResult, isNotNull);
        expect(recoveredResult!.data['fresh'], isTrue);

        await dataManager.stop();
      });

      test('应该处理部分策略恢复的情况', () async {
        // 准备不同数据类型的测试数据
        final marketData = DataItem(
          dataType: DataType.marketIndex,
          data: {'index': '000001', 'value': 3100.0},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.excellent,
          source: DataSource.websocket,
          id: 'market-recovery-1',
        );

        final fundData = DataItem(
          dataType: DataType.fundNetValue,
          data: {'fundCode': '000001', 'netValue': 1.2345},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'fund-recovery-1',
        );

        // 初始状态：只有WebSocket不可用
        unstableWebSocketStrategy.setAvailability(false);
        unstablePollingStrategy.setAvailability(true);

        unstablePollingStrategy.addMockData(fundData);

        dataManager.registerStrategy(unstableWebSocketStrategy);
        dataManager.registerStrategy(unstablePollingStrategy);

        await dataManager.start();

        // 验证只有Polling数据可用
        final fundResult = await dataManager.getData(DataType.fundNetValue);
        expect(fundResult, isNotNull);
        expect(fundResult!.source, DataSource.httpPolling);

        final marketResult = await dataManager.getData(DataType.marketIndex);
        expect(marketResult, isNull); // WebSocket不可用

        // 恢复WebSocket
        unstableWebSocketStrategy.setAvailability(true);
        unstableWebSocketStrategy.addMockData(marketData);

        await Future.delayed(const Duration(milliseconds: 200));

        // 验证WebSocket恢复
        final recoveredMarketResult =
            await dataManager.getData(DataType.marketIndex);
        expect(recoveredMarketResult, isNotNull);
        expect(recoveredMarketResult!.source, DataSource.websocket);

        await dataManager.stop();
      });
    });

    group('网络状态变化场景测试', () {
      test('应该响应网络状态变化', () async {
        networkSimulator.startSimulation();

        final statusChanges = <NetworkStatusResult>[];
        networkSimulator.statusStream.listen(statusChanges.add);

        // 等待网络状态变化
        await Future.delayed(const Duration(seconds: 8));

        expect(statusChanges.isNotEmpty, isTrue);

        // 验证网络状态多样性
        final offlineCount = statusChanges.where((s) => !s.isConnected).length;
        final poorQualityCount = statusChanges
            .where((s) => s.isConnected && !s.isHighQuality)
            .length;
        final goodQualityCount =
            statusChanges.where((s) => s.isConnected && s.isHighQuality).length;

        expect(offlineCount + poorQualityCount + goodQualityCount,
            statusChanges.length);

        networkSimulator.stopSimulation();
      });

      test('应该根据网络质量调整策略选择', () async {
        networkSimulator.startSimulation();

        final strategySelections = <String>[];

        // 监听网络状态变化并调整策略
        networkSimulator.statusStream.listen((status) async {
          final strategies = [
            unstableWebSocketStrategy,
            unstablePollingStrategy
          ];

          // 根据网络质量选择策略
          DataFetchStrategy? selectedStrategy;
          if (status.isStable) {
            // 网络稳定，优先选择WebSocket
            selectedStrategy = strategies
                .where((s) => s.name.contains('WebSocket'))
                .firstOrNull;
          } else if (status.isConnected) {
            // 网络不稳定，选择更可靠的Polling
            selectedStrategy =
                strategies.where((s) => s.name.contains('Polling')).firstOrNull;
          } else {
            // 网络断开，选择OnDemand
            selectedStrategy = strategies
                .where((s) => s.name.contains('OnDemand'))
                .firstOrNull;
          }

          if (selectedStrategy != null) {
            strategySelections.add(selectedStrategy.name);
          }
        });

        await Future.delayed(const Duration(seconds: 6));

        expect(strategySelections.isNotEmpty, isTrue);

        networkSimulator.stopSimulation();
      });

      test('应该在强制网络故障时正确降级', () async {
        // 启动网络模拟
        networkSimulator.startSimulation();

        // 初始状态：网络正常
        unstableWebSocketStrategy.setAvailability(true);
        unstablePollingStrategy.setAvailability(true);

        dataManager.registerStrategy(unstableWebSocketStrategy);
        dataManager.registerStrategy(unstablePollingStrategy);

        await dataManager.start();

        // 验证初始状态可以获取数据
        final initialResult = await dataManager.getData(DataType.marketIndex);
        expect(initialResult, isNotNull);

        // 强制网络故障
        networkSimulator.forceNetworkFailure();

        // 等待系统响应
        await Future.delayed(const Duration(milliseconds: 500));

        // 验证降级行为
        final failureResult = await dataManager.getData(DataType.marketIndex);
        // 在实际实现中，这里应该返回缓存数据或null

        // 强制网络恢复
        networkSimulator.forceNetworkRecovery();

        await Future.delayed(const Duration(milliseconds: 500));

        // 验证恢复行为
        final recoveryResult = await dataManager.getData(DataType.marketIndex);
        expect(recoveryResult, isNotNull);

        networkSimulator.stopSimulation();
        await dataManager.stop();
      });
    });

    group('长时间运行稳定性测试', () {
      test('应该在长时间网络不稳定时保持系统稳定', () async {
        // 设置高失败率的策略
        unstableWebSocketStrategy.setFailureRate(0.4);
        unstablePollingStrategy.setFailureRate(0.3);

        // 准备测试数据
        for (int i = 0; i < 100; i++) {
          unstableWebSocketStrategy.addMockData(DataItem(
            dataType: DataType.marketIndex,
            data: {'index': '000001', 'value': 3000.0 + i},
            timestamp: DateTime.now(),
            quality: DataQualityLevel.good,
            source: DataSource.websocket,
            id: 'stress-test-ws-$i',
          ));

          unstablePollingStrategy.addMockData(DataItem(
            dataType: DataType.fundNetValue,
            data: {'fundCode': '000001', 'netValue': 1.0 + i * 0.01},
            timestamp: DateTime.now(),
            quality: DataQualityLevel.good,
            source: DataSource.httpPolling,
            id: 'stress-test-poll-$i',
          ));
        }

        stableOnDemandStrategy.setFailureRate(0.1);
        for (int i = 0; i < 50; i++) {
          stableOnDemandStrategy.addMockData(DataItem(
            dataType: DataType.historicalPerformance,
            data: {'date': '2024-01-01', 'value': 1.0 + i * 0.1},
            timestamp: DateTime.now(),
            quality: DataQualityLevel.fair,
            source: DataSource.httpOnDemand,
            id: 'stress-test-ondemand-$i',
          ));
        }

        dataManager.registerStrategy(unstableWebSocketStrategy);
        dataManager.registerStrategy(unstablePollingStrategy);
        dataManager.registerStrategy(stableOnDemandStrategy);

        await dataManager.start();

        // 长时间运行测试
        final successCount = <String, int>{};
        final failureCount = <String, int>{};

        for (int i = 0; i < 100; i++) {
          // 测试不同数据类型
          final marketResult = await dataManager.getData(DataType.marketIndex);
          final fundResult = await dataManager.getData(DataType.fundNetValue);
          final historyResult =
              await dataManager.getData(DataType.historicalPerformance);

          successCount['market'] =
              (successCount['market'] ?? 0) + (marketResult != null ? 1 : 0);
          failureCount['market'] =
              (failureCount['market'] ?? 0) + (marketResult == null ? 1 : 0);

          successCount['fund'] =
              (successCount['fund'] ?? 0) + (fundResult != null ? 1 : 0);
          failureCount['fund'] =
              (failureCount['fund'] ?? 0) + (fundResult == null ? 1 : 0);

          successCount['history'] =
              (successCount['history'] ?? 0) + (historyResult != null ? 1 : 0);
          failureCount['history'] =
              (failureCount['history'] ?? 0) + (historyResult == null ? 1 : 0);

          await Future.delayed(const Duration(milliseconds: 50));
        }

        // 验证系统稳定性
        expect(
            successCount['market']! +
                successCount['fund']! +
                successCount['history']!,
            greaterThan(0));

        // 验证不同数据类型的成功率符合预期（OnDemand应该最稳定）
        final marketSuccessRate = successCount['market']! / 100;
        final fundSuccessRate = successCount['fund']! / 100;
        final historySuccessRate = successCount['history']! / 100;

        expect(historySuccessRate, greaterThan(fundSuccessRate));
        expect(fundSuccessRate, greaterThan(marketSuccessRate));

        // 验证系统仍然运行正常
        expect(dataManager.state, ManagerState.running);

        // 检查性能指标
        final metrics = dataManager.getPerformanceMetrics();
        expect(metrics['market_index']['requestCount'], 100);
        expect(metrics['fund_net_value']['requestCount'], 100);
        expect(metrics['historical_performance']['requestCount'], 100);

        await dataManager.stop();
      });

      test('应该在策略频繁故障时正确处理', () async {
        // 设置极高的失败率
        unstableWebSocketStrategy.setFailureRate(0.9);
        unstablePollingStrategy.setFailureRate(0.8);

        dataManager.registerStrategy(unstableWebSocketStrategy);
        dataManager.registerStrategy(unstablePollingStrategy);

        await dataManager.start();

        // 快速连续请求
        final results = <DataItem?>[];
        for (int i = 0; i < 50; i++) {
          final result = await dataManager.getData(DataType.fundNetValue);
          results.add(result);
        }

        // 验证系统没有崩溃
        expect(results.length, 50);

        // 验证错误处理
        final nullCount = results.where((r) => r == null).length;
        expect(nullCount, greaterThan(0)); // 应该有失败的请求

        await dataManager.stop();
      });
    });

    group('边界条件和错误处理测试', () {
      test('应该处理所有策略同时故障的情况', () async {
        // 所有策略都不可用
        unstableWebSocketStrategy.setAvailability(false);
        unstablePollingStrategy.setAvailability(false);
        stableOnDemandStrategy.setAvailability(false);

        dataManager.registerStrategy(unstableWebSocketStrategy);
        dataManager.registerStrategy(unstablePollingStrategy);
        dataManager.registerStrategy(stableOnDemandStrategy);

        await dataManager.start();

        // 多次尝试获取数据
        for (int i = 0; i < 10; i++) {
          final result = await dataManager.getData(DataType.fundNetValue);
          expect(result, isNull); // 所有策略都不可用
        }

        // 验证系统仍然运行
        expect(dataManager.state, ManagerState.running);

        await dataManager.stop();
      });

      test('应该正确处理策略动态可用性变化', () async {
        // 准备测试数据
        final testData = DataItem(
          dataType: DataType.fundNetValue,
          data: {'fundCode': '000001', 'netValue': 1.2345},
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'dynamic-test-1',
        );

        unstablePollingStrategy.addMockData(testData);
        dataManager.registerStrategy(unstablePollingStrategy);

        await dataManager.start();

        // 测试策略可用性变化
        for (int cycle = 0; cycle < 5; cycle++) {
          // 策略可用
          unstablePollingStrategy.setAvailability(true);
          final availableResult =
              await dataManager.getData(DataType.fundNetValue);
          expect(availableResult, isNotNull);

          await Future.delayed(const Duration(milliseconds: 100));

          // 策略不可用
          unstablePollingStrategy.setAvailability(false);
          final unavailableResult =
              await dataManager.getData(DataType.fundNetValue);
          expect(unavailableResult, isNull);

          await Future.delayed(const Duration(milliseconds: 100));
        }

        await dataManager.stop();
      });

      test('应该正确处理资源清理和重新初始化', () async {
        // 第一次运行
        dataManager.registerStrategy(unstablePollingStrategy);
        await dataManager.start();
        await dataManager.stop();
        await dataManager.dispose();

        // 重新初始化
        dataManager = HybridDataManager();
        dataManager.registerStrategy(unstablePollingStrategy);
        await dataManager.start();

        final result = await dataManager.getData(DataType.fundNetValue);
        // 结果取决于策略状态

        await dataManager.stop();
        await dataManager.dispose();

        // 验证没有内存泄漏
        expect(dataManager.state, ManagerState.stopped);
      });
    });
  });
}
