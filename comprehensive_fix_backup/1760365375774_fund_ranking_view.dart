import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fund_ranking.dart';
import '../bloc/fund_ranking_bloc.dart';
import '../bloc/fund_ranking_event.dart';
import '../bloc/fund_ranking_state.dart';
import 'fund_ranking_card.dart';
import 'fund_ranking_table.dart';
import 'loading_widget.dart';
import 'error_widget.dart';

/// 基金排行榜视图组件
///
/// 根据当前状态显示不同的UI内容：
/// - 加载状态
/// - 成功状态（卡片/表格视图）
/// - 错误状态
/// - 空状态
class FundRankingView extends StatefulWidget {
  /// 排行榜类型
  final RankingType rankingType;

  /// 是否只显示收藏基金
  final bool showOnlyFavorites;

  /// 是否为搜索模式
  final bool isSearchMode;

  /// 基金选择回调
  final Function(FundRanking)? onFundSelected;

  /// 基金收藏回调
  final Function(String, bool)? onFundFavorite;

  const FundRankingView({
    super.key,
    required this.rankingType,
    this.showOnlyFavorites = false,
    this.isSearchMode = false,
    this.onFundSelected,
    this.onFundFavorite,
  });

  @override
  State<FundRankingView> createState() => _FundRankingViewState();
}

