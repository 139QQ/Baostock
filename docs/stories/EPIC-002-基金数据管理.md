# EPIC-002: 基金数据管理

## 📊 史诗概述

**史诗目标**: 构建完整的基金数据管理系统，实现基金信息的获取、展示、搜索和筛选功能，为用户提供全面的基金数据访问能力。

**商业价值**:
- 数据基础: 为用户提供全面准确的基金数据
- 用户价值: 满足用户基础的数据查询需求
- 竞争优势: 提供更丰富、更准确的基金信息
- 业务支撑: 为后续分析功能提供数据支撑

**开发时间**: 6周
**团队规模**: 4-5人
**依赖关系**: EPIC-001 (基础架构建设)

---

## 📋 用户故事详细列表

### 📈 基金信息展示

#### US-002.1: 实现基金基本信息展示

**用户故事**: 作为投资者，我希望能够查看基金的基本信息，包括基金名称、代码、类型、公司等核心信息，以便快速了解基金概况。

**优先级**: P0
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-001.1, US-001.9

**验收标准**:
- [ ] 基金基本信息完整展示
- [ ] 数据准确性和实时性
- [ ] 响应时间≤500ms
- [ ] 支持10,000+基金数据展示
- [ ] 数据更新延迟≤5分钟

**技术要点**:
```dart
// 基金信息展示组件
class FundInfoWidget extends StatelessWidget {
  final Fund fund;

  const FundInfoWidget({super.key, required this.fund});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFundHeader(),
            const SizedBox(height: 12),
            _buildFundDetails(),
            const SizedBox(height: 12),
            _buildFundMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildFundHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fund.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${fund.code} | ${fund.type}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        FundRiskIndicator(riskLevel: fund.riskLevel),
      ],
    );
  }

  Widget _buildFundDetails() {
    return Column(
      children: [
        _buildDetailRow('基金公司', fund.company),
        _buildDetailRow('成立日期',
          DateFormat('yyyy-MM-dd').format(fund.establishedDate)),
        if (fund.minInvestment != null)
          _buildDetailRow('最低投资', '¥${fund.minInvestment}'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundMetrics() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('单位净值', '¥${fund.nav.toStringAsFixed(4)}'),
          _buildMetric('净值日期',
            DateFormat('MM-dd').format(fund.navDate)),
          _buildMetric('日涨跌', _calculateDailyChange()),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _calculateDailyChange() {
    // 计算日涨跌幅
    // TODO: 实现涨跌幅计算逻辑
    return '+0.00%';
  }
}

// 风险指示器
class FundRiskIndicator extends StatelessWidget {
  final String? riskLevel;

  const FundRiskIndicator({super.key, this.riskLevel});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (riskLevel?.toLowerCase()) {
      case 'low':
      case '低风险':
        color = Colors.green;
        text = '低风险';
        break;
      case 'medium':
      case '中风险':
        color = Colors.orange;
        text = '中风险';
        break;
      case 'high':
      case '高风险':
        color = Colors.red;
        text = '高风险';
        break;
      default:
        color = Colors.grey;
        text = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
```

**API接口**:
```dart
// 基金API服务扩展
class FundApiService {
  // ... 其他方法

  Future<List<Fund>> getFundList({
    int page = 1,
    int size = 20,
    String? type,
    String? company,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/funds',
        queryParameters: {
          'page': page,
          'size': size,
          if (type != null) 'type': type,
          if (company != null) 'company': company,
          if (sortBy != null) 'sort_by': sortBy,
          'order': ascending ? 'asc' : 'desc',
        },
      );

      final funds = response.data!
          .map((json) => Fund.fromJson(json as Map<String, dynamic>))
          .toList();

      return funds;
    } on DioException catch (e) {
      throw _handleApiException(e);
    }
  }

  Future<Fund?> getFundByCode(String fundCode) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/funds/code/$fundCode',
      );

      return Fund.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleApiException(e);
    }
  }
}
```

**测试要点**:
- 数据展示完整性
- 不同基金类型兼容性
- 异常数据处理
- 性能基准测试

---

#### US-002.2: 开发基金净值历史数据展示

