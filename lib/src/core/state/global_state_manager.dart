/// 全局状态管理器
///
/// 重构后的GlobalCubitManager，职责更加专一：
/// 1. 协调各模块的状态管理器
/// 2. 提供全局状态持久化功能
/// 3. 支持Feature Toggle切换
/// 4. 简化依赖关系和生命周期管理
library global_state_manager;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../di/di_initializer.dart' as di;
import 'feature_toggle_service.dart';
import 'unified_bloc_factory.dart';
import '../../features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import '../../features/fund/presentation/cubits/fund_nav_cubit.dart';
import '../../features/fund/presentation/cubits/realtime_data_cubit.dart';
// import '../../features/fund/presentation/cubits/fund_favorite_cubit.dart'; // 暂时注释
import '../../features/fund/presentation/cubit/fund_comparison_cubit.dart';
import '../../features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import '../../features/portfolio/presentation/cubit/fund_favorite_cubit.dart';
import '../../features/market/presentation/cubits/market_index_cubit.dart';
import '../../features/market/presentation/cubits/index_trend_cubit.dart';
import '../../features/alerts/presentation/cubits/push_notification_cubit.dart';
import '../../bloc/fund_search_bloc.dart';
import '../../bloc/fund_detail_bloc.dart';

/// 全局状态管理器
class GlobalStateManager {
  /// 私有构造函数，实现单例模式
  GlobalStateManager._();

  static GlobalStateManager? _instance;

  /// 获取全局状态管理器的单例实例
  static GlobalStateManager get instance {
    _instance ??= GlobalStateManager._();
    return _instance!;
  }

  /// 特性开关服务
  final FeatureToggleService _featureToggle = FeatureToggleService.instance;

  /// BLoC工厂
  final UnifiedBlocFactory _blocFactory = UnifiedBlocFactory.instance;

  /// 活跃的状态管理器实例
  final Map<String, dynamic> _activeManagers = {};

  /// 是否已初始化
  bool _isInitialized = false;

  /// 公开的初始化状态检查
  bool get isInitialized => _isInitialized;