class _FundRankingViewState extends State<FundRankingView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 视图模式
  RankingViewMode _viewMode = RankingViewMode.card;

  // 滚动控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundRankingBloc, FundRankingState>(
      builder: (context, state) {
        // 根据状态显示不同内容
        if (state.isLoading) {
          return _buildLoadingState(state);
        } else if (state.isFailure) {
          return _buildErrorState(state.failureData!);
        } else if (state.isSuccess) {
          return _buildSuccessState(state.successData!);
        } else {
          return _buildInitialState();
        }
      },
    );
  }

  /// 构建初始状态
  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在初始化排行榜...'),
        ],
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState(FundRankingState state) {
    return Column(
      children: [
        // 如果是加载更多，显示现有内容
        if (state.rankingState is FundRankingLoadInProgress &&
            (state.rankingState as FundRankingLoadInProgress).isLoadingMore)
          _buildRankingContent(state.successData?.rankings ?? []),

        // 加载指示器
        if (!(state.rankingState is FundRankingLoadInProgress &&
            (state.rankingState as FundRankingLoadInProgress).isLoadingMore))
          const LoadingWidget(),
      ],
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(FundRankingLoadFailure failureState) {
    return RankingErrorWidget(
      error: failureState.error,
      isNetworkError: failureState.isNetworkError,
      isDataError: failureState.isDataError,
      retryCount: failureState.retryCount,
      onRetry: () {
        if (failureState.criteria != null) {
          context.read<FundRankingBloc>().add(
                LoadFundRankings(criteria: failureState.criteria!),
              );
        }
      },
    );
  }

  /// 构建成功状态
  Widget _buildSuccessState(FundRankingLoadSuccess successState) {
    final rankings = _filterRankings(successState.rankings);

    if (rankings.isEmpty) {
      return _buildEmptyState(successState);
    }

    return Column(
      children: [
        // 工具栏
        _buildToolbar(successState),

        // 排行榜内容
        Expanded(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildRankingContent(rankings),
                ),
              );
            },
          ),
        ),

        // 加载更多指示器
        if (successState.hasMoreData) _buildLoadMoreIndicator(),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(FundRankingLoadSuccess successState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isSearchMode
                ? Icons.search_off
                : widget.showOnlyFavorites
                    ? Icons.favorite_border
                    : Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyMessage(),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptySubMessage(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          if (!widget.isSearchMode && !widget.showOnlyFavorites)
            ElevatedButton.icon(
              onPressed: () {
                context.read<FundRankingBloc>().add(RefreshFundRankings());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
        ],
      ),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar(FundRankingLoadSuccess successState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 结果数量
          Text(
            '共 ${successState.totalCount} 只基金',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const Spacer(),

          // 视图模式切换
          _buildViewModeToggle(),

          const SizedBox(width: 16),

          // 排序选项
          _buildSortOptions(),
        ],
      ),
    );
  }

  /// 构建视图模式切换
  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(
            icon: Icons.view_module,
            label: '卡片',
            isSelected: _viewMode == RankingViewMode.card,
            onTap: () => _switchViewMode(RankingViewMode.card),
          ),
          _buildViewModeButton(
            icon: Icons.view_list,
            label: '表格',
            isSelected: _viewMode == RankingViewMode.table,
            onTap: () => _switchViewMode(RankingViewMode.table),
          ),
        ],
      ),
    );
  }

  /// 构建视图模式按钮
  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建排序选项
  Widget _buildSortOptions() {
    return PopupMenuButton<RankingSortBy>(
      icon: const Icon(Icons.sort, size: 20),
      tooltip: '排序方式',
      onSelected: (sortBy) {
        context.read<FundRankingBloc>().add(ChangeSortBy(sortBy));
      },
      itemBuilder: (context) => RankingSortBy.values.map((sortBy) {
        return PopupMenuItem<RankingSortBy>(
          value: sortBy,
          child: Text(_getSortByDisplayName(sortBy)),
        );
      }).toList(),
    );
  }

  /// 构建排行榜内容
  Widget _buildRankingContent(List<FundRanking> rankings) {
    if (_viewMode == RankingViewMode.card) {
      return _buildCardView(rankings);
    } else {
      return _buildTableView(rankings);
    }
  }

  /// 构建卡片视图
  Widget _buildCardView(List<FundRanking> rankings) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          final ranking = rankings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FundRankingCard(
              ranking: ranking,
              position: index + 1,
              onTap: () => widget.onFundSelected?.call(ranking),
              onFavorite: (isFavorite) {
                widget.onFundFavorite?.call(ranking.fundCode, isFavorite);
              },
              animationDelay: Duration(milliseconds: index * 50),
            ),
          );
        },
      ),
    );
  }

  /// 构建表格视图
  Widget _buildTableView(List<FundRanking> rankings) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: FundRankingTable(
          rankings: rankings,
          onTap: widget.onFundSelected,
          onFavorite: widget.onFundFavorite,
        ),
      ),
    );
  }

  /// 构建加载更多指示器
  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('加载更多...'),
        ],
      ),
    );
  }

  /// 筛选排行榜数据
  List<FundRanking> _filterRankings(List<FundRanking> rankings) {
    if (widget.showOnlyFavorites) {
      final favoriteFunds = context.read<FundRankingBloc>().state.favoriteFunds;
      return rankings.where((r) => favoriteFunds.contains(r.fundCode)).toList();
    }
    return rankings;
  }

  /// 获取空状态消息
  String _getEmptyMessage() {
    if (widget.isSearchMode) {
      return '未找到匹配的基金';
    } else if (widget.showOnlyFavorites) {
      return '暂无收藏基金';
    } else {
      return '暂无排行榜数据';
    }
  }

  /// 获取空状态子消息
  String _getEmptySubMessage() {
    if (widget.isSearchMode) {
      return '请尝试其他搜索关键词';
    } else if (widget.showOnlyFavorites) {
      return '点击基金卡片上的收藏按钮添加收藏';
    } else {
      return '请检查网络连接或稍后重试';
    }
  }

  /// 获取排序方式显示名称
  String _getSortByDisplayName(RankingSortBy sortBy) {
    switch (sortBy) {
      case RankingSortBy.returnRate:
        return '按收益率排序';
      case RankingSortBy.unitNav:
        return '按单位净值排序';
      case RankingSortBy.accumulatedNav:
        return '按累计净值排序';
      case RankingSortBy.dailyReturn:
        return '按日增长率排序';
      case RankingSortBy.rankingPosition:
        return '按排名排序';
    }
  }

  /// 切换视图模式
  void _switchViewMode(RankingViewMode mode) {
    setState(() {
      _viewMode = mode;
    });

    // 重新播放动画
    _animationController.reset();
    _animationController.forward();
  }

  /// 刷新
  Future<void> _onRefresh() async {
    context.read<FundRankingBloc>().add(RefreshFundRankings());
  }
}
