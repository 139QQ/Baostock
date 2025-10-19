import 'dart:async';
import 'package:flutter/material.dart';

import '../../domain/entities/fund_ranking.dart';
import '../domain/services/fund_pagination_service.dart';
import 'fund_card_theme.dart';
import 'fund_card_components.dart';

/// 增强版基金排行榜列表组件
///
/// 集成分页加载、刷新控制、错误处理等功能
class EnhancedFundRankingList extends StatefulWidget {
  /// 自定义标题
  final String? title;

  /// 自定义高度限制
  final double? maxHeight;

  /// 是否显示刷新按钮
  final bool showRefreshButton;

  /// 基金点击回调
  final Function(FundRanking)? onFundTap;

  /// 收藏回调
  final Function(String, bool)? onFavorite;

  /// 已收藏的基金代码
  final Set<String> favoriteFunds;

  /// 自定义样式
  final FundCardSize cardSize;

  /// 自定义主题颜色
  final Color? themeColor;

  const EnhancedFundRankingList({
    super.key,
    this.title,
    this.maxHeight,
    this.showRefreshButton = true,
    this.onFundTap,
    this.onFavorite,
    this.favoriteFunds = const {},
    this.cardSize = FundCardSize.normal,
    this.themeColor,
  });

  @override
  State<EnhancedFundRankingList> createState() =>
      _EnhancedFundRankingListState();
}

