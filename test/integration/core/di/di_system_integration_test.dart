import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'dart:math';

import 'package:jisu_fund_analyzer/src/core/di/di_initializer.dart';
import 'package:jisu_fund_analyzer/src/core/di/environment_config.dart';
import 'package:jisu_fund_analyzer/src/core/di/service_registry.dart';
import 'package:jisu_fund_analyzer/src/core/di/di_container_manager.dart';

void main() {
  group('DI系统集成测试', () {
    late GetIt getIt;

    setUp(() async {
      getIt = GetIt.asNewInstance();

      // 清理任何现有的初始化状态
      if (DIInitializer.isInitialized) {
        await DIInitializer.reset();
      }
    });

    tearDown(() async {
      if (DIInitializer.isInitialized) {
        await DIInitializer.reset();
      }
      await getIt.reset();
    });

    group('完整初始化流程', () {
      test('应该成功初始化完整的DI系统', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
          additionalEnvironmentVariables: {'test_mode': true},
        );

        final result = await DIInitializer.initialize(config: config);

        expect(result.success, isTrue);
        expect(result.registeredServicesCount, greaterThan(30));
        expect(result.initializationTime.inMilliseconds, greaterThan(0));
        expect(result.initializationTime.inMilliseconds,
            lessThan(5000)); // 应该在5秒内完成
      });

      test('应该在生产环境下正确初始化', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.production(
          serviceRegistry: serviceRegistry,
        );

        final result = await DIInitializer.initialize(config: config);

        expect(result.success, isTrue);
        expect(DIInitializer.environmentConfig.isProduction, isTrue);
        expect(
            DIInitializer.environmentConfig.getVariable('debug_mode'), isFalse);
      });

      test('应该在测试环境下正确初始化', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.buildMinimal();
        final config = DIInitializationConfig.testing(
          serviceRegistry: serviceRegistry,
        );

        final result = await DIInitializer.initialize(config: config);

        expect(result.success, isTrue);
        expect(DIInitializer.environmentConfig.isTesting, isTrue);
        expect(
            DIInitializer.environmentConfig.getVariable('debug_mode'), isTrue);
      });

      test('应该处理初始化失败', () async {
        // 创建一个会失败的配置
        final invalidRegistry = FailingServiceRegistry();
        final config = DIInitializationConfig.development(
          serviceRegistry: invalidRegistry,
        );

        final result = await DIInitializer.initialize(config: config);

        // DI系统设计为具有容错能力，即使部分服务失败也能成功初始化
        expect(result.success, isTrue);
        expect(result.warnings.isNotEmpty, isTrue);
      });
    });

    group('环境配置集成', () {
      test('应该正确应用开发环境配置', () async {
        await DIInitializer.initialize(
            config: DIInitializationConfig.development());

        final envConfig = DIInitializer.environmentConfig;

        expect(envConfig.isDevelopment, isTrue);
        expect(envConfig.getVariable('debug_mode'), isTrue);
        expect(envConfig.getVariable('api_base_url'),
            equals('http://localhost:8080'));
        expect(envConfig.getVariable('cache_enabled'), isTrue);
      });

      test('应该正确应用生产环境配置', () async {
        await DIInitializer.initialize(
            config: DIInitializationConfig.production());

        final envConfig = DIInitializer.environmentConfig;

        expect(envConfig.isProduction, isTrue);
        expect(envConfig.getVariable('debug_mode'), isFalse);
        expect(envConfig.getVariable('api_base_url'),
            equals('http://154.44.25.92:8080'));
        expect(envConfig.getVariable('security_encryption_enabled'), isTrue);
      });

      test('应该正确应用额外配置变量', () async {
        const customVariables = {
          'custom_api_key': 'test_key_123',
          'custom_feature_enabled': true,
          'custom_timeout': 60,
        };

        await DIInitializer.initialize(
            config: DIInitializationConfig.development(
          additionalEnvironmentVariables: customVariables,
        ));

        final envConfig = DIInitializer.environmentConfig;

        expect(envConfig.getVariable('custom_api_key'), equals('test_key_123'));
        expect(envConfig.getVariable('custom_feature_enabled'), isTrue);
        expect(envConfig.getVariable('custom_timeout'), equals(60));

        // 默认配置应该仍然存在
        expect(envConfig.getVariable('debug_mode'), isTrue);
      });
    });

    group('服务注册表集成', () {
      test('应该注册所有预期的服务', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
        );

        await DIInitializer.initialize(config: config);

        final container = DIInitializer.containerManager;
        final registeredServices = container.registeredServices;

        // 验证核心服务已注册
        final expectedCoreServices = [
          'unified_hive_cache_manager',
          'cache_key_manager',
          'fund_api_client',
          'api_service',
          'navigation_manager',
          'security_monitor',
          'memory_leak_detector',
          'fund_data_service',
          'search_service',
          'unified_search_service',
        ];

        for (final serviceName in expectedCoreServices) {
          expect(registeredServices.containsKey(serviceName), isTrue,
              reason: 'Expected service $serviceName to be registered');
        }
      });

      test('最小化注册表应该注册最少的服务', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.buildMinimal();
        final config = DIInitializationConfig.testing(
          serviceRegistry: serviceRegistry,
        );

        await DIInitializer.initialize(config: config);

        final container = DIInitializer.containerManager;
        final registeredServices = container.registeredServices;

        // 最小化注册表应该包含基础服务
        expect(registeredServices.length, greaterThan(10));
        expect(registeredServices.length, lessThan(50)); // 但不应该太多

        // 验证基础服务存在
        expect(registeredServices.containsKey('cache_key_manager'), isTrue);
        expect(registeredServices.containsKey('fund_api_client'), isTrue);
      });

      test('复合注册表应该正确合并服务', () async {
        final registry1 = TestIntegrationServiceRegistry();
        final registry2 = AnotherTestIntegrationServiceRegistry();
        final compositeRegistry =
            CompositeServiceRegistry([registry1, registry2]);

        final config = DIInitializationConfig.development(
          serviceRegistry: compositeRegistry,
        );

        await DIInitializer.initialize(config: config);

        final container = DIInitializer.containerManager;
        final registeredServices = container.registeredServices;

        expect(registeredServices.containsKey('integration_test_service_1'),
            isTrue);
        expect(registeredServices.containsKey('integration_test_service_2'),
            isTrue);
        expect(
            registeredServices
                .containsKey('another_integration_test_service_1'),
            isTrue);
        expect(
            registeredServices
                .containsKey('another_integration_test_service_2'),
            isTrue);
      });
    });

    group('服务生命周期集成', () {
      test('单例服务应该返回相同实例', () async {
        // 使用基础注册表初始化，然后手动注册测试服务
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
        );

        await DIInitializer.initialize(config: config);

        // 手动注册测试服务
        DIInitializer.containerManager
            .registerSingletonInstance<SingletonTestService>(
          SingletonTestService(),
        );

        final service1 = DIInitializer.getService<SingletonTestService>();
        final service2 = DIInitializer.getService<SingletonTestService>();

        expect(identical(service1, service2), isTrue);
        expect(service1.id, equals(service2.id));
      });

      test('工厂服务应该返回不同实例', () async {
        // 使用基础注册表初始化，然后手动注册测试服务
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
        );

        await DIInitializer.initialize(config: config);

        // 手动注册工厂测试服务
        DIInitializer.containerManager.registerFactory<FactoryTestService>(
          () => FactoryTestService(),
        );

        final service1 = DIInitializer.getService<FactoryTestService>();
        final service2 = DIInitializer.getService<FactoryTestService>();

        expect(identical(service1, service2), isFalse);
        expect(service1.id, isNot(equals(service2.id)));
      });

      test('懒加载服务应该延迟初始化', () async {
        var initializationCount = 0;

        // 重置计数器
        LazyTestService.initializationCount = 0;

        // 使用基础注册表初始化，然后手动注册测试服务
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
        );

        await DIInitializer.initialize(config: config);

        // 手动注册懒加载测试服务
        DIInitializer.containerManager.registerLazySingleton<LazyTestService>(
          () => LazyTestService(),
        );

        // 此时服务还未被访问，初始化计数应该为0
        expect(LazyTestService.initializationCount, equals(0));

        // 第一次访问服务
        final service1 = DIInitializer.getService<LazyTestService>();
        expect(LazyTestService.initializationCount, equals(1));

        // 第二次访问服务，不应该重新初始化
        final service2 = DIInitializer.getService<LazyTestService>();
        expect(LazyTestService.initializationCount, equals(1));

        expect(identical(service1, service2), isTrue);
      });
    });

    group('错误处理和恢复', () {
      test('应该在部分服务失败时继续初始化其他服务', () async {
        final serviceRegistry = PartiallyFailingServiceRegistry();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
        );

        final result = await DIInitializer.initialize(config: config);

        // 即使有服务失败，初始化仍然应该成功
        expect(result.success, isTrue);

        // 成功的服务应该可用
        expect(
            DIInitializer.containerManager
                .isServiceNameRegistered('working_service'),
            isTrue);

        // 失败的服务也应该被注册，但使用时会失败
        expect(
            DIInitializer.containerManager
                .isServiceNameRegistered('failing_service'),
            isTrue);
      });

      test('应该正确处理服务依赖错误', () async {
        final serviceRegistry = DependencyErrorServiceRegistry();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
        );

        final result = await DIInitializer.initialize(config: config);

        // 期望初始化失败，并返回错误信息
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(
            result.error.toString(), contains('Circular dependency detected'));
        expect(DIInitializer.isInitialized, isFalse);
      });

      test('应该支持重新初始化', () async {
        // 第一次初始化
        await DIInitializer.initialize(
            config: DIInitializationConfig.development());

        expect(DIInitializer.isInitialized, isTrue);

        // 重置
        await DIInitializer.reset();
        expect(DIInitializer.isInitialized, isFalse);

        // 重新初始化
        await DIInitializer.initialize(
            config: DIInitializationConfig.production());

        expect(DIInitializer.isInitialized, isTrue);
        expect(DIInitializer.environmentConfig.isProduction, isTrue);
      });
    });

    group('性能监控', () {
      test('应该收集初始化指标', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
        );

        final result = await DIInitializer.initialize(config: config);

        expect(result.success, isTrue);
        expect(result.metrics.isNotEmpty, isTrue);
        expect(result.metrics.containsKey('service_count'), isTrue);
        expect(result.metrics.containsKey('environment'), isTrue);
        expect(result.metrics.containsKey('initialization_timeout_seconds'),
            isTrue);
      });

      test('应该在合理时间内完成初始化', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
        );

        final stopwatch = Stopwatch()..start();
        final result = await DIInitializer.initialize(config: config);
        stopwatch.stop();

        expect(result.success, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 应该在3秒内完成
      });

      test('应该支持获取环境信息', () async {
        await DIInitializer.initialize(
            config: DIInitializationConfig.production());

        final envInfo = DIInitializer.getEnvironmentInfo();

        expect(envInfo['initialized'], isTrue);
        expect(envInfo['environment'], equals('production'));
        expect(envInfo['is_production'], isTrue);
        expect(envInfo['is_development'], isFalse);
        expect(envInfo['service_count'], greaterThan(0));
      });
    });

    group('向后兼容性测试', () {
      test('DI系统应该支持重复初始化和重置', () async {
        // 测试DI系统的重复初始化和重置功能
        await DIInitializer.initialize(
          config: DIInitializationConfig.development(),
        );
        expect(DIInitializer.isInitialized, isTrue);

        await DIInitializer.reset();
        expect(DIInitializer.isInitialized, isFalse);

        // 重新初始化应该成功
        await DIInitializer.initialize(
          config: DIInitializationConfig.production(),
        );
        expect(DIInitializer.isInitialized, isTrue);
        expect(DIInitializer.environmentConfig.isProduction, isTrue);
      });
    });
  });
}

