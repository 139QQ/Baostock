import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import '../fund_exploration/presentation/widgets/fund_ranking_wrapper_unified.dart';
import '../fund_exploration/presentation/widgets/money_funds_section.dart';

/// 基金排行榜页面 V2
///
/// 使用统一状态管理架构的新版本
/// 简化功能，专注于核心排行榜展示
class FundRankingPageV2 extends StatefulWidget {
  const FundRankingPageV2({super.key});

  @override
  State<FundRankingPageV2> createState() => _FundRankingPageV2State();
}

class _FundRankingPageV2State extends State<FundRankingPageV2>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(_onScroll);

    // 监听tab切换
    _tabController.addListener(_handleTabChange);

    // 初始化加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FundExplorationCubit>().loadFundRankings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 监听滚动事件，实现加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 距离底部200px时加载更多
      final cubit = context.read<FundExplorationCubit>();
      if (cubit.state.hasMoreData) {
        cubit.loadMoreData();
      }
    }
  }

  /// 处理tab切换
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    final cubit = context.read<FundExplorationCubit>();

    switch (_tabController.index) {
      case 0: // 综合排行
        cubit.switchToRankingView();
        break;
      case 1: // 分类排行
        cubit.switchToRankingView();
        break;
      case 2: // 公司排行
        cubit.switchToRankingView();
        break;
      case 3: // 周期排行
        cubit.switchToRankingView();
        break;
      case 4: // 货币基金
        cubit.switchToMoneyFundsView();
        break;
    }
  }

  /// 切换搜索状态
  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        // 清除搜索
        context.read<FundExplorationCubit>().searchFunds('');
      }
    });
  }

  /// 执行搜索
  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<FundExplorationCubit>().searchFunds(query.trim());
    } else {
      context.read<FundExplorationCubit>().searchFunds('');
    }
  }

  /// 刷新数据
  void _refreshData() {
    context.read<FundExplorationCubit>().refreshData();
  }

  /// 构建标题
  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '基金排行榜',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '实时数据，智能分析',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索基金代码或名称...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<FundExplorationCubit>().searchFunds('');
            },
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onChanged: _performSearch,
        onSubmitted: _performSearch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            _buildSliverTabBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverallRanking(),
            _buildByTypeRanking(),
            _buildByCompanyRanking(),
            _buildByPeriodRanking(),
            _buildMoneyFunds(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// 构建应用栏
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: _showSearch ? _buildSearchBar() : _buildTitle(),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('刷新'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sort',
              child: Row(
                children: [
                  Icon(Icons.sort),
                  SizedBox(width: 8),
                  Text('排序'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建标签栏
  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '综合排行'),
            Tab(text: '分类排行'),
            Tab(text: '公司排行'),
            Tab(text: '周期排行'),
            Tab(text: '货币基金'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      pinned: true,
    );
  }

  /// 构建综合排行
  Widget _buildOverallRanking() {
    return _buildRankingContent('overall');
  }

  /// 构建分类排行
  Widget _buildByTypeRanking() {
    return _buildRankingContent('type');
  }

  /// 构建公司排行
  Widget _buildByCompanyRanking() {
    return _buildRankingContent('company');
  }

  /// 构建周期排行
  Widget _buildByPeriodRanking() {
    return _buildRankingContent('period');
  }

  /// 构建货币基金
  Widget _buildMoneyFunds() {
    return const MoneyFundsSection();
  }

  /// 构建排行内容
  Widget _buildRankingContent(String type) {
    return const FundRankingWrapperUnified();
  }

  /// 处理菜单操作
  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _refreshData();
        break;
      case 'sort':
        _showSortDialog();
        break;
    }
  }

  /// 显示排序对话框
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('排序方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('按收益率'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: 实现排序逻辑
              },
            ),
            ListTile(
              title: const Text('按基金规模'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: 实现排序逻辑
              },
            ),
            ListTile(
              title: const Text('按名称'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: 实现排序逻辑
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// TabBar 委托类，用于固定 TabBar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
