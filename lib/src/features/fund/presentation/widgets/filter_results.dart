import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_filter_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/filter_event.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/filter_state.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/filter_chip.dart';
import '../../domain/entities/fund.dart';
import '../bloc/filter_bloc.dart';
import 'filter_loading_indicator.dart';

/// 筛选结果展示组件
///
/// 用于展示筛选后的基金列表，支持分页加载、排序切换等功能。
class FilterResults extends StatefulWidget {
  /// 基金卡片点击回调
  final Function(Fund)? onFundTap;

  /// 基金卡片收藏回调
  final Function(Fund)? onFundFavorite;

  /// 基金卡片对比回调
  final Function(Fund)? onFundCompare;

  /// 自定义空状态组件
  final Widget? emptyWidget;

  /// 自定义加载状态组件
  final Widget? loadingWidget;

  /// 自定义错误状态组件
  final Widget? errorWidget;

  /// 是否显示排序选项
  final bool showSortOptions;

  /// 是否显示分页加载
  final bool showPagination;

  /// 列表视图模式
  final ListViewMode viewMode;

  /// 视图模式切换回调
  final ValueChanged<ListViewMode>? onViewModeChanged;

  const FilterResults({
    super.key,
    this.onFundTap,
    this.onFundFavorite,
    this.onFundCompare,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.showSortOptions = true,
    this.showPagination = true,
    this.viewMode = ListViewMode.list,
    this.onViewModeChanged,
  });

  @override
  State<FilterResults> createState() => _FilterResultsState();
}

