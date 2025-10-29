import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fund_ranking.dart';
import '../fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import 'fund_ranking_table.dart';
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
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        // 根据状态显示不同内容
        if (state.isLoading && state.fundRankings.isEmpty) {
          return _buildInitialState();
        } else if (state.errorMessage != null) {
          return _buildErrorState(state.errorMessage!);
        } else {
          return _buildSuccessState(state);
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

  /// 构建错误状态
  Widget _buildErrorState(String errorMessage) {
    return RankingErrorWidget(
      error: errorMessage,
      isNetworkError: errorMessage.contains('网络'),
      isDataError: errorMessage.contains('数据'),
      retryCount: 0,
      onRetry: () {
        context
            .read<FundExplorationCubit>()
            .loadFundRankings(forceRefresh: true);
      },
    );
  }

  /// 构建成功状态
  Widget _buildSuccessState(FundExplorationState state) {
    final rankings =
        _filterRankings(_convertToDomainRankings(state.currentData));

    if (rankings.isEmpty) {
      return _buildEmptyState(state);
    }

    return Column(
      children: [
        // 工具栏
        _buildToolbar(state),
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
        if (state.hasMoreData) _buildLoadMoreIndicator(),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(FundExplorationState state) {
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
                context
                    .read<FundExplorationCubit>()
                    .loadFundRankings(forceRefresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
        ],
      ),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar(FundExplorationState state) {
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
            '共 ${state.totalCount} 只基金',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const Spacer(),

          // 排序选项
          _buildSortOptions(),
        ],
      ),
    );
  }

  /// 构建排序选项
  Widget _buildSortOptions() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort, size: 20),
      tooltip: '排序方式',
      onSelected: (sortBy) {
        context.read<FundExplorationCubit>().updateSortBy(sortBy);
      },
      itemBuilder: (context) => [
        'return1Y',
        'return3Y',
        'dailyReturn',
        'fundName',
        'fundCode'
      ].map((sortBy) {
        return PopupMenuItem<String>(
          value: sortBy,
          child: Text(_getSortByDisplayName(sortBy)),
        );
      }).toList(),
    );
  }

  /// 构建排行榜内容
  Widget _buildRankingContent(List<FundRanking> rankings) {
    return _buildTableView(rankings);
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

  /// 转换 shared FundRanking 到 domain FundRanking
  List<FundRanking> _convertToDomainRankings(List<dynamic> sharedRankings) {
    return sharedRankings.map((sharedFund) {
      // 假设 sharedFund 是 shared_models.FundRanking 类型
      return FundRanking(
        fundCode: sharedFund.fundCode,
        fundName: sharedFund.fundName,
        fundType: sharedFund.fundType,
        company: sharedFund.fundCompany,
        rankingPosition: 1, // 默认排名
        totalCount: sharedRankings.length,
        unitNav: sharedFund.nav,
        accumulatedNav: 0.0, // 默认值
        dailyReturn: sharedFund.dailyReturn,
        return1W: 0.0, // 默认值
        return1M: 0.0, // 默认值
        return3M: 0.0, // 默认值
        return6M: 0.0, // 默认值
        return1Y: sharedFund.oneYearReturn,
        return2Y: 0.0, // 默认值
        return3Y: sharedFund.threeYearReturn,
        returnYTD: 0.0, // 默认值
        returnSinceInception: sharedFund.sinceInceptionReturn,
        rankingDate: DateTime.now(), // 使用当前日期
        previousPosition: 0, // 默认值
        positionChange: 0.0, // 默认值，表示无变化
        rankingType: RankingType.overall,
        rankingPeriod: RankingPeriod.oneYear,
      );
    }).toList();
  }

  /// 筛选排行榜数据
  List<FundRanking> _filterRankings(List<FundRanking> rankings) {
    if (widget.showOnlyFavorites) {
      // 这里可以根据需要实现收藏逻辑
      // 暂时返回空列表，因为新的状态管理中还没有实现favoriteFunds
      return rankings
          .where((r) => r.fundCode.contains('161725'))
          .toList(); // 示例：只显示特定基金
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
  String _getSortByDisplayName(String sortBy) {
    switch (sortBy) {
      case 'return1Y':
        return '按近1年收益排序';
      case 'return3Y':
        return '按近3年收益排序';
      case 'dailyReturn':
        return '按日增长率排序';
      case 'fundName':
        return '按基金名称排序';
      case 'fundCode':
        return '按基金代码排序';
      default:
        return '按默认排序';
    }
  }

  /// 刷新
  Future<void> _onRefresh() async {
    context.read<FundExplorationCubit>().loadFundRankings(forceRefresh: true);
  }
}
