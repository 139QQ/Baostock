import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../bloc/fund_search_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/state/tool_panel/tool_panel_cubit.dart';
import '../../../../../../features/fund/domain/entities/fund.dart';
import '../../../../shared/models/fund_ranking.dart';
import '../../domain/models/fund_filter.dart';
import '../cubit/fund_exploration_cubit.dart';
import '../widgets/fund_comparison_tool.dart';
import '../widgets/fund_filter_panel.dart';
import '../widgets/hot_funds_section.dart';
import '../widgets/investment_calculator.dart';
import '../widgets/one_step_search_bar.dart';
import '../widgets/responsive_fund_grid.dart';
import '../widgets/tool_panel_container.dart';
import '../widgets/user_feedback_collector.dart';
import '../widgets/user_onboarding_guide.dart';

/// 极简基金探索页面
///
/// 采用单栏沉浸式设计，突出核心内容，降低视觉噪音
/// 主要功能：
/// - 顶部优雅搜索框
/// - 大量留白设计
/// - 折叠面板功能访问
/// - 底部悬浮极简工具栏
/// - 卡片流内容展示
/// - 无限滚动支持
class MinimalistFundExplorationPage extends StatelessWidget {
  /// 创建极简基金探索页面
  const MinimalistFundExplorationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FundExplorationCubit>(
          create: (context) => sl<FundExplorationCubit>(),
        ),
        BlocProvider<FundSearchBloc>(
          create: (context) => sl<FundSearchBloc>(),
        ),
        BlocProvider<ToolPanelCubit>(
          create: (context) => ToolPanelCubit(),
        ),
      ],
      child: const _MinimalistFundExplorationPageContent(),
    );
  }
}

class _MinimalistFundExplorationPageContent extends StatefulWidget {
  const _MinimalistFundExplorationPageContent();

  @override
  State<_MinimalistFundExplorationPageContent> createState() =>
      _MinimalistFundExplorationPageContentState();
}

