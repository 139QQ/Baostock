import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/core/di/service_registry.dart';
import 'package:jisu_fund_analyzer/src/core/di/di_container_manager.dart';

import 'service_registry_test.mocks.dart';

@GenerateMocks([DIContainerManager])
void main() {
  group('BaseServiceRegistry', () {
    late BaseServiceRegistry registry;
    late MockDIContainerManager mockContainerManager;

    setUp(() {
      registry = TestServiceRegistry();
      mockContainerManager = MockDIContainerManager();
    });

    test('应该正确注册服务', () {
      final registration = ServiceRegistration.lazySingleton(
        name: 'test_service',
        implementationType: TestService,
      );

      registry.register(registration);
      final services = registry.getServices();

      expect(
          services.length, equals(3)); // TestServiceRegistry的2个默认服务 + 测试注册的1个服务
      expect(services.containsKey('test_service'), isTrue);
      expect(services['test_service'], equals(registration));
    });

    test('应该支持批量注册服务', () {
      final services = {
        'service1': ServiceRegistration.lazySingleton(
          name: 'service1',
          implementationType: TestService,
        ),
        'service2': ServiceRegistration.lazySingleton(
          name: 'service2',
          implementationType: AnotherTestService,
        ),
      };

      registry.registerAll(services);
      final registeredServices = registry.getServices();

      expect(registeredServices.length,
          equals(4)); // TestServiceRegistry的2个默认服务 + 批量注册的2个服务
      expect(registeredServices.containsKey('service1'), isTrue);
      expect(registeredServices.containsKey('service2'), isTrue);
    });

    test('覆盖注册的服务应该显示警告', () {
      final registration1 = ServiceRegistration.lazySingleton(
        name: 'test_service',
        implementationType: TestService,
      );

      final registration2 = ServiceRegistration.lazySingleton(
        name: 'test_service',
        implementationType: AnotherTestService,
      );

      registry.register(registration1);
      registry.register(registration2); // 应该覆盖

      final services = registry.getServices();
      expect(services.length, equals(3)); // TestServiceRegistry的2个默认服务，其中1个被覆盖
      expect(services['test_service'], equals(registration2));
    });
  });

  group('CacheServiceRegistry', () {
    late CacheServiceRegistry registry;
    late MockDIContainerManager mockContainerManager;

    setUp(() {
      mockContainerManager = MockDIContainerManager();
      registry = CacheServiceRegistry();
    });

    test('应该注册正确的缓存服务', () async {
      // 先验证服务定义
      final services = registry.getServices();
      expect(services.length, equals(6)); // 应该有6个缓存服务

      final expectedServices = [
        'unified_hive_cache_manager',
        'unified_cache_service',
        'cache_key_manager',
        'cache_invalidation_manager',
        'cache_performance_monitor',
        'cache_preheating_manager',
      ];

      for (final serviceName in expectedServices) {
        expect(services.containsKey(serviceName), isTrue,
            reason: 'Missing service: $serviceName');
        final registration = services[serviceName]!;

        // 只有特定服务需要异步初始化
        final shouldBeAsync = serviceName == 'unified_hive_cache_manager' ||
            serviceName == 'unified_cache_service' ||
            serviceName == 'cache_invalidation_manager' ||
            serviceName == 'cache_performance_monitor' ||
            serviceName == 'cache_preheating_manager';
        expect(registration.asyncInitialization, equals(shouldBeAsync),
            reason:
                'Service $serviceName async initialization status mismatch');
      }
    });

    test('缓存服务应该使用正确的生命周期', () {
      final services = registry.getServices();

      // 检查特定服务的生命周期
      final keyManagerService = services['cache_key_manager']!;
      expect(keyManagerService.lifetime, equals(ServiceLifetime.singleton));

      final unifiedManagerService = services['unified_hive_cache_manager']!;
      expect(unifiedManagerService.lifetime,
          equals(ServiceLifetime.lazySingleton));
    });
  });

  group('NetworkServiceRegistry', () {
    late NetworkServiceRegistry registry;
    late MockDIContainerManager mockContainerManager;

    setUp(() {
      registry = NetworkServiceRegistry();
      mockContainerManager = MockDIContainerManager();
    });

    test('应该注册正确的网络服务', () {
      final services = registry.getServices();
      expect(services.length, equals(3)); // 应该有3个网络服务

      final expectedServices = [
        'fund_api_client',
        'api_service',
        'navigation_manager',
      ];

      for (final serviceName in expectedServices) {
        expect(services.containsKey(serviceName), isTrue,
            reason: 'Missing service: $serviceName');
      }
    });

    test('网络服务应该使用懒加载单例生命周期', () async {
      await registry.registerServices(mockContainerManager);

      final services = registry.getServices();

      for (final registration in services.values) {
        expect(registration.lifetime, equals(ServiceLifetime.lazySingleton),
            reason: 'Network services should use lazy singleton lifetime');
      }
    });
  });

  group('SecurityServiceRegistry', () {
    late SecurityServiceRegistry registry;
    late MockDIContainerManager mockContainerManager;

    setUp(() {
      registry = SecurityServiceRegistry();
      mockContainerManager = MockDIContainerManager();
    });

    test('应该注册正确的安全服务', () {
      final services = registry.getServices();
      expect(services.length, equals(4)); // 应该有4个安全服务

      final expectedServices = [
        'security_monitor',
        'security_middleware',
        'security_utils',
        'secure_storage_service',
      ];

      for (final serviceName in expectedServices) {
        expect(services.containsKey(serviceName), isTrue,
            reason: 'Missing service: $serviceName');
      }
    });
  });

  group('PerformanceServiceRegistry', () {
    late PerformanceServiceRegistry registry;
    late MockDIContainerManager mockContainerManager;

    setUp(() {
      registry = PerformanceServiceRegistry();
      mockContainerManager = MockDIContainerManager();
    });

    test('应该注册正确的性能服务', () {
      final services = registry.getServices();
      expect(services.length, equals(7)); // 应该有7个性能服务

      final expectedServices = [
        'memory_leak_detector',
        'device_performance_detector',
        'memory_pressure_monitor',
        'advanced_memory_manager',
        'dynamic_cache_adjuster',
        'memory_cleanup_manager',
        'low_overhead_monitor',
      ];

      for (final serviceName in expectedServices) {
        expect(services.containsKey(serviceName), isTrue,
            reason: 'Missing service: $serviceName');
      }
    });

    test('性能服务应该支持异步初始化', () {
      final services = registry.getServices();

      // 检查特定的异步性能服务
      final asyncServices = [
        'memory_leak_detector',
        'memory_pressure_monitor',
        'advanced_memory_manager',
        'dynamic_cache_adjuster',
        'memory_cleanup_manager',
        'low_overhead_monitor',
      ];

      for (final registration in services.values) {
        final shouldBeAsync = asyncServices.contains(registration.name);
        expect(registration.asyncInitialization, equals(shouldBeAsync),
            reason:
                'Performance service ${registration.name} async initialization status mismatch');
      }
    });
  });

  group('DataServiceRegistry', () {
    late DataServiceRegistry registry;
    late MockDIContainerManager mockContainerManager;

    setUp(() {
      registry = DataServiceRegistry();
      mockContainerManager = MockDIContainerManager();
    });

    test('应该注册正确的数据服务', () {
      final services = registry.getServices();
      expect(services.length, equals(9)); // 应该有9个数据服务

      final expectedServices = [
        'fund_remote_data_source',
        'fund_local_data_source',
        'fund_repository',
        'portfolio_profit_repository',
        'fund_data_service',
        'data_validation_service',
        'search_service',
        'unified_search_service',
        'money_fund_service',
      ];

      for (final serviceName in expectedServices) {
        expect(services.containsKey(serviceName), isTrue,
            reason: 'Missing service: $serviceName');
      }
    });

    test('统一搜索服务应该支持异步初始化', () async {
      await registry.registerServices(mockContainerManager);

      final services = registry.getServices();
      final unifiedSearchService = services['unified_search_service'];

      expect(unifiedSearchService, isNotNull);
      expect(unifiedSearchService!.asyncInitialization, isTrue);
    });
  });

  group('BusinessServiceRegistry', () {
    late BusinessServiceRegistry registry;
    late MockDIContainerManager mockContainerManager;

    setUp(() {
      registry = BusinessServiceRegistry();
      mockContainerManager = MockDIContainerManager();
    });

    test('应该注册正确的业务服务', () {
      final services = registry.getServices();
      expect(services.length, equals(8)); // 应该有8个业务服务

      final expectedServices = [
        'fund_analysis_service',
        'portfolio_analysis_service',
        'high_performance_fund_service',
        'smart_recommendation_service',
        'fund_comparison_service',
        'fund_favorite_service',
        'push_analytics_service',
        'android_permission_service',
      ];

      for (final serviceName in expectedServices) {
        expect(services.containsKey(serviceName), isTrue,
            reason: 'Missing service: $serviceName');
      }
    });
  });

  group('StateServiceRegistry', () {
    late StateServiceRegistry registry;
    late MockDIContainerManager mockContainerManager;

    setUp(() {
      registry = StateServiceRegistry();
      mockContainerManager = MockDIContainerManager();
    });

    test('应该注册正确的状态服务', () {
      final services = registry.getServices();
      expect(services.length, equals(4)); // 应该有4个状态服务

      final expectedServices = [
        'feature_toggle_service',
        'bloc_factory_initializer',
        'unified_bloc_factory',
        'global_state_manager',
      ];

      for (final serviceName in expectedServices) {
        expect(services.containsKey(serviceName), isTrue,
            reason: 'Missing service: $serviceName');
      }
    });

    test('特性开关和全局状态管理器应该是单例', () async {
      await registry.registerServices(mockContainerManager);

      final services = registry.getServices();

      final featureToggleService = services['feature_toggle_service'];
      final globalStateManager = services['global_state_manager'];

      expect(featureToggleService!.lifetime, equals(ServiceLifetime.singleton));
      expect(
          globalStateManager!.lifetime, equals(ServiceLifetime.lazySingleton));
    });
  });

  group('CompositeServiceRegistry', () {
    late CompositeServiceRegistry compositeRegistry;
    late MockDIContainerManager mockContainerManager;

    setUp(() {
      mockContainerManager = MockDIContainerManager();
    });

    test('应该合并多个注册表的服务', () {
      final registry1 = TestServiceRegistry();
      final registry2 = AnotherTestServiceRegistry();

      compositeRegistry = CompositeServiceRegistry([registry1, registry2]);
      final services = compositeRegistry.getServices();
      expect(services.length, equals(4)); // 2 + 2 = 4 个服务
    });

    test('应该支持添加和移除注册表', () async {
      final registry1 = TestServiceRegistry();
      final registry2 = AnotherTestServiceRegistry();

      compositeRegistry = CompositeServiceRegistry([registry1]);

      // 初始状态
      var services = compositeRegistry.getServices();
      expect(services.length, equals(2));

      // 添加注册表
      compositeRegistry.addRegistry(registry2);
      services = compositeRegistry.getServices();
      expect(services.length, equals(4));

      // 移除注册表
      compositeRegistry.removeRegistry(registry2);
      services = compositeRegistry.getServices();
      expect(services.length, equals(2));
    });

    test('应该支持清空所有注册表', () async {
      final registry1 = TestServiceRegistry();
      final registry2 = AnotherTestServiceRegistry();

      compositeRegistry = CompositeServiceRegistry([registry1, registry2]);
      expect(compositeRegistry.getServices().length, equals(4));

      compositeRegistry.clearRegistries();
      expect(compositeRegistry.getServices().length, equals(0));
    });
  });

  group('DefaultServiceRegistryBuilder', () {
    test('应该构建完整的默认注册表', () {
      final registry = DefaultServiceRegistryBuilder.build();

      expect(registry, isA<CompositeServiceRegistry>());
      expect(registry.getServices().length, greaterThan(0));
    });

    test('应该构建最小化注册表', () {
      final registry = DefaultServiceRegistryBuilder.buildMinimal();

      expect(registry, isA<CompositeServiceRegistry>());
      expect(registry.getServices().length, greaterThan(0));

      // 最小化注册表应该比完整注册表服务少
      final fullRegistry = DefaultServiceRegistryBuilder.build();
      expect(registry.getServices().length,
          lessThan(fullRegistry.getServices().length));
    });

    test('完整和最小化构建应该返回不同的实例', () {
      final minimal = DefaultServiceRegistryBuilder.buildMinimal();
      final full = DefaultServiceRegistryBuilder.build();

      expect(identical(minimal, full), isFalse);
    });
  });

  group('服务注册验证', () {
    test('所有注册表应该有有效的服务名称', () {
      final registries = [
        CacheServiceRegistry(),
        NetworkServiceRegistry(),
        SecurityServiceRegistry(),
        PerformanceServiceRegistry(),
        DataServiceRegistry(),
        BusinessServiceRegistry(),
        StateServiceRegistry(),
      ];

      for (final registry in registries) {
        final services = registry.getServices();

        for (final entry in services.entries) {
          expect(entry.key.isNotEmpty, isTrue,
              reason: 'Service name should not be empty');
          expect(entry.key.trim(), equals(entry.key),
              reason:
                  'Service name should not have leading/trailing whitespace');
        }
      }
    });

    test('所有注册表应该有有效的服务类型', () {
      final registries = [
        CacheServiceRegistry(),
        NetworkServiceRegistry(),
        SecurityServiceRegistry(),
        PerformanceServiceRegistry(),
        DataServiceRegistry(),
        BusinessServiceRegistry(),
        StateServiceRegistry(),
      ];

      for (final registry in registries) {
        final services = registry.getServices();

        for (final registration in services.values) {
          expect(registration.implementationType, isNotNull,
              reason: 'Service implementation type should not be null');
          expect(registration.name.isNotEmpty, isTrue,
              reason: 'Service name should not be empty');
        }
      }
    });
  });
}

// 测试用的服务注册表
class TestServiceRegistry extends BaseServiceRegistry {
  TestServiceRegistry() {
    register(ServiceRegistration.lazySingleton(
      name: 'test_service_1',
      implementationType: TestService,
    ));
    register(ServiceRegistration.lazySingleton(
      name: 'test_service_2',
      implementationType: AnotherTestService,
    ));
  }
}

class AnotherTestServiceRegistry extends BaseServiceRegistry {
  AnotherTestServiceRegistry() {
    register(ServiceRegistration.lazySingleton(
      name: 'another_test_service_1',
      implementationType: TestService,
    ));
    register(ServiceRegistration.lazySingleton(
      name: 'another_test_service_2',
      implementationType: AnotherTestService,
    ));
  }
}

// 测试用的服务类
class TestService {
  final String name = 'test_service';
}

class AnotherTestService {
  final String name = 'another_test_service';
}
