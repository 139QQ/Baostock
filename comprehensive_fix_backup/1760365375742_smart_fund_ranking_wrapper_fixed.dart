import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'fund_ranking_section_fixed.dart';
import '../cubit/fund_exploration_cubit.dart';

/// 智能基金排行组件包装器 - 修复版本
///
/// 支持按需加载基金排行数据，优化用户体验
/// 避免集中式加载导致的频率限制问题
/// 提供详细的加载进度和状态提示
///
/// ✅ 修复问题：当组件初始化时如果已经有数据（缓存），直接显示数据而不是加载提示
class SmartFundRankingWrapperFixed extends StatefulWidget {
  const SmartFundRankingWrapperFixed({super.key});

  @override
  State<SmartFundRankingWrapperFixed> createState() =>
      _SmartFundRankingWrapperFixedState();
}

class _SmartFundRankingWrapperFixedState
    extends State<SmartFundRankingWrapperFixed> {
  bool _hasAttemptedLoad = false;
  String _loadingStatus = '准备中...';
  int _loadingProgress = 0;
  Timer? _retryTimer; // 定时重试定时器

  @override
  void initState() {
    super.initState();
    // 启动定时重试机制
    _startRetryTimer();
    // 检查初始状态，如果已经有数据，直接标记为已尝试加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<FundExplorationCubit>();
      final state = cubit.state;

      // 如果已经有数据，直接标记为已尝试加载，避免显示加载提示
      if (state.fundRankings.isNotEmpty) {
        debugPrint('✅ SmartFundRankingWrapperFixed: 初始化时发现已有数据，直接显示');
        setState(() {
          _hasAttemptedLoad = true;
        });
      } else {
        // 延迟加载，确保组件已渲染
        _loadFundRankingsIfNeeded();
      }
    });
  }

  /// 按需加载基金排行（智能策略）
  void _loadFundRankingsIfNeeded() {
    final cubit = context.read<FundExplorationCubit>();
    final state = cubit.state;

    // 智能加载策略：只有当组件完全渲染且用户可能看到时才加载
    if (!_hasAttemptedLoad &&
        state.fundRankings.isEmpty &&
        state.status != FundExplorationStatus.loading) {
      // 延迟10毫秒加载，确保组件完全渲染且用户可能看到
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) {
          debugPrint('🔄 SmartFundRankingWrapperFixed 智能按需加载基金排行...');

          // 更新加载状态
          setState(() {
            _hasAttemptedLoad = true;
            _loadingStatus = '正在连接服务器...';
            _loadingProgress = 10;
          });

          // 模拟加载进度
          _simulateLoadingProgress();

          cubit.loadFundRankings();
        }
      });
    }
  }

  /// 模拟加载进度
  void _simulateLoadingProgress() {
    const steps = [
      '正在连接服务器...', // 10%
      '正在请求数据...', // 30%
      '正在接收数据...', // 60%
      '正在解析数据...', // 80%
      '正在整理排行...', // 95%
      '数据加载完成！', // 100%
    ];

    const progressValues = [10, 30, 60, 80, 95, 100];

    for (int i = 0; i < steps.length; i++) {
      Future.delayed(Duration(milliseconds: 200 * (i + 1)), () {
        if (mounted) {
          setState(() {
            _loadingStatus = steps[i];
            _loadingProgress = progressValues[i];
          });
        }
      });
    }
  }

  /// 手动重新加载
  void _reloadFundRankings() {
    final cubit = context.read<FundExplorationCubit>();
    debugPrint('🔄 SmartFundRankingWrapperFixed 手动重新加载基金排行...');
    cubit.loadFundRankings();
  }

  @override
  void dispose() {
    // 清理定时器
    _retryTimer?.cancel();
    super.dispose();
  }

  /// 启动定时重试机制
  void _startRetryTimer() {
    // 每30秒检查一次，如果当前是模拟数据，则尝试重新加载真实数据
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final cubit = context.read<FundExplorationCubit>();
      final state = cubit.state;

      // 如果当前是模拟数据，尝试重新加载真实数据
      if (state.fundRankings.isNotEmpty && !state.isFundRankingsRealData) {
        debugPrint('🔄 SmartFundRankingWrapperFixed: 定时重试机制触发，尝试加载真实数据');
        _loadRealData();
      }
    });
  }

  /// 尝试加载真实数据（忽略现有数据）
  void _loadRealData() {
    final cubit = context.read<FundExplorationCubit>();
    debugPrint('🔄 SmartFundRankingWrapperFixed: 强制重新加载真实数据');
    cubit.forceReloadFundRankings();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        final fundRankings = state.fundRankings;
        final errorMessage = state.errorMessage;

        // 智能状态处理 - 修复版本：优化状态判断逻辑
        // 确保永远不会卡死在加载状态
        if (state.status == FundExplorationStatus.loading &&
            fundRankings.isEmpty) {
          // 正在加载且没有数据 - 显示加载状态
          return _buildLoadingState();
        } else if (errorMessage != null && fundRankings.isEmpty) {
          // 加载失败且没有数据 - 显示错误状态
          return _buildErrorState(errorMessage);
        } else if (fundRankings.isNotEmpty) {
          // 有数据时始终显示数据（即使有错误也显示数据）
          if (errorMessage != null) {
            debugPrint(
                '⚠️ SmartFundRankingWrapperFixed: 数据加载成功但有警告: $errorMessage');
          }

          // 如果是模拟数据，显示提示横幅
          if (!state.isFundRankingsRealData) {
            debugPrint('⚠️ SmartFundRankingWrapperFixed: 当前显示模拟数据，将定期重试加载真实数据');
            return Column(
              children: [
                // 模拟数据提示横幅
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '当前显示模拟数据，真实数据加载中...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadRealData,
                        child: Text(
                          '立即重试',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 基金排行数据
                Expanded(
                  child: FundRankingSectionFixed(
                    fundRankings: fundRankings,
                    isLoading: state.status == FundExplorationStatus.loading,
                    errorMessage: errorMessage,
                    onLoadMore: () {
                      debugPrint('🔄 用户请求加载更多基金排行数据');
                    },
                  ),
                ),
              ],
            );
          }

          return FundRankingSectionFixed(
            fundRankings: fundRankings,
            isLoading: state.status == FundExplorationStatus.loading,
            errorMessage: errorMessage,
            onLoadMore: () {
              debugPrint('🔄 用户请求加载更多基金排行数据');
            },
          );
        } else {
          // 加载完成但数据为空 - 显示空状态
          return _buildEmptyState();
        }
      },
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 24),

          // 进度条
          Container(
            width: 200,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _loadingProgress / 100,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF1E40AF),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),

          // 进度百分比
          Text(
            '$_loadingProgress%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
            ),
          ),
          SizedBox(height: 8),

          // 状态描述
          Text(
            _loadingStatus,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),

          // 提示信息
          Text(
            '基金排行数据较大，请耐心等待...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 24),

          // 预计时间提示
          Text(
            '预计时间: 15-30秒',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(String errorMessage) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '基金排行加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '错误: $errorMessage',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _reloadFundRankings,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '暂无基金排行数据',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '请稍后重试',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _reloadFundRankings,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载提示
  Widget _buildLoadingHint() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '基金排行数据加载中...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '请稍候，正在获取最新排行数据',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _reloadFundRankings,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('立即加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
