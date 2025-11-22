import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/core/services/base/service_registry.dart';
import 'package:jisu_fund_analyzer/src/core/services/base/i_unified_service.dart';

// 生成Mock类
@GenerateMocks([IUnifiedService])
import 'service_registry_test.mocks.dart';

void main() {
  group('ServiceRegistry', () {
    late ServiceRegistry registry;
    late MockIUnifiedService mockService1;
    late MockIUnifiedService mockService2;

    setUp(() {
      registry = ServiceRegistry();

      mockService1 = MockIUnifiedService();
      mockService2 = MockIUnifiedService();

      // 设置服务基本属性
      when(mockService1.serviceName).thenReturn('TestService1');
      when(mockService1.version).thenReturn('1.0.0');
      when(mockService1.dependencies).thenReturn([]);

      when(mockService2.serviceName).thenReturn('TestService2');
      when(mockService2.version).thenReturn('1.0.0');
      when(mockService2.dependencies).thenReturn([]);
    });

    tearDown(() async {
      await registry.dispose();
    });

    test('应该正确创建服务注册表', () {
      expect(registry, isNotNull);
      expect(registry.getRegisteredServiceNames(), isEmpty);
    });

    test('应该注册服务实例', () async {
      await registry.registerService(mockService1);

      expect(registry.isRegisteredByName('TestService1'), isTrue);
      expect(registry.getRegisteredServiceNames(), contains('TestService1'));
      expect(registry.getService<MockIUnifiedService>(), equals(mockService1));
    });

    test('应该注册服务工厂', () async {
      await registry.registerServiceFactory<MockIUnifiedService>(
        'FactoryService1',
        () => mockService1,
      );

      expect(registry.isRegisteredByName('FactoryService1'), isTrue);

      // 获取服务应该创建新实例
      final service = registry.getServiceByName('FactoryService1');
      expect(service, isNotNull);
      expect(service!.serviceName, equals('TestService1'));
    });

    test('应该注册单例服务工厂', () async {
      await registry.registerSingletonServiceFactory<MockIUnifiedService>(
        'SingletonFactory1',
        () => mockService1,
      );

      expect(registry.isRegisteredByName('SingletonFactory1'), isTrue);

      // 多次获取应该返回相同实例
      final service1 = registry.getServiceByName('SingletonFactory1');
      final service2 = registry.getServiceByName('SingletonFactory1');
      expect(identical(service1, service2), isTrue);
    });

    test('应该覆盖已存在的服务', () async {
      final mockService1v2 = MockIUnifiedService();
      when(mockService1v2.serviceName).thenReturn('TestService1');
      when(mockService1v2.version).thenReturn('2.0.0');
      when(mockService1v2.dependencies).thenReturn([]);

      await registry.registerService(mockService1);
      await registry.registerService(mockService1v2);

      final service = registry.getService<MockIUnifiedService>();
      expect(service.version, equals('2.0.0'));
    });

    test('应该验证服务依赖关系', () async {
      // TestService2依赖TestService1
      when(mockService2.dependencies).thenReturn(['TestService1']);

      // 先注册依赖的服务
      await registry.registerService(mockService1);

      // 然后注册依赖的服务
      await registry.registerService(mockService2);

      expect(registry.isRegisteredByName('TestService1'), isTrue);
      expect(registry.isRegisteredByName('TestService2'), isTrue);
    });

    test('应该拒绝空的依赖服务名称', () async {
      when(mockService2.dependencies).thenReturn(['']);

      expect(
        () => registry.registerService(mockService2),
        throwsA(isA<ServiceDependencyException>().having(
          (e) => e.message,
          'message',
          contains('依赖服务名称不能为空'),
        )),
      );
    });

    test('应该正确处理类型安全的服务获取', () async {
      await registry.registerService(mockService1);

      final service = registry.getService<MockIUnifiedService>();
      expect(service, equals(mockService1));

      // 按名称获取基础接口类型
      final baseService = registry.getServiceByName('TestService1');
      expect(baseService, equals(mockService1));
    });

    test('应该正确处理按名称的服务获取', () async {
      await registry.registerService(mockService1);

      final service = registry.getServiceByName('TestService1');
      expect(service, equals(mockService1));

      final nonExistentService =
          registry.getServiceByName('NonExistentService');
      expect(nonExistentService, isNull);
    });

    test('应该正确检查服务是否已注册', () async {
      await registry.registerService(mockService1);

      expect(registry.isRegistered<MockIUnifiedService>(), isTrue);
      expect(registry.isRegisteredByName('TestService1'), isTrue);
      expect(registry.isRegisteredByName('NonExistentService'), isFalse);
    });

    test('应该正确获取服务元数据', () async {
      await registry.registerService(mockService1);

      final metadata = registry.getServiceMetadata('TestService1');
      expect(metadata, isNotNull);
      expect(metadata!.serviceName, equals('TestService1'));
      expect(metadata.version, equals('1.0.0'));
      expect(metadata.dependencies, isEmpty);
    });

    test('应该正确获取所有服务元数据', () async {
      await registry.registerService(mockService1);
      await registry.registerService(mockService2);

      final allMetadata = registry.getAllServiceMetadata();
      expect(allMetadata.length, equals(2));
      expect(allMetadata, contains('TestService1'));
      expect(allMetadata, contains('TestService2'));
    });

    test('应该正确注销服务', () async {
      await registry.registerService(mockService1);
      expect(registry.isRegisteredByName('TestService1'), isTrue);

      when(mockService1.dispose()).thenAnswer((_) async {});

      await registry.unregisterService('TestService1');

      expect(registry.isRegisteredByName('TestService1'), isFalse);
      verify(mockService1.dispose()).called(1);
    });

    test('应该正确清理所有服务', () async {
      await registry.registerService(mockService1);
      await registry.registerService(mockService2);

      when(mockService1.dispose()).thenAnswer((_) async {});
      when(mockService2.dispose()).thenAnswer((_) async {});

      await registry.clear();

      expect(registry.getRegisteredServiceNames(), isEmpty);
      verify(mockService1.dispose()).called(1);
      verify(mockService2.dispose()).called(1);
    });

    test('应该正确获取统计信息', () async {
      await registry.registerService(mockService1);
      await registry.registerServiceFactory<MockIUnifiedService>(
        'FactoryService1',
        () => mockService2,
      );

      final stats = registry.getStats();
      expect(stats['total_services'], equals(2));
      expect(stats['singleton_services'], equals(1));
      expect(stats['factory_services'], equals(1));
      expect(stats['initialized_instances'], equals(1)); // 只有注册的实例
    });

    test('应该拒绝在销毁后注册服务', () async {
      await registry.dispose();

      expect(
        () => registry.registerService(mockService1),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('ServiceRegistry已销毁'),
        )),
      );
    });

    test('应该拒绝在销毁后获取服务', () async {
      await registry.dispose();

      expect(
        () => registry.getServiceByName('TestService1'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('ServiceRegistry已销毁'),
        )),
      );
    });
  });

  group('ServiceDependencyResolver', () {
    late ServiceRegistry registry;
    late ServiceDependencyResolver resolver;
    late MockIUnifiedService mockService1;
    late MockIUnifiedService mockService2;
    late MockIUnifiedService mockService3;

    setUp(() async {
      registry = ServiceRegistry();
      resolver = ServiceDependencyResolver(registry);

      mockService1 = MockIUnifiedService();
      mockService2 = MockIUnifiedService();
      mockService3 = MockIUnifiedService();

      when(mockService1.serviceName).thenReturn('Service1');
      when(mockService1.version).thenReturn('1.0.0');
      when(mockService1.dependencies).thenReturn(['Service2']);

      when(mockService2.serviceName).thenReturn('Service2');
      when(mockService2.version).thenReturn('1.0.0');
      when(mockService2.dependencies).thenReturn(['Service3']);

      when(mockService3.serviceName).thenReturn('Service3');
      when(mockService3.version).thenReturn('1.0.0');
      when(mockService3.dependencies).thenReturn([]);

      await registry.registerService(mockService3);
      await registry.registerService(mockService2);
      await registry.registerService(mockService1);
    });

    tearDown(() async {
      await registry.dispose();
    });

    test('应该正确解析依赖链', () {
      final chain = resolver.resolveDependencyChain('Service1');

      // 依赖链应该是：Service3 -> Service2 -> Service1
      expect(chain, contains('Service1'));
      expect(chain, contains('Service2'));
      expect(chain, contains('Service3'));
      expect(chain.length, equals(3));
    });

    test('应该正确获取依赖图', () {
      final graph = resolver.getDependencyGraph();

      expect(graph, contains('Service1'));
      expect(graph, contains('Service2'));
      expect(graph, contains('Service3'));

      expect(graph['Service1'], equals(['Service2']));
      expect(graph['Service2'], equals(['Service3']));
      expect(graph['Service3'], isEmpty);
    });

    test('应该检测循环依赖', () async {
      // 创建循环依赖：Service1依赖Service2，Service2依赖Service1
      final mockService1WithCycle = MockIUnifiedService();
      final mockService2WithCycle = MockIUnifiedService();

      when(mockService1WithCycle.serviceName).thenReturn('Service1Cycle');
      when(mockService1WithCycle.version).thenReturn('1.0.0');
      when(mockService1WithCycle.dependencies).thenReturn(['Service2Cycle']);

      when(mockService2WithCycle.serviceName).thenReturn('Service2Cycle');
      when(mockService2WithCycle.version).thenReturn('1.0.0');
      when(mockService2WithCycle.dependencies).thenReturn(['Service1Cycle']);

      // 先注册Service2Cycle，再注册Service1Cycle
      await registry.registerService(mockService2WithCycle);
      await registry.registerService(mockService1WithCycle);

      final resolverWithCycle = ServiceDependencyResolver(registry);

      expect(
        () => resolverWithCycle.resolveDependencyChain('Service1Cycle'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('循环依赖'),
        )),
      );
    });

    test('应该验证所有依赖关系', () {
      final errors = resolver.validateAllDependencies();
      expect(errors, isEmpty); // 所有依赖都已注册
    });
  });

  group('ServiceConfigurationBuilder', () {
    late ServiceRegistry registry;

    setUp(() {
      registry = ServiceRegistry();
    });

    tearDown(() async {
      await registry.dispose();
    });

    test('应该支持链式配置', () async {
      final mockService = MockIUnifiedService();
      when(mockService.serviceName).thenReturn('ChainService');
      when(mockService.version).thenReturn('1.0.0');
      when(mockService.dependencies).thenReturn([]);

      await registry.registerService(mockService);

      expect(registry.isRegisteredByName('ChainService'), isTrue);

      final metadata = registry.getServiceMetadata('ChainService');
      expect(metadata!.version, equals('1.0.0'));
    });
  });

  group('ServiceMetadata', () {
    test('应该正确创建服务元数据', () {
      final metadata = ServiceMetadata(
        serviceName: 'TestService',
        version: '1.0.0',
        dependencies: ['Dep1', 'Dep2'],
        description: 'Test service',
        tags: {'key': 'value'},
      );

      expect(metadata.serviceName, equals('TestService'));
      expect(metadata.version, equals('1.0.0'));
      expect(metadata.dependencies, equals(['Dep1', 'Dep2']));
      expect(metadata.description, equals('Test service'));
      expect(metadata.tags['key'], equals('value'));
    });

    test('应该支持默认值', () {
      final metadata = ServiceMetadata(
        serviceName: 'TestService',
        version: '1.0.0',
        dependencies: [],
      );

      expect(metadata.description, isEmpty);
      expect(metadata.tags, isEmpty);
    });
  });
}
