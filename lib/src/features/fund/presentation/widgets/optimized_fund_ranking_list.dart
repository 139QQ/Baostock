import 'package:flutter/material.dart';

import '../../domain/entities/fund_ranking.dart';
import 'optimized_fund_ranking_card.dart';

/// 优化版基金排行榜列表组件
///
/// 优化点：
/// - 支持懒加载和分页
/// - 使用ListView.builder优化内存使用
/// - 防抖动加载更多
/// - 支持下拉刷新
/// - 智能缓存回收
class OptimizedFundRankingList extends StatefulWidget {
  /// 排行榜数据
  final List<FundRanking> rankings;

  /// 是否正在加载
  final bool isLoading;

  /// 是否有更多数据
  final bool hasMore;

  /// 错误信息
  final String? error;

  /// 加载更多回调
  final Future<void> Function()? onLoadMore;

  /// 刷新回调
  final Future<void> Function()? onRefresh;

  /// 基金点击回调
  final Function(FundRanking)? onFundTap;

  /// 收藏回调
  final Function(String, bool)? onFavorite;

  /// 已收藏的基金代码列表
  final Set<String> favoriteFunds;

  /// 每页显示数量
  final int pageSize;

  const OptimizedFundRankingList({
    super.key,
    required this.rankings,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.onLoadMore,
    this.onRefresh,
    this.onFundTap,
    this.onFavorite,
    this.favoriteFunds = const {},
    this.pageSize = 20,
  });

  @override
  State<OptimizedFundRankingList> createState() =>
      _OptimizedFundRankingListState();
}

class _OptimizedFundRankingListState extends State<OptimizedFundRankingList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // 防抖动计时器
  DateTime? _lastLoadTime;

  @override
  bool get wantKeepAlive => true;

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

  /// 滚动监听，实现懒加载
  void _onScroll() {
    if (!mounted) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = maxScroll - currentScroll;

    // 当滚动到距离底部200像素时开始加载
    if (delta < 200 &&
        !_isLoadingMore &&
        widget.hasMore &&
        widget.onLoadMore != null) {
      // 防抖动：限制加载频率，至少间隔1秒
      final now = DateTime.now();
      if (_lastLoadTime == null ||
          now.difference(_lastLoadTime!) > const Duration(seconds: 1)) {
        _lastLoadTime = now;
        _loadMore();
      }
    }
  }

  /// 加载更多数据
  Future<void> _loadMore() async {
    if (_isLoadingMore || !widget.hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore?.call();
    } catch (e) {
      // 错误处理由父组件负责
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  /// 下拉刷新
  Future<void> _refresh() async {
    await widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 主列表
          if (widget.rankings.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= widget.rankings.length) {
                    return null;
                  }

                  final ranking = widget.rankings[index];
                  final position = index + 1;
                  final isFavorite =
                      widget.favoriteFunds.contains(ranking.fundCode);

                  return OptimizedFundRankingCard(
                    ranking: ranking,
                    position: position,
                    isFavorite: isFavorite,
                    onTap: () => widget.onFundTap?.call(ranking),
                    onFavorite: (favorite) =>
                        widget.onFavorite?.call(ranking.fundCode, favorite),
                  );
                },
                childCount: widget.rankings.length,
              ),
            ),

          // 加载指示器
          if (_isLoadingMore || widget.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          // 没有更多数据提示
          if (!widget.hasMore && widget.rankings.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    '已加载全部数据',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

          // 错误提示
          if (widget.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.error!,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 空状态
          if (widget.rankings.isEmpty &&
              !widget.isLoading &&
              widget.error == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt,
                      color: Colors.grey[400],
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无排行榜数据',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '下拉刷新试试',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 基金排行榜列表控制器
///
/// 用于管理列表状态和数据加载
class FundRankingListController {
  final List<FundRanking> _rankings = [];
  final Set<String> _favoriteFunds = {};
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 0;

  List<FundRanking> get rankings => List.unmodifiable(_rankings);
  Set<String> get favoriteFunds => Set.unmodifiable(_favoriteFunds);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get currentPage => _currentPage;

  /// 设置初始数据
  void setInitialData(List<FundRanking> data) {
    _rankings.clear();
    _rankings.addAll(data);
    _currentPage = 0;
    _hasMore = data.length >= 20; // 假设每页20条
    _error = null;
  }

  /// 添加更多数据
  void addMoreData(List<FundRanking> data) {
    _rankings.addAll(data);
    _currentPage++;
    _hasMore = data.length >= 20; // 假设每页20条
    _error = null;
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
  }

  /// 设置错误
  void setError(String? error) {
    _error = error;
    _isLoading = false;
  }

  /// 切换收藏状态
  void toggleFavorite(String fundCode) {
    if (_favoriteFunds.contains(fundCode)) {
      _favoriteFunds.remove(fundCode);
    } else {
      _favoriteFunds.add(fundCode);
    }
  }

  /// 重置状态
  void reset() {
    _rankings.clear();
    _favoriteFunds.clear();
    _isLoading = false;
    _hasMore = true;
    _error = null;
    _currentPage = 0;
  }

  /// 更新单个排名数据
  void updateRanking(FundRanking updatedRanking) {
    final index = _rankings.indexWhere(
      (ranking) => ranking.fundCode == updatedRanking.fundCode,
    );
    if (index != -1) {
      _rankings[index] = updatedRanking;
    }
  }

  /// 根据基金代码获取排名
  FundRanking? getRankingByCode(String fundCode) {
    try {
      return _rankings.firstWhere(
        (ranking) => ranking.fundCode == fundCode,
      );
    } catch (e) {
      return null;
    }
  }
}
