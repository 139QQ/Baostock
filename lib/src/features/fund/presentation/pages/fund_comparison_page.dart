import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../../domain/entities/comparison_result.dart';
import '../../domain/entities/fund_ranking.dart';
import '../cubit/fund_comparison_cubit.dart';
import '../../../../core/di/di_initializer.dart';
import '../widgets/comparison_selector.dart';
import '../widgets/comparison_table.dart';
import '../widgets/comparison_carousel.dart';
import '../widgets/comparison_statistics.dart' as stats;
import '../../../../core/utils/logger.dart';

/// 基金对比页面
///
/// 提供完整的基金对比功能，包括选择、分析和展示
class FundComparisonPage extends StatefulWidget {
  /// 可选基金列表
  final List<FundRanking> availableFunds;

  /// 初始对比条件
  final MultiDimensionalComparisonCriteria? initialCriteria;

  const FundComparisonPage({
    super.key,
    required this.availableFunds,
    this.initialCriteria,
  });

  @override
  State<FundComparisonPage> createState() => _FundComparisonPageState();
}

class _FundComparisonPageState extends State<FundComparisonPage>
    with TickerProviderStateMixin {
  static const String _tag = 'FundComparisonPage';

  late TabController _tabController;
  late FundComparisonCubit _comparisonCubit;
  MultiDimensionalComparisonCriteria? _currentCriteria;
  bool _isSelectorExpanded = true;
  bool _useCarouselView = true; // 新增：控制使用轮播视图还是表格视图
  final Set<String> _favoriteFunds = {}; // 收藏的基金
  final Set<String> _comparisonFunds = {}; // 对比中的基金

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 使用依赖注入
    _comparisonCubit = sl<FundComparisonCubit>();

    // 如果有初始条件，应用它
    if (widget.initialCriteria != null) {
      _currentCriteria = widget.initialCriteria;
      _isSelectorExpanded = false;
      _loadComparisonData(widget.initialCriteria!);
    }

    AppLogger.info(_tag,
        'FundComparisonPage initialized with ${widget.availableFunds.length} funds');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _comparisonCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider.value(
        value: _comparisonCubit,
        child: Column(
          children: [
            // 页面头部
            _buildPageHeader(),

            // 选择器区域
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isSelectorExpanded ? null : 0,
              child: _isSelectorExpanded
                  ? _buildSelectorSection()
                  : const SizedBox.shrink(),
            ),

            // 内容区域
            Expanded(
              child: _buildContentSection(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.compare_arrows,
                color: Color(0xFF1E40AF),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '基金多维对比',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E40AF),
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '深度分析基金表现，发现投资机会',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSelectorExpanded = !_isSelectorExpanded;
                  });
                },
                icon: Icon(
                  _isSelectorExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                tooltip: _isSelectorExpanded ? '收起选择器' : '展开选择器',
              ),
            ],
          ),

          // 当前对比条件概览
          if (_currentCriteria != null && _currentCriteria!.isValid())
            _buildCriteriaOverview(),
        ],
      ),
    );
  }

  Widget _buildCriteriaOverview() {
    final criteria = _currentCriteria!;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '正在对比 ${criteria.fundCodes.length} 只基金 • ${criteria.periods.length} 个时间段',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isSelectorExpanded = true;
              });
            },
            child: const Text('修改'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: ComparisonSelector(
        onCriteriaChanged: _onCriteriaChanged,
        availableFunds: widget.availableFunds,
        initialCriteria: widget.initialCriteria,
      ),
    );
  }

  Widget _buildContentSection() {
    if (_currentCriteria == null || !_currentCriteria!.isValid()) {
      return _buildEmptyState();
    }

    return BlocBuilder<FundComparisonCubit, FundComparisonState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingState();
        }

        if (state.status == FundComparisonStatus.error) {
          return _buildErrorState(state.error ?? '未知错误');
        }

        if (state.status != FundComparisonStatus.loaded ||
            state.result == null) {
          return _buildNoDataState();
        }

        if (_useCarouselView) {
          // 轮播视图
          return _buildCarouselView(state.result!);
        } else {
          // 原有的表格视图
          return TabBarView(
            controller: _tabController,
            children: [
              // 对比表格视图
              _buildTableView(state.result!),

              // 统计分析视图
              _buildStatisticsView(state.result!),

              // 详细分析视图
              _buildDetailView(state.result!),
            ],
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '选择基金开始对比分析',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '请在上方选择2-5只基金进行对比',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isSelectorExpanded = true;
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('选择基金'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '正在分析基金数据...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '分析失败',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade400,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _retryLoad(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新尝试'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSelectorExpanded = true;
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('修改条件'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无对比数据',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '请尝试选择不同的基金或时间段',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(ComparisonResult result) {
    return Column(
      children: [
        // Tab 导航栏
        _buildTabBar(),

        // 对比表格
        Expanded(
          child: ComparisonTable(
            comparisonResult: result,
            onTap: _onFundTap,
            onFundDetail: _onFundDetail,
            showStatistics: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsView(ComparisonResult result) {
    return Column(
      children: [
        // Tab 导航栏
        _buildTabBar(),

        // 统计分析
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: stats.ComparisonStatistics(
              comparisonResult: result,
              chartType: stats.StatisticsChartType.bar,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(ComparisonResult result) {
    return Column(
      children: [
        // Tab 导航栏
        _buildTabBar(),

        // 详细分析
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildDetailedAnalysis(result),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.table_chart),
            text: '对比表格',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: '统计分析',
          ),
          Tab(
            icon: Icon(Icons.insights),
            text: '详细分析',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis(ComparisonResult result) {
    final cubit = context.read<FundComparisonCubit>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '详细投资分析',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // 收益分析
            _buildAnalysisSection(
              '收益分析',
              cubit.calculateReturnAnalysis(),
              Icons.trending_up,
              Colors.green,
            ),

            const SizedBox(height: 16),

            // 风险分析
            _buildAnalysisSection(
              '风险分析',
              cubit.calculateRiskAnalysis(),
              Icons.warning,
              Colors.orange,
            ),

            const SizedBox(height: 16),

            // 相关性分析
            _buildAnalysisSection(
              '相关性分析',
              cubit.calculateCorrelationAnalysis(),
              Icons.link,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(
      String title, Map<String, dynamic> data, IconData icon, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 分析数据展示
          ...data.entries.map((entry) {
            return _buildAnalysisItem(entry.key, entry.value, color);
          }),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String key, dynamic value, Color color) {
    String displayKey = _getAnalysisDisplayName(key);
    String displayValue = _getAnalysisDisplayValue(key, value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            displayKey,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    if (_currentCriteria == null || !_currentCriteria!.isValid()) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 视图切换按钮
        if (!_useCarouselView) // 只在表格视图显示切换按钮
          FloatingActionButton(
            heroTag: "toggle_view",
            onPressed: _toggleView,
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.view_carousel),
          ),
        if (!_useCarouselView) const SizedBox(height: 8),

        // 刷新按钮
        FloatingActionButton(
          heroTag: "refresh",
          onPressed: _refreshComparison,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.refresh),
        ),
        const SizedBox(height: 8),

        // 导出按钮
        FloatingActionButton.extended(
          heroTag: "export",
          onPressed: _exportComparison,
          icon: const Icon(Icons.download),
          label: const Text('导出'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ],
    );
  }

  void _onCriteriaChanged(MultiDimensionalComparisonCriteria criteria) {
    setState(() {
      _currentCriteria = criteria;
    });

    if (criteria.isValid()) {
      _loadComparisonData(criteria);
    }
  }

  void _loadComparisonData(MultiDimensionalComparisonCriteria criteria) {
    _comparisonCubit.loadComparison(criteria);
  }

  void _refreshComparison() {
    if (_currentCriteria != null) {
      _comparisonCubit.refreshComparison();
    }
  }

  void _retryLoad() {
    if (_currentCriteria != null) {
      _loadComparisonData(_currentCriteria!);
    }
  }

  void _exportComparison() {
    // 导出功能的实现
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中')),
    );
  }

  void _onFundTap(FundComparisonData data) {
    // 点击基金行的处理
    AppLogger.info(_tag, 'Fund tapped: ${data.fundName} (${data.fundCode})');
  }

  void _onFundDetail(String fundCode) {
    // 查看基金详情的处理
    AppLogger.info(_tag, 'Fund detail requested: $fundCode');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看基金 $fundCode 详情功能开发中')),
    );
  }

  String _getAnalysisDisplayName(String key) {
    switch (key) {
      case 'totalFunds':
        return '基金总数';
      case 'positiveReturns':
        return '盈利基金数';
      case 'negativeReturns':
        return '亏损基金数';
      case 'winRate':
        return '胜率';
      case 'averageReturn':
        return '平均收益率';
      case 'bestPerforming':
        return '最佳表现';
      case 'worstPerforming':
        return '最差表现';
      case 'volatility':
        return '收益波动率';
      case 'averageVolatility':
        return '平均波动率';
      case 'maxVolatility':
        return '最大波动率';
      case 'minVolatility':
        return '最小波动率';
      case 'riskLevel':
        return '风险等级';
      case 'riskDistribution':
        return '风险分布';
      case 'averageCorrelation':
        return '平均相关性';
      case 'diversificationLevel':
        return '分散化程度';
      case 'highlyCorrelatedPairs':
        return '高相关配对';
      default:
        return key;
    }
  }

  String _getAnalysisDisplayValue(String key, dynamic value) {
    if (value == null) return 'N/A';

    switch (key) {
      case 'winRate':
        return '${(value as double).toStringAsFixed(1)}%';
      case 'averageReturn':
      case 'averageVolatility':
      case 'maxVolatility':
      case 'minVolatility':
      case 'averageCorrelation':
        return '${(value as double).toStringAsFixed(2)}%';
      case 'bestPerforming':
      case 'worstPerforming':
        if (value is FundComparisonData) {
          return '${value.fundName} (${(value.totalReturn * 100).toStringAsFixed(2)}%)';
        }
        return value.toString();
      case 'riskDistribution':
        if (value is Map<String, int>) {
          return value.entries.map((e) => '${e.key}:${e.value}').join(', ');
        }
        return value.toString();
      default:
        return value.toString();
    }
  }

  Widget _buildCarouselView(ComparisonResult result) {
    return ComparisonCarousel(
      comparisonResult: result,
      onFundTap: _onFundTap,
      onFundDetail: _onFundDetail,
      onFavorite: _onFavorite,
      onCompare: _onCompare,
      favoriteFunds: _favoriteFunds,
      comparisonFunds: _comparisonFunds,
    );
  }

  void _toggleView() {
    setState(() {
      _useCarouselView = !_useCarouselView;
    });
    AppLogger.info(
        _tag, 'View toggled to: ${_useCarouselView ? "Carousel" : "Table"}');
  }

  void _onFavorite(String fundCode, bool isFavorite) {
    setState(() {
      if (isFavorite) {
        _favoriteFunds.add(fundCode);
      } else {
        _favoriteFunds.remove(fundCode);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? '已添加到收藏' : '已取消收藏'),
        duration: const Duration(seconds: 2),
      ),
    );

    AppLogger.info(_tag, 'Fund $fundCode favorite status: $isFavorite');
  }

  void _onCompare(String fundCode) {
    setState(() {
      if (_comparisonFunds.contains(fundCode)) {
        _comparisonFunds.remove(fundCode);
      } else {
        if (_comparisonFunds.length < 5) {
          _comparisonFunds.add(fundCode);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('最多同时对比5只基金')),
          );
          return;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_comparisonFunds.contains(fundCode) ? '已添加到对比' : '已从对比中移除'),
        duration: const Duration(seconds: 2),
      ),
    );

    AppLogger.info(_tag,
        'Fund $fundCode comparison status: ${_comparisonFunds.contains(fundCode)}');
  }
}