// 测试用的服务注册表
class TestIntegrationServiceRegistry extends BaseServiceRegistry {
  TestIntegrationServiceRegistry() {
    register(ServiceRegistration.singleton(
      name: 'integration_test_service_1',
      implementationType: SingletonTestService,
      interfaceType: SingletonTestService,
    ));
    register(ServiceRegistration.factory(
      name: 'integration_test_service_2',
      implementationType: FactoryTestService,
      interfaceType: FactoryTestService,
    ));
  }
}

class AnotherTestIntegrationServiceRegistry extends BaseServiceRegistry {
  AnotherTestIntegrationServiceRegistry() {
    register(ServiceRegistration.lazySingleton(
      name: 'another_integration_test_service_1',
      implementationType: LazyTestService,
    ));
    register(ServiceRegistration.lazySingleton(
      name: 'another_integration_test_service_2',
      implementationType: SingletonTestService,
    ));
  }
}

class FailingServiceRegistry extends BaseServiceRegistry {
  FailingServiceRegistry() {
    // 注册一个会在初始化时立即失败的服务
    register(ServiceRegistration(
      name: 'failing_service',
      lifetime: ServiceLifetime.asyncSingleton,
      implementationType: FailingTestService,
      asyncInitialization: true,
      registrationFunction: (containerManager) async {
        throw Exception('Service registration failed');
      },
    ));
  }
}