**用户故事**: 作为投资者，我希望查看基金的历史净值走势，以便分析基金的历史表现和趋势。

**优先级**: P0
**复杂度**: 中
**预估工期**: 4天
**依赖关系**: US-002.1

**验收标准**:
- [ ] 历史净值数据完整展示
- [ ] 支持不同时间范围查看 (1月/3月/6月/1年/全部)
- [ ] 图表交互流畅，支持缩放和滑动
- [ ] 净值数据准确，更新及时
- [ ] 支持净值数据导出

**技术实现**:
```dart
// 基金净值图表组件
class FundNavChartWidget extends StatefulWidget {
  final String fundCode;
  final List<FundNavData> navData;

  const FundNavChartWidget({
    super.key,
    required this.fundCode,
    required this.navData,
  });

  @override
  State<FundNavChartWidget> createState() => _FundNavChartWidgetState();
}

class _FundNavChartWidgetState extends State<FundNavChartWidget> {
  ChartTimeRange _timeRange = ChartTimeRange.threeMonths;
  bool _showGrid = true;
  bool _showVolume = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildChartHeader(),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 16),
            _buildChartControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader() {
    final filteredData = _getFilteredData();
    final performance = _calculatePerformance(filteredData);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '净值走势',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '期间收益: ${performance.periodReturn}',
              style: TextStyle(
                fontSize: 14,
                color: performance.periodReturn.startsWith('+')
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          '${DateFormat('yyyy-MM-dd').format(filteredData.first.date)} - '
          '${DateFormat('yyyy-MM-dd').format(filteredData.last.date)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final filteredData = _getFilteredData();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: _showGrid ? FlGridData(show: true) : FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _calculateDateInterval(filteredData),
                getTitlesWidget: (value, meta) {
                  final date = filteredData[value.toInt()].date;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: filteredData
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.nav))
                  .toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
              ),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final data = filteredData[spot.spotIndex.toInt()];
                  return LineTooltipItem(
                    '${DateFormat('yyyy-MM-dd').format(data.date)}\n'
                    '净值: ¥${data.nav.toStringAsFixed(4)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          minY: _calculateMinY(filteredData),
          maxY: _calculateMaxY(filteredData),
        ),
      ),
    );
  }

  Widget _buildChartControls() {
    return Column(
      children: [
        Row(
          children: [
            const Text('时间范围: '),
            ...ChartTimeRange.values.map((range) {
              final isSelected = _timeRange == range;
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: FilterChip(
                  label: Text(range.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _timeRange = range;
                      });
                    }
                  },
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Switch(
              value: _showGrid,
              onChanged: (value) {
                setState(() {
                  _showGrid = value;
                });
              },
            ),
            const Text('显示网格'),
            const SizedBox(width: 16),
            Switch(
              value: _showVolume,
              onChanged: (value) {
                setState(() {
                  _showVolume = value;
                });
              },
            ),
            const Text('显示成交量'),
          ],
        ),
      ],
    );
  }

  List<FundNavData> _getFilteredData() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_timeRange) {
      case ChartTimeRange.oneMonth:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case ChartTimeRange.threeMonths:
        startDate = now.subtract(const Duration(days: 90));
        break;
      case ChartTimeRange.sixMonths:
        startDate = now.subtract(const Duration(days: 180));
        break;
      case ChartTimeRange.oneYear:
        startDate = now.subtract(const Duration(days: 365));
        break;
      case ChartTimeRange.all:
        return widget.navData;
    }

    return widget.navData
        .where((data) => data.date.isAfter(startDate))
        .toList();
  }

  double _calculateDateInterval(List<FundNavData> data) {
    if (data.length <= 20) return 1;
    if (data.length <= 50) return 3;
    if (data.length <= 100) return 5;
    return 10;
  }

  double _calculateMinY(List<FundNavData> data) {
    final minNav = data.map((d) => d.nav).reduce(math.min);
    return minNav * 0.995;
  }

  double _calculateMaxY(List<FundNavData> data) {
    final maxNav = data.map((d) => d.nav).reduce(math.max);
    return maxNav * 1.005;
  }

  FundPerformance _calculatePerformance(List<FundNavData> data) {
    if (data.length < 2) {
      return FundPerformance(periodReturn: '0.00%', annualizedReturn: '0.00%');
    }

    final startNav = data.first.nav;
    final endNav = data.last.nav;
    final totalReturn = (endNav - startNav) / startNav;

    final days = data.last.date.difference(data.first.date).inDays;
    final annualizedReturn = math.pow(1 + totalReturn, 365 / days) - 1;

    return FundPerformance(
      periodReturn: '${(totalReturn * 100).toStringAsFixed(2)}%',
      annualizedReturn: '${(annualizedReturn * 100).toStringAsFixed(2)}%',
    );
  }
}

// 图表时间范围枚举
enum ChartTimeRange {
  oneMonth('1个月'),
  threeMonths('3个月'),
  sixMonths('6个月'),
  oneYear('1年'),
  all('全部');

  const ChartTimeRange(this.label);
  final String label;
}

// 基金净值数据模型
class FundNavData {
  final DateTime date;
  final double nav;
  final double? accumNav;
  final double? dailyReturn;

  FundNavData({
    required this.date,
    required this.nav,
    this.accumNav,
    this.dailyReturn,
  });

  factory FundNavData.fromJson(Map<String, dynamic> json) {
    return FundNavData(
      date: DateTime.parse(json['date'] as String),
      nav: (json['nav'] as num).toDouble(),
      accumNav: (json['accum_nav'] as num?)?.toDouble(),
      dailyReturn: (json['daily_return'] as num?)?.toDouble(),
    );
  }
}

// 基金业绩数据
class FundPerformance {
  final String periodReturn;
  final String annualizedReturn;

  FundPerformance({
    required this.periodReturn,
    required this.annualizedReturn,
  });
}
```

