import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jisu_fund_analyzer/src/core/network/polling\network_monitor.dart';

void main() {
  group('NetworkStatusResult', () {
    test('应该正确创建离线状态', () {
      final result = NetworkStatusResult.offline();

      expect(result.isConnected, isFalse);
      expect(result.quality, 0.0);
      expect(result.hasInternetAccess, isFalse);
      expect(result.primaryConnection, ConnectivityResult.none);
      expect(result.isHighQuality, isFalse);
      expect(result.isStable, isFalse);
      expect(result.connectivityResults, [ConnectivityResult.none]);
    });

    test('应该正确创建在线状态', () {
      final result = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.wifi],
        quality: 0.8,
        latency: 100,
        hasInternetAccess: true,
      );

      expect(result.isConnected, isTrue);
      expect(result.quality, 0.8);
      expect(result.latency, 100);
      expect(result.hasInternetAccess, isTrue);
      expect(result.primaryConnection, ConnectivityResult.wifi);
      expect(result.isHighQuality, isTrue);
      expect(result.isStable, isTrue);
    });

    test('应该正确识别主要连接类型', () {
      final wifiResult = NetworkStatusResult.online(
        connectivityResults: [
          ConnectivityResult.wifi,
          ConnectivityResult.mobile
        ],
        quality: 0.7,
        hasInternetAccess: true,
      );
      expect(wifiResult.primaryConnection, ConnectivityResult.wifi);

      final mobileResult = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.mobile],
        quality: 0.5,
        hasInternetAccess: true,
      );
      expect(mobileResult.primaryConnection, ConnectivityResult.mobile);

      final ethernetResult = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.ethernet],
        quality: 0.9,
        hasInternetAccess: true,
      );
      expect(ethernetResult.primaryConnection, ConnectivityResult.ethernet);
    });

    test('应该正确判断连接质量', () {
      final highQuality = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.wifi],
        quality: 0.8,
        hasInternetAccess: true,
      );
      expect(highQuality.isHighQuality, isTrue);

      final lowQuality = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.mobile],
        quality: 0.5,
        hasInternetAccess: true,
      );
      expect(lowQuality.isHighQuality, isFalse);
    });

    test('应该正确判断连接稳定性', () {
      final stable = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.wifi],
        quality: 0.8,
        latency: 500,
        hasInternetAccess: true,
      );
      expect(stable.isStable, isTrue);

      final unstable = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.mobile],
        quality: 0.6,
        latency: 1500,
        hasInternetAccess: true,
      );
      expect(unstable.isStable, isFalse);

      final noLatency = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.wifi],
        quality: 0.8,
        hasInternetAccess: true,
      );
      expect(noLatency.isStable, isFalse);
    });

    test('应该正确序列化为JSON', () {
      final result = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.wifi],
        quality: 0.75,
        latency: 120,
        hasInternetAccess: true,
        metadata: {'test': 'value'},
      );

      final json = result.toJson();

      expect(json['connectivityResults'], ['wifi']);
      expect(json['isConnected'], isTrue);
      expect(json['quality'], 0.75);
      expect(json['latency'], 120);
      expect(json['hasInternetAccess'], isTrue);
      expect(json['primaryConnection'], 'wifi');
      expect(json['isHighQuality'], isTrue);
      expect(json['isStable'], isTrue);
      expect(json['metadata'], {'test': 'value'});
      expect(json['timestamp'], isA<String>());
    });

    test('应该提供正确的字符串表示', () {
      final result = NetworkStatusResult.online(
        connectivityResults: [ConnectivityResult.wifi],
        quality: 0.85,
        latency: 150,
        hasInternetAccess: true,
      );

      final str = result.toString();
      expect(str, contains('connected: true'));
      expect(str, contains('quality: 85.0%'));
      expect(str, contains('latency: 150ms'));
      expect(str, contains('type: wifi'));
    });
  });

  group('DataSourceAvailability', () {
    test('应该正确创建不可用状态', () {
      final availability = DataSourceAvailability.unavailable(
        'test-source',
        'Test Source',
        consecutiveFailures: 3,
      );

      expect(availability.sourceId, 'test-source');
      expect(availability.sourceName, 'Test Source');
      expect(availability.isAvailable, isFalse);
      expect(availability.responseTime, isNull);
      expect(availability.reliability, 0.0);
      expect(availability.consecutiveFailures, 3);
      expect(availability.health, DataSourceHealth.down);
    });

    test('应该正确创建可用状态', () {
      final availability = DataSourceAvailability.available(
        'test-source',
        'Test Source',
        responseTime: 200,
        reliability: 0.95,
        lastSuccessTime: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(availability.sourceId, 'test-source');
      expect(availability.sourceName, 'Test Source');
      expect(availability.isAvailable, isTrue);
      expect(availability.responseTime, 200);
      expect(availability.reliability, 0.95);
      expect(availability.consecutiveFailures, 0);
      expect(availability.health, DataSourceHealth.excellent);
    });

    test('应该根据性能指标确定健康状态', () {
      // 优秀状态
      final excellent = DataSourceAvailability.available(
        'excellent-source',
        'Excellent Source',
        responseTime: 300,
        reliability: 0.95,
      );
      expect(excellent.health, DataSourceHealth.excellent);

      // 良好状态
      final good = DataSourceAvailability.available(
        'good-source',
        'Good Source',
        responseTime: 800,
        reliability: 0.85,
      );
      expect(good.health, DataSourceHealth.good);

      // 一般状态
      final fair = DataSourceAvailability.available(
        'fair-source',
        'Fair Source',
        responseTime: 1500,
        reliability: 0.7,
      );
      expect(fair.health, DataSourceHealth.fair);

      // 较差状态
      final poor = DataSourceAvailability.available(
        'poor-source',
        'Poor Source',
        responseTime: 2500,
        reliability: 0.5,
      );
      expect(poor.health, DataSourceHealth.poor);
    });

    test('应该正确序列化为JSON', () {
      final availability = DataSourceAvailability.available(
        'test-source',
        'Test Source',
        responseTime: 150,
        reliability: 0.9,
        metadata: {'test': 'value'},
      );

      final json = availability.toJson();

      expect(json['sourceId'], 'test-source');
      expect(json['sourceName'], 'Test Source');
      expect(json['isAvailable'], isTrue);
      expect(json['responseTime'], 150);
      expect(json['reliability'], 0.9);
      expect(json['consecutiveFailures'], 0);
      expect(json['health'], 'excellent');
      expect(json['metadata'], {'test': 'value'});
      expect(json['lastSuccessTime'], isA<String>());
    });

    test('应该提供正确的字符串表示', () {
      final availability = DataSourceAvailability.available(
        'test-source',
        'Test Source',
        responseTime: 200,
        reliability: 0.85,
      );

      final str = availability.toString();
      expect(str, contains('id: test-source'));
      expect(str, contains('available: true'));
      expect(str, contains('health: excellent'));
      expect(str, contains('responseTime: 200ms'));
      expect(str, contains('reliability: 85.0%'));
    });
  });

  group('NetworkMonitorConfig', () {
    test('应该使用默认配置', () {
      const config = NetworkMonitorConfig();

      expect(config.checkInterval, const Duration(seconds: 30));
      expect(config.latencyTestUrls, contains('https://www.baidu.com'));
      expect(config.latencyTestUrls, contains('https://www.tencent.com'));
      expect(config.latencyTestUrls, contains('https://httpbin.org/get'));
      expect(config.timeout, const Duration(seconds: 10));
      expect(config.enableDetailedLogging, isFalse);
      expect(config.dataSourceConfigs, isEmpty);
    });

    test('应该正确创建自定义配置', () {
      const config = NetworkMonitorConfig(
        checkInterval: Duration(minutes: 1),
        latencyTestUrls: ['https://example.com'],
        timeout: Duration(seconds: 5),
        enableDetailedLogging: true,
      );

      expect(config.checkInterval, const Duration(minutes: 1));
      expect(config.latencyTestUrls, ['https://example.com']);
      expect(config.timeout, const Duration(seconds: 5));
      expect(config.enableDetailedLogging, isTrue);
    });

    test('应该正确序列化为JSON', () {
      const config = NetworkMonitorConfig(
        checkInterval: Duration(seconds: 60),
        latencyTestUrls: ['https://test.com'],
        timeout: Duration(seconds: 15),
        enableDetailedLogging: true,
      );

      final json = config.toJson();

      expect(json['checkInterval'], 60000);
      expect(json['latencyTestUrls'], ['https://test.com']);
      expect(json['timeout'], 15000);
      expect(json['enableDetailedLogging'], isTrue);
      expect(json['dataSourceConfigs'], isEmpty);
    });
  });

  group('DataSourceCheckConfig', () {
    test('应该正确创建默认配置', () {
      const config = DataSourceCheckConfig(
        checkUrl: 'https://api.example.com/health',
      );

      expect(config.checkUrl, 'https://api.example.com/health');
      expect(config.method, 'GET');
      expect(config.headers, isNull);
      expect(config.expectedStatusCode, 200);
      expect(config.maxResponseTime, 5000);
    });

    test('应该正确创建自定义配置', () {
      const config = DataSourceCheckConfig(
        checkUrl: 'https://api.example.com/status',
        method: 'POST',
        headers: {'Authorization': 'Bearer token'},
        expectedStatusCode: 201,
        maxResponseTime: 3000,
      );

      expect(config.checkUrl, 'https://api.example.com/status');
      expect(config.method, 'POST');
      expect(config.headers, {'Authorization': 'Bearer token'});
      expect(config.expectedStatusCode, 201);
      expect(config.maxResponseTime, 3000);
    });

    test('应该正确序列化为JSON', () {
      const config = DataSourceCheckConfig(
        checkUrl: 'https://api.example.com/health',
        method: 'GET',
        headers: {'X-API-Key': 'test-key'},
        expectedStatusCode: 200,
        maxResponseTime: 5000,
      );

      final json = config.toJson();

      expect(json['checkUrl'], 'https://api.example.com/health');
      expect(json['method'], 'GET');
      expect(json['headers'], {'X-API-Key': 'test-key'});
      expect(json['expectedStatusCode'], 200);
      expect(json['maxResponseTime'], 5000);
    });
  });

  group('NetworkMonitor - 基础功能测试', () {
    late NetworkMonitor monitor;
    late NetworkMonitorConfig config;

    setUp(() {
      config = const NetworkMonitorConfig(
        checkInterval: Duration(seconds: 1), // 快速测试
        enableDetailedLogging: false,
        latencyTestUrls: ['https://httpbin.org/get'],
      );
      monitor = NetworkMonitor(config: config);
    });

    tearDown(() async {
      await monitor.dispose();
    });

    test('应该正确初始化监控器', () {
      expect(monitor.isMonitoring, isFalse);
      expect(monitor.currentNetworkStatus, isNull);
      expect(monitor.dataSourceAvailability, isEmpty);
      expect(monitor.networkStatusStream, isNotNull);
      expect(monitor.dataSourcesStream, isNotNull);
    });

    test('应该正确启动和停止监控', () async {
      await monitor.startMonitoring();
      expect(monitor.isMonitoring, isTrue);

      await monitor.stopMonitoring();
      expect(monitor.isMonitoring, isFalse);
    });

    test('重复启动应该忽略', () async {
      await monitor.startMonitoring();
      await monitor.startMonitoring(); // 第二次应该被忽略
      expect(monitor.isMonitoring, isTrue);

      await monitor.stopMonitoring();
    });

    test('重复停止应该忽略', () async {
      await monitor.startMonitoring();
      await monitor.stopMonitoring();
      await monitor.stopMonitoring(); // 第二次应该被忽略
      expect(monitor.isMonitoring, isFalse);
    });

    test('应该提供监控统计信息', () {
      final stats = monitor.getMonitoringStats();

      expect(stats.containsKey('isMonitoring'), isTrue);
      expect(stats.containsKey('config'), isTrue);
      expect(stats.containsKey('currentNetworkStatus'), isTrue);
      expect(stats.containsKey('dataSourceCount'), isTrue);
      expect(stats.containsKey('availableDataSources'), isTrue);
      expect(stats.containsKey('bestDataSource'), isTrue);
      expect(stats.containsKey('dataSourceAvailability'), isTrue);

      expect(stats['isMonitoring'], isFalse);
      expect(stats['dataSourceCount'], 0);
      expect(stats['availableDataSources'], 0);
      expect(stats['bestDataSource'], isNull);
    });

    test('应该正确处理数据源配置', () async {
      final configWithDataSources = NetworkMonitorConfig(
        checkInterval: const Duration(seconds: 1),
        dataSourceConfigs: {
          'test-api': DataSourceCheckConfig(
            checkUrl: 'https://httpbin.org/status/200',
          ),
        },
      );

      final monitorWithDataSources =
          NetworkMonitor(config: configWithDataSources);

      await monitorWithDataSources.startMonitoring();

      // 等待数据源检测
      await Future.delayed(const Duration(milliseconds: 1500));

      final stats = monitorWithDataSources.getMonitoringStats();
      expect(stats['dataSourceCount'], 1);

      await monitorWithDataSources.dispose();
    });
  });

  group('NetworkMonitor - 数据源功能测试', () {
    late NetworkMonitor monitor;
    late NetworkMonitorConfig config;

    setUp(() {
      config = NetworkMonitorConfig(
        checkInterval: const Duration(seconds: 2),
        enableDetailedLogging: false,
        dataSourceConfigs: {
          'api-1': DataSourceCheckConfig(
            checkUrl: 'https://httpbin.org/status/200',
            maxResponseTime: 5000,
          ),
          'api-2': DataSourceCheckConfig(
            checkUrl: 'https://httpbin.org/status/404',
            maxResponseTime: 3000,
          ),
        },
      );
      monitor = NetworkMonitor(config: config);
    });

    tearDown(() async {
      await monitor.dispose();
    });

    test('应该正确检测数据源可用性', () async {
      await monitor.startMonitoring();

      // 等待数据源检测完成
      await Future.delayed(const Duration(milliseconds: 2500));

      final availability = monitor.dataSourceAvailability;
      expect(availability, isNotEmpty);
      expect(availability.containsKey('api-1'), isTrue);
      expect(availability.containsKey('api-2'), isTrue);

      await monitor.stopMonitoring();
    });

    test('应该获取特定数据源可用性', () async {
      await monitor.startMonitoring();

      await Future.delayed(const Duration(milliseconds: 2500));

      final api1Availability = monitor.getDataSourceAvailability('api-1');
      expect(api1Availability, isNotNull);
      expect(api1Availability!.sourceId, 'api-1');

      final unknownAvailability = monitor.getDataSourceAvailability('unknown');
      expect(unknownAvailability, isNull);

      await monitor.stopMonitoring();
    });

    test('应该获取最佳可用数据源', () async {
      await monitor.startMonitoring();

      await Future.delayed(const Duration(milliseconds: 2500));

      final bestSource = monitor.getBestAvailableDataSource();
      // 应该返回可用的数据源（api-1应该返回200状态）
      expect(bestSource, isNotNull);
      expect(bestSource, anyOf(['api-1', 'api-2']));

      await monitor.stopMonitoring();
    });

    test('应该支持手动数据源检测', () async {
      final results = await monitor.checkDataSources();
      expect(results, isNotNull);
      expect(results, isNotEmpty);
      expect(results.containsKey('api-1'), isTrue);
      expect(results.containsKey('api-2'), isTrue);
    });
  });

  group('NetworkMonitor - 网络状态测试', () {
    late NetworkMonitor monitor;

    setUp(() {
      monitor = NetworkMonitor(
        config: const NetworkMonitorConfig(
          checkInterval: Duration(seconds: 1),
          enableDetailedLogging: false,
        ),
      );
    });

    tearDown(() async {
      await monitor.dispose();
    });

    test('应该支持手动网络状态检测', () async {
      final status = await monitor.checkNetworkStatus();
      expect(status, isNotNull);
      expect(status, isA<NetworkStatusResult>());
      expect(status.timestamp, isNotNull);
    });

    test('应该正确处理网络状态流', () async {
      final statusList = <NetworkStatusResult>[];
      final subscription = monitor.networkStatusStream.listen(statusList.add);

      await monitor.startMonitoring();

      // 等待至少一次状态更新
      await Future.delayed(const Duration(milliseconds: 1500));

      expect(statusList, isNotEmpty);
      expect(statusList.first, isA<NetworkStatusResult>());

      await subscription.cancel();
      await monitor.stopMonitoring();
    });

    test('应该正确处理数据源可用性流', () async {
      final configWithDataSources = NetworkMonitorConfig(
        checkInterval: const Duration(seconds: 1),
        dataSourceConfigs: {
          'test-api': DataSourceCheckConfig(
            checkUrl: 'https://httpbin.org/status/200',
          ),
        },
      );

      final monitorWithDataSources =
          NetworkMonitor(config: configWithDataSources);
      final availabilityList = <Map<String, DataSourceAvailability>>[];
      final subscription =
          monitorWithDataSources.dataSourcesStream.listen(availabilityList.add);

      await monitorWithDataSources.startMonitoring();

      // 等待至少一次可用性更新
      await Future.delayed(const Duration(milliseconds: 1500));

      expect(availabilityList, isNotEmpty);
      expect(
          availabilityList.first, isA<Map<String, DataSourceAvailability>>());
      expect(availabilityList.first.containsKey('test-api'), isTrue);

      await subscription.cancel();
      await monitorWithDataSources.dispose();
    });
  });

  group('DataSourceHealth 枚举测试', () {
    test('应该包含所有预期的健康状态', () {
      final healthStates = DataSourceHealth.values;
      expect(healthStates, contains(DataSourceHealth.excellent));
      expect(healthStates, contains(DataSourceHealth.good));
      expect(healthStates, contains(DataSourceHealth.fair));
      expect(healthStates, contains(DataSourceHealth.poor));
      expect(healthStates, contains(DataSourceHealth.down));
      expect(healthStates, contains(DataSourceHealth.unknown));
    });

    test('健康状态应该有正确的顺序', () {
      // 检查健康状态的相对顺序
      expect(DataSourceHealth.excellent.index,
          lessThan(DataSourceHealth.good.index));
      expect(
          DataSourceHealth.good.index, lessThan(DataSourceHealth.fair.index));
      expect(
          DataSourceHealth.fair.index, lessThan(DataSourceHealth.poor.index));
      expect(
          DataSourceHealth.poor.index, lessThan(DataSourceHealth.down.index));
    });
  });

  group('边界条件和错误处理测试', () {
    test('应该处理空的数据源配置', () async {
      const emptyConfig = NetworkMonitorConfig(
        dataSourceConfigs: {},
      );

      final monitor = NetworkMonitor(config: emptyConfig);

      await monitor.startMonitoring();
      expect(monitor.dataSourceAvailability, isEmpty);

      final stats = monitor.getMonitoringStats();
      expect(stats['dataSourceCount'], 0);
      expect(stats['availableDataSources'], 0);

      await monitor.dispose();
    });

    test('应该处理无效的数据源URL', () async {
      final configWithInvalidUrl = NetworkMonitorConfig(
        dataSourceConfigs: {
          'invalid-source': DataSourceCheckConfig(
            checkUrl: 'https://invalid-url-that-does-not-exist.com',
            maxResponseTime: 1000,
          ),
        },
      );

      final monitor = NetworkMonitor(config: configWithInvalidUrl);

      await monitor.startMonitoring();

      // 等待检测完成
      await Future.delayed(const Duration(milliseconds: 2000));

      final availability = monitor.getDataSourceAvailability('invalid-source');
      expect(availability, isNotNull);
      expect(availability!.isAvailable, isFalse);
      expect(availability.consecutiveFailures, greaterThan(0));

      await monitor.dispose();
    });

    test('应该处理快速的启动停止操作', () async {
      final monitor = NetworkMonitor();

      // 快速启动停止
      await monitor.startMonitoring();
      await monitor.stopMonitoring();
      await monitor.startMonitoring();
      await monitor.stopMonitoring();

      expect(monitor.isMonitoring, isFalse);

      await monitor.dispose();
    });

    test('应该在销毁时正确清理资源', () async {
      final monitor = NetworkMonitor();

      await monitor.startMonitoring();
      expect(monitor.isMonitoring, isTrue);

      await monitor.dispose();
      expect(monitor.isMonitoring, isFalse);
    });
  });

  group('集成测试', () {
    test('完整的监控工作流程', () async {
      final config = NetworkMonitorConfig(
        checkInterval: const Duration(seconds: 1),
        enableDetailedLogging: true,
        latencyTestUrls: ['https://httpbin.org/get'],
        dataSourceConfigs: {
          'health-check': DataSourceCheckConfig(
            checkUrl: 'https://httpbin.org/status/200',
            maxResponseTime: 3000,
          ),
          'failure-check': DataSourceCheckConfig(
            checkUrl: 'https://httpbin.org/status/500',
            maxResponseTime: 3000,
          ),
        },
      );

      final monitor = NetworkMonitor(config: config);

      // 收集网络状态更新
      final networkStatuses = <NetworkStatusResult>[];
      final networkSubscription =
          monitor.networkStatusStream.listen(networkStatuses.add);

      // 收集数据源可用性更新
      final dataSourceUpdates = <Map<String, DataSourceAvailability>>[];
      final dataSourceSubscription =
          monitor.dataSourcesStream.listen(dataSourceUpdates.add);

      await monitor.startMonitoring();

      // 等待多次检测
      await Future.delayed(const Duration(milliseconds: 3500));

      // 验证网络状态检测
      expect(networkStatuses, isNotEmpty);
      expect(networkStatuses.first, isA<NetworkStatusResult>());
      expect(networkStatuses.first.timestamp, isNotNull);

      // 验证数据源检测
      expect(dataSourceUpdates, isNotEmpty);
      expect(dataSourceUpdates.first, isNotEmpty);
      expect(dataSourceUpdates.first.containsKey('health-check'), isTrue);
      expect(dataSourceUpdates.first.containsKey('failure-check'), isTrue);

      // 验证统计数据
      final stats = monitor.getMonitoringStats();
      expect(stats['isMonitoring'], isTrue);
      expect(stats['dataSourceCount'], 2);
      expect(stats['config'], isNotNull);

      // 手动触发检测
      final manualNetworkStatus = await monitor.checkNetworkStatus();
      expect(manualNetworkStatus, isNotNull);

      final manualDataSources = await monitor.checkDataSources();
      expect(manualDataSources, isNotNull);
      expect(manualDataSources, isNotEmpty);

      // 清理
      await networkSubscription.cancel();
      await dataSourceSubscription.cancel();
      await monitor.dispose();

      // 验证清理后的状态
      expect(monitor.isMonitoring, isFalse);
    });

    test('应该正确处理网络状态变化', () async {
      final monitor = NetworkMonitor(
        config: const NetworkMonitorConfig(
          checkInterval: Duration(seconds: 2),
        ),
      );

      final statusChanges = <NetworkStatusResult>[];
      final subscription =
          monitor.networkStatusStream.listen(statusChanges.add);

      await monitor.startMonitoring();

      // 等待初始状态
      await Future.delayed(const Duration(milliseconds: 500));
      final initialCount = statusChanges.length;

      // 等待更多状态更新
      await Future.delayed(const Duration(seconds: 3));

      // 应该有更多的状态更新（定期检测）
      expect(statusChanges.length, greaterThan(initialCount));

      await subscription.cancel();
      await monitor.dispose();
    });
  });
}
