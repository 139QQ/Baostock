import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/core/state/unified_bloc_factory.dart';
import 'package:jisu_fund_analyzer/src/core/state/bloc_factory_initializer.dart';
import 'package:jisu_fund_analyzer/src/core/state/feature_toggle_service.dart';

void main() {
  group('UnifiedBlocFactory Tests', () {
    late UnifiedBlocFactory factory;
    late FeatureToggleService featureToggle;

    setUpAll(() {
      // 初始化BLoC工厂注册表
      BlocFactoryInitializer.initialize();
    });

    setUp(() {
      factory = UnifiedBlocFactory.instance;
      featureToggle = FeatureToggleService.instance;
      featureToggle.resetToDefault();
    });

    tearDown(() async {
      await factory.releaseAll();
      featureToggle.resetToDefault();
    });

    test('should be singleton', () {
      final instance1 = UnifiedBlocFactory.instance;
      final instance2 = UnifiedBlocFactory.instance;

      expect(identical(instance1, instance2), true);
    });

    test('should throw error when feature toggle is disabled', () {
      // 确保alerts模块的BLoC模式是禁用的
      featureToggle.disableBlocForModule('alerts');

      expect(
        () => factory.getBloc<BlocBase>(BlocType.cache),
        throwsA(isA<StateError>()),
      );
    });

    test('should create bloc when feature toggle is enabled', () {
      // 启用alerts模块的BLoC模式
      featureToggle.enableBlocForModule('alerts');

      expect(
        () => factory.getBloc<BlocBase>(BlocType.cache),
        returnsNormally,
      );
    });

    test('should manage singleton instances correctly', () {
      featureToggle.enableBlocForModule('alerts');

      final bloc1 = factory.getBloc<BlocBase>(BlocType.cache);
      final bloc2 = factory.getBloc<BlocBase>(BlocType.cache);

      expect(identical(bloc1, bloc2), true);
    });

    test('should create new instance when forceNewInstance is true', () {
      featureToggle.enableBlocForModule('alerts');

      final bloc1 = factory.getBloc<BlocBase>(BlocType.cache);
      final bloc2 =
          factory.getBloc<BlocBase>(BlocType.cache, forceNewInstance: true);

      expect(identical(bloc1, bloc2), false);
    });

    test('should handle custom instance names', () {
      featureToggle.enableBlocForModule('alerts');

      final bloc1 =
          factory.getBloc<BlocBase>(BlocType.cache, customName: 'customCache');
      final bloc2 =
          factory.getBloc<BlocBase>(BlocType.cache, customName: 'customCache');

      expect(identical(bloc1, bloc2), true);
    });

    test('should track instance counts correctly', () {
      featureToggle.enableBlocForModule('alerts');

      final bloc = factory.getBloc<BlocBase>(BlocType.cache);
      expect(factory.hasInstance('cache'), true);

      final stats = factory.getStatistics();
      expect(stats['totalInstances'], greaterThan(0));
      expect(stats['instanceCounts'], isA<Map>());
      expect(stats['instanceTypes'], isA<Map>());
    });

    test('should release instances correctly', () async {
      featureToggle.enableBlocForModule('alerts');

      final bloc = factory.getBloc<BlocBase>(BlocType.cache);
      expect(factory.hasInstance('cache'), true);

      await factory.releaseBloc('cache');
      expect(factory.hasInstance('cache'), false);
    });

    test('should handle reference counting correctly', () async {
      featureToggle.enableBlocForModule('alerts');

      final bloc1 = factory.getBloc<BlocBase>(BlocType.cache);
      final bloc2 = factory.getBloc<BlocBase>(BlocType.cache); // 增加引用计数

      expect(factory.hasInstance('cache'), true);

      await factory.releaseBloc('cache');
      expect(factory.hasInstance('cache'), true); // 仍然有引用

      await factory.releaseBloc('cache');
      expect(factory.hasInstance('cache'), false); // 引用计数为0，被释放
    });

    test('should release all instances correctly', () async {
      featureToggle.enableBlocForModule('alerts');
      featureToggle.enableBlocForModule('fund');

      final cacheBloc = factory.getBloc<BlocBase>(BlocType.cache);
      final fundSearchBloc = factory.getBloc<BlocBase>(BlocType.fundSearch);

      expect(factory.hasInstance('cache'), true);
      expect(factory.hasInstance('fundSearch'), true);

      await factory.releaseAll();

      expect(factory.hasInstance('cache'), false);
      expect(factory.hasInstance('fundSearch'), false);
    });

    test('should handle non-existent instance gracefully', () async {
      await factory.releaseBloc('nonExistent'); // 不应该抛出异常
      expect(factory.hasInstance('nonExistent'), false);
    });

    test('should get existing instance without creating new one', () {
      featureToggle.enableBlocForModule('alerts');

      final bloc1 = factory.getBloc<BlocBase>(BlocType.cache);
      final bloc2 = factory.getInstance<BlocBase>('cache');

      expect(identical(bloc1, bloc2), true);

      final nonExistent = factory.getInstance<BlocBase>('nonExistent');
      expect(nonExistent, isNull);
    });

    test('should provide current state information', () {
      featureToggle.enableBlocForModule('alerts');

      final bloc = factory.getBloc<BlocBase>(BlocType.cache);

      factory.printCurrentState();

      final stats = factory.getStatistics();
      expect(stats['totalInstances'], greaterThan(0));
    });

    test('should handle concurrent operations safely', () async {
      featureToggle.enableBlocForModule('alerts');

      // 测试并发创建
      final futures =
          List.generate(10, (_) => factory.getBloc<BlocBase>(BlocType.cache));
      final blocs = await Future.wait(futures);

      // 所有实例应该是同一个（单例）
      for (final bloc in blocs) {
        expect(identical(bloc, blocs.first), true);
      }

      // 测试并发释放
      final releaseFutures =
          List.generate(10, (_) => factory.releaseBloc('cache'));
      await Future.wait(releaseFutures);

      expect(factory.hasInstance('cache'), false);
    });

    test('should handle different bloc types correctly', () {
      // 测试所有注册的BLoC类型
      final blocTypes = [
        BlocType.fundSearch,
        BlocType.portfolio,
        BlocType.fundDetail,
        BlocType.auth,
        BlocType.filter,
        BlocType.search,
        BlocType.cache,
        BlocType.fund,
      ];

      for (final type in blocTypes) {
        try {
          final bloc = factory.getBloc<BlocBase>(type, forceNewInstance: true);
          expect(bloc, isA<BlocBase>());
        } catch (e) {
          // 某些BLoC类型可能需要特定的特性开关配置
          expect(e, isA<StateError>());
        }
      }
    });
  });

  group('BlocFactoryRegistry Tests', () {
    setUp(() {
      BlocFactoryRegistry.clearAll();
    });

    tearDown(() {
      BlocFactoryRegistry.clearAll();
    });

    test('should register and retrieve factories correctly', () {
      final mockFactory = MockBlocFactory();

      BlocFactoryRegistry.registerFactory(BlocType.cache, mockFactory);

      final retrievedFactory = BlocFactoryRegistry.getFactory(BlocType.cache);
      expect(retrievedFactory, equals(mockFactory));
    });

    test('should return null for unregistered factory', () {
      final factory = BlocFactoryRegistry.getFactory(BlocType.cache);
      expect(factory, isNull);
    });

    test('should get all registered factories', () {
      final mockFactory1 = MockBlocFactory();
      final mockFactory2 = MockBlocFactory();

      BlocFactoryRegistry.registerFactory(BlocType.cache, mockFactory1);
      BlocFactoryRegistry.registerFactory(BlocType.fund, mockFactory2);

      final allFactories = BlocFactoryRegistry.getAllFactories();
      expect(allFactories.length, 2);
      expect(allFactories[BlocType.cache], equals(mockFactory1));
      expect(allFactories[BlocType.fund], equals(mockFactory2));
    });

    test('should clear all factories correctly', () {
      final mockFactory = MockBlocFactory();
      BlocFactoryRegistry.registerFactory(BlocType.cache, mockFactory);

      expect(BlocFactoryRegistry.getAllFactories().length, 1);

      BlocFactoryRegistry.clearAll();

      expect(BlocFactoryRegistry.getAllFactories().length, 0);
    });
  });
}

// Mock classes for testing
class MockBlocFactory implements BlocFactory<BlocBase> {
  @override
  String get blocName => 'MockBloc';

  @override
  BlocType get blocType => BlocType.cache;

  @override
  BlocBase create(BlocCreationConfig config) {
    return MockBloc();
  }
}

class MockBloc extends BlocBase {
  MockBloc() : super(MockInitialState());

  @override
  MockInitialState get currentState => MockInitialState();
}

class MockInitialState {
  MockInitialState();
}