**测试要点**:
- 图表渲染性能
- 数据准确性
- 用户交互流畅性
- 不同时间范围切换

---

#### US-002.3: 实现基金收益率统计分析

**用户故事**: 作为投资者，我希望查看基金的收益率统计和分析，包括不同时间段的收益率、风险指标等，以便评估基金的业绩表现。

**优先级**: P1
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-002.2

**验收标准**:
- [ ] 收益率统计准确完整
- [ ] 支持多种收益率指标 (累计收益、年化收益等)
- [ ] 风险指标计算准确
- [ ] 与同类基金对比功能
- [ ] 收益率数据可视化

**实现方案**:
```dart
// 基金收益率统计组件
class FundReturnStatsWidget extends StatelessWidget {
  final FundReturnStats stats;
  final List<FundReturnStats>? benchmarkStats;

  const FundReturnStatsWidget({
    super.key,
    required this.stats,
    this.benchmarkStats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '收益率统计',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildReturnGrid(),
            if (benchmarkStats != null) ...[
              const SizedBox(height: 20),
              _buildBenchmarkComparison(),
            ],
            const SizedBox(height: 20),
            _buildRiskMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildReturnCard('近1月', stats.oneMonthReturn),
        _buildReturnCard('近3月', stats.threeMonthReturn),
        _buildReturnCard('近6月', stats.sixMonthReturn),
        _buildReturnCard('近1年', stats.oneYearReturn),
        _buildReturnCard('近3年', stats.threeYearReturn),
        _buildReturnCard('成立来', stats.sinceInceptionReturn),
      ],
    );
  }

  Widget _buildReturnCard(String period, double? returnValue) {
    final displayValue = returnValue != null
        ? '${returnValue >= 0 ? '+' : ''}${(returnValue * 100).toStringAsFixed(2)}%'
        : '--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            period,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: returnValue != null && returnValue >= 0
                  ? Colors.green
                  : returnValue != null
                      ? Colors.red
                      : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkComparison() {
    if (benchmarkStats == null || benchmarkStats!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '同类基金对比',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...['oneMonthReturn', 'threeMonthReturn', 'sixMonthReturn', 'oneYearReturn']
            .map((period) => _buildBenchmarkRow(period)),
      ],
    );
  }

  Widget _buildBenchmarkRow(String periodField) {
    final periodLabels = {
      'oneMonthReturn': '近1月',
      'threeMonthReturn': '近3月',
      'sixMonthReturn': '近6月',
      'oneYearReturn': '近1年',
    };

    final fundReturn = _getReturnValue(stats, periodField);
    final avgReturn = _getBenchmarkAverage(periodField);
    final rank = _getRank(periodField);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(periodLabels[periodField]!),
          ),
          Expanded(
            child: _buildReturnComparisonBar(fundReturn, avgReturn),
          ),
          const SizedBox(width: 12),
          _buildRankBadge(rank),
        ],
      ),
    );
  }

  Widget _buildReturnComparisonBar(double? fundReturn, double? avgReturn) {
    if (fundReturn == null || avgReturn == null) {
      return const Text('数据不足');
    }

    final diff = fundReturn - avgReturn;
    final maxDiff = 0.1; // 最大差异10%

    return Container(
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[200],
      ),
      child: FractionallySizedBox(
        alignment: diff >= 0 ? Alignment.centerLeft : Alignment.centerRight,
        widthFactor: (diff.abs() / maxDiff).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: diff >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    if (rank <= 10) {
      color = Colors.green;
    } else if (rank <= 50) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '前$rank%',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRiskMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '风险指标',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildRiskMetricRow('最大回撤', '${(stats.maxDrawdown * 100).toStringAsFixed(2)}%'),
        _buildRiskMetricRow('夏普比率', stats.sharpeRatio.toStringAsFixed(2)),
        _buildRiskMetricRow('波动率', '${(stats.volatility * 100).toStringAsFixed(2)}%'),
        _buildRiskMetricRow('Beta系数', stats.beta.toStringAsFixed(2)),
      ],
    );
  }

  Widget _buildRiskMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double? _getReturnValue(FundReturnStats stats, String field) {
    switch (field) {
      case 'oneMonthReturn':
        return stats.oneMonthReturn;
      case 'threeMonthReturn':
        return stats.threeMonthReturn;
      case 'sixMonthReturn':
        return stats.sixMonthReturn;
      case 'oneYearReturn':
        return stats.oneYearReturn;
      default:
        return null;
    }
  }

  double? _getBenchmarkAverage(String field) {
    if (benchmarkStats == null || benchmarkStats!.isEmpty) return null;

    double sum = 0;
    int count = 0;

    for (final stat in benchmarkStats!) {
      final value = _getReturnValue(stat, field);
      if (value != null) {
        sum += value;
        count++;
      }
    }

    return count > 0 ? sum / count : null;
  }

  int _getRank(String field) {
    if (benchmarkStats == null || benchmarkStats!.isEmpty) return 50;

    final fundReturn = _getReturnValue(stats, field);
    if (fundReturn == null) return 50;

    int betterCount = 0;
    for (final stat in benchmarkStats!) {
      final benchmarkReturn = _getReturnValue(stat, field);
      if (benchmarkReturn != null && fundReturn > benchmarkReturn) {
        betterCount++;
      }
    }

    return ((betterCount / benchmarkStats!.length) * 100).round();
  }
}

// 基金收益率统计数据模型
class FundReturnStats {
  final String fundCode;
  final String fundName;
  final double? oneMonthReturn;
  final double? threeMonthReturn;
  final double? sixMonthReturn;
  final double? oneYearReturn;
  final double? threeYearReturn;
  final double? sinceInceptionReturn;
  final double maxDrawdown;
  final double sharpeRatio;
  final double volatility;
  final double beta;

  FundReturnStats({
    required this.fundCode,
    required this.fundName,
    this.oneMonthReturn,
    this.threeMonthReturn,
    this.sixMonthReturn,
    this.oneYearReturn,
    this.threeYearReturn,
    this.sinceInceptionReturn,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.volatility,
    required this.beta,
  });

  factory FundReturnStats.fromJson(Map<String, dynamic> json) {
    return FundReturnStats(
      fundCode: json['fund_code'] as String,
      fundName: json['fund_name'] as String,
      oneMonthReturn: (json['one_month_return'] as num?)?.toDouble(),
      threeMonthReturn: (json['three_month_return'] as num?)?.toDouble(),
      sixMonthReturn: (json['six_month_return'] as num?)?.toDouble(),
      oneYearReturn: (json['one_year_return'] as num?)?.toDouble(),
      threeYearReturn: (json['three_year_return'] as num?)?.toDouble(),
      sinceInceptionReturn: (json['since_inception_return'] as num?)?.toDouble(),
      maxDrawdown: (json['max_drawdown'] as num).toDouble(),
      sharpeRatio: (json['sharpe_ratio'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      beta: (json['beta'] as num).toDouble(),
    );
  }
}
```