  /// 初始化全局状态管理器
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔄 GlobalStateManager: 已经初始化');
      return;
    }

    try {
      debugPrint('🚀 GlobalStateManager: 开始初始化...');

      // 根据特性开关初始化相应的状态管理器
      await _initializeStateManagers();

      _isInitialized = true;
      debugPrint('✅ GlobalStateManager: 初始化完成');
    } catch (e) {
      debugPrint('❌ GlobalStateManager: 初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化各模块的状态管理器
  Future<void> _initializeStateManagers() async {
    final modules = ['alerts', 'market', 'fund', 'portfolio'];

    for (final module in modules) {
      try {
        if (_featureToggle.useBlocMode(module)) {
          await _initializeBlocManager(module);
        } else {
          await _initializeCubitManager(module);
        }
        debugPrint('✅ GlobalStateManager: $module 模块初始化完成');
      } catch (e) {
        debugPrint('⚠️ GlobalStateManager: $module 模块初始化失败: $e');
        // 继续初始化其他模块
      }
    }
  }

  /// 初始化BLoC模式的状态管理器
  Future<void> _initializeBlocManager(String module) async {
    switch (module) {
      case 'alerts':
        // alerts模块使用PushNotificationBloc - 暂时跳过BLoC模式
        await _initializeCubitManager(module);
        break;
      case 'market':
        // market模块保持现有Cubit（暂不转换）
        await _initializeCubitManager(module);
        break;
      case 'fund':
        // fund模块混合使用BLoC和Cubit
        await _initializeFundManagers();
        break;
      case 'portfolio':
        // portfolio模块保持现有Cubit（暂不转换）
        await _initializeCubitManager(module);
        break;
    }
  }

  /// 初始化Cubit模式的状态管理器
  Future<void> _initializeCubitManager(String module) async {
    final getIt = di.sl;

    switch (module) {
      case 'alerts':
        _activeManagers['alerts'] = getIt<PushNotificationCubit>();
        break;
      case 'market':
        _activeManagers['market'] = getIt<MarketIndexCubit>();
        _activeManagers['indexTrend'] = getIt<IndexTrendCubit>();
        break;
      case 'fund':
        _activeManagers['fundExploration'] = getIt<FundExplorationCubit>();
        _activeManagers['fundNav'] = getIt<FundNavCubit>();
        _activeManagers['realtimeData'] = getIt<RealtimeDataCubit>();
        break;
      case 'portfolio':
        _activeManagers['portfolioAnalysis'] = getIt<PortfolioAnalysisCubit>();
        _activeManagers['fundFavorite'] = getIt<FundFavoriteCubit>();
        break;
    }
  }

  /// 初始化基金相关的状态管理器（混合模式）
  Future<void> _initializeFundManagers() async {
    final getIt = di.sl;

    // 保持现有Cubit
    _activeManagers['fundExploration'] = getIt<FundExplorationCubit>();
    _activeManagers['fundNav'] = getIt<FundNavCubit>();
    _activeManagers['realtimeData'] = getIt<RealtimeDataCubit>();

    // 添加新的BLoC（如果启用）- 暂时跳过BLoC模式
    if (_featureToggle.useBlocMode('fund')) {
      // TODO: 实现BLoC模式，暂时使用现有Cubit
      // final fundSearchBloc = _blocFactory.getBloc<FundSearchBloc>(BlocType.fundSearch);
      // final fundDetailBloc = _blocFactory.getBloc<FundDetailBloc>(BlocType.fundDetail);
      // _activeManagers['fundSearch'] = fundSearchBloc;
      // _activeManagers['fundDetail'] = fundDetailBloc;
    }
  }

  /// 获取指定模块的状态管理器
  T? getStateManager<T>(String key) {
    final manager = _activeManagers[key];
    if (manager == null) {
      debugPrint('⚠️ GlobalStateManager: 未找到状态管理器 $key');
      return null;
    }
    return manager as T?;
  }

  /// 获取基金探索Cubit（保持向后兼容）
  FundExplorationCubit? getFundRankingCubit() {
    return getStateManager<FundExplorationCubit>('fundExploration');
  }

  /// 获取市场指数Cubit（保持向后兼容）
  MarketIndexCubit? getMarketIndexCubit() {
    return getStateManager<MarketIndexCubit>('market');
  }

  /// 获取指数趋势Cubit（保持向后兼容）
  IndexTrendCubit? getIndexTrendCubit() {
    return getStateManager<IndexTrendCubit>('indexTrend');
  }

  /// 获取推送通知状态管理器（适配Feature Toggle）
  dynamic getPushNotificationManager() {
    final useBloc = _featureToggle.useBlocMode('alerts');
    return useBloc
        ? getStateManager('alerts') // BLoC
        : getStateManager<PushNotificationCubit>('alerts'); // Cubit
  }

  /// 切换模块的状态管理模式
  Future<void> switchModuleMode(String module, bool useBlocMode) async {
    debugPrint(
        '🔄 GlobalStateManager: 切换 $module 模块到 ${useBlocMode ? "BLoC" : "Cubit"} 模式');

    try {
      // 1. 停用当前的状态管理器
      await _deactivateManager(module);

      // 2. 更新特性开关
      if (useBlocMode) {
        _featureToggle.enableBlocForModule(module);
      } else {
        _featureToggle.disableBlocForModule(module);
      }

      // 3. 重新初始化该模块
      if (useBlocMode) {
        await _initializeBlocManager(module);
      } else {
        await _initializeCubitManager(module);
      }

      debugPrint('✅ GlobalStateManager: $module 模块切换完成');
    } catch (e) {
      debugPrint('❌ GlobalStateManager: $module 模块切换失败: $e');
      rethrow;
    }
  }

  /// 停用指定模块的状态管理器
  Future<void> _deactivateManager(String module) async {
    final keysToRemove =
        _activeManagers.keys.where((key) => key.startsWith(module)).toList();

    for (final key in keysToRemove) {
      final manager = _activeManagers[key];
      if (manager is BlocBase) {
        await manager.close();
        debugPrint('🗑️ GlobalStateManager: 已关闭状态管理器 $key');
      }
      _activeManagers.remove(key);
    }
  }

  /// 获取模块状态信息
  Map<String, dynamic> getModuleStatus(String module) {
    final moduleManagers = _activeManagers.entries
        .where((entry) => entry.key.startsWith(module))
        .toList();

    return {
      'module': module,
      'mode': _featureToggle.useBlocMode(module) ? 'BLoC' : 'Cubit',
      'managers': moduleManagers
          .map((entry) => {
                'key': entry.key,
                'type': entry.value.runtimeType.toString(),
                'isActive': entry.value is BlocBase
                    ? !(entry.value as BlocBase).isClosed
                    : true,
              })
          .toList(),
      'totalManagers': moduleManagers.length,
    };
  }

  /// 获取所有模块状态信息
  Map<String, dynamic> getAllModulesStatus() {
    final modules = ['alerts', 'market', 'fund', 'portfolio'];
    final status = <String, dynamic>{};

    for (final module in modules) {
      status[module] = getModuleStatus(module);
    }

    status['global'] = {
      'isInitialized': _isInitialized,
      'totalManagers': _activeManagers.length,
      'featureToggleMode': _featureToggle.config.currentMode.name,
      'migrationProgress': _featureToggle.getMigrationProgress(),
    };

    return status;
  }

  /// 保存状态快照（用于状态恢复）
  Future<void> saveStateSnapshot() async {
    debugPrint('💾 GlobalStateManager: 保存状态快照...');

    try {
      for (final entry in _activeManagers.entries) {
        final manager = entry.value;
        if (manager is dynamic && manager.saveState != null) {
          try {
            await manager.saveState();
            debugPrint('✅ 已保存 ${entry.key} 状态');
          } catch (e) {
            debugPrint('⚠️ 保存 ${entry.key} 状态失败: $e');
          }
        }
      }
      debugPrint('✅ GlobalStateManager: 状态快照保存完成');
    } catch (e) {
      debugPrint('❌ GlobalStateManager: 状态快照保存失败: $e');
    }
  }

  /// 恢复状态快照
  Future<void> restoreStateSnapshot() async {
    debugPrint('🔄 GlobalStateManager: 恢复状态快照...');

    try {
      for (final entry in _activeManagers.entries) {
        final manager = entry.value;
        if (manager is dynamic && manager.restoreState != null) {
          try {
            await manager.restoreState();
            debugPrint('✅ 已恢复 ${entry.key} 状态');
          } catch (e) {
            debugPrint('⚠️ 恢复 ${entry.key} 状态失败: $e');
          }
        }
      }
      debugPrint('✅ GlobalStateManager: 状态快照恢复完成');
    } catch (e) {
      debugPrint('❌ GlobalStateManager: 状态快照恢复失败: $e');
    }
  }

  /// 释放所有资源
  Future<void> dispose() async {
    debugPrint('🗑️ GlobalStateManager: 释放资源...');

    try {
      // 保存最终状态
      await saveStateSnapshot();

      // 释放所有状态管理器
      for (final entry in _activeManagers.entries) {
        final manager = entry.value;
        if (manager is BlocBase) {
          await manager.close();
          debugPrint('🗑️ 已释放 ${entry.key}');
        }
      }

      // 释放BLoC工厂实例
      await _blocFactory.releaseAll();

      _activeManagers.clear();
      _isInitialized = false;

      debugPrint('✅ GlobalStateManager: 资源释放完成');
    } catch (e) {
      debugPrint('❌ GlobalStateManager: 资源释放失败: $e');
    }
  }

  /// 重置全局状态管理器
  Future<void> reset() async {
    debugPrint('🔄 GlobalStateManager: 重置...');

    await dispose();

    // 重置特性开关
    _featureToggle.resetToDefault();

    // 重新初始化
    await initialize();

    debugPrint('✅ GlobalStateManager: 重置完成');
  }

  /// 打印当前状态信息
  void printCurrentState() {
    debugPrint('📊 GlobalStateManager 当前状态:');
    debugPrint('  初始化状态: $_isInitialized');
    debugPrint('  活跃管理器数量: ${_activeManagers.length}');
    debugPrint('  特性开关模式: ${_featureToggle.config.currentMode.name}');

    final progress = _featureToggle.getMigrationProgress();
    debugPrint('  迁移进度: ${progress.progressPercentage.toStringAsFixed(1)}%');

    debugPrint('  活跃管理器:');
    _activeManagers.forEach((key, value) {
      final type = value.runtimeType.toString();
      final isClosed = value is BlocBase ? value.isClosed : false;
      debugPrint('    $key: $type (${isClosed ? "已关闭" : "活跃"})');
    });
  }
}
