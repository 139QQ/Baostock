import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/fund.dart';
import '../../../../../../core/utils/batch_data_loader.dart';

/// 优化的基金列表视图 - 使用ListView.builder实现懒加载
///
/// 特点：
/// - 只渲染可见区域的Widget，大幅减少内存占用
/// - 支持无限滚动和分批加载
/// - 自动预加载和缓存管理
/// - 滚动性能优化
/// - 内存管理和数据释放
class OptimizedFundListView extends StatefulWidget {
  final BatchDataLoader<Map<String, dynamic>> dataLoader;
  final String selectedPeriod;
  final Function(FundRanking, int)? onFundTap;
  final Function(FundRanking, int)? onFundFavorite;
  final Function(FundRanking, int)? onFundDetails;
  final Set<String> favoriteFunds;
  final bool enablePullToRefresh;
  final bool enableInfiniteScroll;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const OptimizedFundListView({
    super.key,
    required this.dataLoader,
    this.selectedPeriod = '近一年',
    this.onFundTap,
    this.onFundFavorite,
    this.onFundDetails,
    this.favoriteFunds = const {},
    this.enablePullToRefresh = true,
    this.enableInfiniteScroll = true,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<OptimizedFundListView> createState() => _OptimizedFundListViewState();
}

class _OptimizedFundListViewState extends State<OptimizedFundListView>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  List<FundRanking> _displayData = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _totalCount = 0;
  bool _hasMore = true;

  // 性能优化相关
  final Map<int, FundRanking> _itemCache = {};
  final Set<int> _visibleIndices = {};
  Timer? _scrollEndTimer;
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollEndTimer?.cancel();
    widget.dataLoader.dispose();
    _itemCache.clear();
    _visibleIndices.clear();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final result = await widget.dataLoader.loadPage(0);

      if (mounted) {
        setState(() {
          _displayData = _convertToFundRankings(result.data);
          _totalCount = result.totalCount;
          _hasMore = result.hasMore;
          _isLoading = false;
          _currentPage = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore || !widget.enableInfiniteScroll) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await widget.dataLoader.loadPage(nextPage);

      if (mounted) {
        setState(() {
          _displayData.addAll(_convertToFundRankings(result.data));
          _hasMore = result.hasMore;
          _isLoading = false;
          _currentPage = nextPage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (!widget.enablePullToRefresh) return;

    _itemCache.clear();
    _visibleIndices.clear();
    widget.dataLoader.clearCache();
    await _loadInitialData();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // 检测是否滚动到底部附近
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = widget.dataLoader.config.prefetchDistance.toDouble();

    if (maxScroll - currentScroll <= delta && _hasMore && !_isLoading) {
      _loadMoreData();
    }

    // 滚动结束后的内存优化
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 10), () {
      _optimizeMemory();
    });
  }

  void _optimizeMemory() {
    // 清理不可见区域的缓存
    final keysToRemove = <int>[];
    for (final index in _itemCache.keys) {
      if (!_visibleIndices.contains(index)) {
        keysToRemove.add(index);
      }
    }

    if (keysToRemove.isNotEmpty) {
      for (final key in keysToRemove) {
        _itemCache.remove(key);
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  FundRanking _convertToFundRanking(
      Map<String, dynamic> data, int rankingPosition, int totalCount) {
    return FundRanking(
      fundCode: data['基金代码']?.toString() ?? '',
      fundName: data['基金简称']?.toString() ?? '',
      fundType: data['基金类型']?.toString() ?? '',
      company: data['基金公司']?.toString() ?? '',
      rankingPosition: rankingPosition,
      totalCount: totalCount,
      unitNav: double.tryParse(data['单位净值']?.toString() ?? '0') ?? 0.0,
      accumulatedNav: double.tryParse(data['累计净值']?.toString() ?? '0') ?? 0.0,
      dailyReturn: _parsePercentage(data['日增长率']),
      return1W: _parsePercentage(data['近一周']),
      return1M: _parsePercentage(data['近一月']),
      return3M: _parsePercentage(data['近三月']),
      return6M: _parsePercentage(data['近六月']),
      return1Y: _parsePercentage(data['近一年']),
      return2Y: _parsePercentage(data['近两年']),
      return3Y: _parsePercentage(data['近三年']),
      returnYTD: _parsePercentage(data['今年来']),
      returnSinceInception: _parsePercentage(data['成立来']),
      date: data['日期']?.toString() ?? '',
      fee:
          double.tryParse(data['手续费']?.toString().replaceAll('%', '') ?? '0') ??
              0.0,
    );
  }

  List<FundRanking> _convertToFundRankings(
      List<Map<String, dynamic>> dataList) {
    return dataList.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return _convertToFundRanking(data, index + 1, _totalCount);
    }).toList();
  }

  double _parsePercentage(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().replaceAll('%', '');
    return double.tryParse(str) ?? 0.0;
  }

  Widget _buildItem(BuildContext context, int index) {
    _visibleIndices.add(index);

    // 尝试从缓存获取
    if (_itemCache.containsKey(index)) {
      return _buildFundCard(_itemCache[index]!, index + 1);
    }

    // 创建新的数据项
    if (index < _displayData.length) {
      final fund = _displayData[index];
      _itemCache[index] = fund;
      return _buildFundCard(fund, index + 1);
    }

    // 加载指示器
    if (index == _displayData.length && _isLoading) {
      return _buildLoadingIndicator();
    }

    return const SizedBox.shrink();
  }

  Widget _buildFundCard(FundRanking fund, int ranking) {
    return _OptimizedFundCard(
      fund: fund,
      ranking: ranking,
      selectedPeriod: widget.selectedPeriod,
      onTap: () => widget.onFundTap?.call(fund, ranking),
      onFavorite: () => widget.onFundFavorite?.call(fund, ranking),
      onDetails: () => widget.onFundDetails?.call(fund, ranking),
      isFavorite: widget.favoriteFunds.contains(fund.fundCode),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('加载中...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return widget.emptyWidget ?? _defaultEmptyWidget();
  }

  Widget _buildErrorState() {
    return widget.errorWidget ?? _defaultErrorWidget();
  }

  Widget _defaultEmptyWidget() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无数据', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('加载失败', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _displayData.isEmpty) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _displayData.isEmpty) {
      return _buildErrorState();
    }

    if (_displayData.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _displayData.length + (_hasMore ? 1 : 0),
        itemBuilder: _buildItem,
      ),
    );
  }
}

/// 优化的基金卡片 - 简化版本，减少Widget嵌套层级
class _OptimizedFundCard extends StatelessWidget {
  final FundRanking fund;
  final int ranking;
  final String selectedPeriod;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onDetails;
  final bool isFavorite;

  const _OptimizedFundCard({
    required this.fund,
    required this.ranking,
    required this.selectedPeriod,
    this.onTap,
    this.onFavorite,
    this.onDetails,
    this.isFavorite = false,
  });

  Color _getReturnColor(double returnValue) {
    if (returnValue > 0) return const Color(0xFF10B981);
    if (returnValue < 0) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  Color _getFundTypeColor(String type) {
    switch (type) {
      case '股票型':
        return const Color(0xFFEF4444);
      case '债券型':
        return const Color(0xFF10B981);
      case '混合型':
        return const Color(0xFFF59E0B);
      case '货币型':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  double _getReturnForPeriod() {
    switch (selectedPeriod) {
      case '日增长率':
        return fund.dailyReturn;
      case '近一周':
        return fund.return1W;
      case '近一月':
        return fund.return1M;
      case '近三月':
        return fund.return3M;
      case '近六月':
        return fund.return6M;
      case '近一年':
        return fund.return1Y;
      case '近两年':
        return fund.return2Y;
      case '近三年':
        return fund.return3Y;
      case '今年来':
        return fund.returnYTD;
      case '成立来':
        return fund.returnSinceInception;
      default:
        return fund.return1Y;
    }
  }

  @override
  Widget build(BuildContext context) {
    final returnValue = _getReturnForPeriod();
    final returnColor = _getReturnColor(returnValue);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 排名
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ranking <= 3
                    ? [Colors.amber, Colors.grey, Colors.brown][ranking - 1]
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$ranking',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ranking <= 3 ? Colors.white : Colors.grey.shade700,
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
                    fund.fundName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          fund.fundCode,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              _getFundTypeColor(fund.fundType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          fund.fundType,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getFundTypeColor(fund.fundType),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 收益率
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: returnColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${returnValue.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: returnColor,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 操作按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onFavorite,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isFavorite ? Colors.red : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDetails,
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
