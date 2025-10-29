import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../fund_exploration/presentation/cubit/fund_exploration_cubit.dart';

/// 简化的搜索结果组件
///
/// 使用统一的FundExplorationCubit状态管理
/// 直接展示搜索结果
class SimpleSearchResults extends StatelessWidget {
  /// 搜索查询
  final String query;

  /// 结果项点击回调
  final Function(String fundCode, String fundName)? onFundSelected;

  /// 自定义空状态组件
  final Widget? emptyWidget;

  /// 自定义加载指示器
  final Widget? loadingIndicator;

  /// 是否显示搜索统计
  final bool showStatistics;

  const SimpleSearchResults({
    super.key,
    required this.query,
    this.onFundSelected,
    this.emptyWidget,
    this.loadingIndicator,
    this.showStatistics = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(BuildContext context, FundExplorationState state) {
    // 加载状态
    if (state.isLoading) {
      return loadingIndicator ?? _buildDefaultLoadingIndicator();
    }

    // 错误状态
    if (state.showErrorView) {
      return _buildErrorWidget(context, state);
    }

    // 数据展示状态
    if (state.showDataView) {
      return _buildResultsWidget(context, state);
    }

    // 空状态
    return emptyWidget ?? _buildEmptyWidget();
  }

  Widget _buildDefaultLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在搜索...'),
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
              '搜索失败',
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
            ElevatedButton.icon(
              onPressed: () {
                // 重新执行搜索
                context.read<FundExplorationCubit>().searchFunds(query);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '未找到搜索结果',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试使用不同的关键词',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsWidget(BuildContext context, FundExplorationState state) {
    final rankings = state.currentData;

    if (rankings.isEmpty) {
      return _buildEmptyWidget();
    }

    return Column(
      children: [
        // 搜索统计信息
        if (showStatistics) ...[
          _buildSearchStatistics(context, state, rankings),
          const Divider(height: 1),
        ],

        // 搜索结果列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rankings.length,
            itemBuilder: (context, index) {
              final ranking = rankings[index];
              return _buildResultItem(context, ranking, index);
            },
          ),
        ),

        // 加载更多指示器
        if (state.hasMoreData) _buildLoadMoreIndicator(context),
      ],
    );
  }

  Widget _buildSearchStatistics(
      BuildContext context, FundExplorationState state, List rankings) {
    final query = state.searchQuery;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Text(
        '找到 ${rankings.length} 个相关结果 "${query.isEmpty ? "全部基金" : query}"',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, ranking, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(index),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          ranking.fundName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${ranking.fundCode} • ${ranking.shortType}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ranking.formatReturn(ranking.oneYearReturn),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ranking.oneYearReturn >= 0 ? Colors.green : Colors.red,
              ),
            ),
            Text(
              '近1年',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          onFundSelected?.call(ranking.fundCode, ranking.fundName);
        },
        onLongPress: () {
          _showBottomSheet(context, ranking);
        },
      ),
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

  void _showBottomSheet(BuildContext context, ranking) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: Text('基金详情'),
              subtitle: Text('${ranking.fundCode} - ${ranking.fundName}'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: Text('日收益率'),
              trailing: Text(
                ranking.formatReturn(ranking.dailyReturn),
                style: TextStyle(
                  color: ranking.dailyReturn >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timeline),
              title: const Text('近3年收益率'),
              trailing: Text(
                ranking.formatReturn(ranking.threeYearReturn),
                style: TextStyle(
                  color:
                      ranking.threeYearReturn >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text('基金规模'),
              trailing: Text(ranking.formatFundSize()),
            ),
            if (ranking.fundCompany.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.business),
                title: Text('基金公司'),
                subtitle: Text(ranking.fundCompany),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '加载更多...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