class _EnhancedFundRankingListState extends State<EnhancedFundRankingList>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late FundPaginationService _paginationService;
  late ScrollController _scrollController;
  late AnimationController _refreshAnimationController;
  late Animation<double> _refreshAnimation;

  // 状态管理
  List<FundRanking> _funds = [];
  PaginationState _paginationState = const PaginationState(
    currentPage: 1,
    pageSize: 20,
    hasMore: true,
    isLoading: false,
    totalCount: 0,
    cachedPages: [],
  );

  bool _isRefreshing = false;
  String? _lastError;
  DateTime? _lastUpdateTime;

  // 防抖控制
  Timer? _scrollDebounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _refreshAnimationController.dispose();
    _scrollController.dispose();
    _paginationService.dispose();
    super.dispose();
  }

  /// 初始化服务
  void _initializeServices() {
    // 这里需要传入实际的API客户端
    // final apiClient = context.read<FundApiClient>();
    // _paginationService = FundPaginationService(apiClient);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  /// 初始化动画
  void _initializeAnimations() {
    _refreshAnimationController = AnimationController(
      duration: FundCardAnimationConfig.mediumDuration,
      vsync: this,
    );

    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshAnimationController,
      curve: FundCardAnimationConfig.defaultCurve,
    ));
  }

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isRefreshing = true;
        _lastError = null;
      });

      final result = await _paginationService.loadFirstPage();

      if (mounted) {
        setState(() {
          _funds = result.data;
          _paginationState = _paginationService.currentState;
          _lastUpdateTime = DateTime.now();
          _isRefreshing = false;

          if (result.hasError && result.errorMessage != null) {
            _lastError = result.errorMessage;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _lastError = '初始加载失败: ${e.toString()}';
        });
      }
    }
  }

  /// 滚动监听
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final metrics = _scrollController.position;
    final currentScroll = metrics.pixels;
    final maxScroll = metrics.maxScrollExtent;
    final remaining = maxScroll - currentScroll;

    // 防抖处理
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted &&
          _paginationService.shouldLoadMore(currentScroll, maxScroll)) {
        _loadMoreData();
      }
    });
  }

  /// 加载更多数据
  Future<void> _loadMoreData() async {
    if (_paginationState.isLoading || !_paginationState.hasMore) return;

    try {
      final result = await _paginationService.loadNextPage();

      if (mounted) {
        setState(() {
          _funds = result.data;
          _paginationState = _paginationService.currentState;
          _lastUpdateTime = DateTime.now();

          if (result.hasError && result.errorMessage != null) {
            _lastError = result.errorMessage;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = '加载更多失败: ${e.toString()}';
        });
      }
    }
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    try {
      setState(() {
        _isRefreshing = true;
        _lastError = null;
      });

      _refreshAnimationController.forward();

      final result = await _paginationService.refresh();

      if (mounted) {
        setState(() {
          _funds = result.data;
          _paginationState = _paginationService.currentState;
          _lastUpdateTime = DateTime.now();
          _isRefreshing = false;

          if (result.hasError && result.errorMessage != null) {
            _lastError = result.errorMessage;
          }
        });
      }

      await _refreshAnimationController.reverse();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _lastError = '刷新失败: ${e.toString()}';
        });
        await _refreshAnimationController.reverse();
      }
    }
  }

  /// 重试加载
  Future<void> _retryLoad() async {
    if (_funds.isEmpty) {
      await _loadInitialData();
    } else {
      await _loadMoreData();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final height = widget.maxHeight ?? 400;

    return Column(
      children: [
        // 标题栏
        if (widget.title != null) _buildHeader(),

        // 刷新指示器
        _buildRefreshIndicator(),

        // 列表内容
        SizedBox(
          height: height,
          child: _buildContent(),
        ),
      ],
    );
  }

  /// 构建标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 标题
          Expanded(
            child: Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),

          // 统计信息
          _buildStatistics(),

          // 刷新按钮
          if (widget.showRefreshButton) _buildRefreshButton(),
        ],
      ),
    );
  }

  /// 构建统计信息
  Widget _buildStatistics() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.list_alt,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '${_funds.length}条',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        if (_paginationState.hasMore) ...[
          const SizedBox(width: 8),
          Text(
            '加载中...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
        ],
      ],
    );
  }

  /// 构建刷新按钮
  Widget _buildRefreshButton() {
    return AnimatedBuilder(
      animation: _refreshAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _refreshAnimation.value * 2 * 3.14159265359,
          child: IconButton(
            onPressed: _isRefreshing ? null : _refreshData,
            icon: Icon(
              Icons.refresh,
              color: _isRefreshing
                  ? Colors.grey
                  : widget.themeColor ?? Colors.blue,
            ),
            splashRadius: 20,
            tooltip: '刷新数据',
          ),
        );
      },
    );
  }

  /// 构建刷新指示器
  Widget _buildRefreshIndicator() {
    if (!_isRefreshing) return const SizedBox.shrink();

    return Container(
      height: 2,
      child: LinearProgressIndicator(
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.themeColor ?? Colors.blue,
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    if (_funds.isEmpty && _paginationState.isLoading) {
      return _buildLoadingState();
    }

    if (_funds.isEmpty && _lastError != null) {
      return _buildErrorState();
    }

    if (_funds.isEmpty) {
      return _buildEmptyState();
    }

    return _buildFundList();
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.themeColor ?? Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '正在加载基金数据...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请稍候...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              '数据加载失败',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _lastError ?? '未知错误',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无基金数据',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下拉刷新试试',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建基金列表
  Widget _buildFundList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _funds.length + (_paginationState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _funds.length) {
          // 加载更多指示器
          return _buildLoadMoreIndicator();
        }

        final fund = _funds[index];
        final position = index + 1;
        final isFavorite = widget.favoriteFunds.contains(fund.fundCode);

        return FundCardWrapper(
          fund: fund,
          position: position,
          isFavorite: isFavorite,
          cardSize: widget.cardSize,
          themeColor: widget.themeColor,
          onTap: () => widget.onFundTap?.call(fund),
          onFavorite: (favorite) =>
              widget.onFavorite?.call(fund.fundCode, favorite),
        );
      },
    );
  }

  /// 构建加载更多指示器
  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }
}

/// 基金卡片包装器
class FundCardWrapper extends StatelessWidget {
  final FundRanking fund;
  final int position;
  final bool isFavorite;
  final FundCardSize cardSize;
  final Color? themeColor;
  final VoidCallback? onTap;
  final Function(bool)? onFavorite;

  const FundCardWrapper({
    super.key,
    required this.fund,
    required this.position,
    required this.isFavorite,
    this.cardSize = FundCardSize.normal,
    this.themeColor,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: FundCardTheme.cardMargin,
      child: FundCardHeader(
        fund: fund,
        position: position,
        isFavorite: isFavorite,
        cardSize: cardSize,
        themeColor: themeColor,
        onTap: onTap,
        onFavorite: onFavorite,
      ),
    );
  }
}