**测试要点**:
- 收益率计算准确性
- 风险指标计算
- 同类对比数据
- 数据可视化效果

---

#### US-002.4: 开发基金分红记录展示

**用户故事**: 作为投资者，我希望查看基金的分红记录，包括分红金额、分红日期、分红方式等信息，以便了解基金的分红历史。

**优先级**: P1
**复杂度**: 低
**预估工期**: 2天
**依赖关系**: US-002.1

**验收标准**:
- [ ] 分红记录完整展示
- [ ] 分红信息准确及时
- [ ] 支持分红数据导出
- [ ] 分红统计分析
- [ ] 分红提醒功能

**实现方案**:
```dart
// 基金分红记录组件
class FundDividendWidget extends StatelessWidget {
  final String fundCode;
  final List<FundDividend> dividends;

  const FundDividendWidget({
    super.key,
    required this.fundCode,
    required this.dividends,
  });

  @override
  Widget build(BuildContext context) {
    if (dividends.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDividendHeader(),
            const SizedBox(height: 16),
            _buildDividendSummary(),
            const SizedBox(height: 16),
            _buildDividendList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无分红记录',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividendHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '分红记录',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton.icon(
          onPressed: () {
            // 导出分红记录
          },
          icon: const Icon(Icons.download, size: 16),
          label: const Text('导出'),
        ),
      ],
    );
  }

  Widget _buildDividendSummary() {
    final totalAmount = dividends.fold<double>(
        0, (sum, dividend) => sum + dividend.amountPerUnit);
    final dividendCount = dividends.length;
    final latestDividend = dividends.first; // 假设已按日期倒序排列

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('累计分红', '¥${totalAmount.toStringAsFixed(4)}'),
          _buildSummaryItem('分红次数', '$dividendCount次'),
          _buildSummaryItem('最近分红',
            DateFormat('yyyy-MM-dd').format(latestDividend.exDate)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDividendList() {
    return Column(
      children: [
        _buildListHeader(),
        const SizedBox(height: 8),
        ...dividends.map((dividend) => _buildDividendItem(dividend)),
      ],
    );
  }

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('权益登记日', style: TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text('除息日', style: TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text('派息日', style: TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text('每份分红', style: TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text('分红方式', style: TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDividendItem(FundDividend dividend) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(DateFormat('yyyy-MM-dd').format(dividend.recordDate))),
          Expanded(flex: 3, child: Text(DateFormat('yyyy-MM-dd').format(dividend.exDate))),
          Expanded(flex: 3, child: Text(DateFormat('yyyy-MM-dd').format(dividend.payDate))),
          Expanded(
            flex: 2,
            child: Text(
              '¥${dividend.amountPerUnit.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getDividendTypeLabel(dividend.type),
              style: TextStyle(
                color: _getDividendTypeColor(dividend.type),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDividendTypeLabel(DividendType type) {
    switch (type) {
      case DividendType.cash:
        return '现金分红';
      case DividendType.reinvest:
        return '红利再投';
    }
  }

  Color _getDividendTypeColor(DividendType type) {
    switch (type) {
      case DividendType.cash:
        return Colors.blue;
      case DividendType.reinvest:
        return Colors.green;
    }
  }
}

// 基金分红数据模型
class FundDividend {
  final String fundCode;
  final DateTime recordDate;
  final DateTime exDate;
  final DateTime payDate;
  final double amountPerUnit;
  final DividendType type;
  final double? netAssetValue;

  FundDividend({
    required this.fundCode,
    required this.recordDate,
    required this.exDate,
    required this.payDate,
    required this.amountPerUnit,
    required this.type,
    this.netAssetValue,
  });

  factory FundDividend.fromJson(Map<String, dynamic> json) {
    return FundDividend(
      fundCode: json['fund_code'] as String,
      recordDate: DateTime.parse(json['record_date'] as String),
      exDate: DateTime.parse(json['ex_date'] as String),
      payDate: DateTime.parse(json['pay_date'] as String),
      amountPerUnit: (json['amount_per_unit'] as num).toDouble(),
      type: DividendType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DividendType.cash,
      ),
      netAssetValue: (json['net_asset_value'] as num?)?.toDouble(),
    );
  }

  // 按日期倒序排列
  static int compareByDate(FundDividend a, FundDividend b) {
    return b.recordDate.compareTo(a.recordDate);
  }
}

// 分红类型枚举
enum DividendType {
  cash,
  reinvest,
}
```

