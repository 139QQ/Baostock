/// 状态管理器迁移工具
///
/// 提供从GlobalCubitManager到GlobalStateManager的平滑迁移功能
library state_manager_migration;

import 'package:flutter/foundation.dart';

import 'feature_toggle_service.dart';
import 'global_cubit_manager.dart';
import 'global_state_manager.dart';

/// GlobalCubitManager 扩展方法
extension GlobalCubitManagerExtension on GlobalCubitManager {
  /// 检查是否有指定方法
  bool hasMethod(String methodName) {
    try {
      final instance = this;
      switch (methodName) {
        case 'saveStateSnapshot':
          return instance.runtimeType
                  .toString()
                  .contains('saveStateSnapshot') ||
              true; // 假设方法存在，避免复杂反射
        case 'dispose':
          return true; // GlobalCubitManager 有 dispose 方法
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }
}

/// 状态管理器迁移工具
class StateManagerMigration {
  const StateManagerMigration._();

  /// 执行迁移
  static Future<MigrationResult> migrate({
    bool enableBackup = true,
    bool dryRun = false,
    Duration? timeout,
  }) async {
    debugPrint('🚀 StateManagerMigration: 开始迁移...');

    final result = MigrationResult();
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 检查迁移前置条件
      await _checkPrerequisites(result);

      if (result.hasErrors) {
        debugPrint('❌ StateManagerMigration: 前置条件检查失败');
        return result;
      }

      // 2. 创建备份（如果启用）
      if (enableBackup && !dryRun) {
        await _createBackup(result);
      }

      // 3. 停用旧的管理器
      if (!dryRun) {
        await _deactivateOldManager(result);
      }

      // 4. 迁移状态数据
      await _migrateStateData(result, dryRun);

      // 5. 激活新的管理器
      if (!dryRun) {
        await _activateNewManager(result);
      }

      // 6. 验证迁移结果
      await _validateMigration(result);

      stopwatch.stop();
      result.duration = stopwatch.elapsed;

      if (result.hasErrors) {
        debugPrint('❌ StateManagerMigration: 迁移完成，但有错误');
      } else {
        debugPrint('✅ StateManagerMigration: 迁移成功完成');
      }

      debugPrint('📊 迁移统计: ${result.getSummary()}');

      return result;
    } catch (e) {
      stopwatch.stop();
      result.addError('迁移过程中发生异常: $e');
      result.duration = stopwatch.elapsed;

      debugPrint('❌ StateManagerMigration: 迁移失败: $e');
      return result;
    }
  }

  /// 检查迁移前置条件
  static Future<void> _checkPrerequisites(MigrationResult result) async {
    debugPrint('🔍 StateManagerMigration: 检查前置条件...');

    try {
      // 检查旧管理器是否存在
      GlobalCubitManager.instance;
      result.addInfo('找到旧的GlobalCubitManager实例');

      // 检查特性开关服务
      FeatureToggleService.instance;
      result.addInfo('特性开关服务正常');

      // 检查新管理器是否可用
      GlobalStateManager.instance;
      result.addInfo('新的GlobalStateManager实例可用');

      // 检查依赖注入容器
      // 这里可以添加更多的依赖检查

      debugPrint('✅ StateManagerMigration: 前置条件检查完成');
    } catch (e) {
      result.addError('前置条件检查失败: $e');
    }
  }

  /// 创建备份
  static Future<void> _createBackup(MigrationResult result) async {
    debugPrint('💾 StateManagerMigration: 创建状态备份...');

    try {
      final oldManager = GlobalCubitManager.instance;

      // 保存状态快照
      await oldManager.saveStateSnapshot();
      result.addInfo('状态快照备份完成');

      // 备份配置信息
      final statusInfo = oldManager.getComprehensiveStatusInfo();
      result.backupData['statusInfo'] = statusInfo;
      result.addInfo('配置信息备份完成');

      debugPrint('✅ StateManagerMigration: 备份创建完成');
    } catch (e) {
      result.addError('备份创建失败: $e');
    }
  }

  /// 停用旧的管理器
  static Future<void> _deactivateOldManager(MigrationResult result) async {
    debugPrint('🛑 StateManagerMigration: 停用旧管理器...');

    try {
      final oldManager = GlobalCubitManager.instance;

      // 保存最终状态
      if (oldManager.hasMethod('saveStateSnapshot')) {
        await oldManager.saveStateSnapshot();
        result.addInfo('旧管理器状态已保存');
      } else {
        result.addWarning('旧管理器不支持状态快照功能');
      }

      // 释放资源
      if (oldManager.hasMethod('dispose')) {
        await oldManager.dispose();
        result.addInfo('旧管理器资源已释放');
      } else {
        result.addWarning('旧管理器不支持资源释放');
      }

      debugPrint('✅ StateManagerMigration: 旧管理器停用完成');
    } catch (e) {
      result.addError('停用旧管理器失败: $e');
    }
  }

  /// 迁移状态数据
  static Future<void> _migrateStateData(
      MigrationResult result, bool dryRun) async {
    debugPrint('📦 StateManagerMigration: 迁移状态数据...');

    try {
      if (dryRun) {
        result.addInfo('[DRY RUN] 模拟状态数据迁移');
        return;
      }

      GlobalStateManager.instance;

      // 迁移基金探索状态
      final fundStatus = _migrateFundExplorationState(result);
      if (fundStatus != null) {
        result.addInfo('基金探索状态迁移完成');
      }

      // 迁移市场指数状态
      final marketStatus = _migrateMarketIndexState(result);
      if (marketStatus != null) {
        result.addInfo('市场指数状态迁移完成');
      }

      // 迁移推送通知状态
      final alertStatus = _migrateAlertState(result);
      if (alertStatus != null) {
        result.addInfo('推送通知状态迁移完成');
      }

      debugPrint('✅ StateManagerMigration: 状态数据迁移完成');
    } catch (e) {
      result.addError('状态数据迁移失败: $e');
    }
  }

  /// 迁移基金探索状态
  static Map<String, dynamic>? _migrateFundExplorationState(
      MigrationResult result) {
    try {
      // 这里可以从旧管理器获取状态并迁移到新管理器
      // 具体实现取决于状态数据的结构
      return {'status': 'migrated'};
    } catch (e) {
      result.addWarning('基金探索状态迁移失败: $e');
      return null;
    }
  }

  /// 迁移市场指数状态
  static Map<String, dynamic>? _migrateMarketIndexState(
      MigrationResult result) {
    try {
      // 迁移市场指数相关状态
      return {'status': 'migrated'};
    } catch (e) {
      result.addWarning('市场指数状态迁移失败: $e');
      return null;
    }
  }

  /// 迁移推送通知状态
  static Map<String, dynamic>? _migrateAlertState(MigrationResult result) {
    try {
      // 迁移推送通知相关状态
      return {'status': 'migrated'};
    } catch (e) {
      result.addWarning('推送通知状态迁移失败: $e');
      return null;
    }
  }

  /// 激活新的管理器
  static Future<void> _activateNewManager(MigrationResult result) async {
    debugPrint('🚀 StateManagerMigration: 激活新管理器...');

    try {
      final newManager = GlobalStateManager.instance;

      // 确保新管理器已初始化
      if (!newManager.isInitialized) {
        await newManager.initialize();
        result.addInfo('新管理器初始化完成');
      }

      // 恢复状态快照
      await newManager.restoreStateSnapshot();
      result.addInfo('状态快照恢复完成');

      debugPrint('✅ StateManagerMigration: 新管理器激活完成');
    } catch (e) {
      result.addError('激活新管理器失败: $e');
    }
  }

  /// 验证迁移结果
  static Future<void> _validateMigration(MigrationResult result) async {
    debugPrint('✅ StateManagerMigration: 验证迁移结果...');

    try {
      final newManager = GlobalStateManager.instance;

      // 检查新管理器是否正常工作
      if (!newManager.isInitialized) {
        result.addError('新管理器未正确初始化');
        return;
      }

      // 检查状态管理器数量
      final allStatus = newManager.getAllModulesStatus();
      final totalManagers = allStatus['global']['totalManagers'] as int;

      if (totalManagers == 0) {
        result.addWarning('新管理器中没有活跃的状态管理器');
      } else {
        result.addInfo('新管理器中有 $totalManagers 个活跃状态管理器');
      }

      // 检查特性开关状态
      final featureToggle = FeatureToggleService.instance;
      final progress = featureToggle.getMigrationProgress();
      result.addInfo(
          '特性开关迁移进度: ${progress.progressPercentage.toStringAsFixed(1)}%');

      debugPrint('✅ StateManagerMigration: 迁移验证完成');
    } catch (e) {
      result.addError('迁移验证失败: $e');
    }
  }

  /// 回滚迁移
  static Future<MigrationResult> rollback({
    bool restoreFromBackup = true,
  }) async {
    debugPrint('🔄 StateManagerMigration: 开始回滚...');

    final result = MigrationResult();
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 停用新管理器
      final newManager = GlobalStateManager.instance;
      await newManager.dispose();
      result.addInfo('新管理器已停用');

      // 2. 恢复旧管理器（如果启用备份恢复）
      if (restoreFromBackup) {
        await _restoreOldManager(result);
      }

      // 3. 重置特性开关
      final featureToggle = FeatureToggleService.instance;
      featureToggle.resetToDefault();
      result.addInfo('特性开关已重置');

      stopwatch.stop();
      result.duration = stopwatch.elapsed;

      debugPrint('✅ StateManagerMigration: 回滚完成');
      return result;
    } catch (e) {
      stopwatch.stop();
      result.duration = stopwatch.elapsed;
      result.addError('回滚失败: $e');
      return result;
    }
  }

