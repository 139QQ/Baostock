import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/state/feature_toggle_service.dart';

void main() {
  group('FeatureToggleService Tests', () {
    late FeatureToggleService service;

    setUp(() {
      // 重置服务状态
      service = FeatureToggleService.instance;
      service.resetToDefault();
    });

    tearDown(() {
      // 清理测试状态
      service.resetToDefault();
    });

    test('should initialize with default configuration', () {
      expect(service.config.currentMode, StateManagementMode.cubit);
      expect(service.config.moduleToggles['alerts'], false);
      expect(service.config.moduleToggles['market'], false);
      expect(service.config.moduleToggles['fund'], false);
      expect(service.config.moduleToggles['portfolio'], false);
    });

    test('should use cubit mode by default for all modules', () {
      expect(service.useCubitMode('alerts'), true);
      expect(service.useCubitMode('market'), true);
      expect(service.useCubitMode('fund'), true);
      expect(service.useCubitMode('portfolio'), true);
    });

    test('should not use bloc mode by default', () {
      expect(service.useBlocMode('alerts'), false);
      expect(service.useBlocMode('market'), false);
      expect(service.useBlocMode('fund'), false);
      expect(service.useBlocMode('portfolio'), false);
    });

    test('should toggle module to bloc mode correctly', () {
      service.enableBlocForModule('alerts');

      expect(service.useBlocMode('alerts'), true);
      expect(service.useCubitMode('alerts'), false);
      expect(service.useBlocMode('market'), false); // 其他模块不变
    });

    test('should toggle module back to cubit mode correctly', () {
      service.enableBlocForModule('alerts');
      service.disableBlocForModule('alerts');

      expect(service.useBlocMode('alerts'), false);
      expect(service.useCubitMode('alerts'), true);
    });

    test('should switch global mode correctly', () {
      service.switchMode(StateManagementMode.bloc);

      expect(service.config.currentMode, StateManagementMode.bloc);
      expect(service.useBlocMode('alerts'), true);
      expect(service.useBlocMode('market'), true);
      expect(service.useBlocMode('fund'), true);
      expect(service.useBlocMode('portfolio'), true);
    });

    test('should handle hybrid mode correctly', () {
      service.switchMode(StateManagementMode.hybrid);
      service.enableBlocForModule('alerts');

      expect(service.config.currentMode, StateManagementMode.hybrid);
      expect(service.useBlocMode('alerts'), true);
      expect(service.useCubitMode('market'), true); // 未启用的模块保持Cubit
    });

    test('should calculate migration progress correctly', () {
      expect(service.getMigrationProgress().progressPercentage, 0.0);

      service.enableBlocForModule('alerts');
      var progress = service.getMigrationProgress();
      expect(progress.progressPercentage, 25.0); // 1/4 modules

      service.enableBlocForModule('market');
      progress = service.getMigrationProgress();
      expect(progress.progressPercentage, 50.0); // 2/4 modules

      service.enableBlocForModule('fund');
      progress = service.getMigrationProgress();
      expect(progress.progressPercentage, 75.0); // 3/4 modules

      service.enableBlocForModule('portfolio');
      progress = service.getMigrationProgress();
      expect(progress.progressPercentage, 100.0); // 4/4 modules
    });

    test('should enable batch migration correctly', () {
      service.switchMode(StateManagementMode.hybrid);

      service.enableBatch(0); // alerts
      expect(service.useBlocMode('alerts'), true);
      expect(service.useBlocMode('market'), false);

      service.enableBatch(1); // market
      expect(service.useBlocMode('market'), true);
      expect(service.useBlocMode('fund'), false);
    });

    test('should handle invalid batch index gracefully', () {
      service.switchMode(StateManagementMode.hybrid);

      service.enableBatch(-1); // 应该不崩溃
      service.enableBatch(99); // 应该不崩溃

      expect(service.useBlocMode('alerts'), false);
    });

    test('should export and import configuration correctly', () {
      service.enableBlocForModule('alerts');
      service.switchMode(StateManagementMode.hybrid);

      final exported = service.exportToJson();

      service.resetToDefault();
      expect(service.config.currentMode, StateManagementMode.cubit);
      expect(service.useBlocMode('alerts'), false);

      service.loadFromJson(exported);
      expect(service.config.currentMode, StateManagementMode.hybrid);
      expect(service.useBlocMode('alerts'), true);
    });

    test('should provide migration progress information', () {
      service.enableBlocForModule('alerts');
      service.enableBlocForModule('market');

      final progress = service.getMigrationProgress();
      expect(progress.totalModules, 4);
      expect(progress.enabledModules, 2);
      expect(progress.progressPercentage, 50.0);
      // 启用BLoC模式后，应该自动切换到混合模式
      expect(progress.currentMode, StateManagementMode.hybrid);
    });
  });
}
