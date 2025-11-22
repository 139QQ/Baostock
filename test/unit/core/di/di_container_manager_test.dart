import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';

import 'package:jisu_fund_analyzer/src/core/di/di_container_manager.dart';
import 'package:jisu_fund_analyzer/src/core/di/environment_config.dart';

// 生成Mock类
void main() {
  group('DIContainerManager', () {
    late DIContainerManager containerManager;
    late GetIt getIt;

    setUp(() {
      getIt = GetIt.asNewInstance();
      containerManager = DIContainerManager(getIt: getIt);
    });

    tearDown(() async {
      await containerManager.reset();
      await getIt.reset();
    });

    group('容器初始化', () {
      test('应该正确初始化空的容器管理器', () {
        expect(containerManager.getIt, equals(getIt));
        expect(containerManager.registeredServicesCount, equals(0));
        expect(containerManager.isConfigured, isFalse);
        expect(containerManager.currentEnvironment, equals('unknown'));
      });

      test('应该正确配置容器', () async {
        final config = DIContainerConfig.fromConfig(
          environment: 'test',
          environmentVariables: {'test_key': 'test_value'},
        );

        await containerManager.configure(config);

        expect(containerManager.isConfigured, isTrue);
        expect(containerManager.currentConfig, equals(config));
        expect(containerManager.currentEnvironment, equals('test'));
        expect(config.getEnvironmentVariable<String>('test_key'),
            equals('test_value'));
      });
    });

    group('服务注册', () {
      test('应该成功注册单例服务实例', () {
        final service = TestService();
        containerManager.registerSingletonInstance<TestService>(service);

        expect(containerManager.registeredServicesCount, equals(1));
        expect(containerManager.isRegistered<TestService>(), isTrue);
        expect(containerManager.isServiceNameRegistered('TestService'), isTrue);
        expect(containerManager.getServiceRegistrationType('TestService'),
            equals('singleton'));
      });

      test('应该成功注册懒加载单例服务', () {
        containerManager
            .registerLazySingleton<TestService>(() => TestService());

        expect(containerManager.registeredServicesCount, equals(1));
        expect(containerManager.isRegistered<TestService>(), isTrue);
        expect(containerManager.getServiceRegistrationType('TestService'),
            equals('lazySingleton'));
      });

      test('应该成功注册工厂服务', () {
        containerManager.registerFactory<TestService>(() => TestService());

        expect(containerManager.registeredServicesCount, equals(1));
        expect(containerManager.isRegistered<TestService>(), isTrue);
        expect(containerManager.getServiceRegistrationType('TestService'),
            equals('factory'));
      });

      test('应该成功注册异步单例服务', () async {
        await containerManager
            .registerAsyncSingleton<AsyncTestService>(() async {
          await Future.delayed(Duration(milliseconds: 10));
          return AsyncTestService();
        });

        expect(containerManager.registeredServicesCount, equals(1));
        expect(containerManager.isRegistered<AsyncTestService>(), isTrue);
        expect(containerManager.getServiceRegistrationType('AsyncTestService'),
            equals('asyncSingleton'));
      });

      test('应该防止重复注册相同名称的服务', () {
        final service1 = TestService();
        final service2 = AnotherTestService();

        containerManager.registerSingletonInstance<TestService>(service1,
            name: 'duplicate_test');
        expect(containerManager.registeredServicesCount, equals(1));

        // 尝试重复注册同名服务
        containerManager.registerSingletonInstance<AnotherTestService>(service2,
            name: 'duplicate_test');
        expect(containerManager.registeredServicesCount, equals(1)); // 数量不变
      });

      test('应该支持自定义服务名称', () {
        containerManager.registerLazySingleton<TestService>(
          () => TestService(),
          name: 'custom_service_name',
        );

        expect(containerManager.registeredServicesCount, equals(1));
        expect(containerManager.isServiceNameRegistered('custom_service_name'),
            isTrue);
        expect(
            containerManager.getServiceRegistrationType('custom_service_name'),
            equals('lazySingleton'));
      });

      test('应该正确处理注册失败', () {
        containerManager.registerLazySingleton<InvalidService>(
            () => throw Exception('Invalid service'));
        // 注册时不会立即抛出异常，只有在获取服务时才会失败
        expect(
          () => containerManager.get<InvalidService>(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('服务获取', () {
      setUp(() {
        containerManager
            .registerLazySingleton<TestService>(() => TestService());
      });

      test('应该正确获取已注册的服务', () {
        final service = containerManager.get<TestService>();
        expect(service, isA<TestService>());
        expect(service.name, equals('test'));
      });

      test('单例服务应该返回同一实例', () {
        final service1 = containerManager.get<TestService>();
        final service2 = containerManager.get<TestService>();
        expect(identical(service1, service2), isTrue);
      });

      test('工厂服务应该返回不同实例', () async {
        await containerManager.reset();
        containerManager.registerFactory<TestService>(() => TestService());

        final service1 = containerManager.get<TestService>();
        final service2 = containerManager.get<TestService>();
        expect(identical(service1, service2), isFalse);
      });

      test('异步获取服务应该正常工作', () async {
        await containerManager.reset();
        await containerManager
            .registerAsyncSingleton<AsyncTestService>(() async {
          await Future.delayed(Duration(milliseconds: 10));
          return AsyncTestService();
        });

        final service = await containerManager.getAsync<AsyncTestService>();
        expect(service, isA<AsyncTestService>());
        expect(service.initialized, isTrue);
      });

      test('获取未注册的服务应该抛出异常', () {
        expect(
          () => containerManager.get<UnregisteredService>(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('服务状态检查', () {
      test('应该正确检查服务是否已注册', () {
        expect(containerManager.isRegistered<TestService>(), isFalse);
        expect(
            containerManager.isServiceNameRegistered('TestService'), isFalse);

        containerManager
            .registerLazySingleton<TestService>(() => TestService());

        expect(containerManager.isRegistered<TestService>(), isTrue);
        expect(containerManager.isServiceNameRegistered('TestService'), isTrue);
      });

      test('应该返回正确的服务名称列表', () {
        containerManager.registerLazySingleton<TestService>(() => TestService(),
            name: 'service1');
        containerManager.registerSingletonInstance<AnotherTestService>(
            AnotherTestService(),
            name: 'service2');

        final serviceNames = containerManager.registeredServiceNames;
        expect(serviceNames.length, equals(2));
        expect(serviceNames, contains('service1'));
        expect(serviceNames, contains('service2'));
      });

      test('应该返回正确的服务注册信息', () {
        containerManager
            .registerLazySingleton<TestService>(() => TestService());

        final registeredServices = containerManager.registeredServices;
        expect(registeredServices.length, equals(1));
        expect(registeredServices['TestService'], equals('lazySingleton'));
      });
    });

    group('自定义服务注册', () {
      test('应该支持使用registrationFunction注册服务', () async {
        final registration = ServiceRegistration(
          name: 'custom_service',
          lifetime: ServiceLifetime.lazySingleton,
          implementationType: TestService,
          registrationFunction: (manager) async {
            manager.registerLazySingleton<TestService>(() => TestService(),
                name: 'custom_service');
          },
        );

        await containerManager.registerService(registration);
        expect(
            containerManager.isServiceNameRegistered('custom_service'), isTrue);
        expect(containerManager.getServiceRegistrationType('custom_service'),
            equals('lazySingleton'));
      });

      test('应该支持使用factory函数注册服务', () {
        final registration = ServiceRegistration.factory(
          name: 'factory_service',
          implementationType: TestService,
          factory: () => TestService(),
        );

        containerManager.registerService(registration);
        expect(containerManager.getServiceRegistrationType('factory_service'),
            equals('factory'));
      });
    });

    group('批量注册', () {
      test('应该支持批量注册服务', () async {
        final registrations = <Future<void> Function()>[
          () async {
            containerManager
                .registerLazySingleton<TestService>(() => TestService());
          },
          () async {
            containerManager.registerSingletonInstance<AnotherTestService>(
                AnotherTestService());
          },
          () async {
            containerManager.registerFactory<FactoryTestService>(
                () => FactoryTestService());
          },
        ];

        await containerManager.registerBatch(registrations);

        expect(containerManager.registeredServicesCount, equals(3));
        expect(containerManager.isRegistered<TestService>(), isTrue);
        expect(containerManager.isRegistered<AnotherTestService>(), isTrue);
        expect(containerManager.isRegistered<FactoryTestService>(), isTrue);
      });

      test('批量注册失败应该抛出异常', () async {
        final registrations = <Future<void> Function()>[
          () async {
            containerManager
                .registerLazySingleton<TestService>(() => TestService());
          },
          () async {
            // 先注册一个会导致失败的服务
            containerManager.registerLazySingleton<InvalidService>(
                () => throw Exception('Invalid'));
            // 然后尝试获取它来触发异常
            containerManager.get<InvalidService>();
          },
        ];

        expect(
          () async => await containerManager.registerBatch(registrations),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('容器重置', () {
      test('应该正确重置容器状态', () async {
        containerManager
            .registerLazySingleton<TestService>(() => TestService());

        expect(containerManager.registeredServicesCount, equals(1));
        expect(containerManager.isConfigured, isFalse);

        final config = DIContainerConfig.fromConfig(environment: 'test');
        await containerManager.configure(config);

        expect(containerManager.isConfigured, isTrue);

        await containerManager.reset();

        expect(containerManager.registeredServicesCount, equals(0));
        expect(containerManager.isConfigured, isFalse);
        expect(containerManager.isRegistered<TestService>(), isFalse);
      });
    });

    group('容器状态信息', () {
      test('应该返回正确的容器状态', () async {
        final config = DIContainerConfig.fromConfig(
          environment: 'development',
          environmentVariables: {'debug': true},
        );

        containerManager
            .registerLazySingleton<TestService>(() => TestService());

        await containerManager.configure(config);

        final status = containerManager.containerStatus;

        expect(status['isConfigured'], isTrue);
        expect(status['environment'], equals('development'));
        expect(status['isDevelopment'], isTrue);
        expect(status['isTesting'], isFalse);
        expect(status['isProduction'], isFalse);
        expect(status['registeredServicesCount'], equals(1));
        expect(status['registeredServices'], contains('TestService'));
      });
    });

    group('环境相关方法', () {
      test('应该正确获取环境变量', () async {
        final config = DIContainerConfig.fromConfig(
          environment: 'production',
          environmentVariables: {
            'api_url': 'https://api.example.com',
            'timeout': 30,
            'debug_mode': false,
          },
        );

        await containerManager.configure(config);

        expect(
            containerManager.currentConfig!
                .getEnvironmentVariable<String>('api_url'),
            equals('https://api.example.com'));
        expect(
            containerManager.currentConfig!
                .getEnvironmentVariable<int>('timeout'),
            equals(30));
        expect(
            containerManager.currentConfig!
                .getEnvironmentVariable<bool>('debug_mode'),
            isFalse);
        expect(
            containerManager.currentConfig!
                .getEnvironmentVariable<String>('non_existent'),
            isNull);
      });

      test('应该正确返回环境状态', () async {
        await containerManager
            .configure(DIContainerConfig.fromConfig(environment: 'testing'));

        expect(containerManager.isDevelopment, isFalse);
        expect(containerManager.isTesting, isTrue);
        expect(containerManager.isProduction, isFalse);

        await containerManager
            .configure(DIContainerConfig.fromConfig(environment: 'production'));

        expect(containerManager.isDevelopment, isFalse);
        expect(containerManager.isTesting, isFalse);
        expect(containerManager.isProduction, isTrue);
      });
    });

    group('按名称获取服务', () {
      test('应该支持按名称获取服务', () {
        containerManager.registerLazySingleton<NamedTestService>(
          () => NamedTestService('custom_name'),
          name: 'named_service',
        );

        final service =
            containerManager.getByName<NamedTestService>('named_service');
        expect(service, isA<NamedTestService>());
        expect(service.name, equals('custom_name'));
      });

      test('按名称获取不存在的服务应该抛出异常', () {
        expect(
          () => containerManager.getByName<TestService>('non_existent_service'),
          throwsA(isA<ServiceRegistrationException>()),
        );
      });
    });

    group('错误处理', () {
      test('获取服务失败应该记录错误并重新抛出', () async {
        // 创建一个已注册但GetIt中没有的服务来模拟错误
        final containerManager = DIContainerManager();
        // 不实际注册服务，只是标记为已注册
        containerManager
            .registerLazySingleton<TestService>(() => TestService());

        // 现在手动清除GetIt中的注册来模拟错误
        await containerManager.getIt.reset();

        expect(
          () => containerManager.get<TestService>(),
          throwsA(isA<StateError>()),
        );
      });

      test('异步获取服务失败应该记录错误并重新抛出', () async {
        final containerManager = DIContainerManager();
        // 同样模拟异步获取失败
        await containerManager
            .registerAsyncSingleton<AsyncTestService>(() async {
          await Future.delayed(Duration(milliseconds: 10));
          return AsyncTestService();
        });

        // 清除注册来模拟错误
        await containerManager.getIt.reset();

        expect(
          () async => await containerManager.getAsync<AsyncTestService>(),
          throwsA(isA<StateError>()),
        );
      });
    });
  });

  group('ServiceRegistration', () {
    test('应该正确创建单例注册', () {
      final registration = ServiceRegistration.singleton(
        name: 'test',
        implementationType: String,
      );

      expect(registration.name, equals('test'));
      expect(registration.implementationType, equals(String));
      expect(registration.lifetime, equals(ServiceLifetime.singleton));
      expect(registration.asyncInitialization, isFalse);
    });

    test('应该正确创建懒加载单例注册', () {
      final registration = ServiceRegistration.lazySingleton(
        name: 'test',
        implementationType: String,
        asyncInitialization: true,
      );

      expect(registration.name, equals('test'));
      expect(registration.implementationType, equals(String));
      expect(registration.lifetime, equals(ServiceLifetime.lazySingleton));
      expect(registration.asyncInitialization, isTrue);
    });

    test('应该正确创建工厂注册', () {
      final registration = ServiceRegistration.factory(
        name: 'test',
        implementationType: String,
      );

      expect(registration.name, equals('test'));
      expect(registration.implementationType, equals(String));
      expect(registration.lifetime, equals(ServiceLifetime.factory));
    });

    test('应该正确创建异步单例注册', () {
      final registration = ServiceRegistration.asyncSingleton(
        name: 'test',
        implementationType: String,
      );

      expect(registration.name, equals('test'));
      expect(registration.implementationType, equals(String));
      expect(registration.lifetime, equals(ServiceLifetime.asyncSingleton));
      expect(registration.asyncInitialization, isTrue);
    });

    test('应该支持自定义工厂函数', () {
      final customFactory = () => 'custom_value';
      final registration = ServiceRegistration.factory(
        name: 'test',
        implementationType: String,
        factory: customFactory,
      );

      expect(registration.factory, equals(customFactory));
    });

    test('应该支持接口类型', () {
      final registration = ServiceRegistration.singleton(
        name: 'test',
        implementationType: String,
        interfaceType: Object,
      );

      expect(registration.interfaceType, equals(Object));
    });
  });

  group('DIContainerConfig', () {
    test('应该正确创建配置', () {
      final environmentVariables = {
        'key': 'value',
        'timeout': 30,
        'debug': true,
      };

      final config = DIContainerConfig.fromConfig(
        environment: 'development',
        environmentVariables: environmentVariables,
      );

      expect(config.environment, equals('development'));
      expect(config.getEnvironmentVariable('key'), equals('value'));
      expect(config.getEnvironmentVariable('timeout'), equals(30));
      expect(config.getEnvironmentVariable('debug'), isTrue);
    });

    test('应该正确检查环境类型', () {
      final devConfig =
          DIContainerConfig.fromConfig(environment: 'development');
      final testConfig = DIContainerConfig.fromConfig(environment: 'testing');
      final prodConfig =
          DIContainerConfig.fromConfig(environment: 'production');

      expect(devConfig.isDevelopment, isTrue);
      expect(devConfig.isTesting, isFalse);
      expect(devConfig.isProduction, isFalse);

      expect(testConfig.isDevelopment, isFalse);
      expect(testConfig.isTesting, isTrue);
      expect(testConfig.isProduction, isFalse);

      expect(prodConfig.isDevelopment, isFalse);
      expect(prodConfig.isTesting, isFalse);
      expect(prodConfig.isProduction, isTrue);
    });
  });
}

// 测试用的服务类
class TestService {
  final String name;

  TestService() : name = 'test';

  String get getName => name;
}

class AnotherTestService {
  final String name;

  AnotherTestService() : name = 'another_test';

  String get getName => name;
}

class AsyncTestService {
  final bool initialized = true;

  AsyncTestService();
}

class FactoryTestService {
  final String name = 'factory_service';
}

class NamedTestService {
  final String name;

  NamedTestService(this.name);
}

class InvalidService {
  InvalidService() {
    throw Exception('Invalid service constructor');
  }
}

class UnregisteredService {
  UnregisteredService();
}
