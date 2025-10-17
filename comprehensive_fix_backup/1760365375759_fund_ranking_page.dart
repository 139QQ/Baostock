import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/fund_ranking_bloc.dart';
import '../bloc/fund_ranking_event.dart';
import '../bloc/fund_ranking_state.dart';
import '../widgets/fund_ranking_view.dart';
import '../widgets/ranking_controls.dart';
import '../widgets/ranking_statistics.dart';

/// 基金排行榜页面
///
/// 提供完整的基金排行榜功能，包括：
/// - 多维度排行榜展示
/// - 实时筛选和排序
/// - 分页和加载更多
/// - 收藏管理
/// - 搜索功能
class FundRankingPage extends StatefulWidget {
  const FundRankingPage({super.key});

  @override
  State<FundRankingPage> createState() => _FundRankingPageState();
}

class _FundRankingPageState extends State<FundRankingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // 搜索控制器
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // 是否显示搜索框
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    // 加载默认排行榜
    _loadDefaultRanking();

    // 监听滚动以实现无限加载
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 加载默认排行榜
  void _loadDefaultRanking() {
    context.read<FundRankingBloc>().add(LoadFundRankings(
          criteria: const RankingCriteria(
            rankingType: RankingType.overall,
            rankingPeriod: RankingPeriod.oneYear,
            sortBy: RankingSortBy.returnRate,
            page: 1,
            pageSize: 20,
          ),
        ));
  }

  /// 监听滚动事件
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 距离底部200px时加载更多
      final bloc = context.read<FundRankingBloc>();
      if (bloc.state.successData?.hasMoreData == true) {
        bloc.add(LoadMoreRankings());
      }
    }
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
            _buildTabContent(RankingType.overall),
            _buildTabContent(RankingType.byType),
            _buildTabContent(RankingType.byCompany),
            _buildTabContent(RankingType.byPeriod),
            _buildFavoriteTabContent(),
            _buildSearchTabContent(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
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
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('导出数据'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('设置'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
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
          '实时基金业绩排行，助您把握投资机会',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '搜索基金名称或代码...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onSubmitted: _handleSearch,
      ),
    );
  }

  /// 构建标签栏
  Widget _buildSliverTabBar() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '总榜'),
            Tab(text: '分类榜'),
            Tab(text: '公司榜'),
            Tab(text: '时段榜'),
            Tab(text: '收藏'),
            Tab(text: '搜索'),
          ],
        ),
      ),
    );
  }

  /// 构建标签内容
  Widget _buildTabContent(RankingType rankingType) {
    return Column(
      children: [
        // 排行榜控制组件
        RankingControls(
          rankingType: rankingType,
          onCriteriaChanged: (criteria) {
            context.read<FundRankingBloc>().add(LoadFundRankings(
                  criteria: criteria,
                ));
          },
        ),

        // 统计信息
        BlocBuilder<FundRankingBloc, FundRankingState>(
          builder: (context, state) {
            final statistics = state.successData?.statistics;
            if (statistics != null) {
              return RankingStatistics(statistics: statistics);
            }
            return const SizedBox.shrink();
          },
        ),

        // 排行榜内容
        Expanded(
          child: FundRankingView(
            rankingType: rankingType,
            onFundSelected: _handleFundSelected,
            onFundFavorite: _handleFundFavorite,
          ),
        ),
      ],
    );
  }

  /// 构建收藏标签内容
  Widget _buildFavoriteTabContent() {
    return BlocBuilder<FundRankingBloc, FundRankingState>(
      builder: (context, state) {
        if (state.favoriteFunds.isEmpty) {
          return _buildEmptyFavorites();
        }

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '我的收藏',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: FundRankingView(
                rankingType: RankingType.overall,
                showOnlyFavorites: true,
                onFundSelected: _handleFundSelected,
                onFundFavorite: _handleFundFavorite,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建搜索标签内容
  Widget _buildSearchTabContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: '输入基金名称或代码进行搜索...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: _handleSearch,
            onChanged: _handleSearchChanged,
          ),
        ),
        Expanded(
          child: FundRankingView(
            rankingType: RankingType.overall,
            isSearchMode: true,
            onFundSelected: _handleFundSelected,
            onFundFavorite: _handleFundFavorite,
          ),
        ),
      ],
    );
  }

  /// 构建空收藏状态
  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏基金',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击基金卡片上的收藏按钮添加收藏',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建浮动操作按钮
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _scrollToTop,
      icon: const Icon(Icons.keyboard_arrow_up),
      label: const Text('回到顶部'),
    );
  }

  /// 切换搜索状态
  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchFocusNode.unfocus();
        // 清除搜索状态
        context.read<FundRankingBloc>().add(ClearSearchRankings());
      }
    });
  }

  /// 处理搜索
  void _handleSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<FundRankingBloc>().add(SearchRankings(
            query: query.trim(),
          ));
    }
  }

  /// 处理搜索变化
  void _handleSearchChanged(String query) {
    // 可以在这里实现实时搜索
    if (query.trim().isEmpty) {
      context.read<FundRankingBloc>().add(ClearSearchRankings());
    }
  }

  /// 清除搜索
  void _clearSearch() {
    _searchController.clear();
    context.read<FundRankingBloc>().add(ClearSearchRankings());
  }

  /// 处理基金选择
  void _handleFundSelected(FundRanking fund) {
    Navigator.pushNamed(
      context,
      '/fund-detail',
      arguments: fund.fundCode,
    );
  }

  /// 处理基金收藏
  void _handleFundSelected(String fundCode, bool isFavorite) {
    if (isFavorite) {
      context.read<FundRankingBloc>().add(AddFavoriteFund(fundCode));
    } else {
      context.read<FundRankingBloc>().add(RemoveFavoriteFund(fundCode));
    }
  }

  /// 处理菜单操作
  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        context.read<FundRankingBloc>().add(RefreshFundRankings());
        break;
      case 'export':
        _showExportDialog();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }

  /// 显示导出对话框
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出数据'),
        content: const Text('选择导出格式：'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportData('csv');
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportData('excel');
            },
            child: const Text('Excel'),
          ),
        ],
      ),
    );
  }

  /// 显示设置对话框
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('排行榜设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('自动刷新'),
              subtitle: const Text('每15分钟自动刷新数据'),
              value: true, // 这里应该从设置中读取
              onChanged: (value) {
                // 保存设置
              },
            ),
            SwitchListTile(
              title: const Text('显示统计信息'),
              subtitle: const Text('在排行榜上方显示统计数据'),
              value: true, // 这里应该从设置中读取
              onChanged: (value) {
                // 保存设置
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 导出数据
  void _exportData(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在导出${format.toUpperCase()}格式数据...'),
        duration: const Duration(seconds: 2),
      ),
    );
    // 这里实现实际的导出逻辑
  }

  /// 滚动到顶部
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