class _MinimalistFundExplorationPageContentState
    extends State<_MinimalistFundExplorationPageContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FundFilter _currentFilter = FundFilter();

  bool _showFilterPanel = false;
  bool _showToolsPanel = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 无限滚动加载更多
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 触发加载更多
      _loadMoreFunds();
    }
  }

  void _loadMoreFunds() {
    // TODO: 实现加载更多逻辑
    debugPrint('加载更多基金...');
  }

  void _handleSearch(String query) {
    _searchController.text = query;
    context.read<FundExplorationCubit>().searchFunds(query);
  }

  void _handleFilterChanged(FundFilter filter) {
    setState(() {
      _showFilterPanel = false;
    });

    context.read<FundExplorationCubit>().applyFilters(
          fundType: filter.fundTypes.isNotEmpty ? filter.fundTypes.first : null,
          sortBy: filter.sortBy,
          minReturn: filter.minReturn1Y?.toString(),
          maxReturn: filter.maxReturn1Y?.toString(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC), // 极简背景色
      body: Stack(
        children: [
          // 主要内容
          SafeArea(
            child: Column(
              children: [
                // 顶部搜索区域 - 大量留白
                _buildTopSearchSection(),

                // 折叠工具面板 - Story 1.6 新增
                if (_showToolsPanel) _buildToolsPanel(),

                // 折叠筛选面板
                if (_showFilterPanel) _buildFilterPanel(),

                // 主内容区域 - 卡片流
                Expanded(
                  child: _buildContentSection(),
                ),

                // 底部悬浮极简工具栏
                _buildFloatingToolbar(),
              ],
            ),
          ),

          // 用户引导层
          const UserOnboardingGuide(),

          // 用户反馈收集层
          const UserFeedbackCollector(),
        ],
      ),
    );
  }

  /// 构建顶部搜索区域 - 极简设计，大量留白
  Widget _buildTopSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        children: [
          // 优雅搜索框
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: OneStepSearchBar(
              autofocus: false,
              showSuggestions: true,
              onSearchChanged: (query) {
                // 实时搜索处理
                _handleRealtimeSearch(query);
              },
              onSearchSubmitted: (query) {
                // 提交搜索处理
                _handleSearchSubmitted(query);
              },
              onClear: () {
                _handleSearchCleared();
              },
            ),
          ),
          const SizedBox(height: 16),

          // 快速筛选标签
          _buildQuickFilterChips(),
        ],
      ),
    );
  }

  /// 构建快速筛选标签
  Widget _buildQuickFilterChips() {
    final chips = [
      {'label': '热门基金', 'icon': Icons.local_fire_department},
      {'label': '高收益', 'icon': Icons.trending_up},
      {'label': '稳健型', 'icon': Icons.shield},
      {'label': '新基金', 'icon': Icons.new_releases},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: chips
          .map((chip) => FilterChip(
                label: Text(chip['label'] as String),
                avatar: Icon(chip['icon'] as IconData, size: 16),
                onSelected: (selected) {
                  // 处理快速筛选
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFFE8F5E8),
                checkmarkColor: const Color(0xFF2E7D32),
              ))
          .toList(),
    );
  }

  /// 构建工具面板 - Story 1.6 新增
  Widget _buildToolsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
      child: ToolPanelContainer(
        showHeader: true,
        config: ToolPanelConfig.compactConfig,
        onPanelStateChanged: (panelId, isExpanded) {
          // 记录面板状态变化
          debugPrint('面板 $panelId 展开状态: $isExpanded');
        },
        onFiltersChanged: _handleFilterChanged,
        // 提供自定义的筛选器回调
        initialExpandedState: const {
          'filter': false,
          'comparison': false,
          'calculator': false,
        },
      ),
    );
  }

  /// 构建筛选面板
  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FundFilterPanel(
        filters: _currentFilter,
        onFiltersChanged: _handleFilterChanged,
      ),
    );
  }

  /// 构建主内容区域 - 响应式卡片网格
  Widget _buildContentSection() {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        if (state.isLoading && state.fundRankings.isEmpty) {
          return _buildLoadingState();
        }

        if (state.errorMessage != null && state.fundRankings.isEmpty) {
          return _buildErrorState(state.errorMessage!);
        }

        // 获取当前要显示的数据
        final currentData = _getCurrentDisplayData(state);

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 热门基金区域
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 16.0),
                child: _buildSectionHeader('热门推荐', Icons.local_fire_department),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32.0),
                child: const HotFundsSection(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 基金网格区域 - 使用新的响应式布局
            SliverToBoxAdapter(
              child: _buildFundGridSection(currentData, state),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: 100)), // 为底部工具栏预留空间
          ],
        );
      },
    );
  }

  /// 获取当前要显示的数据
  List<FundRanking> _getCurrentDisplayData(FundExplorationState state) {
    switch (state.status) {
      case FundExplorationStatus.searching:
      case FundExplorationStatus.searched:
        return state.searchResults;
      case FundExplorationStatus.filtering:
      case FundExplorationStatus.filtered:
        return state.filteredRankings;
      case FundExplorationStatus.initial:
      case FundExplorationStatus.loading:
      case FundExplorationStatus.loaded:
      case FundExplorationStatus.error:
        return state.fundRankings;
    }
  }

  /// 构建基金网格区域
  Widget _buildFundGridSection(
      List<FundRanking> rankings, FundExplorationState state) {
    if (rankings.isEmpty) {
      return _buildEmptyState(state.status);
    }

    final adaptedFunds =
        rankings.map((ranking) => _convertToFund(ranking)).toList();

    return ResponsiveFundGrid(
      funds: adaptedFunds,
      onFundTap: (fund) => _onFundSelected(fund),
      onFavoriteToggle: (fund) => _toggleFavorite(fund),
      onCompareToggle: (fund) => _toggleComparison(fund),
      favoriteFunds: state.favoriteFunds,
      comparingFunds: state.comparingFunds,
      showPerformanceMetrics: true,
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(FundExplorationStatus status) {
    String message;
    IconData icon;

    switch (status) {
      case FundExplorationStatus.searched:
        message = '未找到匹配的基金';
        icon = Icons.search_off;
        break;
      case FundExplorationStatus.filtered:
        message = '没有符合筛选条件的基金';
        icon = Icons.filter_list_off;
        break;
      case FundExplorationStatus.initial:
      case FundExplorationStatus.loading:
      case FundExplorationStatus.loaded:
      case FundExplorationStatus.searching:
      case FundExplorationStatus.filtering:
      case FundExplorationStatus.error:
        message = '暂无基金数据';
        icon = Icons.inbox_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(64),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          if (status == FundExplorationStatus.searched ||
              status == FundExplorationStatus.filtered)
            TextButton(
              onPressed: () {
                context.read<FundExplorationCubit>().clearSearch();
              },
              child: const Text('清除条件'),
            ),
        ],
      ),
    );
  }

  /// 将 FundRanking 转换为 Fund
  Fund _convertToFund(dynamic ranking) {
    if (ranking is Fund) return ranking;

    // 如果是 FundRanking，进行转换
    return Fund(
      code: ranking.fundCode ?? '',
      name: ranking.fundName ?? '',
      type: ranking.fundType ?? '',
      company: ranking.company ?? '',
      unitNav: ranking.unitNav ?? 0.0,
      accumulatedNav: ranking.accumulatedNav ?? 0.0,
      dailyReturn: ranking.dailyReturn ?? 0.0,
      return1W: ranking.return1W ?? 0.0,
      return1M: ranking.return1M ?? 0.0,
      return3M: ranking.return3M ?? 0.0,
      return1Y: ranking.return1Y ?? 0.0,
      return2Y: ranking.return2Y ?? 0.0,
      return3Y: ranking.return3Y ?? 0.0,
      returnYTD: ranking.returnYTD ?? 0.0,
      returnSinceInception: ranking.returnSinceInception ?? 0.0,
      lastUpdate: ranking.rankingDate ?? DateTime.now(),
    );
  }

  /// 处理基金选择
  void _onFundSelected(Fund fund) {
    // 导航到基金详情页面
    // TODO: 实现导航逻辑
    print('选中基金: ${fund.name} (${fund.code})');
  }

  /// 切换收藏状态
  void _toggleFavorite(Fund fund) {
    context.read<FundExplorationCubit>().toggleFavorite(fund.code);
  }

  /// 切换对比状态
  void _toggleComparison(Fund fund) {
    context.read<FundExplorationCubit>().toggleComparisonByCode(fund.code);
  }

  /// 实时搜索处理
  void _handleRealtimeSearch(String query) {
    if (query.trim().isEmpty) {
      context.read<FundExplorationCubit>().clearSearch();
      return;
    }

    // 触发实时搜索，使用防抖处理
    context.read<FundExplorationCubit>().searchFunds(query);
  }

  /// 搜索提交处理
  void _handleSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    // 执行搜索
    _handleSearch(query);
  }

  /// 搜索清除处理
  void _handleSearchCleared() {
    context.read<FundExplorationCubit>().clearSearch();
    _searchController.clear();
  }

  /// 构建节标题
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2E7D32)),
          SizedBox(height: 16),
          Text(
            '正在加载基金数据...',
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFD32F2F)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<FundExplorationCubit>().initialize();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  /// 构建底部悬浮极简工具栏
  Widget _buildFloatingToolbar() {
    return Container(
      margin: const EdgeInsets.all(24.0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToolbarButton(
              icon: Icons.filter_list,
              label: '筛选',
              onTap: () {
                setState(() {
                  _showFilterPanel = !_showFilterPanel;
                });
              },
              isActive: _showFilterPanel,
            ),
            _buildToolbarButton(
              icon: Icons.build_circle_outlined,
              label: '工具',
              onTap: () {
                setState(() {
                  _showToolsPanel = !_showToolsPanel;
                });
              },
              isActive: _showToolsPanel,
            ),
            _buildToolbarButton(
              icon: Icons.compare_arrows,
              label: '对比',
              onTap: () => _showComparisonDialog(context),
            ),
            _buildToolbarButton(
              icon: Icons.calculate,
              label: '计算',
              onTap: () => _showCalculatorDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  isActive ? const Color(0xFF2E7D32) : const Color(0xFF666666),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF666666),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示基金对比对话框
  void _showComparisonDialog(BuildContext context) {
    final fundExplorationCubit = context.read<FundExplorationCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;

          // 响应式约束
          final dialogMaxWidth = math.min(500.0, screenWidth * 0.9);
          final dialogMaxHeight = math.min(600.0, screenHeight * 0.85);
          final isSmallScreen = screenHeight < 700;

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              constraints: BoxConstraints(
                maxWidth: dialogMaxWidth,
                maxHeight: dialogMaxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '基金对比工具',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: BlocProvider<FundExplorationCubit>.value(
                        value: fundExplorationCubit,
                        child: const FundComparisonTool(),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 显示定投计算器对话框
  void _showCalculatorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;

          // 响应式约束
          final dialogMaxWidth = math.min(500.0, screenWidth * 0.9);
          final dialogMaxHeight = math.min(600.0, screenHeight * 0.85);
          final isSmallScreen = screenHeight < 700;

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              constraints: BoxConstraints(
                maxWidth: dialogMaxWidth,
                maxHeight: dialogMaxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '定投计算器',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  const Expanded(
                    child: SingleChildScrollView(
                      child: InvestmentCalculator(),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
