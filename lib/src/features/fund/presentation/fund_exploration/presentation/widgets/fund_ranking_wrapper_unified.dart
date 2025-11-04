import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fund_exploration_cubit.dart';
import '../../../../shared/models/fund_ranking.dart';

/// 统一基金排行包装器
///
/// 直接使用统一的FundExplorationCubit进行状态管理
/// 提供简洁的UI展示和交互
class FundRankingWrapperUnified extends StatelessWidget {
  const FundRankingWrapperUnified({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        return IntrinsicHeight(
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, FundExplorationState state) {
    // 调试信息
    print('🔍 FundRankingWrapperUnified: _buildContent');
    print('   Status: ${state.status}');
    print('   IsLoading: ${state.isLoading}');
    print('   ShowErrorView: ${state.showErrorView}');
    print('   ShowDataView: ${state.showDataView}');
    print('   FundRankings count: ${state.fundRankings.length}');
    print('   CurrentData count: ${state.currentData.length}');
    print('   LastUpdateTime: ${state.lastUpdateTime}');
    print('   ErrorMessage: ${state.errorMessage}');

    // 临时修复：如果状态是loading但isLoading为false，强制显示错误状态
    if (state.status == FundExplorationStatus.loading && !state.isLoading) {
      print('⚠️ 检测到状态不一致，强制显示错误状态');
      return _buildForceErrorWidget(context);
    }

    // 加载状态
    if (state.isLoading) {
      return _buildLoadingWidget();
    }

    // 错误状态
    if (state.showErrorView) {
      return _buildErrorWidget(context, state);
    }

    // 数据展示状态 - 修复逻辑，直接检查是否有数据和状态
    if (state.status == FundExplorationStatus.loaded &&
        state.fundRankings.isNotEmpty) {
      return _buildDataWidget(context, state);
    }

    // 特殊处理：状态是loaded但没有数据，可能是API返回空数据
    if (state.status == FundExplorationStatus.loaded &&
        state.fundRankings.isEmpty) {
      return _buildNoDataWidget(context, state);
    }

    // 空状态
    return _buildEmptyWidget();
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载基金数据...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, FundExplorationState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? '未知错误',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<FundExplorationCubit>().refreshData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<FundExplorationCubit>().forceReloadData();
                  },
                  icon: const Icon(Icons.cached),
                  label: const Text('强制刷新'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '请尝试刷新或调整筛选条件',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget(BuildContext context, FundExplorationState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            Text(
              '无法获取基金数据',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '服务器可能暂时无法访问，请稍后重试',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<FundExplorationCubit>().refreshData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<FundExplorationCubit>().forceReloadData();
                  },
                  icon: const Icon(Icons.cached),
                  label: const Text('强制刷新'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForceErrorWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              '状态不一致错误',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '检测到加载状态不一致，请重试',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<FundExplorationCubit>().forceReloadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('强制重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataWidget(BuildContext context, FundExplorationState state) {
    final rankings = state.currentData;

    // 调试日志
    print('🔍 FundRankingWrapperUnified: _buildDataWidget called');
    print('   State status: ${state.status}');
    print('   Data count: ${rankings.length}');
    print('   Is real data: ${state.isRealData}');
    print('   Current view: ${state.activeView}');

    if (rankings.isEmpty) {
      print('⚠️ FundRankingWrapperUnified: No data to display');
      return _buildEmptyWidget();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 数据统计信息和刷新按钮
        _buildStatisticsHeader(state),

        // 基金列表 - 使用SizedBox限制高度避免布局冲突
        SizedBox(
          height: 400, // 设置固定高度
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rankings.length,
            itemBuilder: (context, index) {
              final ranking = rankings[index];
              return _buildFundCard(context, ranking, index, state);
            },
          ),
        ),

        // 加载更多按钮
        if (state.hasMoreData) _buildLoadMoreButton(context),

        // 手动刷新按钮
        _buildRefreshButton(context),
      ],
    );
  }

  Widget _buildStatisticsHeader(FundExplorationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(
            state.dataStatistics,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (state.lastUpdateTime != null)
            Text(
              '更新于 ${_formatTime(state.lastUpdateTime!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFundCard(BuildContext context, FundRanking ranking, int index,
      FundExplorationState state) {
    final isExpanded = state.expandedFunds.contains(ranking.fundCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context
              .read<FundExplorationCubit>()
              .toggleFundExpanded(ranking.fundCode);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基金基本信息
              Row(
                children: [
                  // 排名
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankColor(index),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${ranking.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 基金信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ranking.fundName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              ranking.fundCode,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                ranking.shortType,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 收益率
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ranking.formatReturn(ranking.oneYearReturn),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ranking.oneYearReturn >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      Text(
                        '近1年',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 展开的详细信息
              if (isExpanded) ...[
                const SizedBox(height: 16),
                _buildExpandedDetails(ranking),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedDetails(FundRanking ranking) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDetailItem('日收益', ranking.formatReturn(ranking.dailyReturn)),
            const SizedBox(width: 24),
            _buildDetailItem(
                '近3年', ranking.formatReturn(ranking.threeYearReturn)),
            const SizedBox(width: 24),
            _buildDetailItem('基金规模', ranking.formatFundSize()),
          ],
        ),
        if (ranking.fundCompany.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDetailItem('基金公司', ranking.fundCompany),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(BuildContext context) {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        if (state.isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              context.read<FundExplorationCubit>().loadMoreData();
            },
            child: const Text('加载更多'),
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    if (index < 3) {
      return Colors.amber;
    } else if (index < 10) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildRefreshButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              context.read<FundExplorationCubit>().refreshData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('刷新数据'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<FundExplorationCubit>().forceReloadData();
            },
            icon: const Icon(Icons.cached),
            label: const Text('强制刷新'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