class _FilterResultsState extends State<FilterResults> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = MediaQuery.of(context).size.height * 0.2;

    if (maxScroll - currentScroll <= delta) {
      _loadMore();
    }
  }

  void _loadMore() {
    final state = context.read<FilterBloc>().state;
    if (state.hasMore && !state.isLoading) {
      context.read<FilterBloc>().add(const LoadMoreResults());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, state) {
        // 初始加载状态
        if (state.isLoading && state.result == null) {
          return widget.loadingWidget ?? const _LoadingWidget();
        }

        // 错误状态
        if (state.hasError) {
          return widget.errorWidget ??
              FilterErrorIndicator(
                error: state.error!,
                onRetry: () => _retryFilter(),
                isVisible: state.isFailure,
              );
        }

        // 空状态
        if (state.isEmpty) {
          return widget.emptyWidget ??
              _EmptyWidget(
                hasActiveFilters: state.hasActiveFilters,
                onResetFilters: () => _resetFilters(),
              );
        }

        // 结果展示
        return FilterResultAnimation(
          showResults: state.isSuccess,
          resultCount: state.currentResultCount,
          totalCount: state.totalResultCount,
          child: Column(
            children: [
              // 结果统计和工具栏
              if (widget.showSortOptions) _buildResultToolbar(state),

              // 结果列表
              Expanded(
                child: _buildResultsList(state),
              ),

              // 分页加载指示器
              if (widget.showPagination &&
                  state.status == FilterStatus.loadingMore)
                const _LoadingMoreWidget(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultToolbar(FilterState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: colors.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // 结果统计
          Expanded(
            child: Text(
              '找到 ${state.totalResultCount} 只基金'
              '${state.hasActiveFilters ? ' (已应用筛选)' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.8),
              ),
            ),
          ),

          // 排序选项
          if (widget.showSortOptions) ...[
            PopupMenuButton<String>(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _getSortLabel(state.criteria.sortBy),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
              onSelected: (sortBy) {
                context.read<FilterBloc>().add(
                      ChangeSortOption(
                        sortBy: sortBy,
                        sortDirection:
                            state.criteria.sortDirection ?? SortDirection.desc,
                      ),
                    );
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'name',
                  child: Text('按名称'),
                ),
                const PopupMenuItem(
                  value: 'code',
                  child: Text('按代码'),
                ),
                const PopupMenuItem(
                  value: 'nav',
                  child: Text('按净值'),
                ),
                const PopupMenuItem(
                  value: 'return_1y',
                  child: Text('按近一年收益'),
                ),
                const PopupMenuItem(
                  value: 'return_3y',
                  child: Text('按近三年收益'),
                ),
                const PopupMenuItem(
                  value: 'scale',
                  child: Text('按规模'),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // 排序方向切换
            IconButton(
              onPressed: () {
                final newDirection =
                    state.criteria.sortDirection == SortDirection.desc
                        ? SortDirection.asc
                        : SortDirection.desc;
                context.read<FilterBloc>().add(
                      ChangeSortOption(
                        sortBy: state.criteria.sortBy ?? 'return_1y',
                        sortDirection: newDirection,
                      ),
                    );
              },
              icon: Icon(
                state.criteria.sortDirection == SortDirection.desc
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
              ),
              tooltip: state.criteria.sortDirection == SortDirection.desc
                  ? '降序'
                  : '升序',
            ),
          ],

          // 视图模式切换
          if (widget.onViewModeChanged != null) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewModeButton(ListViewMode.list, Icons.list),
                _buildViewModeButton(ListViewMode.grid, Icons.grid_view),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewModeButton(ListViewMode mode, IconData icon) {
    final isSelected = widget.viewMode == mode;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return IconButton(
      onPressed: () {
        if (widget.onViewModeChanged != null) {
          widget.onViewModeChanged!(mode);
        }
      },
      icon: Icon(icon),
      color: isSelected ? colors.primary : colors.onSurface.withOpacity(0.6),
      tooltip: mode == ListViewMode.list ? '列表视图' : '网格视图',
    );
  }

  Widget _buildResultsList(FilterState state) {
    switch (widget.viewMode) {
      case ListViewMode.grid:
        return _buildGridView(state);
      case ListViewMode.list:
      default:
        return _buildListView(state);
    }
  }

  Widget _buildListView(FilterState state) {
    return RefreshIndicator(
      onRefresh: _refreshResults,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.currentResultCount,
        itemBuilder: (context, index) {
          final fund = state.result!.funds[index];
          return _FundListItem(
            fund: fund,
            onTap: () => widget.onFundTap?.call(fund),
            onFavorite: () => widget.onFundFavorite?.call(fund),
            onCompare: () => widget.onFundCompare?.call(fund),
          );
        },
      ),
    );
  }

  Widget _buildGridView(FilterState state) {
    return RefreshIndicator(
      onRefresh: _refreshResults,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: state.currentResultCount,
        itemBuilder: (context, index) {
          final fund = state.result!.funds[index];
          return _FundGridItem(
            fund: fund,
            onTap: () => widget.onFundTap?.call(fund),
            onFavorite: () => widget.onFundFavorite?.call(fund),
            onCompare: () => widget.onFundCompare?.call(fund),
          );
        },
      ),
    );
  }

  Future<void> _refreshResults() async {
    // 重新应用当前筛选条件
    final criteria = context.read<FilterBloc>().state.criteria;
    context.read<FilterBloc>().add(ApplyFilter(criteria: criteria));
  }

  void _retryFilter() {
    final criteria = context.read<FilterBloc>().state.criteria;
    context.read<FilterBloc>().add(ApplyFilter(criteria: criteria));
  }

  void _resetFilters() {
    context.read<FilterBloc>().add(const ResetFilter());
  }

  String _getSortLabel(String? sortBy) {
    switch (sortBy) {
      case 'name':
        return '名称';
      case 'code':
        return '代码';
      case 'nav':
        return '净值';
      case 'return_1y':
        return '近一年收益';
      case 'return_3y':
        return '近三年收益';
      case 'scale':
        return '规模';
      default:
        return '默认';
    }
  }
}

/// 列表视图模式枚举
enum ListViewMode {
  /// 列表视图
  list,

  /// 网格视图
  grid,
}

/// 基金列表项组件
class _FundListItem extends StatelessWidget {
  final Fund fund;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onCompare;

  const _FundListItem({
    required this.fund,
    this.onTap,
    this.onFavorite,
    this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基金基本信息
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fund.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fund.code,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 操作按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onFavorite != null)
                        IconButton(
                          onPressed: onFavorite,
                          icon: const Icon(Icons.favorite_border),
                          tooltip: '收藏',
                        ),
                      if (onCompare != null)
                        IconButton(
                          onPressed: onCompare,
                          icon: const Icon(Icons.compare_arrows),
                          tooltip: '对比',
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 收益率信息
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      '近一年收益',
                      '${fund.return1Y.toStringAsFixed(2)}%',
                      fund.return1Y > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      '近三年收益',
                      '${fund.return3Y.toStringAsFixed(2)}%',
                      fund.return3Y > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      '基金规模',
                      '${fund.scale.toStringAsFixed(0)}亿',
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              // 基金类型和风险
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fund.type,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRiskColor(fund.riskLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fund.riskLevel,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getRiskColor(fund.riskLevel),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      BuildContext context, String label, String value, Color valueColor) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'R1':
        return FundFilterChipColors.riskLevel1;
      case 'R2':
        return FundFilterChipColors.riskLevel2;
      case 'R3':
        return FundFilterChipColors.riskLevel3;
      case 'R4':
        return FundFilterChipColors.riskLevel4;
      case 'R5':
        return FundFilterChipColors.riskLevel5;
      default:
        return Colors.grey;
    }
  }
}

/// 基金网格项组件
class _FundGridItem extends StatelessWidget {
  final Fund fund;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onCompare;

  const _FundGridItem({
    required this.fund,
    this.onTap,
    this.onFavorite,
    this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基金名称
              Text(
                fund.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // 基金代码
              Text(
                fund.code,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.7),
                ),
              ),

              const Spacer(),

              // 收益率
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      '近一年收益',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${fund.return1Y.toStringAsFixed(2)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: fund.return1Y > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onFavorite != null)
                    IconButton(
                      onPressed: onFavorite,
                      icon: const Icon(Icons.favorite_border, size: 18),
                      tooltip: '收藏',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (onCompare != null)
                    IconButton(
                      onPressed: onCompare,
                      icon: const Icon(Icons.compare_arrows, size: 18),
                      tooltip: '对比',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 加载状态组件
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在筛选基金...'),
        ],
      ),
    );
  }
}

/// 加载更多状态组件
class _LoadingMoreWidget extends StatelessWidget {
  const _LoadingMoreWidget();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('加载更多...'),
          ],
        ),
      ),
    );
  }
}

/// 空状态组件
class _EmptyWidget extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onResetFilters;

  const _EmptyWidget({
    required this.hasActiveFilters,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveFilters ? Icons.filter_list_off : Icons.search_off,
              size: 64,
              color: colors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasActiveFilters ? '未找到符合条件的基金' : '暂无基金数据',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilters ? '请尝试调整筛选条件' : '请稍后再试或联系客服',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('清除筛选条件'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