**测试要点**:
- 分红数据展示完整性
- 日期格式化正确性
- 分红统计准确性
- 导出功能正常

---

### 🔍 基金搜索功能

#### US-002.5: 实现基金代码和名称搜索

**用户故事**: 作为投资者，我希望能够通过基金代码或名称快速搜索基金，以便快速找到感兴趣的基金产品。

**优先级**: P0
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-002.1

**验收标准**:
- [ ] 支持基金代码精确搜索
- [ ] 支持基金名称模糊搜索
- [ ] 搜索响应时间≤300ms
- [ ] 搜索结果准确率≥95%
- [ ] 搜索历史记录管理

**实现方案**:
```dart
// 基金搜索组件
class FundSearchWidget extends StatefulWidget {
  final Function(Fund) onFundSelected;
  final List<String>? recentSearches;

  const FundSearchWidget({
    super.key,
    required this.onFundSelected,
    this.recentSearches,
  });

  @override
  State<FundSearchWidget> createState() => _FundSearchWidgetState();
}

class _FundSearchWidgetState extends State<FundSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<FundSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  Timer? _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final fundApiService = FundApiService(ApiClient());
      final results = await fundApiService.searchFunds(query.trim());

      setState(() {
        _searchResults = results.take(20).toList(); // 限制显示20个结果
        _isSearching = false;
      });

      // 保存搜索历史
      if (results.isNotEmpty) {
        await _saveSearchHistory(query.trim());
      }

    } catch (e) {
      setState(() {
        _errorMessage = _getSearchErrorMessage(e);
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    final databaseService = DatabaseService();
    await databaseService.addToSearchHistory(query);
  }

  String _getSearchErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return '搜索失败，请稍后重试';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: const InputDecoration(
          hintText: '搜索基金代码或名称',
          prefixIcon: Icon(Icons.search, size: 20),
          suffixIcon: Icon(Icons.mic, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        autofocus: true,
        onSubmitted: (value) {
          _performSearch(value);
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_searchController.text.trim().isEmpty) {
      return _buildEmptySearchState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildSearchResults();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('搜索中...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _performSearch(_searchController.text);
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.recentSearches != null && widget.recentSearches!.isNotEmpty)
            _buildRecentSearches(),
          const SizedBox(height: 24),
          _buildHotSearches(),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '最近搜索',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // 清空搜索历史
              },
              child: const Text('清空'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.recentSearches!.take(10).map((query) {
            return ActionChip(
              label: Text(query),
              onPressed: () {
                _searchController.text = query;
                _performSearch(query);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHotSearches() {
    // 这里可以从服务器获取热门搜索词
    final hotSearches = [
      '易方达蓝筹精选',
      '汇添富价值精选',
      '兴全合润',
      '富国天惠',
      '中欧时代先锋',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '热门搜索',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hotSearches.map((query) {
            return ActionChip(
              label: Text(query),
              onPressed: () {
                _searchController.text = query;
                _performSearch(query);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '未找到相关基金',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请尝试其他关键词',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultItem(result);
      },
    );
  }

  Widget _buildSearchResultItem(FundSearchResult result) {
    return InkWell(
      onTap: () {
        widget.onFundSelected(result.fund);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.fund.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.fund.code} | ${result.fund.type}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    result.matchType.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (result.highlightText != null) ...[
              const SizedBox(height: 8),
              Text(
                result.highlightText!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 基金搜索结果模型
class FundSearchResult {
  final Fund fund;
  final MatchType matchType;
  final String? highlightText;

  FundSearchResult({
    required this.fund,
    required this.matchType,
    this.highlightText,
  });

  factory FundSearchResult.fromJson(Map<String, dynamic> json) {
    return FundSearchResult(
      fund: Fund.fromJson(json['fund'] as Map<String, dynamic>),
      matchType: MatchType.values.firstWhere(
        (e) => e.name == json['match_type'],
        orElse: () => MatchType.name,
      ),
      highlightText: json['highlight_text'] as String?,
    );
  }
}

// 匹配类型枚举
enum MatchType {
  code,
  name,
  company,
  type;

  String get label {
    switch (this) {
      case MatchType.code:
        return '代码匹配';
      case MatchType.name:
        return '名称匹配';
      case MatchType.company:
        return '公司匹配';
      case MatchType.type:
        return '类型匹配';
    }
  }
}

// API服务扩展
extension FundApiServiceSearch on FundApiService {
  Future<List<FundSearchResult>> searchFunds(String query) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/funds/search',
        queryParameters: {'q': query, 'limit': 50},
      );

      return response.data!
          .map((json) => FundSearchResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleApiException(e);
    }
  }
}
```

