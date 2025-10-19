import 'package:flutter/material.dart';
import '../../features/fund/presentation/fund_exploration/presentation/cubit/fund_ranking_cubit_simple.dart';

/// 全局Cubit管理器
///
/// 负责管理应用中所有Cubit实例的生命周期，确保状态在页面切换时保持不变
class GlobalCubitManager {
  static GlobalCubitManager? _instance;
  static GlobalCubitManager get instance {
    _instance ??= GlobalCubitManager._();
    return _instance!;
  }

  GlobalCubitManager._();

  /// 基金排行Cubit实例
  SimpleFundRankingCubit? _fundRankingCubit;

  /// 获取或创建基金排行Cubit
  SimpleFundRankingCubit getFundRankingCubit() {
    if (_fundRankingCubit == null || _fundRankingCubit!.isClosed) {
      debugPrint('🔄 GlobalCubitManager: 创建新的SimpleFundRankingCubit实例');
      _fundRankingCubit = SimpleFundRankingCubit();
    } else {
      debugPrint('✅ GlobalCubitManager: 复用现有的SimpleFundRankingCubit实例，状态保持');
      debugPrint('📊 当前状态数据量: ${_fundRankingCubit!.state.rankings.length}条记录');
      debugPrint('📊 当前加载状态: ${_fundRankingCubit!.state.isLoading}');
      debugPrint('📊 当前错误信息: "${_fundRankingCubit!.state.error}"');
    }
    return _fundRankingCubit!;
  }

  /// 重置基金排行Cubit（用于应用重启或完全刷新）
  void resetFundRankingCubit() {
    if (_fundRankingCubit != null && !_fundRankingCubit!.isClosed) {
      debugPrint('🔄 GlobalCubitManager: 关闭旧的SimpleFundRankingCubit实例');
      _fundRankingCubit!.close();
    }
    _fundRankingCubit = null;
    debugPrint('✅ GlobalCubitManager: 已重置SimpleFundRankingCubit');
  }

  /// 清理所有Cubit资源
  void dispose() {
    if (_fundRankingCubit != null && !_fundRankingCubit!.isClosed) {
      debugPrint('🔄 GlobalCubitManager: 清理SimpleFundRankingCubit资源');
      _fundRankingCubit!.close();
      _fundRankingCubit = null;
    }
  }

  /// 检查基金排行Cubit状态
  bool get isFundRankingCubitActive {
    return _fundRankingCubit != null && !_fundRankingCubit!.isClosed;
  }

  /// 获取当前基金排行状态信息
  String getFundRankingStatusInfo() {
    if (!isFundRankingCubitActive) {
      return 'Cubit未初始化或已关闭';
    }

    final state = _fundRankingCubit!.state;
    return '数据量: ${state.rankings.length}条, 加载中: ${state.isLoading}, 有错误: ${state.error.isNotEmpty}, 有更多数据: ${state.hasMoreData}';
  }
}