import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';

import 'package:jisu_fund_analyzer/src/core/services/base/service_lifecycle_manager.dart';
import 'package:jisu_fund_analyzer/src/core/services/base/service_registry.dart';
import 'package:jisu_fund_analyzer/src/core/services/base/i_unified_service.dart';

// 生成Mock类
@GenerateMocks([IUnifiedService, ServiceContainer])
import 'service_lifecycle_manager_test.mocks.dart';

void main() {
  group('ServiceLifecycleManager', () {
    late ServiceLifecycleManager manager;
    late MockServiceContainer mockContainer;
    late MockIUnifiedService mockService1;
    late MockIUnifiedService mockService2;

    setUp(() {
      mockContainer = MockServiceContainer();
      manager = ServiceLifecycleManager(mockContainer);

      mockService1 = MockIUnifiedService();
      mockService2 = MockIUnifiedService();

      // 设置服务基本属性
      when(mockService1.serviceName).thenReturn('TestService1');
      when(mockService1.version).thenReturn('1.0.0');
      when(mockService1.dependencies).thenReturn([]);
      when(mockService1.lifecycleState)
          .thenReturn(ServiceLifecycleState.uninitialized);

      when(mockService2.serviceName).thenReturn('TestService2');
      when(mockService2.version).thenReturn('1.0.0');
      when(mockService2.dependencies).thenReturn([]);
      when(mockService2.lifecycleState)
          .thenReturn(ServiceLifecycleState.uninitialized);
    });

    tearDown(() {
      manager.dispose();
    });

    test('应该正确创建生命周期管理器', () {
      expect(manager, isNotNull);
      expect(manager.getAllServiceStates(), isEmpty);
    });

    test('应该按依赖顺序初始化服务', () async {
      // 设置依赖关系：Service2依赖Service1
      when(mockService2.dependencies).thenReturn(['TestService1']);

      // 模拟容器行为
      when(mockContainer.getRegisteredServiceNames())
          .thenReturn(['TestService1', 'TestService2']);
      when(mockContainer.getServiceByName('TestService1'))
          .thenReturn(mockService1);
      when(mockContainer.getServiceByName('TestService2'))
          .thenReturn(mockService2);

      // 模拟初始化行为
      when(mockService1.initialize(any)).thenAnswer((_) async {});
      when(mockService2.initialize(any)).thenAnswer((_) async {});

      // 模拟状态变化
      when(mockService1.lifecycleState)
          .thenReturn(ServiceLifecycleState.initialized);
      when(mockService2.lifecycleState)
          .thenReturn(ServiceLifecycleState.initialized);

      final initializedServices = await manager.initializeAllServices();

      expect(initializedServices, contains('TestService1'));
      expect(initializedServices, contains('TestService2'));

      verify(mockService1.initialize(any)).called(1);
      verify(mockService2.initialize(any)).called(1);
    });

    test('应该检测循环依赖', () async {
      // 设置循环依赖：Service1依赖Service2，Service2依赖Service1
      when(mockService1.dependencies).thenReturn(['TestService2']);
      when(mockService2.dependencies).thenReturn(['TestService1']);

      when(mockContainer.getRegisteredServiceNames())
          .thenReturn(['TestService1', 'TestService2']);
      when(mockContainer.getServiceByName('TestService1'))
          .thenReturn(mockService1);
      when(mockContainer.getServiceByName('TestService2'))
          .thenReturn(mockService2);

      expect(
        () => manager.initializeAllServices(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('循环依赖'),
        )),
      );
    });

    test('应该处理初始化超时', () async {
      when(mockContainer.getRegisteredServiceNames())
          .thenReturn(['TestService1']);
      when(mockContainer.getServiceByName('TestService1'))
          .thenReturn(mockService1);

      // 设置一个永不完成的初始化
      when(mockService1.initialize(any))
          .thenAnswer((_) => Future.delayed(Duration(hours: 1)));

      final shortTimeoutManager = ServiceLifecycleManager(
        mockContainer,
        initializationTimeout: Duration(milliseconds: 100),
      );

      // 根据R.3优雅降级规范，超时服务不会阻止其他服务初始化
      final initializedServices =
          await shortTimeoutManager.initializeAllServices();

      // 超时的服务不应该在成功初始化的列表中
      expect(initializedServices, isEmpty);

      // 服务状态应该是error
      expect(shortTimeoutManager.getServiceState('TestService1'),
          equals(ServiceLifecycleState.error));

      shortTimeoutManager.dispose();
    });

    test('应该按逆序销毁服务', () async {
      when(mockService1.dependencies).thenReturn([]);
      when(mockService2.dependencies).thenReturn(['TestService1']);

      when(mockContainer.getRegisteredServiceNames())
          .thenReturn(['TestService1', 'TestService2']);
      when(mockContainer.getServiceByName('TestService1'))
          .thenReturn(mockService1);
      when(mockContainer.getServiceByName('TestService2'))
          .thenReturn(mockService2);

      when(mockService1.initialize(any)).thenAnswer((_) async {});
      when(mockService2.initialize(any)).thenAnswer((_) async {});

      when(mockService1.dispose()).thenAnswer((_) async {});
      when(mockService2.dispose()).thenAnswer((_) async {});

      await manager.initializeAllServices();
      await manager.disposeAllServices();

      // 验证销毁顺序：Service2先销毁，Service1后销毁（逆序）
      verifyInOrder([
        mockService2.dispose(),
        mockService1.dispose(),
      ]);
    });

    test('应该正确跟踪服务状态', () async {
      when(mockContainer.getRegisteredServiceNames())
          .thenReturn(['TestService1']);
      when(mockContainer.getServiceByName('TestService1'))
          .thenReturn(mockService1);
      when(mockService1.initialize(any)).thenAnswer((_) async {});

      // 监听状态变化事件
      final events = <ServiceLifecycleEvent>[];
      manager.lifecycleEvents.listen(events.add);

      // 等待一下确保事件监听器已设置
      await Future.delayed(Duration(milliseconds: 10));

      await manager.initializeAllServices();

      // 等待一下确保所有事件都被处理
      await Future.delayed(Duration(milliseconds: 10));

      expect(manager.getServiceState('TestService1'),
          equals(ServiceLifecycleState.initialized));
      expect(events.length, greaterThan(0));
      expect(
        events.any((e) =>
            e.type == 'state_changed' &&
            e.details['new_state'] == 'initialized'),
        isTrue,
      );
    });

    test('应该生成健康状态报告', () async {
      when(mockContainer.getRegisteredServiceNames())
          .thenReturn(['TestService1']);
      when(mockContainer.getServiceByName('TestService1'))
          .thenReturn(mockService1);
      when(mockService1.initialize(any)).thenAnswer((_) async {});

      when(mockService1.checkHealth())
          .thenAnswer((_) async => ServiceHealthStatus(
                isHealthy: true,
                message: 'Service is healthy',
                lastCheck: DateTime.now(),
              ));

      await manager.initializeAllServices();
      final healthReport = await manager.getHealthReport();

      expect(healthReport, contains('TestService1'));
      expect(healthReport['TestService1']!.isHealthy, isTrue);
    });

    test('应该正确检查所有服务是否已初始化', () async {
      when(mockContainer.getRegisteredServiceNames())
          .thenReturn(['TestService1']);
      when(mockContainer.getServiceByName('TestService1'))
          .thenReturn(mockService1);
      when(mockService1.initialize(any)).thenAnswer((_) async {});

      // 初始化前
      expect(manager.allServicesInitialized(), isFalse);

      await manager.initializeAllServices();

      // 初始化后
      expect(manager.allServicesInitialized(), isTrue);
    });

    test('应该处理部分服务初始化失败', () async {
      when(mockContainer.getRegisteredServiceNames())
          .thenReturn(['TestService1', 'TestService2']);
      when(mockContainer.getServiceByName('TestService1'))
          .thenReturn(mockService1);
      when(mockContainer.getServiceByName('TestService2'))
          .thenReturn(mockService2);

      when(mockService1.initialize(any)).thenAnswer((_) async {});

      when(mockService2.initialize(any)).thenThrow(Exception('初始化失败'));

      final initializedServices = await manager.initializeAllServices();

      expect(initializedServices, contains('TestService1'));
      expect(initializedServices, isNot(contains('TestService2')));

      // 检查错误状态
      expect(manager.getServiceState('TestService2'),
          equals(ServiceLifecycleState.error));
    });
  });

  group('ServiceLifecycleEvent', () {
    test('应该正确创建状态变化事件', () {
      final event = ServiceLifecycleEvent.stateChanged(
        'TestService',
        ServiceLifecycleState.uninitialized,
        ServiceLifecycleState.initialized,
      );

      expect(event.type, equals('state_changed'));
      expect(event.details['service_name'], equals('TestService'));
      expect(event.details['old_state'], equals('uninitialized'));
      expect(event.details['new_state'], equals('initialized'));
    });

    test('应该正确创建成功事件', () {
      final event = ServiceLifecycleEvent.success(
        'test_operation',
        'Test completed successfully',
        details: {'key': 'value'},
      );

      expect(event.type, equals('success'));
      expect(event.message, equals('Test completed successfully'));
      expect(event.details['operation'], equals('test_operation'));
      expect(event.details['key'], equals('value'));
    });

    test('应该正确创建错误事件', () {
      final event = ServiceLifecycleEvent.error(
        'test_operation',
        'Test failed',
        details: {'error_code': 500},
      );

      expect(event.type, equals('error'));
      expect(event.message, equals('Test failed'));
      expect(event.details['operation'], equals('test_operation'));
      expect(event.details['error_code'], equals(500));
    });
  });

  group('ServiceInitializationTimeoutException', () {
    test('应该正确创建超时异常', () {
      final exception = ServiceInitializationTimeoutException(
        'TestService',
        Duration(seconds: 30),
      );

      expect(exception.serviceName, equals('TestService'));
      expect(exception.timeout, equals(Duration(seconds: 30)));
      expect(exception.toString(), contains('TestService'));
      expect(exception.toString(), contains('30秒'));
    });
  });
}
