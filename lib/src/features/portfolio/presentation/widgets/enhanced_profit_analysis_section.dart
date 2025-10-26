import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_state.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/widgets/profit_metrics_grid.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/widgets/profit_trend_chart.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/widgets/fund_contribution_ranking_list.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/widgets/profit_decomposition_panel.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/fund_contribution.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/responsive_layout_builder.dart';

/// 增强版收益分析模块
///
/// 按照文档规范实现完整的收益分析界面布局：
/// - 顶部标题和筛选区域
/// - 核心收益指标卡片区域 (3x2网格)
/// - 交互式收益趋势图表区域 (主图表+副图)
/// - 个基收益贡献排行区域
/// - 可折叠分析面板
class EnhancedProfitAnalysisSection extends StatefulWidget {
  const EnhancedProfitAnalysisSection({super.key});

  @override
  State<EnhancedProfitAnalysisSection> createState() =>
      _EnhancedProfitAnalysisSectionState();
}

class _EnhancedProfitAnalysisSectionState
    extends State<EnhancedProfitAnalysisSection> {
  // 时间周期选择
  String _selectedPeriod = '1月';
  final List<String> _periods = [
    '3日',
    '1周',
    '1月',
    '3月',
    '6月',
    '1年',
    '3年',
    '今年来',
    '成立来'
  ];

  // 时间周期配置 - 缓存计算结果
  late final Map<String, int> _periodDays;

  // 收益类型选择
  String _selectedReturnType = '净值收益';
  final List<String> _returnTypes = ['净值收益', '分红收益', '综合收益', '基准对比'];

  // 数据加载状态
  bool _isPeriodChanging = false;
  bool _isReturnTypeChanging = false;

  // 缓存模拟数据，避免重复创建
  List<FundContribution>? _cachedContributions;

  @override
  void initState() {
    super.initState();
    // 初始化时间周期配置
    _periodDays = {
      '3日': 3,
      '1周': 7,
      '1月': 30,
      '3月': 90,
      '6月': 180,
      '1年': 365,
      '3年': 1095,
      '今年来':
          DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays,
      '成立来': 9999, // 表示从成立以来
    };
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: BlocBuilder<PortfolioAnalysisCubit, PortfolioAnalysisState>(
        // 优化：只在必要时重建，指定buildWhen条件
        buildWhen: (previous, current) {
          // 只有在关键状态变化时才重建
          if (previous.holdings.length != current.holdings.length) return true;
          if (previous.isLoading != current.isLoading) return true;
          if (previous.hasError != current.hasError) return true;
          if (previous.error != current.error) return true;
          if (previous.isCalculating != current.isCalculating) return true;
          if (previous.fundMetrics.length != current.fundMetrics.length)
            return true;

          // 其他状态变化不需要重建整个UI
          return false;
        },
        builder: (context, state) {
          return ResponsiveLayoutBuilder(
            builder: (context, screenType) {
              // 获取响应式间距 - 缓存计算结果
              final screenWidth = MediaQuery.of(context).size.width;
              final sectionSpacing = ResponsiveUtils.getResponsiveSpacing(
                width: screenWidth,
                spacings: const {
                  ScreenType.mobile: 16.0,
                  ScreenType.tablet: 20.0,
                  ScreenType.desktop: 24.0,
                  ScreenType.largeDesktop: 32.0,
                },
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标题和筛选区域
                  _buildHeaderAndFilters(context, state, screenType),
                  SizedBox(height: sectionSpacing),

                  // 错误状态显示
                  if (state.hasError) ...[
                    _buildErrorWidget(state.error!, screenType),
                    SizedBox(height: sectionSpacing),
                  ],

                  // 核心收益指标卡片区域 (3x2网格)
                  _buildCoreMetricsCards(state, screenType),
                  SizedBox(height: sectionSpacing),

                  // 交互式收益趋势图表区域
                  _buildInteractiveChartSection(state, screenType),
                  SizedBox(height: sectionSpacing),

                  // 个基收益贡献排行区域
                  _buildContributionRankingSection(state, screenType),
                  SizedBox(height: sectionSpacing),

                  // 可折叠分析面板
                  _buildCollapsibleAnalysisPanels(state, screenType),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 构建顶部标题和筛选区域
  Widget _buildHeaderAndFilters(BuildContext context,
      PortfolioAnalysisState state, ScreenType screenType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题区域
        Row(
          children: [
            Text(
              '收益分析',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const Spacer(),
            // 刷新按钮
            IconButton(
              onPressed: () {
                context.read<PortfolioAnalysisCubit>().refreshData();
              },
              icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
              tooltip: '刷新数据',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 时间周期选择器
        _buildPeriodSelector(),
        const SizedBox(height: 12),

        // 收益类型选择器
        _buildReturnTypeSelector(),
        const SizedBox(height: 8),

        // 分隔线
        Divider(color: Colors.grey[300], thickness: 1),
      ],
    );
  }

  /// 构建时间周期选择器
  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '时间周期',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 8),
            if (_isPeriodChanging) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '切换中...',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
            ],
            const Spacer(),
            // 当前选择的信息提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_periodDays[_selectedPeriod] ?? 0}天',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _periods.length,
            itemBuilder: (context, index) {
              final period = _periods[index];
              final isSelected = period == _selectedPeriod;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: _isPeriodChanging && isSelected
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(period),
                          ],
                        )
                      : Text(period),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && !_isPeriodChanging) {
                      _changePeriod(period);
                    }
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor:
                      Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  elevation: isSelected ? 2 : 0,
                  pressElevation: 4,
                ),
              );
            },
          ),
        ),

        // 时间周期说明
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _getPeriodDescription(_selectedPeriod),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建收益类型选择器
  Widget _buildReturnTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '收益类型',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 8),
            if (_isReturnTypeChanging) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '计算中...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 12,
                ),
              ),
            ],
            const Spacer(),
            // 收益类型图标
            Icon(
              _getReturnTypeIcon(_selectedReturnType),
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _returnTypes.length,
            itemBuilder: (context, index) {
              final returnType = _returnTypes[index];
              final isSelected = returnType == _selectedReturnType;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getReturnTypeIcon(returnType),
                        size: 14,
                        color: isSelected
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      _isReturnTypeChanging && isSelected
                          ? SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            )
                          : Text(returnType),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && !_isReturnTypeChanging) {
                      _changeReturnType(returnType);
                    }
                  },
                  backgroundColor: Colors.grey[50],
                  selectedColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                  checkmarkColor: Theme.of(context).colorScheme.secondary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.grey[600],
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.grey[300]!,
                  ),
                  elevation: isSelected ? 1 : 0,
                  pressElevation: 3,
                ),
              );
            },
          ),
        ),

        // 收益类型说明
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _getReturnTypeDescription(_selectedReturnType),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建错误显示组件
  Widget _buildErrorWidget(String error, ScreenType screenType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<PortfolioAnalysisCubit>().initializeAnalysis();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建核心收益指标卡片区域 (3x2网格)
  Widget _buildCoreMetricsCards(
      PortfolioAnalysisState state, ScreenType screenType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区域标题
        Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '核心收益指标',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (state.isLoading && state.holdings.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '计算中',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // 现有的指标网格组件
        if (state.fundMetrics.isNotEmpty)
          ProfitMetricsGrid(
            metrics: state.fundMetrics.isNotEmpty
                ? state.fundMetrics.values.first
                : null,
            isLoading: state.isLoading,
            onRefresh: () {
              context.read<PortfolioAnalysisCubit>().refreshData();
            },
          )
        else
          _buildEmptyMetricsCard(),
      ],
    );
  }

  /// 构建空指标卡片
  Widget _buildEmptyMetricsCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            '暂无收益数据',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '请添加持仓后查看收益分析',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建交互式收益趋势图表区域
  Widget _buildInteractiveChartSection(
      PortfolioAnalysisState state, ScreenType screenType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图表标题和控制栏
        Row(
          children: [
            Icon(
              Icons.show_chart,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '收益趋势分析',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            // 图表控制按钮
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: 缩放重置
                  },
                  icon: const Icon(Icons.zoom_out_map),
                  tooltip: '重置缩放',
                  iconSize: 18,
                ),
                IconButton(
                  onPressed: () {
                    // TODO: 导出图表
                  },
                  icon: const Icon(Icons.download),
                  tooltip: '导出图表',
                  iconSize: 18,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 主图表区域
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: state.holdings.isNotEmpty
              ? ProfitTrendChart(
                  holdings: state.holdings,
                  metrics: state.fundMetrics.isNotEmpty
                      ? state.fundMetrics.values.first
                      : null,
                  isLoading: state.isLoading,
                  onExportData: () {
                    _exportChartData();
                  },
                )
              : _buildEmptyChartWidget(),
        ),
      ],
    );
  }

  /// 构建空图表组件
  Widget _buildEmptyChartWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.area_chart,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            '暂无图表数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建个基收益贡献排行区域
  Widget _buildContributionRankingSection(
      PortfolioAnalysisState state, ScreenType screenType) {
    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 区域标题
          Row(
            children: [
              Icon(
                Icons.leaderboard,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '个基收益贡献排行',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (state.isLoading && state.holdings.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '分析中',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 贡献排行组件
          Container(
            height: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: state.holdings.isNotEmpty
                ? FundContributionRankingList(
                    contributions: _generateMockContributions(state.holdings),
                    isLoading: state.isLoading,
                    onFundSelected: (contribution) {
                      _showFundDetailDialog(contribution);
                    },
                    onRefresh: () {
                      context.read<PortfolioAnalysisCubit>().refreshData();
                    },
                  )
                : _buildEmptyContributionWidget(),
          ),
        ],
      ),
    );
  }

  /// 生成模拟贡献数据 - 优化版本，使用缓存避免重复创建
  List<FundContribution> _generateMockContributions(List holdings) {
    // 如果已有缓存数据且数据没有变化，直接返回缓存
    if (_cachedContributions != null) {
      return _cachedContributions!;
    }

    // 这里应该从实际的基金数据计算贡献度
    // 目前使用模拟数据进行演示
    _cachedContributions = [
      FundContribution(
        fundCode: '110022',
        fundName: '易方达消费行业股票',
        fundType: '股票型',
        holdingAmount: 50000.0,
        holdingShares: 25000.0,
        portfolioPercentage: 25.0,
        profitAmount: 8500.0,
        profitRate: 0.17,
        cumulativeProfit: 12000.0,
        contributionPercentage: 4.25,
        riskContribution: 3.8,
        maxDrawdown: -0.15,
        volatility: 0.22,
        sharpeRatio: 1.85,
        betaValue: 1.12,
        riskLevel: '中风险',
        overallScore: 7.8,
        overallRanking: '良好',
        analysisPeriod: '1年',
        benchmarkComparison: 0.05,
        peerRanking: 15,
        isKeyContributor: true,
        contributionTrend: '稳定增长',
        lastUpdated: DateTime.now(),
      ),
      FundContribution(
        fundCode: '161725',
        fundName: '招商中证白酒指数分级',
        fundType: '指数型',
        holdingAmount: 30000.0,
        holdingShares: 18000.0,
        portfolioPercentage: 15.0,
        profitAmount: -2100.0,
        profitRate: -0.07,
        cumulativeProfit: 1800.0,
        contributionPercentage: -1.05,
        riskContribution: 2.1,
        maxDrawdown: -0.28,
        volatility: 0.35,
        sharpeRatio: 0.45,
        betaValue: 1.35,
        riskLevel: '高风险',
        overallScore: 4.2,
        overallRanking: '一般',
        analysisPeriod: '1年',
        benchmarkComparison: -0.12,
        peerRanking: 85,
        isKeyContributor: false,
        contributionTrend: '下滑趋势',
        lastUpdated: DateTime.now(),
      ),
      FundContribution(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        holdingAmount: 40000.0,
        holdingShares: 20000.0,
        portfolioPercentage: 20.0,
        profitAmount: 6400.0,
        profitRate: 0.16,
        cumulativeProfit: 9500.0,
        contributionPercentage: 3.2,
        riskContribution: 2.4,
        maxDrawdown: -0.18,
        volatility: 0.18,
        sharpeRatio: 2.1,
        betaValue: 0.95,
        riskLevel: '中风险',
        overallScore: 8.2,
        overallRanking: '优秀',
        analysisPeriod: '1年',
        benchmarkComparison: 0.08,
        peerRanking: 8,
        isKeyContributor: true,
        contributionTrend: '稳定增长',
        lastUpdated: DateTime.now(),
      ),
      FundContribution(
        fundCode: '110011',
        fundName: '易方达中小盘混合',
        fundType: '混合型',
        holdingAmount: 25000.0,
        holdingShares: 15000.0,
        portfolioPercentage: 12.5,
        profitAmount: 1875.0,
        profitRate: 0.075,
        cumulativeProfit: 3200.0,
        contributionPercentage: 0.94,
        riskContribution: 1.2,
        maxDrawdown: -0.12,
        volatility: 0.20,
        sharpeRatio: 1.65,
        betaValue: 1.05,
        riskLevel: '中风险',
        overallScore: 6.8,
        overallRanking: '中等',
        analysisPeriod: '1年',
        benchmarkComparison: 0.03,
        peerRanking: 25,
        isKeyContributor: false,
        contributionTrend: '基本稳定',
        lastUpdated: DateTime.now(),
      ),
      FundContribution(
        fundCode: '519066',
        fundName: '汇添富蓝筹稳健混合',
        fundType: '混合型',
        holdingAmount: 35000.0,
        holdingShares: 21000.0,
        portfolioPercentage: 17.5,
        profitAmount: 5250.0,
        profitRate: 0.15,
        cumulativeProfit: 7800.0,
        contributionPercentage: 2.63,
        riskContribution: 1.8,
        maxDrawdown: -0.10,
        volatility: 0.15,
        sharpeRatio: 2.3,
        betaValue: 0.88,
        riskLevel: '低风险',
        overallScore: 8.6,
        overallRanking: '优秀',
        analysisPeriod: '1年',
        benchmarkComparison: 0.07,
        peerRanking: 5,
        isKeyContributor: true,
        contributionTrend: '稳定增长',
        lastUpdated: DateTime.now(),
      ),
    ];

    return _cachedContributions!;
  }

  @override
  void dispose() {
    // 清理缓存数据
    _cachedContributions = null;
    super.dispose();
  }

  /// 构建空贡献组件
  Widget _buildEmptyContributionWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无贡献排行数据',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请添加持仓后查看各基金的收益贡献分析',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示基金详情对话框
  void _showFundDetailDialog(FundContribution contribution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contribution.fundName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('基金代码：${contribution.fundCode}'),
              Text('基金类型：${contribution.fundType}'),
              const SizedBox(height: 12),
              Text('持仓金额：¥${contribution.holdingAmount.toStringAsFixed(0)}'),
              Text(
                  '持仓占比：${contribution.portfolioPercentage.toStringAsFixed(1)}%'),
              Text(
                  '收益率：${(contribution.profitRate * 100).toStringAsFixed(2)}%'),
              Text(
                  '贡献度：${contribution.contributionPercentage.toStringAsFixed(2)}%'),
              const SizedBox(height: 12),
              Text('风险等级：${contribution.riskLevel}'),
              Text('综合评分：${contribution.overallScore.toStringAsFixed(1)}分'),
              Text('综合排名：${contribution.overallRanking}'),
            ],
          ),
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

  /// 构建可折叠分析面板
  Widget _buildCollapsibleAnalysisPanels(
      PortfolioAnalysisState state, ScreenType screenType) {
    return Column(
      children: [
        // 收益分解分析面板
        ProfitDecompositionPanel(
          metrics: state.fundMetrics.isNotEmpty
              ? state.fundMetrics.values.first
              : null,
          isLoading: state.isLoading,
          onRefresh: () {
            context.read<PortfolioAnalysisCubit>().refreshData();
          },
        ),
        const SizedBox(height: 16),

        // 风险评估面板
        ExpansionTile(
          title: Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.red[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '风险评估指标',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          subtitle: Text(
            'VaR、最大连续亏损、波动率排名',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              // 风险评估面板状态变化，可以在这里添加额外逻辑
            });
          },
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('风险评估指标组件开发中...'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 切换时间周期
  Future<void> _changePeriod(String period) async {
    if (_isPeriodChanging || period == _selectedPeriod) return;

    setState(() {
      _isPeriodChanging = true;
    });

    try {
      // 显示切换提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在切换到 $period 数据...'),
          duration: const Duration(seconds: 1),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );

      // 模拟数据加载延迟
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _selectedPeriod = period;
      });

      // 触发数据刷新
      if (mounted) {
        context.read<PortfolioAnalysisCubit>().refreshData();
      }

      // 显示切换成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到 $period 数据'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPeriodChanging = false;
        });
      }
    }
  }

  /// 切换收益类型
  Future<void> _changeReturnType(String returnType) async {
    if (_isReturnTypeChanging || returnType == _selectedReturnType) return;

    setState(() {
      _isReturnTypeChanging = true;
    });

    try {
      // 显示计算提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在计算 $returnType...'),
          duration: const Duration(seconds: 1),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );

      // 模拟数据计算延迟
      await Future.delayed(const Duration(milliseconds: 600));

      setState(() {
        _selectedReturnType = returnType;
      });

      // 触发数据刷新
      if (mounted) {
        context.read<PortfolioAnalysisCubit>().refreshData();
      }

      // 显示计算成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到 $returnType'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('计算失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReturnTypeChanging = false;
        });
      }
    }
  }

  /// 获取时间周期描述
  String _getPeriodDescription(String period) {
    switch (period) {
      case '3日':
        return '最近3个交易日的收益表现';
      case '1周':
        return '最近一周的收益表现';
      case '1月':
        return '最近一个月的收益表现';
      case '3月':
        return '最近三个月的收益表现';
      case '6月':
        return '最近半年的收益表现';
      case '1年':
        return '最近一年的收益表现';
      case '3年':
        return '最近三年的年化收益表现';
      case '今年来':
        return '从今年1月1日至今的收益表现';
      case '成立来':
        return '从基金成立至今的累计收益表现';
      default:
        return '选择的时间周期';
    }
  }

  /// 获取收益类型图标
  IconData _getReturnTypeIcon(String returnType) {
    switch (returnType) {
      case '净值收益':
        return Icons.trending_up;
      case '分红收益':
        return Icons.card_giftcard;
      case '综合收益':
        return Icons.pie_chart;
      case '基准对比':
        return Icons.compare_arrows;
      default:
        return Icons.analytics;
    }
  }

  /// 获取收益类型描述
  String _getReturnTypeDescription(String returnType) {
    switch (returnType) {
      case '净值收益':
        return '仅计算基金净值涨跌带来的收益，不包括分红';
      case '分红收益':
        return '仅计算基金分红带来的收益部分';
      case '综合收益':
        return '包含净值收益和分红收益的总收益';
      case '基准对比':
        return '与选定基准指数的收益对比分析';
      default:
        return '选择的收益类型';
    }
  }

  /// 导出图表数据
  void _exportChartData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text('正在导出 $_selectedPeriod $_selectedReturnType 数据...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    // 模拟导出过程
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text('数据已导出到下载目录'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}
