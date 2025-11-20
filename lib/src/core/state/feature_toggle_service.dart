/// 特性开关服务
///
/// 用于管理状态管理统一化过程中的特性开关，支持渐进式迁移
library feature_toggle_service;

import 'package:flutter/foundation.dart';

/// 状态管理模式枚举
enum StateManagementMode {
  /// Cubit模式（当前）
  cubit,

  /// BLoC模式（目标）
  bloc,

  /// 混合模式（渐进迁移）
  hybrid,
}

/// 特性开关配置
class FeatureToggleConfig {
  /// 当前状态管理模式
  final StateManagementMode currentMode;

  /// 各模块的特性开关状态
  final Map<String, bool> moduleToggles;

  /// 是否启用调试日志
  final bool enableDebugLogs;

  /// 迁移批次配置
  final List<String> migrationBatches;

  const FeatureToggleConfig({
    required this.currentMode,
    required this.moduleToggles,
    this.enableDebugLogs = kDebugMode,
    this.migrationBatches = const [
      'alerts',
      'market',
      'fund',
      'portfolio',
    ],
  });

  /// 默认配置（全部使用Cubit模式）
  factory FeatureToggleConfig.defaultConfig() {
    return const FeatureToggleConfig(
      currentMode: StateManagementMode.cubit,
      moduleToggles: {
        'alerts': false,
        'market': false,
        'fund': false,
        'portfolio': false,
      },
    );
  }

  /// 从JSON创建配置
  factory FeatureToggleConfig.fromJson(Map<String, dynamic> json) {
    return FeatureToggleConfig(
      currentMode: StateManagementMode.values.firstWhere(
        (mode) => mode.name == json['currentMode'],
        orElse: () => StateManagementMode.cubit,
      ),
      moduleToggles: Map<String, bool>.from(json['moduleToggles'] ?? {}),
      enableDebugLogs: json['enableDebugLogs'] ?? kDebugMode,
      migrationBatches: List<String>.from(json['migrationBatches'] ?? []),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'currentMode': currentMode.name,
      'moduleToggles': moduleToggles,
      'enableDebugLogs': enableDebugLogs,
      'migrationBatches': migrationBatches,
    };
  }

  /// 创建副本并修改指定字段
  FeatureToggleConfig copyWith({
    StateManagementMode? currentMode,
    Map<String, bool>? moduleToggles,
    bool? enableDebugLogs,
    List<String>? migrationBatches,
  }) {
    return FeatureToggleConfig(
      currentMode: currentMode ?? this.currentMode,
      moduleToggles: moduleToggles ?? this.moduleToggles,
      enableDebugLogs: enableDebugLogs ?? this.enableDebugLogs,
      migrationBatches: migrationBatches ?? this.migrationBatches,
    );
  }
}

/// 特性开关服务
class FeatureToggleService {
  static FeatureToggleService? _instance;
  static FeatureToggleService get instance =>
      _instance ??= FeatureToggleService._();

  FeatureToggleService._();

  FeatureToggleConfig _config = FeatureToggleConfig.defaultConfig();

  /// 当前配置
  FeatureToggleConfig get config => _config;

  /// 获取指定模块是否使用BLoC模式
  bool useBlocMode(String moduleName) {
    switch (_config.currentMode) {
      case StateManagementMode.bloc:
        return true;
      case StateManagementMode.cubit:
        return false;
      case StateManagementMode.hybrid:
        return _config.moduleToggles[moduleName] ?? false;
    }
  }

  /// 获取指定模块是否使用Cubit模式
  bool useCubitMode(String moduleName) {
    return !useBlocMode(moduleName);
  }

  /// 切换指定模块的特性开关
  void toggleModule(String moduleName, bool enableBloc) {
    final updatedToggles = Map<String, bool>.from(_config.moduleToggles);
    updatedToggles[moduleName] = enableBloc;

    _config = _config.copyWith(moduleToggles: updatedToggles);

    if (_config.enableDebugLogs) {
      debugPrint(
          '🔄 FeatureToggle: 模块 $moduleName 现在使用${enableBloc ? "BLoC" : "Cubit"}模式');
    }
  }