**测试要点**:
- 搜索功能准确性
- 搜索响应时间
- 搜索历史管理
- 错误处理机制

---

#### US-002.6: 开发智能搜索和联想功能

**用户故事**: 作为投资者，我希望在输入搜索关键词时能够看到智能联想和建议，以便更快地找到目标基金。

**优先级**: P1
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-002.5

**验收标准**:
- [ ] 实时搜索联想功能
- [ ] 拼音搜索支持
- [ ] 智能纠错建议
- [ ] 搜索预测准确
- [ ] 联想响应时间≤200ms

**实现方案**:
```dart
// 智能搜索组件
class SmartSearchWidget extends StatefulWidget {
  final Function(Fund) onFundSelected;

  const SmartSearchWidget({
    super.key,
    required this.onFundSelected,
  });

  @override
  State<SmartSearchWidget> createState() => _SmartSearchWidgetState();
}

class _SmartSearchWidgetState extends State<SmartSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<SearchSuggestion> _suggestions = [];
  bool _isSuggestionsLoading = false;
  OverlayEntry? _suggestionsOverlay;
  Timer? _suggestionDebouncer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeSuggestionsOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _suggestionDebouncer?.cancel();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final text = _searchController.text;

    _suggestionDebouncer?.cancel();
    _suggestionDebouncer = Timer(const Duration(milliseconds: 200), () {
      if (text.isNotEmpty) {
        _loadSuggestions(text);
      } else {
        _hideSuggestions();
      }
    });
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _loadSuggestions(_searchController.text);
    } else {
      _hideSuggestions();
    }
  }

  Future<void> _loadSuggestions(String query) async {
    if (query.length < 1) {
      _hideSuggestions();
      return;
    }

    setState(() {
      _isSuggestionsLoading = true;
    });

    try {
      final suggestionService = SearchSuggestionService(ApiClient());
      final suggestions = await suggestionService.getSuggestions(query);

      setState(() {
        _suggestions = suggestions;
        _isSuggestionsLoading = false;
      });

      _showSuggestions();

    } catch (e) {
      setState(() {
        _isSuggestionsLoading = false;
        _suggestions = [];
      });
      _hideSuggestions();
    }
  }

  void _showSuggestions() {
    if (_suggestions.isEmpty) return;

    _removeSuggestionsOverlay();

    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _suggestionsOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return _buildSuggestionItem(suggestion);
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_suggestionsOverlay!);
  }

  void _hideSuggestions() {
    _removeSuggestionsOverlay();
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }

  Widget _buildSuggestionItem(SearchSuggestion suggestion) {
    return InkWell(
      onTap: () {
        _searchController.text = suggestion.text;
        widget.onFundSelected(suggestion.fund!);
        _hideSuggestions();
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Icon(
              suggestion.type.icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: _buildHighlightedText(
                        suggestion.displayText,
                        suggestion.matchRanges,
                      ),
                    ),
                  ),
                  if (suggestion.description != null)
                    Text(
                      suggestion.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (suggestion.type == SuggestionType.correction)
              Icon(
                Icons.auto_fix_high,
                size: 16,
                color: Colors.blue[600],
              ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(String text, List<TextRange> matchRanges) {
    if (matchRanges.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final range in matchRanges) {
      if (range.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, range.start)));
      }

      spans.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastEnd = range.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          if (_isSuggestionsLoading)
            const LinearProgressIndicator(),
          Expanded(
            child: _buildSearchContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: '输入基金代码、名称或拼音',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _hideSuggestions();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.mic, size: 20),
                onPressed: () {
                  // 语音搜索
                },
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        autofocus: true,
      ),
    );
  }

  Widget _buildSearchContent() {
    // 显示搜索结果或其他内容
    return Container(); // 占位符
  }
}

// 搜索建议服务
class SearchSuggestionService {
  final ApiClient _apiClient;

  SearchSuggestionService(this._apiClient);

  Future<List<SearchSuggestion>> getSuggestions(String query) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/search/suggestions',
        queryParameters: {'q': query},
      );

      return response.data!
          .map((json) => SearchSuggestion.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // 如果建议服务失败，返回空列表
      return [];
    }
  }
}

// 搜索建议模型
class SearchSuggestion {
  final String text;
  final String displayText;
  final SuggestionType type;
  final Fund? fund;
  final String? description;
  final List<TextRange> matchRanges;

  SearchSuggestion({
    required this.text,
    required this.displayText,
    required this.type,
    this.fund,
    this.description,
    required this.matchRanges,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] as String,
      displayText: json['display_text'] as String,
      type: SuggestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SuggestionType.fund,
      ),
      fund: json['fund'] != null
          ? Fund.fromJson(json['fund'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
      matchRanges: (json['match_ranges'] as List<dynamic>?)
              ?.map((range) => TextRange(
                    range['start'] as int,
                    range['end'] as int,
                  ))
              .toList() ??
          [],
    );
  }
}

// 搜索建议类型枚举
enum SuggestionType {
  fund,
  history,
  hot,
  correction,
  pinyin;

  IconData get icon {
    switch (this) {
      case SuggestionType.fund:
        return Icons.account_balance;
      case SuggestionType.history:
        return Icons.history;
      case SuggestionType.hot:
        return Icons.trending_up;
      case SuggestionType.correction:
        return Icons.auto_fix_high;
      case SuggestionType.pinyin:
        return Icons.translate;
    }
  }
}

// 文本范围工具类
class TextRange {
  final int start;
  final int end;

  TextRange(this.start, this.end);
}
```

