import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens/app_colors.dart';
import '../../../../core/theme/widgets/gradient_container.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../cubit/portfolio_analysis_cubit.dart';
import '../cubit/portfolio_analysis_state.dart';
import 'core_profit_metrics_grid.dart';
import 'fund_contribution_ranking_list.dart';
import 'interactive_profit_trend_chart.dart';
import 'profit_decomposition_panel.dart';

/// 现代化持仓分析页面
///
/// 集成所有现代化组件的完整投资组合分析界面：
/// - 现代化渐变AppBar设计
/// - 核心收益指标3x2网格
/// - 交互式收益趋势图表
/// - 基金贡献排行榜
/// - 智能分析面板
/// - 响应式布局设计
class ModernPortfolioAnalysisPage extends StatefulWidget {
  /// 创建现代化持仓分析页面
  const ModernPortfolioAnalysisPage({super.key});

  @override
  State<ModernPortfolioAnalysisPage> createState() =>
      _ModernPortfolioAnalysisPageState();
}

class _ModernPortfolioAnalysisPageState
    extends State<ModernPortfolioAnalysisPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 分析周期选择
  String _selectedPeriod = '1月';
  final List<String> _periods = ['1周', '1月', '3月', '6月', '1年', '今年来', '成立来'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initAnimations();

    // 加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioAnalysisCubit>().initializeAnalysis();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF233997).withOpacity(0.95),
              const Color(0xFF5E7CFF).withOpacity(0.9),
              Colors.grey[50]!,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(),
              _buildPeriodSelector(),
              _buildTabBar(),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建现代化AppBar
  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GradientText(
                      '持仓分析',
                      gradient: LinearGradient(
                        colors: [Colors.white, Color(0xFFE8F4FF)],
                      ),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '智能分析您的投资组合表现',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建周期选择器
  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadDataForPeriod(period);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : Colors.transparent,
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF233997)
                        : Colors.white.withOpacity(0.8),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建TabBar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: FinancialGradients.primaryGradient,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dashboard_outlined, size: 18),
                SizedBox(width: 6),
                Text('总览'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart, size: 18),
                SizedBox(width: 6),
                Text('趋势'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.leaderboard, size: 18),
                SizedBox(width: 6),
                Text('贡献'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pie_chart, size: 18),
                SizedBox(width: 6),
                Text('分解'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建TabBarView
  Widget _buildTabBarView() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.95),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrendTab(),
          _buildContributionTab(),
          _buildDecompositionTab(),
        ],
      ),
    );
  }

  /// 总览Tab
  Widget _buildOverviewTab() {
    return BlocBuilder<PortfolioAnalysisCubit, PortfolioAnalysisState>(
      builder: (context, state) {
        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('核心收益指标', Icons.trending_up),
                      const SizedBox(height: 20),
                      CoreProfitMetricsGrid(
                        metrics: null, // 暂时使用null，后续可以从portfolioSummary创建
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: 32),
                      _buildQuickAnalysisCards(state),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 趋势Tab
  Widget _buildTrendTab() {
    return BlocBuilder<PortfolioAnalysisCubit, PortfolioAnalysisState>(
      builder: (context, state) {
        return InteractiveProfitTrendChart(
          metrics: null, // 暂时使用null，后续可以从portfolioSummary创建
          holdings: state.holdings,
          isLoading: state.isLoading,
          selectedPeriod: _selectedPeriod,
          onExportData: () => _exportChartData(),
        );
      },
    );
  }

  /// 贡献Tab
  Widget _buildContributionTab() {
    return BlocBuilder<PortfolioAnalysisCubit, PortfolioAnalysisState>(
      builder: (context, state) {
        return FundContributionRankingList(
          contributions: const [], // 暂时使用空列表，后续可以从持仓数据计算贡献度
          isLoading: state.isLoading,
        );
      },
    );
  }

  /// 分解Tab
  Widget _buildDecompositionTab() {
    return BlocBuilder<PortfolioAnalysisCubit, PortfolioAnalysisState>(
      builder: (context, state) {
        return ProfitDecompositionPanel(
          metrics: null, // 暂时使用null，后续可以从portfolioSummary创建
          isLoading: state.isLoading,
        );
      },
    );
  }

  /// 构建节标题
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: FinancialGradients.primaryGradient,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        GradientText(
          title,
          gradient: FinancialGradients.primaryGradient,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建快速分析卡片
  Widget _buildQuickAnalysisCards(PortfolioAnalysisState state) {
    return Column(
      children: [
        _buildAnalysisCard(
          '风险评估',
          _getRiskLevelFromSummary(state.portfolioSummary),
          Icons.warning_rounded,
          _getRiskColorFromSummary(state.portfolioSummary),
        ),
        const SizedBox(height: 16),
        _buildAnalysisCard(
          '投资建议',
          _getInvestmentAdviceFromSummary(state.portfolioSummary),
          Icons.lightbulb_rounded,
          FinancialColors.positive,
        ),
      ],
    );
  }

  /// 构建分析卡片
  Widget _buildAnalysisCard(
      String title, String content, IconData icon, Color color) {
    return GradientContainer(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取风险等级
  String _getRiskLevel(double returnRate) {
    if (returnRate > 15) return '高风险高收益 - 建议适当减仓';
    if (returnRate > 8) return '中等风险 - 收益表现良好';
    if (returnRate > 0) return '低风险 - 稳健收益';
    return '高亏损风险 - 建议调整策略';
  }

  /// 获取风险颜色
  Color _getRiskColor(double returnRate) {
    if (returnRate > 15) return Colors.orange;
    if (returnRate > 8) return Colors.blue;
    if (returnRate > 0) return Colors.green;
    return Colors.red;
  }

  /// 获取投资建议
  String _getInvestmentAdvice(double returnRate) {
    if (returnRate > 15) return '收益表现优秀，建议锁定部分收益';
    if (returnRate > 8) return '组合表现良好，继续保持';
    if (returnRate > 0) return '收益偏低，可考虑优化配置';
    return '当前亏损，建议评估调整组合';
  }

  /// 加载指定周期数据
  void _loadDataForPeriod(String period) {
    final cubit = context.read<PortfolioAnalysisCubit>();
    // 简化处理：重新初始化分析
    cubit.initializeAnalysis(force: true);
  }

  /// 导出图表数据
  void _exportChartData() {
    // 实现数据导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('图表数据导出功能开发中'),
        backgroundColor: Color(0xFF233997),
      ),
    );
  }

  /// 从PortfolioSummary获取风险等级
  String _getRiskLevelFromSummary(PortfolioSummary? summary) {
    final profitRate = summary?.totalReturnRate ?? 0.0;
    return _getRiskLevel(profitRate);
  }

  /// 从PortfolioSummary获取风险颜色
  Color _getRiskColorFromSummary(PortfolioSummary? summary) {
    final totalAssets = summary?.totalAssets ?? 0.0;
    final totalReturn = summary?.totalReturnAmount ?? 0.0;
    final profitRate =
        totalAssets > 0 ? (totalReturn / totalAssets * 100) : 0.0;
    return _getRiskColor(profitRate);
  }

  /// 从PortfolioSummary获取投资建议
  String _getInvestmentAdviceFromSummary(PortfolioSummary? summary) {
    final profitRate = summary?.totalReturnRate ?? 0.0;
    return _getInvestmentAdvice(profitRate);
  }
}
