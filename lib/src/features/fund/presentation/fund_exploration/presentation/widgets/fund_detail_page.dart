import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/fund_performance_chart.dart';
import '../widgets/fund_holding_analysis.dart';
import '../widgets/fund_manager_info.dart';
import '../widgets/fund_risk_assessment.dart';
import '../cubit/fund_detail_cubit.dart';
import '../../domain/models/fund.dart';

/// 基金详情页面
///
/// 展示基金的完整信息，包括�?
/// - 基本信息和关键指�?
/// - 历史业绩表现
/// - 持仓结构分析
/// - 基金经理信息
/// - 风险评估
/// - 实时估值和净值走�?
class FundDetailPage extends StatefulWidget {
  final String fundCode;

  const FundDetailPage({
    super.key,
    required this.fundCode,
  });

  @override
  State<FundDetailPage> createState() => _FundDetailPageState();
}

class _FundDetailPageState extends State<FundDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // 加载基金详情数据
    context.read<FundDetailCubit>().loadFundDetail(widget.fundCode);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: BlocBuilder<FundDetailCubit, FundDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return _buildLoadingWidget();
          }

          if (state.error != null) {
            return _buildErrorWidget(state.error!);
          }

          if (state.fund == null) {
            return _buildEmptyWidget();
          }

          final fund = state.fund!;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // 顶部应用栏和基本信息
                _buildSliverAppBar(fund),

                // 标签页导�?
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: '概览'),
                        Tab(text: '业绩'),
                        Tab(text: '持仓'),
                        Tab(text: '经理'),
                        Tab(text: '风险'),
                      ],
                      labelColor: const Color(0xFF1E40AF),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 概览页面
                _buildOverviewTab(fund, state),

                // 业绩页面
                _buildPerformanceTab(fund, state),

                // 持仓页面
                _buildHoldingTab(fund, state),

                // 基金经理页面
                _buildManagerTab(fund, state),

                // 风险评估页面
                _buildRiskTab(fund, state),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建Sliver应用�?
  Widget _buildSliverAppBar(Fund fund) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F2937),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Text(
        fund.name,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // 分享按钮
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {
            _handleShare(fund);
          },
        ),

        // 收藏按钮
        IconButton(
          icon: Icon(
            fund.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: fund.isFavorite ? Colors.red : null,
          ),
          onPressed: () {
            _handleToggleFavorite(fund);
          },
        ),

        // 更多操作
        PopupMenuButton<String>(
          onSelected: (value) {
            _handleMoreAction(fund, value);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'comparison',
              child: Text('加入对比'),
            ),
            const PopupMenuItem(
              value: 'notification',
              child: Text('设置提醒'),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Text('查看报告'),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E40AF),
                Color(0xFF3B82F6),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets fromLTRB(16, 56, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基金代码和类�?
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getFundTypeColor(fund.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          fund.type,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getFundTypeColor(fund.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fund.code,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 关键指标
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeyMetric(
                        '${fund.return1Y > 0 ? '+' : ''}${fund.return1Y.toStringAsFixed(2)}%',
                        '�?年收�?,
                        Fund.getReturnColor(fund.return1Y),
                      ),
                      _buildKeyMetric(
                        '${fund.return3Y > 0 ? '+' : ''}${fund.return3Y.toStringAsFixed(2)}%',
                        '�?年收�?,
                        Fund.getReturnColor(fund.return3Y),
                      ),
                      _buildKeyMetric(
                        '${fund.scale.toStringAsFixed(1)}�?,
                        '基金规模',
                        Colors.grey.shade700,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 基金经理
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '基金经理�?{fund.manager}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 基金公司
                  Row(
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '基金公司�?{fund.company}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建关键指标
  Widget _buildKeyMetric(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 构建概览标签�?
  Widget _buildOverviewTab(Fund fund, FundDetailState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 实时估值卡�?
          if (state.fundEstimate != null)
            _buildEstimateCard(state.fundEstimate!),

          const SizedBox(height: 16),

          // 基本信息卡片
          _buildBasicInfoCard(fund),

          const SizedBox(height: 16),

          // 费率信息卡片
          _buildFeeInfoCard(fund),

          const SizedBox(height: 16),

          // 投资信息卡片
          _buildInvestmentInfoCard(fund),
        ],
      ),
    );
  }

  /// 构建实时估值卡�?
  Widget _buildEstimateCard(FundEstimate estimate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '实时估值（${estimate.estimateTime ?? "--"}�?,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '估�?,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estimate.estimateValue?.toStringAsFixed(4) ?? '--',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '单位净�?,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (estimate.estimateReturn != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${estimate.estimateReturn! > 0 ? '+' : ''}${estimate.estimateReturn!.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Fund.getReturnColor(estimate.estimateReturn!),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '预估涨跌',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建基本信息卡片
  Widget _buildBasicInfoCard(Fund fund) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('基金全称', fund.name),
            _buildInfoRow('基金代码', fund.code),
            _buildInfoRow('基金类型', fund.type),
            _buildInfoRow('风险等级', fund.riskLevel),
            if (fund.establishDate != null)
              _buildInfoRow(
                  '成立日期', fund.establishDate!.toString().split(' ')[0]),
            if (fund.listingDate != null)
              _buildInfoRow('上市日期', fund.listingDate!.toString().split(' ')[0]),
            _buildInfoRow('基金公司', fund.company),
            _buildInfoRow('基金经理', fund.manager),
            if (fund.currency != null) _buildInfoRow('交易货币', fund.currency!),
            _buildInfoRow('基金状�?, fund.status == 'active' ? '正常运作' : '暂停运作'),
          ],
        ),
      ),
    );
  }

  /// 构建费率信息卡片
  Widget _buildFeeInfoCard(Fund fund) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '费率信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (fund.managementFee != null)
              _buildInfoRow(
                  '管理费率', '${fund.managementFee!.toStringAsFixed(2)}%'),
            if (fund.custodyFee != null)
              _buildInfoRow('托管费率', '${fund.custodyFee!.toStringAsFixed(2)}%'),
            if (fund.purchaseFee != null)
              _buildInfoRow('申购费率', '${fund.purchaseFee!.toStringAsFixed(2)}%'),
            if (fund.redemptionFee != null)
              _buildInfoRow(
                  '赎回费率', '${fund.redemptionFee!.toStringAsFixed(2)}%'),
            if (fund.minimumInvestment != null)
              _buildInfoRow(
                  '最低申购金�?, '${fund.minimumInvestment!.toStringAsFixed(0)}�?),
          ],
        ),
      ),
    );
  }

  /// 构建投资信息卡片
  Widget _buildInvestmentInfoCard(Fund fund) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '投资信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (fund.investmentTarget != null)
              _buildInfoRow('投资目标', fund.investmentTarget!),
            if (fund.investmentScope != null)
              _buildInfoRow('投资范围', fund.investmentScope!),
            if (fund.performanceBenchmark != null)
              _buildInfoRow('业绩基准', fund.performanceBenchmark!),
          ],
        ),
      ),
    );
  }

  /// 构建信息�?
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label�?,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建业绩标签�?
  Widget _buildPerformanceTab(Fund fund, FundDetailState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 收益表现卡片
          _buildReturnPerformanceCard(fund),

          const SizedBox(height: 16),

          // 业绩走势图表
          if (state.navHistory.isNotEmpty)
            FundPerformanceChart(navData: state.navHistory),

          const SizedBox(height: 16),

          // 同类排名
          _buildRankingCard(fund, state),
        ],
      ),
    );
  }

  /// 构建收益表现卡片
  Widget _buildReturnPerformanceCard(Fund fund) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '收益表现',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildReturnRow('�?�?, fund.return1W),
            _buildReturnRow('�?�?, fund.return1M),
            _buildReturnRow('�?�?, fund.return3M),
            _buildReturnRow('�?�?, fund.return6M),
            _buildReturnRow('�?�?, fund.return1Y),
            _buildReturnRow('�?�?, fund.return3Y),
            _buildReturnRow('成立�?, fund.returnSinceInception ?? 0),
          ],
        ),
      ),
    );
  }

  /// 构建收益�?
  Widget _buildReturnRow(String period, double returnValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            period,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '${returnValue > 0 ? '+' : ''}${returnValue.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Fund.getReturnColor(returnValue),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建排名卡片
  Widget _buildRankingCard(Fund fund, FundDetailState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '同类排名',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (state.fundRanking != null) ...[
              _buildRankingRow('�?�?, state.fundRanking!.rankingPosition,
                  state.fundRanking!.totalCount),
              _buildRankingRow('�?�?, state.fundRanking!.rankingPosition,
                  state.fundRanking!.totalCount),
              _buildRankingRow('�?�?, state.fundRanking!.rankingPosition,
                  state.fundRanking!.totalCount),
              _buildRankingRow('�?�?, state.fundRanking!.rankingPosition,
                  state.fundRanking!.totalCount),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('暂无排名数据'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建排名�?
  Widget _buildRankingRow(String period, int? ranking, int totalCount) {
    if (ranking == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              period,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const Text(
              '--',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final percentile = (ranking / totalCount * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            period,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '�?ranking�?/ �?percentile%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ranking <= totalCount * 0.2 ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建持仓标签�?
  Widget _buildHoldingTab(Fund fund, FundDetailState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 持仓分析组件
          if (state.fundHoldings.isNotEmpty)
            FundHoldingAnalysis(holdings: state.fundHoldings)
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('暂无持仓数据'),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建基金经理标签�?
  Widget _buildManagerTab(Fund fund, FundDetailState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.fundManager != null)
            FundManagerInfo(manager: state.fundManager!)
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('暂无基金经理信息'),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建风险标签�?
  Widget _buildRiskTab(Fund fund, FundDetailState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FundRiskAssessment(
            fund: fund,
            riskMetrics: state.riskMetrics,
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
          Text('正在加载基金详情...'),
        ],
      ),
    );
  }

  /// 构建错误组件
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<FundDetailCubit>().loadFundDetail(widget.fundCode);
            },
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  /// 构建空状态组�?
  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('未找到基金信�?),
        ],
      ),
    );
  }

  /// 处理分享
  void _handleShare(Fund fund) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中...')),
    );
  }

  /// 处理收藏切换
  void _handleToggleFavorite(Fund fund) {
    context.read<FundDetailCubit>().toggleFavorite();
  }

  /// 处理更多操作
  void _handleMoreAction(Fund fund, String action) {
    switch (action) {
      case 'comparison':
        Navigator.pushNamed(
          context,
          '/fund-comparison',
          arguments: [fund.code],
        );
        break;
      case 'notification':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提醒功能开发中...')),
        );
        break;
      case 'report':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报告功能开发中...')),
        );
        break;
    }
  }

  /// 获取基金类型颜色
  Color _getFundTypeColor(String type) {
    switch (type) {
      case '股票�?:
        return const Color(0xFFEF4444);
      case '债券�?:
        return const Color(0xFF10B981);
      case '混合�?:
        return const Color(0xFFF59E0B);
      case '货币�?:
        return const Color(0xFF3B82F6);
      case '指数�?:
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }
}

/// 标签栏委�?
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
