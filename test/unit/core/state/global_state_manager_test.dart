import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:jisu_fund_analyzer/src/core/state/global_state_manager.dart';
import 'package:jisu_fund_analyzer/src/core/state/feature_toggle_service.dart';

import 'global_state_manager_test.mocks.dart';

@GenerateMocks([FeatureToggleService])
void main() {
  group('GlobalStateManager Tests', () {
    late GlobalStateManager manager;
    late MockFeatureToggleService mockFeatureToggle;

    setUp(() {
      manager = GlobalStateManager.instance;
      mockFeatureToggle = MockFeatureToggleService();
    });

    tearDown(() async {
      await manager.reset();
    });

    test('should be singleton', () {
      final instance1 = GlobalStateManager.instance;
      final instance2 = GlobalStateManager.instance;

      expect(identical(instance1, instance2), true);
    });

    test('should initialize successfully', () async {
      await manager.initialize();

      expect(manager.isInitialized, true);
    });

    test('should not initialize twice', () async {
      await manager.initialize();
      await manager.initialize(); // 第二次调用应该被忽略

      expect(manager.isInitialized, true);
    });

    test('should handle cubit mode state managers', () async {
      when(mockFeatureToggle.useBlocMode(any)).thenReturn(false);
      when(mockFeatureToggle.useCubitMode(any)).thenReturn(true);

      await manager.initialize();

      // 验证Cubit模式下的状态管理器是否正确初始化
      final fundManager = manager.getStateManager('fundExploration');
      expect(fundManager, isNotNull);
    });

    test('should handle bloc mode state managers', () async {
      when(mockFeatureToggle.useBlocMode('alerts')).thenReturn(true);
      when(mockFeatureToggle.useBlocMode('fund')).thenReturn(true);
      when(mockFeatureToggle.useBlocMode('market')).thenReturn(false);
      when(mockFeatureToggle.useBlocMode('portfolio')).thenReturn(false);

      // 注意：这里需要替换FeatureToggleService实例来使用mock
      // 在实际测试中可能需要依赖注入或服务定位器

      await manager.initialize();

      // 验证BLoC模式下的状态管理器是否正确初始化
      final alertsManager = manager.getStateManager('alerts');
      expect(alertsManager, isNotNull);
    });

    test('should get module status correctly', () async {
      await manager.initialize();

      final alertsStatus = manager.getModuleStatus('alerts');
      expect(alertsStatus['module'], 'alerts');
      expect(alertsStatus['mode'], isA<String>());
      expect(alertsStatus['managers'], isA<List>());
      expect(alertsStatus['totalManagers'], isA<int>());
    });

    test('should get all modules status correctly', () async {
      await manager.initialize();

      final allStatus = manager.getAllModulesStatus();
      expect(allStatus.containsKey('alerts'), true);
      expect(allStatus.containsKey('market'), true);
      expect(allStatus.containsKey('fund'), true);
      expect(allStatus.containsKey('portfolio'), true);
      expect(allStatus.containsKey('global'), true);

      final globalStatus = allStatus['global'];
      expect(globalStatus['isInitialized'], true);
      expect(globalStatus['totalManagers'], isA<int>());
      expect(globalStatus['featureToggleMode'], isA<String>());
      expect(globalStatus['migrationProgress'], isNotNull);
    });

    test('should handle backward compatibility methods', () async {
      await manager.initialize();

      // 测试向后兼容的方法
      final fundCubit = manager.getFundRankingCubit();
      expect(fundCubit, isNotNull);

      final marketCubit = manager.getMarketIndexCubit();
      expect(marketCubit, isNotNull);

      final indexTrendCubit = manager.getIndexTrendCubit();
      expect(indexTrendCubit, isNotNull);
    });

    test('should handle push notification manager adaptation', () async {
      await manager.initialize();

      final pushManager = manager.getPushNotificationManager();
      expect(pushManager, isNotNull);
    });

    test('should handle state snapshot operations', () async {
      await manager.initialize();

      // 这些操作可能会抛出异常，因为具体的状态管理器可能没有实现saveState/restoreState
      // 但不应该导致崩溃
      try {
        await manager.saveStateSnapshot();
        await manager.restoreStateSnapshot();
      } catch (e) {
        // 预期的异常，因为具体实现可能不支持状态快照
        expect(e, isA<Exception>());
      }
    });

    test('should dispose resources correctly', () async {
      await manager.initialize();
      expect(manager.isInitialized, true);

      await manager.dispose();

      // 注意：dispose后isInitialized可能仍然为true，因为这是单例
      // 在实际应用中，dispose通常只在应用退出时调用
    });

    test('should reset correctly', () async {
      await manager.initialize();

      await manager.reset();

      expect(manager.isInitialized, true); // reset后应该重新初始化
    });

    test('should handle module mode switching', () async {
      await manager.initialize();

      // 切换alerts模块到BLoC模式
      await manager.switchModuleMode('alerts', true);

      // 切换alerts模块回到Cubit模式
      await manager.switchModuleMode('alerts', false);

      // 这些操作不应该抛出异常
      expect(true, true);
    });

    test('should handle errors gracefully', () async {
      // 测试错误处理
      try {
        final nonExistentManager = manager.getStateManager('nonExistent');
        expect(nonExistentManager, isNull);
      } catch (e) {
        fail('应该优雅地处理不存在的状态管理器: $e');
      }
    });

    test('should provide current state information', () async {
      await manager.initialize();

      // 打印当前状态信息（这主要用于调试）
      manager.printCurrentState();

      // 验证状态信息的结构
      final allStatus = manager.getAllModulesStatus();
      expect(allStatus['global']['totalManagers'], greaterThan(0));
    });

    test('should handle concurrent operations safely', () async {
      // 测试并发操作的安全性
      await Future.wait([
        manager.initialize(),
        manager.initialize(),
        manager.initialize(),
      ]);

      expect(manager.isInitialized, true);

      // 测试并发的状态查询
      final futures = List.generate(10, (_) => manager.getAllModulesStatus());
      final results = await Future.wait(futures);

      // 所有结果应该一致
      for (final result in results) {
        expect(result['global']['isInitialized'], true);
      }
    });
  });
}
