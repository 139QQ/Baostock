import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';

/// 收益分解分析面板
///
/// 按照文档规范实现收益分解分析功能：
/// - 资产配置收益分析
/// - 个券选择收益分析
/// - 交互收益分析
/// - 归因分析可视化
/// - 详细分解数据展示
class ProfitDecompositionPanel extends StatefulWidget {
  final PortfolioProfitMetrics? metrics;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const ProfitDecompositionPanel({
    super.key,
    this.metrics,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<ProfitDecompositionPanel> createState() =>
      _ProfitDecompositionPanelState();
}

class _ProfitDecompositionPanelState extends State<ProfitDecompositionPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!, width: 1.5),
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
          // 面板标题栏
          _buildPanelHeader(),

          // 展开内容
          if (_isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            _buildTabBar(),
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAssetAllocationAnalysis(),
                  _buildSecuritySelectionAnalysis(),
                  _buildInteractionAnalysis(),
                  _buildDetailedBreakdown(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建面板标题栏
  Widget _buildPanelHeader() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '收益分解分析',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '资产配置收益、个券选择收益、交互收益深度分析',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // 总收益概览
              if (widget.metrics != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getProfitColor(widget.metrics!.totalReturnRate)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(widget.metrics!.totalReturnRate * 100).toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: _getProfitColor(widget.metrics!.totalReturnRate),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // 展开图标
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.orange[700],
        labelColor: Colors.orange[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(
            text: '资产配置',
            icon: Icon(Icons.account_balance, size: 16),
          ),
          Tab(
            text: '个券选择',
            icon: Icon(Icons.trending_up, size: 16),
          ),
          Tab(
            text: '交互收益',
            icon: Icon(Icons.swap_horiz, size: 16),
          ),
          Tab(
            text: '详细分解',
            icon: Icon(Icons.list, size: 16),
          ),
        ],
      ),
    );
  }