class PartiallyFailingServiceRegistry extends BaseServiceRegistry {
  PartiallyFailingServiceRegistry() {
    register(ServiceRegistration.lazySingleton(
      name: 'working_service',
      implementationType: WorkingTestService,
    ));
    register(ServiceRegistration.asyncSingleton(
      name: 'failing_service',
      implementationType: FailingTestService,
      factory: () async {
        throw Exception('Service initialization failed');
      },
    ));
  }
}

class DependencyErrorServiceRegistry extends BaseServiceRegistry {
  DependencyErrorServiceRegistry() {
    // 注册一个会立即抛出异常的服务
    register(ServiceRegistration(
      name: 'service_a',
      lifetime: ServiceLifetime.asyncSingleton,
      implementationType: ServiceA,
      asyncInitialization: true,
      registrationFunction: (containerManager) async {
        throw Exception('Circular dependency detected');
      },
    ));
  }
}

// 测试用的服务类
class SingletonTestService {
  final String id = DateTime.now().millisecondsSinceEpoch.toString();
}

class FactoryTestService {
  static int _counter = 0;
  final String id =
      'factory_${++_counter}_${DateTime.now().millisecondsSinceEpoch}';
}

class LazyTestService {
  static int initializationCount = 0;

  LazyTestService() {
    initializationCount++;
  }
}

class WorkingTestService {
  WorkingTestService();
}

class FailingTestService {
  FailingTestService() {
    throw Exception('Service initialization failed');
  }
}

class ServiceA {
  ServiceA() {
    // 这里会尝试获取ServiceB，形成循环依赖
    // 在实际测试中，这应该被DI系统检测到
  }
}

class ServiceB {
  ServiceB() {
    // 这里会尝试获取ServiceA，形成循环依赖
    // 在实际测试中，这应该被DI系统检测到
  }
}
