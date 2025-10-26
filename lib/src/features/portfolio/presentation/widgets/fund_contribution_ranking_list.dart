import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/fund_contribution.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';

/// 个基收益贡献排行组件
///
/// 按照文档规范实现个基收益贡献排行显示：
/// - 贡献度排行列表
/// - 收益金额和收益率显示
/// - 占比贡献度分析
/// - 排序和筛选功能
/// - 交互式详情查看
class FundContributionRankingList extends StatefulWidget {
  final List<FundContribution> contributions;
  final bool isLoading;
  final Function(FundContribution)? onFundSelected;
  final VoidCallback? onRefresh;

  const FundContributionRankingList({
    super.key,
    this.contributions = const [],
    this.isLoading = false,
    this.onFundSelected,
    this.onRefresh,
  });

  @override
  State<FundContributionRankingList> createState() =>
      _FundContributionRankingListState();
}

class _FundContributionRankingListState
    extends State<FundContributionRankingList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ContributionSortType _sortType = ContributionSortType.profitAmount;
  bool _ascending = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部筛选和排序控制栏
        _buildControlBar(),
        const SizedBox(height: 16),

        // 分类标签页
        _buildTabBar(),
        const SizedBox(height: 16),

        // 贡献排行列表
        Expanded(
          child: _buildContributionList(),
        ),
      ],
    );
  }

  /// 构建控制栏
  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // 搜索栏
          TextField(
            decoration: InputDecoration(
              hintText: '搜索基金名称或代码...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // 排序选项
          Row(
            children: [
              Text(
                '排序方式：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: ContributionSortType.values.map((type) {
                    final isSelected = _sortType == type;
                    return FilterChip(
                      label: Text(_getSortTypeLabel(type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _sortType = type;
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[700],
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),
              // 升序/降序切换
              IconButton(
                onPressed: () {
                  setState(() {
                    _ascending = !_ascending;
                  });
                },
                icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: _ascending ? '升序' : '降序',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).primaryColor,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(
            text: '收益贡献',
            icon: Icon(Icons.trending_up, size: 18),
          ),
          Tab(
            text: '风险贡献',
            icon: Icon(Icons.warning, size: 18),
          ),
          Tab(
            text: '综合评价',
            icon: Icon(Icons.analytics, size: 18),
          ),
        ],
      ),
    );
  }

  /// 构建贡献排行列表
  Widget _buildContributionList() {
    if (widget.isLoading) {
      return _buildLoadingWidget();
    }

    final filteredContributions = _filterAndSortContributions();

    if (filteredContributions.isEmpty) {
      return _buildEmptyWidget();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProfitContributionList(filteredContributions),
        _buildRiskContributionList(filteredContributions),
        _buildOverallEvaluationList(filteredContributions),
      ],
    );
  }

  /// 构建收益贡献列表
  Widget _buildProfitContributionList(List<FundContribution> contributions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: contributions.length,
      itemBuilder: (context, index) {
        final contribution = contributions[index];
        return _buildContributionCard(
            contribution, index, ContributionViewType.profit);
      },
    );
  }

  /// 构建风险贡献列表
  Widget _buildRiskContributionList(List<FundContribution> contributions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: contributions.length,
      itemBuilder: (context, index) {
        final contribution = contributions[index];
        return _buildContributionCard(
            contribution, index, ContributionViewType.risk);
      },
    );
  }

  /// 构建综合评价列表
  Widget _buildOverallEvaluationList(List<FundContribution> contributions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: contributions.length,
      itemBuilder: (context, index) {
        final contribution = contributions[index];
        return _buildContributionCard(
            contribution, index, ContributionViewType.overall);
      },
    );
  }

  /// 构建贡献卡片
  Widget _buildContributionCard(
      FundContribution contribution, int index, ContributionViewType viewType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getContributionColor(contribution, viewType).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            widget.onFundSelected?.call(contribution);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 头部信息
                Row(
                  children: [
                    // 排名
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRankColor(index),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                            contribution.fundName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                contribution.fundCode,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  contribution.fundType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 主要指标
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatContributionValue(contribution, viewType),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                _getContributionColor(contribution, viewType),
                          ),
                        ),
                        Text(
                          _formatContributionPercentage(contribution, viewType),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 详细指标
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricItem(
                      '持仓金额',
                      '¥${contribution.holdingAmount.toStringAsFixed(0)}',
                      Colors.blue[600]!,
                    ),
                    _buildMetricItem(
                      '收益率',
                      '${contribution.profitRate.toStringAsFixed(2)}%',
                      _getProfitColor(contribution.profitRate),
                    ),
                    _buildMetricItem(
                      '占比',
                      '${contribution.portfolioPercentage.toStringAsFixed(1)}%',
                      Colors.purple[600]!,
                    ),
                    _buildMetricItem(
                      '贡献度',
                      '${contribution.contributionPercentage.toStringAsFixed(1)}%',
                      _getContributionColor(contribution, viewType),
                    ),
                  ],
                ),

                // 视图特定内容
                if (viewType == ContributionViewType.profit) ...[
                  const SizedBox(height: 12),
                  _buildProfitDetails(contribution),
                ] else if (viewType == ContributionViewType.risk) ...[
                  const SizedBox(height: 12),
                  _buildRiskDetails(contribution),
                ] else if (viewType == ContributionViewType.overall) ...[
                  const SizedBox(height: 12),
                  _buildOverallDetails(contribution),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建指标项
  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 构建收益详情
  Widget _buildProfitDetails(FundContribution contribution) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '收益贡献分析',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '累计贡献: ¥${contribution.cumulativeProfit.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                contribution.profitRate > 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                size: 16,
                color: contribution.profitRate > 0
                    ? Colors.green[600]
                    : Colors.red[600],
              ),
              const SizedBox(width: 4),
              Text(
                contribution.profitRate > 0 ? '正向贡献' : '负向贡献',
                style: TextStyle(
                  fontSize: 11,
                  color: contribution.profitRate > 0
                      ? Colors.green[600]
                      : Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建风险详情
  Widget _buildRiskDetails(FundContribution contribution) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '风险评估',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '最大回撤: ${contribution.maxDrawdown.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.warning,
                size: 16,
                color: _getRiskLevelColor(contribution.riskLevel),
              ),
              const SizedBox(width: 4),
              Text(
                contribution.riskLevel,
                style: TextStyle(
                  fontSize: 11,
                  color: _getRiskLevelColor(contribution.riskLevel),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建综合详情
  Widget _buildOverallDetails(FundContribution contribution) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '综合评分',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '风险调整收益: ${contribution.sharpeRatio.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(contribution.overallScore).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${contribution.overallScore.toStringAsFixed(1)}分',
              style: TextStyle(
                fontSize: 11,
                color: _getScoreColor(contribution.overallScore),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载组件
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '正在加载贡献排行数据...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空数据组件
  Widget _buildEmptyWidget() {
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
            '请添加持仓后查看各基金的贡献排行',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 筛选和排序贡献数据
  List<FundContribution> _filterAndSortContributions() {
    var contributions = widget.contributions.where((contribution) {
      if (_searchQuery.isEmpty) return true;
      return contribution.fundName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          contribution.fundCode
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    // 排序
    contributions.sort((a, b) {
      int result = 0;
      switch (_sortType) {
        case ContributionSortType.profitAmount:
          result = a.profitAmount.compareTo(b.profitAmount);
          break;
        case ContributionSortType.profitRate:
          result = a.profitRate.compareTo(b.profitRate);
          break;
        case ContributionSortType.contributionPercentage:
          result = a.contributionPercentage.compareTo(b.contributionPercentage);
          break;
        case ContributionSortType.holdingAmount:
          result = a.holdingAmount.compareTo(b.holdingAmount);
          break;
        case ContributionSortType.portfolioPercentage:
          result = a.portfolioPercentage.compareTo(b.portfolioPercentage);
          break;
        case ContributionSortType.overallScore:
          result = a.overallScore.compareTo(b.overallScore);
          break;
      }
      return _ascending ? result : -result;
    });

    return contributions;
  }

  /// 获取排序类型标签
  String _getSortTypeLabel(ContributionSortType type) {
    switch (type) {
      case ContributionSortType.profitAmount:
        return '收益金额';
      case ContributionSortType.profitRate:
        return '收益率';
      case ContributionSortType.contributionPercentage:
        return '贡献度';
      case ContributionSortType.holdingAmount:
        return '持仓金额';
      case ContributionSortType.portfolioPercentage:
        return '持仓占比';
      case ContributionSortType.overallScore:
        return '综合评分';
    }
  }

  /// 获取排名颜色
  Color _getRankColor(int index) {
    if (index == 0) return const Color(0xFFFFD700); // 金色
    if (index == 1) return const Color(0xFFC0C0C0); // 银色
    if (index == 2) return const Color(0xFFCD7F32); // 铜色
    return Colors.grey[600]!;
  }

  /// 获取贡献颜色
  Color _getContributionColor(
      FundContribution contribution, ContributionViewType viewType) {
    switch (viewType) {
      case ContributionViewType.profit:
        return contribution.profitAmount > 0
            ? Colors.green[600]!
            : Colors.red[600]!;
      case ContributionViewType.risk:
        return _getRiskLevelColor(contribution.riskLevel);
      case ContributionViewType.overall:
        return _getScoreColor(contribution.overallScore);
    }
  }

  /// 获取收益颜色
  Color _getProfitColor(double profitRate) {
    if (profitRate > 0) return Colors.green[600]!;
    if (profitRate < 0) return Colors.red[600]!;
    return Colors.grey[600]!;
  }

  /// 获取风险等级颜色
  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case '低风险':
        return Colors.green[600]!;
      case '中风险':
        return Colors.orange[600]!;
      case '高风险':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// 获取评分颜色
  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green[600]!;
    if (score >= 6.0) return Colors.blue[600]!;
    if (score >= 4.0) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  /// 格式化贡献值
  String _formatContributionValue(
      FundContribution contribution, ContributionViewType viewType) {
    switch (viewType) {
      case ContributionViewType.profit:
        return '¥${contribution.profitAmount.abs().toStringAsFixed(0)}';
      case ContributionViewType.risk:
        return '${contribution.maxDrawdown.toStringAsFixed(2)}%';
      case ContributionViewType.overall:
        return contribution.overallScore.toStringAsFixed(1);
    }
  }

  /// 格式化贡献百分比
  String _formatContributionPercentage(
      FundContribution contribution, ContributionViewType viewType) {
    switch (viewType) {
      case ContributionViewType.profit:
        return '${contribution.contributionPercentage.toStringAsFixed(1)}%';
      case ContributionViewType.risk:
        return '风险: ${contribution.riskContribution.toStringAsFixed(1)}%';
      case ContributionViewType.overall:
        return '综合: ${contribution.overallRanking}';
    }
  }
}

/// 贡献排序类型
enum ContributionSortType {
  profitAmount, // 收益金额
  profitRate, // 收益率
  contributionPercentage, // 贡献度
  holdingAmount, // 持仓金额
  portfolioPercentage, // 持仓占比
  overallScore, // 综合评分
}

/// 贡献视图类型
enum ContributionViewType {
  profit, // 收益贡献
  risk, // 风险贡献
  overall, // 综合评价
}