  /// 构建资产配置分析
  Widget _buildAssetAllocationAnalysis() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 配置概览
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '资产配置贡献',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '+2.35%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 配置收益图表
          Expanded(
            child: Row(
              children: [
                // 饼图
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildAllocationPieChart(),
                  ),
                ),
                const SizedBox(width: 16),

                // 配置列表
                Expanded(
                  child: _buildAllocationList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 配置分析说明
          _buildAllocationAnalysis(),
        ],
      ),
    );
  }

  /// 构建资产配置饼图
  Widget _buildAllocationPieChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: 45,
              title: '股票型\n45%',
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              color: Colors.blue[600],
              radius: 60,
            ),
            PieChartSectionData(
              value: 30,
              title: '债券型\n30%',
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              color: Colors.green[600],
              radius: 50,
            ),
            PieChartSectionData(
              value: 15,
              title: '混合型\n15%',
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              color: Colors.orange[600],
              radius: 40,
            ),
            PieChartSectionData(
              value: 10,
              title: '货币型\n10%',
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              color: Colors.purple[600],
              radius: 30,
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          centerSpaceColor: Colors.white,
        ),
      ),
    );
  }

  /// 构建配置列表
  Widget _buildAllocationList() {
    final allocations = [
      {
        'name': '股票型',
        'percentage': 45,
        'return': 3.2,
        'color': Colors.blue[600]
      },
      {
        'name': '债券型',
        'percentage': 30,
        'return': 1.1,
        'color': Colors.green[600]
      },
      {
        'name': '混合型',
        'percentage': 15,
        'return': 0.8,
        'color': Colors.orange[600]
      },
      {
        'name': '货币型',
        'percentage': 10,
        'return': 0.3,
        'color': Colors.purple[600]
      },
    ];

    return Column(
      children: allocations.map((allocation) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: allocation['color'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allocation['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${(allocation['percentage'] as int)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '收益贡献',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '+${(allocation['return'] as double).toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建配置分析说明
  Widget _buildAllocationAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '配置分析',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前资产配置贡献了组合总收益的68.5%，其中股票型基金是主要收益来源。配置效果优于基准配置，超额收益0.85%。',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建个券选择分析
  Widget _buildSecuritySelectionAnalysis() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 选择收益概览
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '个券选择贡献',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '+1.85%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 个券选择排行榜
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildSecuritySelectionList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建个券选择列表
  Widget _buildSecuritySelectionList() {
    final securities = [
      {'name': '易方达消费行业股票', 'selection': 2.3, 'allocation': 1.2, 'total': 3.5},
      {'name': '华夏成长混合', 'selection': 1.8, 'allocation': 0.9, 'total': 2.7},
      {'name': '汇添富蓝筹稳健混合', 'selection': 1.2, 'allocation': 0.6, 'total': 1.8},
      {'name': '招商中证白酒指数', 'selection': -0.8, 'allocation': 0.4, 'total': -0.4},
      {'name': '易方达中小盘混合', 'selection': 0.3, 'allocation': 0.2, 'total': 0.5},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: securities.length,
      itemBuilder: (context, index) {
        final security = securities[index];
        final isPositive = (security['total'] as double) > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                security['name'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 收益分解条形图
              Row(
                children: [
                  // 选择收益
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '选择收益',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${(security['selection'] as double).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (security['selection'] as double) > 0
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 配置收益
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '配置收益',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${(security['allocation'] as double).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 总收益
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '总收益',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${(security['total'] as double).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 收益分解可视化
              const SizedBox(height: 8),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: Row(
                  children: [
                    // 选择收益部分
                    Expanded(
                      flex: ((security['selection'] as double).abs() * 100)
                          .toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: (security['selection'] as double) > 0
                              ? Colors.green[400]
                              : Colors.red[400],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    // 配置收益部分
                    Expanded(
                      flex: ((security['allocation'] as double).abs() * 100)
                          .toInt(),
                      child: Container(
                        color: Colors.blue[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建交互收益分析
  Widget _buildInteractionAnalysis() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 交互收益概览
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '交互收益贡献',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '-0.25%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 交互效应分析
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '交互效应分析',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 交互效应图表
                  Expanded(
                    child: _buildInteractionChart(),
                  ),

                  const SizedBox(height: 16),

                  // 交互效应说明
                  _buildInteractionExplanation(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建交互效应图表
  Widget _buildInteractionChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 图表标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '基金间相关性热力图',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '负相关',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.yellow[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '低相关',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '高相关',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 模拟热力图
          Expanded(
            child: _buildCorrelationHeatmap(),
          ),
        ],
      ),
    );
  }

  /// 构建相关性热力图
  Widget _buildCorrelationHeatmap() {
    final funds = ['消费', '成长', '蓝筹', '白酒', '中小盘'];
    final correlations = [
      [1.0, 0.6, 0.3, 0.8, 0.7],
      [0.6, 1.0, 0.5, 0.4, 0.9],
      [0.3, 0.5, 1.0, 0.2, 0.6],
      [0.8, 0.4, 0.2, 1.0, 0.5],
      [0.7, 0.9, 0.6, 0.5, 1.0],
    ];

    return Column(
      children: [
        // 列标题
        Row(
          children: funds
              .map((fund) => Expanded(
                    child: Center(
                      child: Text(
                        fund,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),

        // 热力图网格
        ...correlations.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final row = entry.value;

          return Row(
            children: [
              // 行标题
              SizedBox(
                width: 40,
                child: Text(
                  funds[rowIndex],
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),

              // 热力图单元格
              ...row.map((correlation) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      height: 30,
                      decoration: BoxDecoration(
                        color: _getCorrelationColor(correlation),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          correlation.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color:
                                correlation > 0.5 ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          );
        }),
      ],
    );
  }

  /// 获取相关性颜色
  Color _getCorrelationColor(double correlation) {
    if (correlation >= 0.8) return Colors.green[600]!;
    if (correlation >= 0.6) return Colors.green[400]!;
    if (correlation >= 0.4) return Colors.yellow[400]!;
    if (correlation >= 0.2) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  /// 构建交互效应说明
  Widget _buildInteractionExplanation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '交互效应分析',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '基金间存在一定的相关性，导致交互收益为负。建议增加低相关性资产以提高组合的分散化效果。',
            style: TextStyle(
              fontSize: 11,
              color: Colors.red[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建详细分解
  Widget _buildDetailedBreakdown() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总览标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '收益详细分解',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              if (widget.onRefresh != null)
                IconButton(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新分解数据',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 分解数据表格
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildBreakdownTable(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分解表格
  Widget _buildBreakdownTable() {
    final breakdownData = [
      {
        'category': '总收益',
        'value': 3.95,
        'percentage': 100.0,
        'color': Colors.blue
      },
      {
        'category': '资产配置收益',
        'value': 2.35,
        'percentage': 59.5,
        'color': Colors.green
      },
      {
        'category': '个券选择收益',
        'value': 1.85,
        'percentage': 46.8,
        'color': Colors.orange
      },
      {
        'category': '交互收益',
        'value': -0.25,
        'percentage': -6.3,
        'color': Colors.red
      },
    ];

    return Column(
      children: [
        // 表头
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text('收益来源',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(
                  child: Text('收益率',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(
                  child: Text('占比',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),

        // 表格内容
        ...breakdownData.map((data) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                // 类别名称和颜色指示器
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: data['color'] as Color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['category'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 收益率
                Expanded(
                  child: Text(
                    '${(data['value'] as double).toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (data['value'] as double) >= 0
                          ? Colors.green[600]
                          : Colors.red[600],
                    ),
                  ),
                ),

                // 占比
                Expanded(
                  child: Text(
                    '${(data['percentage'] as double).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 获取收益颜色
  Color _getProfitColor(double profitRate) {
    if (profitRate > 0) {
      return Colors.green[600]!;
    } else if (profitRate < 0) {
      return Colors.red[600]!;
    }
    return Colors.grey[600]!;
  }
}