**测试要点**:
- 智能联想准确性
- 拼音搜索功能
- 建议响应时间
- 用户交互体验

---

## 📊 史诗验收标准

### 功能验收标准

- [ ] 支持10,000+基金数据的快速查询和展示
- [ ] 搜索响应时间≤500ms，准确率≥95%
- [ ] 筛选功能支持多条件组合筛选
- [ ] 基金详情页面信息完整、更新及时
- [ ] 数据准确性≥99.5%，更新延迟≤5分钟

### 性能验收标准

- [ ] 数据加载时间≤2秒
- [ ] 图表渲染时间≤1秒
- [ ] 搜索响应时间≤300ms
- [ ] 页面切换流畅度60fps
- [ ] 内存使用≤150MB

### 用户体验验收标准

- [ ] 界面设计美观，符合金融产品风格
- [ ] 操作流程简单直观
- [ ] 错误提示友好明确
- [ ] 数据可视化效果清晰
- [ ] 支持无障碍访问

---

## 🚀 后续计划

EPIC-002的完成为用户提供了全面的基金数据访问能力。接下来将进入EPIC-003: 数据分析工具，基于基金数据开发专业的分析功能。

**预计开始时间**: EPIC-002完成后1周
**依赖关系**: EPIC-001 (基础架构建设)
**风险等级**: 中 (依赖外部数据源)

---

*本用户故事文档将随着开发进展持续更新，确保与实际开发进度保持同步。*