  /// 切换全局状态管理模式
  void switchMode(StateManagementMode mode) {
    final previousMode = _config.currentMode;
    _config = _config.copyWith(currentMode: mode);

    if (_config.enableDebugLogs) {
      debugPrint('🔄 FeatureToggle: 状态管理模式从 $previousMode 切换到 $mode');
    }
  }

  /// 启用指定模块的BLoC模式
  void enableBlocForModule(String moduleName) {
    // 如果当前是Cubit模式，自动切换到混合模式
    if (_config.currentMode == StateManagementMode.cubit) {
      switchMode(StateManagementMode.hybrid);
    }
    toggleModule(moduleName, true);
  }

  /// 禁用指定模块的BLoC模式（回到Cubit）
  void disableBlocForModule(String moduleName) {
    toggleModule(moduleName, false);
  }

  /// 批量启用BLoC模式（按批次）
  void enableBatch(int batchIndex) {
    if (batchIndex < 0 || batchIndex >= _config.migrationBatches.length) {
      debugPrint('❌ FeatureToggle: 无效的批次索引 $batchIndex');
      return;
    }

    if (_config.currentMode != StateManagementMode.hybrid) {
      switchMode(StateManagementMode.hybrid);
    }

    final batch = _config.migrationBatches[batchIndex];
    enableBlocForModule(batch);

    if (_config.enableDebugLogs) {
      debugPrint('✅ FeatureToggle: 已启用批次 $batchIndex ($batch) 的BLoC模式');
    }
  }

  /// 获取当前迁移进度
  MigrationProgress getMigrationProgress() {
    final totalModules = _config.moduleToggles.length;
    final enabledModules =
        _config.moduleToggles.values.where((enabled) => enabled).length;

    return MigrationProgress(
      totalModules: totalModules,
      enabledModules: enabledModules,
      progressPercentage:
          totalModules > 0 ? (enabledModules / totalModules) * 100 : 0,
      currentMode: _config.currentMode,
    );
  }

  /// 重置为默认配置
  void resetToDefault() {
    _config = FeatureToggleConfig.defaultConfig();

    if (_config.enableDebugLogs) {
      debugPrint('🔄 FeatureToggle: 已重置为默认配置');
    }
  }

  /// 从JSON加载配置
  void loadFromJson(Map<String, dynamic> json) {
    _config = FeatureToggleConfig.fromJson(json);

    if (_config.enableDebugLogs) {
      debugPrint('✅ FeatureToggle: 已从JSON加载配置');
    }
  }

  /// 导出当前配置为JSON
  Map<String, dynamic> exportToJson() {
    return _config.toJson();
  }

  /// 打印当前状态
  void printCurrentState() {
    if (!_config.enableDebugLogs) return;

    final progress = getMigrationProgress();
    debugPrint('📊 FeatureToggle 当前状态:');
    debugPrint('  模式: ${_config.currentMode.name}');
    debugPrint('  迁移进度: ${progress.progressPercentage.toStringAsFixed(1)}%');
    debugPrint('  已启用模块: ${progress.enabledModules}/${progress.totalModules}');
    debugPrint('  模块开关状态:');
    _config.moduleToggles.forEach((module, enabled) {
      debugPrint('    $module: ${enabled ? "BLoC" : "Cubit"}');
    });
  }
}

/// 迁移进度信息
class MigrationProgress {
  final int totalModules;
  final int enabledModules;
  final double progressPercentage;
  final StateManagementMode currentMode;

  const MigrationProgress({
    required this.totalModules,
    required this.enabledModules,
    required this.progressPercentage,
    required this.currentMode,
  });

  @override
  String toString() {
    return 'MigrationProgress(${progressPercentage.toStringAsFixed(1)}% - $enabledModules/$totalModules modules, mode: $currentMode)';
  }
}
