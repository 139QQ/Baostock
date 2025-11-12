import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../bloc/fund_search_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/state/tool_panel/tool_panel_cubit.dart';
import '../../../../shared/models/fund_ranking.dart';
import '../../domain/models/fund_filter.dart';
import '../cubit/fund_exploration_cubit.dart';
import '../widgets/hot_funds_section.dart';
import '../widgets/user_feedback_collector.dart';
import '../widgets/user_onboarding_guide.dart';
import '../widgets/micro_interaction_fund_card.dart';
import 'widgets/market_snapshot_widget.dart';
import 'widgets/hot_sectors_preview.dart';
import 'widgets/intelligent_search_bar.dart';

/// 统一的基金探索页面
///
/// 融合市场概览和基金探索功能，采用微动交互和极简设计
/// 主要特性：
/// - 🎯 智能搜索：支持基金、板块、概念搜索
/// - 📊 市场快照：实时市场数据和趋势
/// - 🔥 热门推荐：AI驱动的个性化推荐
/// - 🎨 微动交互：细腻的动画和触觉反馈
/// - 📱 响应式布局：适配各种屏幕尺寸
class UnifiedFundExplorationPage extends StatelessWidget {
  const UnifiedFundExplorationPage({super.key});

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
      child: const _UnifiedFundExplorationPageContent(),
    );
  }
}

class _UnifiedFundExplorationPageContent extends StatefulWidget {
  const _UnifiedFundExplorationPageContent();

  @override
  State<_UnifiedFundExplorationPageContent> createState() =>
      _UnifiedFundExplorationPageContentState();
}

class _UnifiedFundExplorationPageContentState
    extends State<_UnifiedFundExplorationPageContent>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FundFilter _currentFilter = FundFilter();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showFilterPanel = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController.addListener(_onScroll);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // 启动入场动画
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 触发无限滚动
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreFunds();
    }
  }

  void _loadMoreFunds() {
    debugPrint('🔄 加载更多基金...');
    // TODO: 实现加载更多逻辑
  }

  void _handleSearch(String query) {
    debugPrint('🔍 搜索: $query');
    // TODO: 实现搜索逻辑
  }

  void _handleFilterChanged(FundFilter filters) {
    setState(() {
      _currentFilter = _currentFilter.copyWith(
        fundTypes: filters.fundTypes,
        riskLevels: filters.riskLevels,
        minReturn1Y: filters.minReturn1Y,
        maxReturn1Y: filters.maxReturn1Y,
        companies: filters.companies,
        sortBy: filters.sortBy,
        sortAscending: filters.sortAscending,
      );
    });
  }

  void _handleSearchFocusChanged(bool focused) {
    // 搜索焦点变化处理
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: Stack(
        children: [
          // 主要内容
          _buildMainContent(),

          // 用户引导层
          const UserOnboardingGuide(),

          // 用户反馈收集层
          const UserFeedbackCollector(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 智能搜索栏
          SliverToBoxAdapter(
            child: _buildIntelligentSearchSection()
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 800))
                .slideY(
                    begin: -0.2,
                    end: 0,
                    duration: const Duration(milliseconds: 600)),
          ),

          // 市场快照（可折叠）
          SliverToBoxAdapter(
            child: _buildMarketSnapshot()
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 1000))
                .slideX(
                    begin: -0.1,
                    end: 0,
                    duration: const Duration(milliseconds: 800)),
          ),

          // 热门板块预览
          SliverToBoxAdapter(
            child: _buildHotSectorsPreview()
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 1200))
                .slideX(
                    begin: 0.1,
                    end: 0,
                    duration: const Duration(milliseconds: 800)),
          ),

          // 智能推荐区域
          SliverToBoxAdapter(
            child: _buildIntelligentRecommendations()
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 1400))
                .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: const Duration(milliseconds: 800)),
          ),

          // 基金网格列表
          _buildFundGridSection(),

          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligentSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          // 页面标题
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '智能基金探索',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'AI驱动的个性化投资推荐',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 智能搜索栏
          IntelligentSearchBar(
            controller: _searchController,
            onSearchChanged: _handleSearch,
            onFocusChanged: _handleSearchFocusChanged,
            onFilterTap: () {
              setState(() {
                _showFilterPanel = !_showFilterPanel;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarketSnapshot() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF8FAFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const MarketSnapshotWidget(),
    );
  }

  Widget _buildHotSectorsPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: const HotSectorsPreview(
        maxItems: 5,
        showTitle: true,
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  Widget _buildIntelligentRecommendations() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI 推荐',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '为您精选',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const HotFundsSection(),
        ],
      ),
    );
  }

  Widget _buildFundGridSection() {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        // 移除统一加载界面 - 直接显示空列表
        // if (state.isLoading && state.fundRankings.isEmpty) {
        //   return SliverToBoxAdapter(
        //     child: _buildLoadingState(),
        //   );
        // }

        if (state.errorMessage != null && state.fundRankings.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildErrorState(state.errorMessage!),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 280,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ranking = state.fundRankings[index];
                return MicroInteractionFundCard(
                  fundRanking: ranking,
                  onTap: () => _onFundSelected(ranking),
                  onFavoriteToggle: () => _toggleFavorite(ranking),
                  onCompareToggle: () => _toggleComparison(ranking),
                );
              },
              childCount: state.fundRankings.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue[400]!,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '智能分析中...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<FundExplorationCubit>().loadFundRankings();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue[600],
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onFundSelected(FundRanking fund) {
    // TODO: 导航到基金详情页面
    debugPrint('选中基金: ${fund.fundName}');
  }

  void _toggleFavorite(FundRanking fund) {
    context.read<FundExplorationCubit>().toggleFavorite(fund.fundCode);
  }

  void _toggleComparison(FundRanking fund) {
    context.read<FundExplorationCubit>().toggleComparisonByCode(fund.fundCode);
  }
}
