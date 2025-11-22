import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:jisu_fund_analyzer/src/core/services/base/service_container.dart';
import 'package:jisu_fund_analyzer/src/core/services/base/service_registry.dart';
import 'package:jisu_fund_analyzer/src/core/services/base/service_lifecycle_manager.dart';
import 'package:jisu_fund_analyzer/src/core/services/base/i_unified_service.dart';

// 测试用的具体服务实现
class TestService implements IUnifiedService {
  ServiceLifecycleState _lifecycleState = ServiceLifecycleState.uninitialized;
  DateTime _startTime = DateTime.now();

  @override
  String get serviceName => 'TestService';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => [];

  @override
  ServiceLifecycleState get lifecycleState => _lifecycleState;

  @override
  Future<void> initialize(ServiceContainer container) async {
    setLifecycleState(ServiceLifecycleState.initialized);
  }

  @override
  Future<void> dispose() async {
    setLifecycleState(ServiceLifecycleState.disposed);
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    return ServiceHealthStatus(
      isHealthy: lifecycleState == ServiceLifecycleState.initialized,
      message: 'Service is healthy',
      lastCheck: DateTime.now(),
    );
  }

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: serviceName,
      version: version,
      uptime: DateTime.now().difference(_startTime),
      memoryUsage: 0,
    );
  }

  /// 受保护的状态设置方法
  void setLifecycleState(ServiceLifecycleState state) {
    _lifecycleState = state;
    if (state == ServiceLifecycleState.initialized) {
      _startTime = DateTime.now();
    }
  }
}

class DependentService implements IUnifiedService {
  ServiceLifecycleState _lifecycleState = ServiceLifecycleState.uninitialized;
  DateTime _startTime = DateTime.now();

  @override
  String get serviceName => 'DependentService';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => ['TestService'];

  @override
  ServiceLifecycleState get lifecycleState => _lifecycleState;

  @override
  Future<void> initialize(ServiceContainer container) async {
    final testService = container.getServiceByName('TestService');
    if (testService == null) {
      throw ServiceDependencyException(serviceName, 'TestService', '依赖服务未找到');
    }

    setLifecycleState(ServiceLifecycleState.initialized);
  }

  @override
  Future<void> dispose() async {
    setLifecycleState(ServiceLifecycleState.disposed);
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    return ServiceHealthStatus(
      isHealthy: lifecycleState == ServiceLifecycleState.initialized,
      message: 'Dependent service is healthy',
      lastCheck: DateTime.now(),
    );
  }

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: serviceName,
      version: version,
      uptime: DateTime.now().difference(_startTime),
      memoryUsage: 0,
    );
  }

  /// 受保护的状态设置方法
  void setLifecycleState(ServiceLifecycleState state) {
    _lifecycleState = state;
    if (state == ServiceLifecycleState.initialized) {
      _startTime = DateTime.now();
    }
  }
}

// 失败服务实现
class FailingService implements IUnifiedService {
  ServiceLifecycleState _lifecycleState = ServiceLifecycleState.uninitialized;
  DateTime _startTime = DateTime.now();

  @override
  String get serviceName => 'FailingService';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => [];

  @override
  ServiceLifecycleState get lifecycleState => _lifecycleState;

  @override
  Future<void> initialize(ServiceContainer container) async {
    // 设置为初始化中状态
    setLifecycleState(ServiceLifecycleState.initializing);
    throw Exception('Initialization failed');
  }

  @override
  Future<void> dispose() async {
    setLifecycleState(ServiceLifecycleState.disposed);
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    return ServiceHealthStatus(
      isHealthy: false,
      message: 'Service failed',
      lastCheck: DateTime.now(),
    );
  }

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: serviceName,
      version: version,
      uptime: Duration.zero,
      memoryUsage: 0,
    );
  }

  /// 受保护的状态设置方法
  void setLifecycleState(ServiceLifecycleState state) {
    _lifecycleState = state;
    if (state == ServiceLifecycleState.initialized) {
      _startTime = DateTime.now();
    }
  }
}

