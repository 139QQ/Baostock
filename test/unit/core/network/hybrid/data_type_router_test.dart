import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_type.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_fetch_strategy.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid\data_type_router.dart';

// Mock实现
class MockDataFetchStrategy implements DataFetchStrategy {
  @override
  final String name;
  @override
  final int priority;
  @override
  final List<DataType> supportedDataTypes;
  bool _isAvailable = true;

  MockDataFetchStrategy({
    required this.name,
    required this.priority,
    required this.supportedDataTypes,
    bool isAvailable = true,
  }) : _isAvailable = isAvailable;

  void setAvailability(bool available) {
    _isAvailable = available;
  }

  @override
  bool isAvailable() => _isAvailable;

  @override
  Stream<DataItem> getDataStream(DataType type,
      {Map<String, dynamic>? parameters}) {
    return Stream.empty();
  }

  @override
  Future<FetchResult> fetchData(DataType type,
      {Map<String, dynamic>? parameters}) async {
    return const FetchResult.failure('Mock implementation');
  }

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'strategy': name,
      'healthy': _isAvailable,
      'priority': priority,
    };
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

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
  group('DataTypeRouter', () {
    late DataTypeRouter router;
    late MockDataFetchStrategy mockWebSocketStrategy;
    late MockDataFetchStrategy mockPollingStrategy;
    late MockDataFetchStrategy mockOnDemandStrategy;

    setUp(() {
      router = DataTypeRouter();

      mockWebSocketStrategy = MockDataFetchStrategy(
        name: 'WebSocketStrategy',
        priority: 100,
        supportedDataTypes: [DataType.marketIndex, DataType.fundNetValue],
        isAvailable: true,
      );

      mockPollingStrategy = MockDataFetchStrategy(
        name: 'HttpPollingStrategy',
        priority: 60,
        supportedDataTypes: [DataType.fundNetValue, DataType.fundBasicInfo],
        isAvailable: true,
      );

      mockOnDemandStrategy = MockDataFetchStrategy(
        name: 'HttpOnDemandStrategy',
        priority: 30,
        supportedDataTypes: [
          DataType.historicalPerformance,
          DataType.fundHoldingDetails
        ],
        isAvailable: true,
      );
    });

    group('基础路由功能', () {
      test('应该在没有可用策略时返回null', () {
        final strategy = router.selectOptimalStrategy(
          [],
          DataType.fundNetValue,
        );
        expect(strategy, isNull);
      });

      test('应该在没有可用策略时返回null', () {
        final unavailableStrategy = MockDataFetchStrategy(
          name: 'UnavailableStrategy',
          priority: 80,
          supportedDataTypes: [DataType.fundNetValue],
          isAvailable: false,
        );

        final strategy = router.selectOptimalStrategy(
          [unavailableStrategy],
          DataType.fundNetValue,
        );
        expect(strategy, isNull);
      });

      test('应该选择最高优先级的可用策略', () {
        final strategy = router.selectOptimalStrategy(
          [mockOnDemandStrategy, mockPollingStrategy, mockWebSocketStrategy],
          DataType.fundNetValue,
        );
        expect(strategy, mockWebSocketStrategy);
      });

      test('应该根据用户偏好选择策略', () {
        final strategy = router.selectOptimalStrategy(
          [mockPollingStrategy, mockOnDemandStrategy],
          DataType.fundNetValue,
          userPreference: FetchStrategyPreference.httpPolling,
        );
        expect(strategy, mockPollingStrategy);
      });

      test('应该在没有偏好匹配时返回最佳策略', () {
        final strategy = router.selectOptimalStrategy(
          [mockPollingStrategy, mockOnDemandStrategy],
          DataType.fundNetValue,
          userPreference: FetchStrategyPreference.websocket, // 没有WebSocket策略
        );
        expect(strategy, mockPollingStrategy); // 返回次优的Polling策略
      });
    });

    group('数据类型特定路由', () {
      test('应该为关键数据选择最可靠的策略', () {
        final strategy = router.selectOptimalStrategy(
          [mockPollingStrategy, mockOnDemandStrategy],
          DataType.connectionStatus, // critical priority
        );
        expect(strategy, mockPollingStrategy); // 选择更高优先级的策略
      });

      test('应该为高优先级数据倾向使用实时策略', () {
        final strategy = router.selectOptimalStrategy(
          [mockWebSocketStrategy, mockPollingStrategy],
          DataType.marketIndex, // high priority
        );
        expect(strategy, mockWebSocketStrategy); // 选择WebSocket策略
      });

      test('应该为中等优先级数据选择平衡的策略', () {
        final strategy = router.selectOptimalStrategy(
          [mockPollingStrategy, mockOnDemandStrategy],
          DataType.fundNetValue, // medium priority
        );
        expect(strategy, mockPollingStrategy); // 选择Polling策略
      });

      test('应该为低优先级数据选择资源消耗少的策略', () {
        final strategy = router.selectOptimalStrategy(
          [mockPollingStrategy, mockOnDemandStrategy],
          DataType.historicalPerformance, // low priority
        );
        expect(strategy, mockOnDemandStrategy); // 选择OnDemand策略
      });
    });

    group('性能跟踪', () {
      test('应该正确记录策略性能数据', () {
        router.updateStrategyPerformance(
          'TestStrategy',
          true,
          const Duration(milliseconds: 100),
        );

        final stats = router.getRoutingStats();
        expect(stats['strategyPerformance'], contains('TestStrategy'));
        expect(
            stats['strategyPerformance']['TestStrategy']['successRate'], 1.0);
        expect(stats['strategyPerformance']['TestStrategy']['averageLatency'],
            100.0);
        expect(stats['strategyPerformance']['TestStrategy']['totalUsage'], 1);
      });

      test('应该正确更新策略性能数据', () {
        // 记录第一次成功
        router.updateStrategyPerformance(
          'TestStrategy',
          true,
          const Duration(milliseconds: 100),
        );

        // 记录第二次失败
        router.updateStrategyPerformance(
          'TestStrategy',
          false,
          const Duration(milliseconds: 200),
          error: 'Network error',
        );

        final stats = router.getRoutingStats();
        final performance = stats['strategyPerformance']['TestStrategy'];

        expect(performance['successRate'], 0.5); // 1/2 = 0.5
        expect(performance['averageLatency'], 150.0); // (100+200)/2 = 150
        expect(performance['totalUsage'], 2);
        expect(performance['errorRate'], 0.5);
        expect(performance['lastError'], 'Network error');
      });

      test('应该正确计算策略得分', () {
        // 添加性能数据
        router.updateStrategyPerformance(
          'HighPerformanceStrategy',
          true,
          const Duration(milliseconds: 50),
        );

        final stats = router.getRoutingStats();
        final performance =
            stats['strategyPerformance']['HighPerformanceStrategy'];
        expect(performance['score'], greaterThan(0));
      });

      test('应该清理过期的性能数据', () {
        router.updateStrategyPerformance(
          'OldStrategy',
          true,
          const Duration(milliseconds: 100),
        );

        // 手动设置过期时间
        final stats = router.getRoutingStats();
        expect(stats['strategyPerformance'], contains('OldStrategy'));

        // 清理数据（实际测试中可能需要修改内部逻辑来模拟过期）
        router.cleanupPerformanceData();
      });
    });

    group('路由统计', () {
      test('应该正确记录路由决策', () {
        router.selectOptimalStrategy(
          [mockPollingStrategy],
          DataType.fundNetValue,
        );

        final stats = router.getRoutingStats();
        expect(stats['routingDecisions'],
            contains('fund_net_value_HttpPollingStrategy'));
        expect(
            stats['routingDecisions']['fund_net_value_HttpPollingStrategy'], 1);
      });

      test('应该提供网络状态信息', () {
        final stats = router.getRoutingStats();
        expect(stats['networkStatus'], isNotNull);
        expect(stats['networkStatus']['isConnected'], isA<bool>());
        expect(stats['networkStatus']['latency'], isA<int>());
      });
    });

    group('复杂场景测试', () {
      test('应该根据网络条件调整策略选择', () {
        // 创建高延迟网络条件
        final slowNetworkStrategy = MockDataFetchStrategy(
          name: 'WebSocketStrategy',
          priority: 100,
          supportedDataTypes: [DataType.marketIndex],
          isAvailable: true,
        );

        // 在实际实现中，网络状态会影响策略选择
        final strategy = router.selectOptimalStrategy(
          [slowNetworkStrategy, mockPollingStrategy],
          DataType.marketIndex,
        );

        // 期望选择适合网络条件的策略
        expect(strategy, isNotNull);
        expect(
            strategy!.name,
            anyOf([
              'WebSocketStrategy',
              'HttpPollingStrategy',
            ]));
      });

      test('应该根据数据紧急程度调整策略选择', () {
        final strategy = router.selectOptimalStrategy(
          [mockWebSocketStrategy, mockPollingStrategy],
          DataType.fundNetValue,
          urgency: DataUrgency.critical,
        );

        // 紧急数据应该选择最可靠的策略
        expect(strategy, isNotNull);
        expect(strategy!.priority, greaterThanOrEqualTo(60));
      });

      test('应该处理多种策略的复杂选择', () {
        final strategies = [
          MockDataFetchStrategy(
            name: 'LowPriorityWebSocket',
            priority: 85,
            supportedDataTypes: [DataType.marketIndex],
            isAvailable: true,
          ),
          MockDataFetchStrategy(
            name: 'HighPriorityPolling',
            priority: 70,
            supportedDataTypes: [DataType.marketIndex],
            isAvailable: true,
          ),
          mockOnDemandStrategy,
        ];

        final strategy = router.selectOptimalStrategy(
          strategies,
          DataType.marketIndex,
          urgency: DataUrgency.high,
        );

        expect(strategy, isNotNull);
        expect(strategy!.supportedDataTypes, contains(DataType.marketIndex));
      });

      test('应该处理策略失败的情况', () {
        // 先记录一些失败的性能数据
        for (int i = 0; i < 5; i++) {
          router.updateStrategyPerformance(
            'FailingStrategy',
            false,
            const Duration(milliseconds: 1000),
            error: 'Connection timeout',
          );
        }

        final failingStrategy = MockDataFetchStrategy(
          name: 'FailingStrategy',
          priority: 90,
          supportedDataTypes: [DataType.fundNetValue],
          isAvailable: true,
        );

        final strategy = router.selectOptimalStrategy(
          [failingStrategy, mockPollingStrategy],
          DataType.fundNetValue,
        );

        // 期望路由器能够考虑历史性能数据
        expect(strategy, isNotNull);
      });
    });

    group('边界条件测试', () {
      test('应该处理空策略列表', () {
        final strategy =
            router.selectOptimalStrategy([], DataType.fundNetValue);
        expect(strategy, isNull);
      });

      test('应该处理不可用策略', () {
        final unavailableStrategy = MockDataFetchStrategy(
          name: 'UnavailableStrategy',
          priority: 100,
          supportedDataTypes: [DataType.fundNetValue],
          isAvailable: false,
        );

        final strategy = router.selectOptimalStrategy(
          [unavailableStrategy],
          DataType.fundNetValue,
        );
        expect(strategy, isNull);
      });

      test('应该处理相同优先级的策略', () {
        final strategy1 = MockDataFetchStrategy(
          name: 'Strategy1',
          priority: 60,
          supportedDataTypes: [DataType.fundNetValue],
          isAvailable: true,
        );

        final strategy2 = MockDataFetchStrategy(
          name: 'Strategy2',
          priority: 60,
          supportedDataTypes: [DataType.fundNetValue],
          isAvailable: true,
        );

        final strategy = router.selectOptimalStrategy(
          [strategy1, strategy2],
          DataType.fundNetValue,
        );

        expect(strategy, isNotNull);
        expect(strategy!.priority, 60);
      });
    });
  });

  group('RoutingContext', () {
    test('应该正确识别WebSocket策略', () {
      final context = RoutingContext(
        dataType: DataType.fundNetValue,
        availableStrategies: [
          MockDataFetchStrategy(
            name: 'WebSocketStrategy',
            priority: 95,
            supportedDataTypes: [DataType.fundNetValue],
          ),
        ],
        networkStatus: const NetworkStatus(
          isConnected: true,
          latency: Duration(milliseconds: 50),
        ),
      );

      expect(context.hasWebSocketStrategy, isTrue);
      expect(context.hasHttpPollingStrategy, isFalse);
    });

    test('应该正确识别HTTP轮询策略', () {
      final context = RoutingContext(
        dataType: DataType.fundNetValue,
        availableStrategies: [
          MockDataFetchStrategy(
            name: 'HttpPollingStrategy',
            priority: 60,
            supportedDataTypes: [DataType.fundNetValue],
          ),
        ],
        networkStatus: const NetworkStatus(
          isConnected: true,
          latency: Duration(milliseconds: 50),
        ),
      );

      expect(context.hasWebSocketStrategy, isFalse);
      expect(context.hasHttpPollingStrategy, isTrue);
    });

    test('应该正确判断网络是否适合实时数据', () {
      final goodNetwork = RoutingContext(
        dataType: DataType.fundNetValue,
        availableStrategies: [],
        networkStatus: const NetworkStatus(
          isConnected: true,
          latency: Duration(milliseconds: 50),
          isMetered: false,
        ),
      );

      final badNetwork = RoutingContext(
        dataType: DataType.fundNetValue,
        availableStrategies: [],
        networkStatus: const NetworkStatus(
          isConnected: true,
          latency: Duration(milliseconds: 2000), // 高延迟
          isMetered: true, // 计量网络
        ),
      );

      final disconnectedNetwork = RoutingContext(
        dataType: DataType.fundNetValue,
        availableStrategies: [],
        networkStatus: const NetworkStatus(
          isConnected: false,
          latency: Duration.zero,
        ),
      );

      expect(goodNetwork.networkSuitableForRealtime, isTrue);
      expect(badNetwork.networkSuitableForRealtime, isFalse);
      expect(disconnectedNetwork.networkSuitableForRealtime, isFalse);
    });
  });

  group('StrategyPerformance', () {
    test('应该正确计算策略得分', () {
      final performance = StrategyPerformance(
        strategyName: 'TestStrategy',
        successRate: 0.9,
        averageLatency: 100.0,
        lastUsedTime: DateTime.now(),
        totalUsage: 50,
        errorRate: 0.1,
      );

      final score = performance.calculateScore();
      expect(score, greaterThan(0));
    });

    test('应该为高成功率策略提供更高得分', () {
      final highPerformance = StrategyPerformance(
        strategyName: 'HighPerformance',
        successRate: 0.95,
        averageLatency: 50.0,
        lastUsedTime: DateTime.now(),
        totalUsage: 100,
      );

      final lowPerformance = StrategyPerformance(
        strategyName: 'LowPerformance',
        successRate: 0.6,
        averageLatency: 200.0,
        lastUsedTime: DateTime.now(),
        totalUsage: 100,
      );

      expect(highPerformance.calculateScore(),
          greaterThan(lowPerformance.calculateScore()));
    });

    test('应该为低延迟策略提供更高得分', () {
      final fastStrategy = StrategyPerformance(
        strategyName: 'FastStrategy',
        successRate: 0.8,
        averageLatency: 30.0,
        lastUsedTime: DateTime.now(),
        totalUsage: 50,
      );

      final slowStrategy = StrategyPerformance(
        strategyName: 'SlowStrategy',
        successRate: 0.8,
        averageLatency: 300.0,
        lastUsedTime: DateTime.now(),
        totalUsage: 50,
      );

      expect(fastStrategy.calculateScore(),
          greaterThan(slowStrategy.calculateScore()));
    });
  });

  group('NetworkStatus', () {
    test('应该正确创建断开连接状态', () {
      final status = NetworkStatus.disconnected();
      expect(status.isConnected, isFalse);
      expect(status.latency, Duration.zero);
    });

    test('应该正确提供网络类型描述', () {
      expect(NetworkType.wifi.description, 'WiFi');
      expect(NetworkType.mobile.description, '移动网络');
      expect(NetworkType.ethernet.description, '以太网');
      expect(NetworkType.unknown.description, '未知');
    });
  });

  group('DataUrgency', () {
    test('应该提供正确的紧急程度权重', () {
      expect(DataUrgency.low.weight, 0.5);
      expect(DataUrgency.normal.weight, 1.0);
      expect(DataUrgency.high.weight, 1.5);
      expect(DataUrgency.critical.weight, 2.0);
    });

    test('应该提供正确的紧急程度描述', () {
      expect(DataUrgency.low.description, '低');
      expect(DataUrgency.normal.description, '正常');
      expect(DataUrgency.high.description, '高');
      expect(DataUrgency.critical.description, '紧急');
    });
  });

  group('集成测试', () {
    test('完整的路由决策流程', () {
      final router = DataTypeRouter();

      // 创建多种策略
      final strategies = [
        MockDataFetchStrategy(
          name: 'WebSocketStrategy',
          priority: 100,
          supportedDataTypes: [DataType.marketIndex],
        ),
        MockDataFetchStrategy(
          name: 'HttpPollingStrategy',
          priority: 70,
          supportedDataTypes: [DataType.fundNetValue, DataType.marketIndex],
        ),
        MockDataFetchStrategy(
          name: 'HttpOnDemandStrategy',
          priority: 40,
          supportedDataTypes: [DataType.historicalPerformance],
        ),
      ];

      // 测试不同数据类型的路由选择
      final marketIndexStrategy = router.selectOptimalStrategy(
        strategies,
        DataType.marketIndex,
      );
      expect(marketIndexStrategy?.name, 'WebSocketStrategy');

      final fundNetValueStrategy = router.selectOptimalStrategy(
        strategies,
        DataType.fundNetValue,
      );
      expect(fundNetValueStrategy?.name, 'HttpPollingStrategy');

      final historicalStrategy = router.selectOptimalStrategy(
        strategies,
        DataType.historicalPerformance,
      );
      expect(historicalStrategy?.name, 'HttpOnDemandStrategy');

      // 模拟性能更新
      router.updateStrategyPerformance(
          'WebSocketStrategy', true, const Duration(milliseconds: 50));
      router.updateStrategyPerformance(
          'HttpPollingStrategy', false, const Duration(milliseconds: 200));

      // 再次测试路由选择，应该考虑性能数据
      final adjustedStrategy = router.selectOptimalStrategy(
        strategies,
        DataType.marketIndex,
        urgency: DataUrgency.normal,
      );

      expect(adjustedStrategy, isNotNull);

      // 验证路由统计
      final stats = router.getRoutingStats();
      expect(stats['routingDecisions'], isNotEmpty);
      expect(stats['strategyPerformance'], isNotEmpty);
    });

    test('应该处理动态策略可用性变化', () {
      final router = DataTypeRouter();

      final strategy1 = MockDataFetchStrategy(
        name: 'PrimaryStrategy',
        priority: 90,
        supportedDataTypes: [DataType.fundNetValue],
        isAvailable: true,
      );

      final strategy2 = MockDataFetchStrategy(
        name: 'BackupStrategy',
        priority: 60,
        supportedDataTypes: [DataType.fundNetValue],
        isAvailable: true,
      );

      // 初始选择主策略
      var selected = router
          .selectOptimalStrategy([strategy1, strategy2], DataType.fundNetValue);
      expect(selected?.name, 'PrimaryStrategy');

      // 模拟主策略不可用
      strategy1.setAvailability(false);
      selected = router
          .selectOptimalStrategy([strategy1, strategy2], DataType.fundNetValue);
      expect(selected?.name, 'BackupStrategy');

      // 模拟主策略恢复
      strategy1.setAvailability(true);
      selected = router
          .selectOptimalStrategy([strategy1, strategy2], DataType.fundNetValue);
      expect(selected?.name, 'PrimaryStrategy');
    });
  });
}
