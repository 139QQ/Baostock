import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/models/fund.dart';

/// 基金风险评估组件
///
/// 展示基金的风险评估信息，包括：
/// - 风险等级评估
/// - 风险指标分析（波动率、最大回撤、夏普比率等）
/// - 风险收益散点图
/// - 历史回撤分析
/// - 风险提示和建议
class FundRiskAssessment extends StatefulWidget {
  final Fund fund;
  final Map<String, dynamic> riskMetrics;

  const FundRiskAssessment({
    super.key,
    required this.fund,
    required this.riskMetrics,
  });

  @override
  State<FundRiskAssessment> createState() => _FundRiskAssessmentState();
}

class _FundRiskAssessmentState extends State<FundRiskAssessment> {
  String _selectedView = '风险指标';

  // 时间周期选项

  // 视图选项
  final List<String> _viewOptions = ['风险指标', '风险收益', '回撤分析', '风险提示'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和控制选项
          Row(
            children: [
              const Text(
                '风险评估',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),

              // 视图选择
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedView,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  items: _viewOptions.map((view) {
                    return DropdownMenuItem<String>(
                      value: view,
                      child: Text(view, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedView = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 内容区域
          _buildContent(),
        ],
      ),
    );
  }

  /// 构建内容
  Widget _buildContent() {
    switch (_selectedView) {
      case '风险指标':
        return _buildRiskIndicators();
      case '风险收益':
        return _buildRiskReturnAnalysis();
      case '回撤分析':
        return _buildDrawdownAnalysis();
      case '风险提示':
        return _buildRiskWarnings();
      default:
        return _buildRiskIndicators();
    }
  }

  /// 构建风险指标
  Widget _buildRiskIndicators() {
    return Column(
      children: [
        // 风险等级卡片
        _buildRiskLevelCard(),

        const SizedBox(height: 16),

        // 关键风险指标
        _buildRiskMetricsCard(),

        const SizedBox(height: 16),

        // 风险指标对比
        _buildRiskComparisonCard(),
      ],
    );
  }

  /// 构建风险等级卡片
  Widget _buildRiskLevelCard() {
    final riskLevel = widget.fund.riskLevel;
    final riskColor = _getRiskLevelColor(riskLevel);
    final riskDescription = _getRiskLevelDescription(riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '风险等级评估',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    riskLevel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 风险描述
            Text(
              riskDescription,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // 风险等级说明
            _buildRiskLevelChart(),
          ],
        ),
      ),
    );
  }

  /// 构建风险等级图表
  Widget _buildRiskLevelChart() {
    final riskLevels = ['R1', 'R2', 'R3', 'R4', 'R5'];
    final currentLevel = widget.fund.riskLevel;
    final currentIndex = riskLevels.indexOf(currentLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '风险等级分布：',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          height: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade300,
                Colors.green,
                Colors.yellow,
                Colors.orange,
                Colors.red,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // 当前位置指示器
              Positioned(
                left: (currentIndex / (riskLevels.length - 1)) *
                    (MediaQuery.of(context).size.width - 32 - 32),
                child: Container(
                  width: 4,
                  height: 16,
                  margin: const EdgeInsets.only(top: -4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // 等级标签
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: riskLevels.map((level) {
            final isCurrent = level == currentLevel;
            return Text(
              level,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? Colors.black : Colors.grey.shade600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建风险指标卡片
  Widget _buildRiskMetricsCard() {
    final volatility = widget.riskMetrics['volatility'] ?? 15.2;
    final maxDrawdown = widget.riskMetrics['maxDrawdown'] ?? -8.5;
    final sharpeRatio = widget.riskMetrics['sharpeRatio'] ?? 1.25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关键风险指标',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 波动率
            _buildRiskMetricRow(
              '年化波动率',
              '${volatility.toStringAsFixed(2)}%',
              _getVolatilityColor(volatility),
              '反映基金收益的波动程度，数值越大风险越高',
            ),

            const SizedBox(height: 12),

            // 最大回撤
            _buildRiskMetricRow(
              '最大回撤',
              '${maxDrawdown.toStringAsFixed(2)}%',
              _getDrawdownColor(maxDrawdown),
              '历史上从最高点到最低点的最大跌幅',
            ),

            const SizedBox(height: 12),

            // 夏普比率
            _buildRiskMetricRow(
              '夏普比率',
              sharpeRatio.toStringAsFixed(2),
              _getSharpeColor(sharpeRatio),
              '衡量单位风险获得的超额收益，数值越大越好',
            ),

            const SizedBox(height: 12),

            // 贝塔系数（如果有）
            if (widget.riskMetrics['beta'] != null)
              _buildRiskMetricRow(
                '贝塔系数',
                widget.riskMetrics['beta'].toStringAsFixed(2),
                _getBetaColor(widget.riskMetrics['beta']),
                '相对于市场的敏感度，大于1表示波动大于市场',
              ),
          ],
        ),
      ),
    );
  }

  /// 构建风险指标行
  Widget _buildRiskMetricRow(
    String label,
    String value,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建风险对比卡片
  Widget _buildRiskComparisonCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '同类基金风险对比',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 对比图表
            SizedBox(
              height: 200,
              child: _buildRiskComparisonChart(),
            ),

            const SizedBox(height: 12),

            // 对比说明
            Text(
              '与同类基金相比，该基金的风险水平处于中等偏上位置，'
              '投资者需要根据自身风险承受能力谨慎投资。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建风险对比图表
  Widget _buildRiskComparisonChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 25,
        barTouchData: BarTouchData(
          enabled: false,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['波动率', '回撤', '夏普', '贝塔'];
                if (value.toInt() < titles.length) {
                  return Text(
                    titles[value.toInt()],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: [
          _makeGroupData(0, 15.2, 12.8, Colors.blue),
          _makeGroupData(1, 8.5, 6.2, Colors.red),
          _makeGroupData(2, 125, 98, Colors.green),
          _makeGroupData(3, 1.1, 0.9, Colors.orange),
        ],
        gridData: FlGridData(
          show: true,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  /// 构建风险收益分析
  Widget _buildRiskReturnAnalysis() {
    return Column(
      children: [
        // 风险收益散点图
        _buildRiskReturnScatterChart(),

        const SizedBox(height: 16),

        // 风险收益分析
        _buildRiskReturnAnalysisCard(),
      ],
    );
  }

  /// 构建风险收益散点图
  Widget _buildRiskReturnScatterChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '风险收益分布',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: _generateStyledScatterSpots(),
                  minX: 0,
                  maxX: 30,
                  minY: -10,
                  maxY: 30,
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    verticalInterval: 5,
                    horizontalInterval: 5,
                  ),
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipItems: (ScatterSpot touchedBarSpot) {
                        return ScatterTooltipItem(
                          '风险: ${touchedBarSpot.x.toStringAsFixed(1)}%\n'
                          '收益: ${touchedBarSpot.y.toStringAsFixed(1)}%',
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '横轴：年化波动率，纵轴：年化收益率。红点表示该基金，蓝点表示同类基金。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建风险收益分析卡片
  Widget _buildRiskReturnAnalysisCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '风险收益分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 该基金位置
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '该基金',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '风险：15.2%，收益：22.3%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 分析结论
            Text(
              '该基金在风险收益坐标系中位于右上区域，说明其承担了相对较高的风险，'
              '但同时也获得了较好的收益表现。适合风险承受能力较强的投资者。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建回撤分析
  Widget _buildDrawdownAnalysis() {
    return Column(
      children: [
        // 历史最大回撤
        _buildMaxDrawdownCard(),

        const SizedBox(height: 16),

        // 回撤恢复时间
        _buildRecoveryTimeCard(),

        const SizedBox(height: 16),

        // 回撤频率分析
        _buildDrawdownFrequencyCard(),
      ],
    );
  }

  /// 构建最大回撤卡片
  Widget _buildMaxDrawdownCard() {
    final maxDrawdown = widget.riskMetrics['maxDrawdown'] ?? -8.5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '历史最大回撤',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${maxDrawdown.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '最大回撤',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '中等',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        '风险水平',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '发生在2022年3月-4月期间，主要受市场整体下跌影响。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建恢复时间卡片
  Widget _buildRecoveryTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '回撤恢复分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRecoveryMetric(
                  '平均恢复时间',
                  '45天',
                  Colors.blue,
                ),
                _buildRecoveryMetric(
                  '最长恢复时间',
                  '120天',
                  Colors.red,
                ),
                _buildRecoveryMetric(
                  '恢复成功率',
                  '95%',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '该基金在遭遇回撤后，通常能在1-2个月内恢复至前期高点，'
              '显示出较强的抗风险能力和恢复能力。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建回撤频率卡片
  Widget _buildDrawdownFrequencyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '回撤频率分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 回撤区间分布
            _buildDrawdownRangeDistribution(),

            const SizedBox(height: 16),

            // 结论
            Text(
              '该基金大部分时间的回撤控制在5%以内，'
              '深度回撤（超过10%）的发生概率较低，整体风险控制较为良好。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建回撤区间分布
  Widget _buildDrawdownRangeDistribution() {
    final ranges = [
      {'range': '0-5%', 'count': 180, 'percentage': 60},
      {'range': '5-10%', 'count': 90, 'percentage': 30},
      {'range': '10-15%', 'count': 24, 'percentage': 8},
      {'range': '>15%', 'count': 6, 'percentage': 2},
    ];

    return Column(
      children: ranges.map((range) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  range['range'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: (range['percentage'] as int) / 100,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getRangeColor(range['range'] as String),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Text(
                  '${range['percentage']}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getRangeColor(range['range'] as String),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建风险提示
  Widget _buildRiskWarnings() {
    return Column(
      children: [
        // 风险提示卡片
        _buildRiskWarningCard(),

        const SizedBox(height: 16),

        // 适合投资者类型
        _buildSuitableInvestorCard(),

        const SizedBox(height: 16),

        // 投资建议
        _buildInvestmentAdviceCard(),
      ],
    );
  }

  /// 构建风险提示卡片
  Widget _buildRiskWarningCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '风险提示',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildWarningItem(
              '市场风险',
              '基金投资可能受到市场整体下跌的影响，存在本金损失的风险。',
            ),
            SizedBox(height: 8),
            _buildWarningItem(
              '流动性风险',
              '在极端市场情况下，基金可能面临赎回压力，影响净值表现。',
            ),
            SizedBox(height: 8),
            _buildWarningItem(
              '管理风险',
              '基金经理的投资决策可能与市场走势不一致，影响基金业绩。',
            ),
            SizedBox(height: 8),
            _buildWarningItem(
              '信用风险',
              '基金投资的债券等固定收益品种可能存在违约风险。',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建适合投资者类型卡片
  Widget _buildSuitableInvestorCard() {
    final riskLevel = widget.fund.riskLevel;
    final investorTypes = _getSuitableInvestorTypes(riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '适合投资者类型',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            ...investorTypes.map((type) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 12),

            // 不适合的投资者
            Text(
              '不适合风险承受能力较低的投资者，如保守型投资者。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建投资建议卡片
  Widget _buildInvestmentAdviceCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '投资建议',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildAdviceItem(
              '分散投资',
              '建议将本基金作为投资组合的一部分，不要将全部资金投入单一基金。',
            ),
            SizedBox(height: 8),
            _buildAdviceItem(
              '长期持有',
              '该基金适合长期投资策略，短期波动较大，建议持有期不少于1年。',
            ),
            SizedBox(height: 8),
            _buildAdviceItem(
              '定期评估',
              '定期关注基金表现和市场变化，必要时调整投资策略。',
            ),
            SizedBox(height: 8),
            _buildAdviceItem(
              '理性投资',
              '不要盲目追涨杀跌，保持理性投资心态。',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建警告项
  Widget _buildWarningItem(String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6, right: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建建议项
  Widget _buildAdviceItem(String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6, right: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建恢复时间指标
  Widget _buildRecoveryMetric(String label, String value, Color color) {
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

  /// 生成样式化的散点图数据（新版 fl_chart API）
  List<ScatterSpot> _generateStyledScatterSpots() {
    final spots = <ScatterSpot>[
      // 同类基金数据（模拟）
      ScatterSpot(12.5, 18.2),
      ScatterSpot(18.3, 15.7),
      ScatterSpot(15.2, 22.1),
      ScatterSpot(20.1, 12.4),
      ScatterSpot(10.8, 25.6),
      ScatterSpot(22.4, 8.9),
      ScatterSpot(16.7, 19.3),
      ScatterSpot(14.9, 16.8),
      ScatterSpot(19.5, 14.2),
      ScatterSpot(13.2, 21.7),
      ScatterSpot(17.8, 17.4),
      ScatterSpot(11.6, 23.9),
      ScatterSpot(21.3, 11.5),
      ScatterSpot(15.7, 18.6),
      ScatterSpot(18.9, 13.8),

      // 该基金（红点）- 最后一个点特殊处理
      ScatterSpot(15.2, 22.3),
    ];

    return spots;
  }

  /// 创建柱状图数据
  BarChartGroupData _makeGroupData(int x, double y1, double y2, Color color) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: y2,
          color: color.withOpacity(0.5),
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  /// 获取风险等级颜色
  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'R1':
        return Colors.green;
      case 'R2':
        return Colors.lightGreen;
      case 'R3':
        return Colors.orange;
      case 'R4':
        return Colors.deepOrange;
      case 'R5':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 获取风险等级描述
  String _getRiskLevelDescription(String riskLevel) {
    switch (riskLevel) {
      case 'R1':
        return '低风险等级，投资标的以货币市场工具、国债等安全性极高的资产为主，本金损失的可能性极低。';
      case 'R2':
        return '中低风险等级，投资标的以高等级债券、银行存款等稳健资产为主，本金损失的可能性较低。';
      case 'R3':
        return '中等风险等级，投资组合相对均衡，可能包含一定比例的股票等风险资产，存在一定的本金损失风险。';
      case 'R4':
        return '中高风险等级，投资组合以股票等权益类资产为主，本金损失的可能性较大，适合风险承受能力较强的投资者。';
      case 'R5':
        return '高风险等级，投资标的波动性大，本金损失的可能性很高，仅适合风险承受能力极强的投资者。';
      default:
        return '风险等级未知，请咨询专业投资顾问。';
    }
  }

  /// 获取波动率颜色
  Color _getVolatilityColor(double volatility) {
    if (volatility < 10) return Colors.green;
    if (volatility < 15) return Colors.orange;
    if (volatility < 20) return Colors.deepOrange;
    return Colors.red;
  }

  /// 获取回撤颜色
  Color _getDrawdownColor(double drawdown) {
    if (drawdown > -5) return Colors.green;
    if (drawdown > -10) return Colors.orange;
    if (drawdown > -15) return Colors.deepOrange;
    return Colors.red;
  }

  /// 获取夏普比率颜色
  Color _getSharpeColor(double sharpe) {
    if (sharpe > 2.0) return Colors.green;
    if (sharpe > 1.0) return Colors.orange;
    if (sharpe > 0.5) return Colors.deepOrange;
    return Colors.red;
  }

  /// 获取贝塔系数颜色
  Color _getBetaColor(double beta) {
    if (beta < 0.8) return Colors.green;
    if (beta < 1.2) return Colors.orange;
    return Colors.red;
  }

  /// 获取适合投资者类型
  List<String> _getSuitableInvestorTypes(String riskLevel) {
    switch (riskLevel) {
      case 'R1':
        return [
          '保守型投资者',
          '稳健型投资者',
          '谨慎型投资者',
        ];
      case 'R2':
        return [
          '稳健型投资者',
          '谨慎型投资者',
          '平衡型投资者',
        ];
      case 'R3':
        return [
          '平衡型投资者',
          '成长型投资者',
          '有一定投资经验的投资者',
        ];
      case 'R4':
        return [
          '成长型投资者',
          '积极型投资者',
          '有丰富投资经验的投资者',
        ];
      case 'R5':
        return [
          '积极型投资者',
          '激进型投资者',
          '专业投资者',
        ];
      default:
        return [
          '有一定风险承受能力的投资者',
        ];
    }
  }

  /// 获取区间颜色
  Color _getRangeColor(String range) {
    if (range.contains('0-5')) return Colors.green;
    if (range.contains('5-10')) return Colors.orange;
    if (range.contains('10-15')) return Colors.deepOrange;
    return Colors.red;
  }
}