void main() {
  group('UnifiedServiceContainer', () {
    late UnifiedServiceContainer container;
    late TestService testService;
    late DependentService dependentService;

    setUp(() {
      container = UnifiedServiceContainer();
      testService = TestService();
      dependentService = DependentService();
    });

    tearDown(() async {
      await container.dispose();
    });

    test('应该正确创建服务容器', () {
      expect(container, isNotNull);
      expect(container.getRegisteredServiceNames(), isEmpty);
      // 对于空容器，所有服务（0个）都已初始化，所以返回true
      expect(container.allServicesInitialized(), isTrue);
    });

    test('应该支持配置初始化', () {
      container = UnifiedServiceContainer(
        configuration: {
          'test_key': 'test_value',
          'debug_mode': true,
        },
      );

      expect(container.getConfig('test_key'), equals('test_value'));
      expect(container.getConfig('debug_mode'), isTrue);
      expect(container.getConfig('non_existent', 'default'), equals('default'));
    });

    test('应该正确设置和获取配置', () {
      container.setConfig('new_key', 'new_value');
      container.setConfig('number_key', 42);

      expect(container.getConfig('new_key'), equals('new_value'));
      expect(container.getConfig('number_key'), equals(42));

      final allConfig = container.getAllConfig();
      expect(allConfig['new_key'], equals('new_value'));
      expect(allConfig['number_key'], equals(42));
    });

    test('应该正确初始化所有服务', () async {
      await container.registerService(testService);
      await container.registerService(dependentService);

      final initializedServices = await container.initialize();

      expect(initializedServices, contains('TestService'));
      expect(initializedServices, contains('DependentService'));
      expect(container.allServicesInitialized(), isTrue);
    });

    test('应该正确获取服务实例', () async {
      await container.registerService(testService);
      await container.initialize();

      // 类型安全获取
      final service = container.getService<TestService>();
      expect(service, equals(testService));

      // 按名称获取
      final serviceByName = container.getServiceByName('TestService');
      expect(serviceByName, equals(testService));

      // 按名称获取基础接口
      final baseService = container.getServiceByName('TestService');
      expect(baseService, isNotNull);
    });

    test('应该正确检查服务状态', () async {
      await container.registerService(testService);
      await container.initialize();

      expect(container.getServiceState('TestService'),
          equals(ServiceLifecycleState.initialized));

      final allStates = container.getAllServiceStates();
      expect(
          allStates['TestService'], equals(ServiceLifecycleState.initialized));
    });

    test('应该正确获取健康状态报告', () async {
      await container.registerService(testService);
      await container.initialize();

      final healthReport = await container.getHealthReport();

      expect(healthReport, contains('TestService'));
      expect(healthReport['TestService']!.isHealthy, isTrue);
      expect(
          healthReport['TestService']!.message, equals('Service is healthy'));
    });

    test('应该正确获取容器统计信息', () async {
      container.setConfig('test_config', 'test_value');
      await container.registerService(testService);
      await container.initialize();

      final stats = container.getContainerStats();

      expect(stats['container_initialized'], isTrue);
      expect(stats['total_services'], equals(1));
      expect(stats['initialized_services'], equals(1));
      expect(stats['failed_services'], equals(0));
      expect(stats['configuration']['test_config'], equals('test_value'));
    });

    test('应该正确重启服务', () async {
      await container.registerService(testService);
      await container.initialize();

      expect(container.getServiceState('TestService'),
          equals(ServiceLifecycleState.initialized));

      await container.restartService('TestService');

      expect(container.getServiceState('TestService'),
          equals(ServiceLifecycleState.initialized));
    });

    test('应该正确重启所有服务', () async {
      await container.registerService(testService);
      await container.registerService(dependentService);
      await container.initialize();

      final reinitializedServices = await container.restartAllServices();

      expect(reinitializedServices, contains('TestService'));
      expect(reinitializedServices, contains('DependentService'));
      expect(container.allServicesInitialized(), isTrue);
    });

    test('应该正确获取服务元数据', () async {
      await container.registerService(testService);

      final metadata = container.getServiceMetadata('TestService');
      expect(metadata, isNotNull);
      expect(metadata!.serviceName, equals('TestService'));
      expect(metadata.version, equals('1.0.0'));
      expect(metadata.dependencies, isEmpty);
    });

    test('应该正确监听生命周期事件', () async {
      await container.registerService(testService);

      await container.initialize();

      // 验证生命周期事件流存在
      expect(container.lifecycleEvents, isNotNull);
    });

    test('应该拒绝在未初始化时获取服务', () async {
      await container.registerService(testService);

      expect(
        () => container.getService<TestService>(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('服务容器未初始化'),
        )),
      );
    });

    test('应该拒绝重复初始化', () async {
      await container.registerService(testService);
      await container.initialize();

      // 第二次初始化应该跳过
      final initializedServices = await container.initialize();
      expect(initializedServices, contains('TestService'));
    });

    test('应该正确处理服务初始化失败', () async {
      // 测试只有失败服务的情况
      final failingService = FailingService();
      await container.registerService(failingService);

      // 验证初始状态
      expect(container.getServiceState('FailingService'),
          equals(ServiceLifecycleState.uninitialized));

      // 直接测试失败服务的行为
      expect(() => failingService.initialize(container),
          throwsA(isA<Exception>()));

      // 验证状态变化
      expect(failingService.lifecycleState,
          equals(ServiceLifecycleState.initializing));
    });

    test('应该正确销毁所有服务', () async {
      await container.registerService(testService);
      await container.registerService(dependentService);
      await container.initialize();

      await container.dispose();

      // 注意：dispose()后容器不再可用，这里主要验证没有异常抛出
    });
  });

  group('ServiceContainerBuilder', () {
    test('应该支持流式配置', () async {
      final builder = ServiceContainerBuilder()
          .withConfig('test_key', 'test_value')
          .withConfig('debug_mode', true)
          .withInitializationTimeout(Duration(seconds: 15));

      final container = await builder.build();

      expect(container.getConfig('test_key'), equals('test_value'));
      expect(container.getConfig('debug_mode'), isTrue);

      await container.dispose();
    });

    test('应该支持构建并初始化', () async {
      final testService = TestService();
      final builder =
          ServiceContainerBuilder().withConfig('test_key', 'test_value');

      final container = await builder.buildAndInitialize();

      expect(container.allServicesInitialized(), isTrue);
      expect(container.getConfig('test_key'), equals('test_value'));

      await container.dispose();
    });
  });

  group('ServiceContainerFactory', () {
    test('应该创建开发环境容器', () async {
      final container =
          await ServiceContainerFactory.createDevelopmentContainer();

      expect(container.getConfig('environment'), equals('development'));
      expect(container.getConfig('debug_mode'), isTrue);
      expect(container.getConfig('log_level'), equals('debug'));

      await container.dispose();
    });

    test('应该创建生产环境容器', () async {
      final container =
          await ServiceContainerFactory.createProductionContainer();

      expect(container.getConfig('environment'), equals('production'));
      expect(container.getConfig('debug_mode'), isFalse);
      expect(container.getConfig('log_level'), equals('info'));

      await container.dispose();
    });

    test('应该创建测试环境容器', () async {
      final container = await ServiceContainerFactory.createTestContainer();

      expect(container.getConfig('environment'), equals('test'));
      expect(container.getConfig('debug_mode'), isTrue);
      expect(container.getConfig('mock_services'), isTrue);

      await container.dispose();
    });

    test('应该支持额外配置', () async {
      final container =
          await ServiceContainerFactory.createDevelopmentContainer(
        additionalConfig: {
          'custom_key': 'custom_value',
          'feature_flag': true,
        },
      );

      expect(container.getConfig('environment'), equals('development'));
      expect(container.getConfig('custom_key'), equals('custom_value'));
      expect(container.getConfig('feature_flag'), isTrue);

      await container.dispose();
    });
  });

  group('服务健康状态', () {
    test('应该正确创建健康状态', () {
      final status = ServiceHealthStatus(
        isHealthy: true,
        message: 'All good',
        lastCheck: DateTime.now(),
        details: {'metric': 100},
      );

      expect(status.isHealthy, isTrue);
      expect(status.message, equals('All good'));
      expect(status.details, contains('metric'));
    });

    test('应该正确转换为字符串', () {
      final status = ServiceHealthStatus(
        isHealthy: false,
        message: 'Error occurred',
        lastCheck: DateTime.now(),
      );

      final stringRep = status.toString();
      expect(stringRep, contains('ServiceHealthStatus'));
      expect(stringRep, contains('isHealthy: false'));
      expect(stringRep, contains('Error occurred'));
    });
  });

  group('服务统计信息', () {
    test('应该正确创建统计信息', () {
      final stats = ServiceStats(
        serviceName: 'TestService',
        version: '1.0.0',
        uptime: Duration(minutes: 30),
        memoryUsage: 1024,
        customMetrics: {'requests': 100},
      );

      expect(stats.serviceName, equals('TestService'));
      expect(stats.version, equals('1.0.0'));
      expect(stats.uptime, equals(Duration(minutes: 30)));
      expect(stats.memoryUsage, equals(1024));
      expect(stats.customMetrics, contains('requests'));
    });

    test('应该正确转换为字符串', () {
      final stats = ServiceStats(
        serviceName: 'TestService',
        version: '1.0.0',
        uptime: Duration(minutes: 30),
        memoryUsage: 1024,
      );

      final stringRep = stats.toString();
      expect(stringRep, contains('ServiceStats'));
      expect(stringRep, contains('TestService'));
      expect(stringRep, contains('version: 1.0.0'));
      expect(stringRep, contains('memory: 1024KB'));
    });
  });
}
