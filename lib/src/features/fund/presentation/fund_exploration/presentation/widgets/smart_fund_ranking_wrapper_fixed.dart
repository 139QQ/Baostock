import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'fund_ranking_section_fixed.dart';
import '../cubit/fund_exploration_cubit.dart';

/// 智能基金排行组件包装器
///
/// 支持按需加载基金排行数据，优化用户体验
/// 避免集中式加载导致的频率限制问题
/// 提供详细的加载进度和状态提示
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
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _startRetryTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<FundExplorationCubit>();
      final state = cubit.state;

      if (state.fundRankings.isNotEmpty) {
        debugPrint('✓SmartFundRankingWrapperFixed: 初始化时发现有数据，直接显示');
        setState(() {
          _hasAttemptedLoad = true;
        });
      } else {
        _loadFundRankingsIfNeeded();
      }
    });
  }

  void _loadFundRankingsIfNeeded() {
    final cubit = context.read<FundExplorationCubit>();
    final state = cubit.state;

    if (!_hasAttemptedLoad &&
        state.fundRankings.isEmpty &&
        state.status != FundExplorationStatus.loading) {
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) {
          debugPrint('🔄 SmartFundRankingWrapperFixed 智能按需加载基金排行...');

          setState(() {
            _hasAttemptedLoad = true;
            _loadingStatus = '正在连接服务器...';
            _loadingProgress = 10;
          });

          _simulateLoadingProgress();
          cubit.loadFundRankings();
        }
      });
    }
  }

  void _simulateLoadingProgress() {
    final steps = [
      '正在连接服务器...',
      '正在请求数据...',
      '正在接收数据...',
      '正在解析数据...',
      '正在整理排行...',
      '数据加载完成！',
    ];

    final progressValues = [10, 30, 60, 80, 95, 100];

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

  void _reloadFundRankings() {
    final cubit = context.read<FundExplorationCubit>();
    debugPrint('🔄 SmartFundRankingWrapperFixed 手动重新加载基金排行...');
    cubit.loadFundRankings();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _startRetryTimer() {
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final cubit = context.read<FundExplorationCubit>();
      final state = cubit.state;

      if (state.fundRankings.isNotEmpty && !state.isFundRankingsRealData) {
        debugPrint('🔄 SmartFundRankingWrapperFixed: 定时重试机制触发，尝试加载真实数据');
        _loadRealData();
      }
    });
  }

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

        if (state.status == FundExplorationStatus.loading &&
            fundRankings.isEmpty) {
          return _buildLoadingState();
        } else if (errorMessage != null && fundRankings.isEmpty) {
          return _buildErrorState(errorMessage);
        } else if (fundRankings.isNotEmpty) {
          if (errorMessage != null) {
            debugPrint(
                '⚠️ SmartFundRankingWrapperFixed: 数据加载成功但有警告: $errorMessage');
          }

          if (!state.isFundRankingsRealData) {
            debugPrint('⚠️ SmartFundRankingWrapperFixed: 当前显示模拟数据，将定期重试加载真实数据');
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
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
          return _buildEmptyState();
        }
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 24),

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
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1E40AF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            '$_loadingProgress%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            _loadingStatus,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            '基金排行数据较大，请耐心等待...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

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
          const SizedBox(height: 16),
          Text(
            '基金排行加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '错误: $errorMessage',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _reloadFundRankings,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

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
          const SizedBox(height: 16),
          Text(
            '暂无基金排行数据',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请稍后重试',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _reloadFundRankings,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

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
          const SizedBox(height: 16),
          Text(
            '基金排行数据加载中..',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请稍候，正在获取最新排行数据',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _reloadFundRankings,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('立即加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}