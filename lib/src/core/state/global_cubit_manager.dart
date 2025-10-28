import 'package:flutter/material.dart';
import '../../features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import '../../core/di/injection_container.dart';

/// 全局Cubit管理器
///
/// 负责管理应用中所有Cubit实例的生命周期，确保状态在页面切换时保持不变
/// 现在使用统一的FundExplorationCubit
class GlobalCubitManager {
  static GlobalCubitManager? _instance;
  static GlobalCubitManager get instance {
    _instance ??= GlobalCubitManager._();
    return _instance!;
  }

  GlobalCubitManager._();

  /// 获取或创建基金探索Cubit
  FundExplorationCubit getFundRankingCubit() {
    debugPrint('🔄 GlobalCubitManager: 获取统一的FundExplorationCubit实例');
    return sl<FundExplorationCubit>();
  }

  /// 重置基金探索Cubit（用于应用重启或完全刷新）
  void resetFundRankingCubit() {
    debugPrint('🔄 GlobalCubitManager: 重置基金探索Cubit');
    // 注意：由于使用了依赖注入，这里不做close操作
    // 让依赖注入容器管理实例生命周期
  }

  /// 获取基金探索状态信息
  String getFundRankingStatusInfo() {
    try {
      final cubit = sl<FundExplorationCubit>();
      final state = cubit.state;
      return '状态: ${state.status}, 数据量: ${state.fundRankings.length}, 加载中: ${state.isLoading}, 错误: "${state.errorMessage ?? "无"}"';
    } catch (e) {
      return '获取状态失败: $e';
    }
  }

  /// 释放所有资源
  void dispose() {
    debugPrint('🗑️ GlobalCubitManager: 释放资源管理器');
    // 依赖注入容器负责资源释放
  }
}