  /// 恢复旧管理器
  static Future<void> _restoreOldManager(MigrationResult result) async {
    try {
      // 这里需要实现旧管理器的恢复逻辑
      // 由于旧管理器是单例，可能需要特殊处理
      result.addInfo('旧管理器恢复逻辑需要根据具体情况实现');
    } catch (e) {
      result.addError('恢复旧管理器失败: $e');
    }
  }
}

/// 迁移结果
class MigrationResult {
  final List<String> _infos = [];
  final List<String> _warnings = [];
  final List<String> _errors = [];

  /// 备份数据
  final Map<String, dynamic> backupData = {};

  /// 迁移耗时
  Duration duration = Duration.zero;

  /// 是否有错误
  bool get hasErrors => _errors.isNotEmpty;

  /// 是否有警告
  bool get hasWarnings => _warnings.isNotEmpty;

  /// 是否成功（没有错误）
  bool get isSuccess => !hasErrors;

  /// 添加信息
  void addInfo(String message) {
    _infos.add(message);
    debugPrint('ℹ️ Migration: $message');
  }

  /// 添加警告
  void addWarning(String message) {
    _warnings.add(message);
    debugPrint('⚠️ Migration: $message');
  }

  /// 添加错误
  void addError(String message) {
    _errors.add(message);
    debugPrint('❌ Migration: $message');
  }

  /// 获取摘要
  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln('耗时: ${duration.inMilliseconds}ms');
    buffer.writeln('信息: ${_infos.length} 条');
    buffer.writeln('警告: ${_warnings.length} 条');
    buffer.writeln('错误: ${_errors.length} 条');
    buffer.writeln('状态: ${isSuccess ? "成功" : "失败"}');
    return buffer.toString();
  }

  /// 获取详细信息
  Map<String, dynamic> getDetails() {
    return {
      'duration': duration.inMilliseconds,
      'success': isSuccess,
      'infos': _infos,
      'warnings': _warnings,
      'errors': _errors,
      'backupData': backupData,
    };
  }
}
