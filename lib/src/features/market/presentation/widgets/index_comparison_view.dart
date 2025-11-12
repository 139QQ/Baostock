import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/market_index_data.dart';

/// 指数对比视图
///
/// 支持多个指数的历史数据对比分析
class IndexComparisonView extends StatefulWidget {
  final List<String> indexCodes;
  final List<MarketIndexData> currentIndexData;
  final Map<String, List<MarketIndexData>> historicalData;
  final IndexComparisonStyle style;
  final Duration comparisonPeriod;
  final Function(String)? onIndexTapped;

  const IndexComparisonView({
    Key? key,
    required this.indexCodes,
    required this.currentIndexData,
    required this.historicalData,
    this.style = IndexComparisonStyle.list,
    this.comparisonPeriod = const Duration(days: 7),
    this.onIndexTapped,
  }) : super(key: key);

  @override
  State<IndexComparisonView> createState() => _IndexComparisonViewState();
}

class _IndexComparisonViewState extends State<IndexComparisonView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  ComparisonViewType _currentViewType = ComparisonViewType.performance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      _currentViewType = ComparisonViewType.values[_tabController.index];
    });

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCurrentView(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.compare,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '指数对比分析',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      '${widget.comparisonPeriod.inDays}日数据对比',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildSummaryCards(),
          ),
        ],
      ),
    );
  }

  /// 构建摘要卡片
  List<Widget> _buildSummaryCards() {
    final indicesData = _getIndicesSummary();

    return [
      _buildSummaryCard(
        '跟踪指数',
        '${indicesData.length}',
        Icons.show_chart,
      ),
      _buildSummaryCard(
        '平均涨跌幅',
        _formatAverageChange(indicesData),
        Icons.trending_up,
      ),
      _buildSummaryCard(
        '最强表现',
        _formatBestPerformer(indicesData),
        Icons.star,
      ),
      _buildSummaryCard(
        '最大波动',
        _formatMaxVolatility(indicesData),
        Icons.show_chart,
      ),
    ];
  }

  /// 构建单个摘要卡片
  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.black54,
        unselectedLabelColor: Colors.black38,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: '表现排行'),
          Tab(text: '走势对比'),
          Tab(text: '相关分析'),
          Tab(text: '详情对比'),
        ],
      ),
    );
  }

  /// 构建当前视图
  Widget _buildCurrentView() {
    switch (_currentViewType) {
      case ComparisonViewType.performance:
        return _buildPerformanceView();
      case ComparisonViewType.trend:
        return _buildTrendComparisonView();
      case ComparisonViewType.correlation:
        return _buildCorrelationView();
      case ComparisonViewType.detail:
        return _buildDetailView();
    }
  }

  /// 构建表现排行视图
  Widget _buildPerformanceView() {
    final indicesData = _getIndicesSummary()
      ..sort((a, b) => b.performance.compareTo(a.performance));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: indicesData.length,
      itemBuilder: (context, index) {
        final data = indicesData[index];
        return _buildPerformanceCard(data, index);
      },
    );
  }

  /// 构建表现排行卡片
  Widget _buildPerformanceCard(IndexSummaryData data, int rank) {
    final rankColor = _getRankColor(rank);
    final performanceColor =
        data.performance >= Decimal.zero ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: rankColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '${rank + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          data.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          data.code,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              data.currentValue.toStringAsFixed(2),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '${_formatChange(data.performance)}%',
              style: TextStyle(
                color: performanceColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => widget.onIndexTapped?.call(data.code),
      ),
    );
  }

  /// 构建趋势对比视图
  Widget _buildTrendComparisonView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: _buildTrendChart(),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  /// 构建趋势图表
  Widget _buildTrendChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: _buildChartTitles(),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: widget.comparisonPeriod.inDays.toDouble(),
        minY: _calculateChartMinY(),
        maxY: _calculateChartMaxY(),
        lineBarsData: _buildTrendLines(),
        lineTouchData: _buildTrendTouchData(),
      ),
    );
  }

  /// 构建趋势线
  List<LineChartBarData> _buildTrendLines() {
    return widget.indexCodes.map((indexCode) {
      final indexData = widget.historicalData[indexCode] ?? [];
      final spots = _generateTrendSpots(indexData);

      final color = _getIndexColor(widget.indexCodes.indexOf(indexCode));

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.1),
        ),
      );
    }).toList();
  }

  /// 生成趋势点
  List<FlSpot> _generateTrendSpots(List<MarketIndexData> data) {
    if (data.isEmpty) {
      return [FlSpot.zero];
    }

    // 简化：使用数据点索引作为X轴，标准化Y轴为相对变化
    final baseValue = data.first.currentValue.toDouble();

    return data.asMap().entries.map((entry) {
      final x = entry.key.toDouble();
      final relativeChange =
          (entry.value.currentValue.toDouble() - baseValue) / baseValue;
      final y = relativeChange * 100; // 转换为百分比

      return FlSpot(x, y);
    }).toList();
  }

  /// 构建图表标题
  FlTitlesData _buildChartTitles() {
    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final day = value.toInt();
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                '$day',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final percentage = value.toStringAsFixed(1);
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建触摸数据
  LineTouchData _buildTrendTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: Colors.blueGrey[800],
        tooltipRoundedRadius: 8,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final indexCode = widget.indexCodes[touchedSpots.indexOf(spot)];
            final indexData = widget.currentIndexData.firstWhere(
              (data) => data.code == indexCode,
              orElse: () => MarketIndexData(
                code: '',
                name: '',
                currentValue: Decimal.zero,
                previousClose: Decimal.zero,
                openPrice: Decimal.zero,
                highPrice: Decimal.zero,
                lowPrice: Decimal.zero,
                changeAmount: Decimal.zero,
                changePercentage: Decimal.zero,
                volume: 0,
                turnover: Decimal.zero,
                updateTime: DateTime.now(),
                marketStatus: MarketStatus.unknown,
              ),
            );

            return LineTooltipItem(
              '${indexData.name}\n${spot.y.toStringAsFixed(2)}%',
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            );
          }).toList();
        },
      ),
      handleBuiltInTouches: true,
    );
  }

  /// 构建图例
  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.indexCodes.map((indexCode) {
        final index = widget.indexCodes.indexOf(indexCode);
        final indexData = widget.currentIndexData.firstWhere(
          (data) => data.code == indexCode,
          orElse: () => MarketIndexData(
            code: '',
            name: '',
            currentValue: Decimal.zero,
            previousClose: Decimal.zero,
            openPrice: Decimal.zero,
            highPrice: Decimal.zero,
            lowPrice: Decimal.zero,
            changeAmount: Decimal.zero,
            changePercentage: Decimal.zero,
            volume: 0,
            turnover: Decimal.zero,
            updateTime: DateTime.now(),
            marketStatus: MarketStatus.unknown,
          ),
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              color: _getIndexColor(index),
            ),
            const SizedBox(width: 6),
            Text(
              indexData.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// 构建相关分析视图
  Widget _buildCorrelationView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCorrelationMatrix(),
          const SizedBox(height: 20),
          _buildCorrelationInsights(),
        ],
      ),
    );
  }

  /// 构建相关矩阵
  Widget _buildCorrelationMatrix() {
    final matrix = _calculateCorrelationMatrix();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey[300]!),
        ),
        children: [
          // 表头
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            children: [
              _buildHeaderCell(''),
              ...widget.indexCodes.map((code) => _buildHeaderCell(
                    _getIndexName(code),
                  )),
            ],
          ),
          // 数据行
          for (int i = 0; i < widget.indexCodes.length; i++)
            TableRow(
              children: [
                _buildHeaderCell(_getIndexName(widget.indexCodes[i])),
                for (int j = 0; j < widget.indexCodes.length; j++)
                  _buildCorrelationCell(matrix[i][j]),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建表头单元格
  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 构建相关单元格
  Widget _buildCorrelationCell(double correlation) {
    final color = _getCorrelationColor(correlation);
    final text = correlation.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(8),
      color: color.withOpacity(0.1),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 构建相关洞察
  Widget _buildCorrelationInsights() {
    final insights = _generateCorrelationInsights();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '相关性洞察',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.insights,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 构建详情对比视图
  Widget _buildDetailView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.indexCodes.length,
      itemBuilder: (context, index) {
        final indexCode = widget.indexCodes[index];
        final currentIndexData = widget.currentIndexData.firstWhere(
          (data) => data.code == indexCode,
          orElse: () => MarketIndexData(
            code: '',
            name: '',
            currentValue: Decimal.zero,
            previousClose: Decimal.zero,
            openPrice: Decimal.zero,
            highPrice: Decimal.zero,
            lowPrice: Decimal.zero,
            changeAmount: Decimal.zero,
            changePercentage: Decimal.zero,
            volume: 0,
            turnover: Decimal.zero,
            updateTime: DateTime.now(),
            marketStatus: MarketStatus.unknown,
          ),
        );

        return _buildIndexDetailCard(index, currentIndexData);
      },
    );
  }

  /// 构建指数详情卡片
  Widget _buildIndexDetailCard(int index, MarketIndexData data) {
    final historical = widget.historicalData[data.code] ?? [];
    final weeklyPerformance = _calculateWeeklyPerformance(historical);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getIndexColor(index),
                  radius: 20,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        data.code,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 当前数据
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem('当前值', data.currentValue.toStringAsFixed(2)),
                _buildDetailItem('涨跌点', data.changeAmount.toStringAsFixed(2)),
                _buildDetailItem('涨跌幅', _formatChange(data.changePercentage)),
              ],
            ),
            const SizedBox(height: 12),
            // 周期表现
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem('周表现', '${_formatChange(weeklyPerformance)}%'),
                _buildDetailItem('成交量', _formatVolume(data.volume)),
                _buildDetailItem('更新时间', _formatTime(data.updateTime)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建详情项
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 计算图表最小Y值
  double _calculateChartMinY() {
    final data = widget.currentIndexData;
    if (data.isEmpty) return -10.0;

    final changes = data.map((d) => d.changePercentage.toDouble()).toList();
    final minChange = changes.reduce(math.min);
    return minChange - 5.0;
  }

  /// 计算图表最大Y值
  double _calculateChartMaxY() {
    final data = widget.currentIndexData;
    if (data.isEmpty) return 10.0;

    final changes = data.map((d) => d.changePercentage.toDouble()).toList();
    final maxChange = changes.reduce(math.max);
    return maxChange + 5.0;
  }

  /// 获取指数摘要数据
  List<IndexSummaryData> _getIndicesSummary() {
    return widget.indexCodes.map((indexCode) {
      final currentIndexData = widget.currentIndexData.firstWhere(
        (data) => data.code == indexCode,
        orElse: () => MarketIndexData(
          code: '',
          name: '',
          currentValue: Decimal.zero,
          previousClose: Decimal.zero,
          openPrice: Decimal.zero,
          highPrice: Decimal.zero,
          lowPrice: Decimal.zero,
          changeAmount: Decimal.zero,
          changePercentage: Decimal.zero,
          volume: 0,
          turnover: Decimal.zero,
          updateTime: DateTime.now(),
          marketStatus: MarketStatus.unknown,
        ),
      );

      final historical = widget.historicalData[indexCode] ?? [];
      final weeklyPerformance = _calculateWeeklyPerformance(historical);
      final volatility = _calculateVolatility(historical);

      return IndexSummaryData(
        code: indexCode,
        name: currentIndexData.name,
        currentValue: currentIndexData.currentValue,
        performance: weeklyPerformance,
        volatility: volatility,
        historicalData: historical,
      );
    }).toList();
  }

  /// 计算周表现
  Decimal _calculateWeeklyPerformance(List<MarketIndexData> historical) {
    if (historical.isEmpty || historical.length < 2) return Decimal.zero;

    final firstValue = historical.first.currentValue;
    final lastValue = historical.last.currentValue;

    if (firstValue == Decimal.zero) return Decimal.zero;

    return Decimal.parse(
        ((lastValue - firstValue) * Decimal.fromInt(100) / firstValue)
            .toString());
  }

  /// 计算波动率
  double _calculateVolatility(List<MarketIndexData> historical) {
    if (historical.isEmpty || historical.length < 2) return 0.0;

    final returns = <double>[];
    for (int i = 1; i < historical.length; i++) {
      final prevValue = historical[i - 1].currentValue.toDouble();
      final currValue = historical[i].currentValue.toDouble();

      if (prevValue != 0) {
        returns.add((currValue - prevValue) / prevValue);
      }
    }

    if (returns.isEmpty) return 0.0;

    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) {
          final diff = r - mean;
          return diff * diff;
        }).reduce((a, b) => a + b) /
        returns.length;

    return math.sqrt(variance) * math.sqrt(252); // 年化波动率
  }

  /// 计算相关矩阵
  List<List<double>> _calculateCorrelationMatrix() {
    final count = widget.indexCodes.length;
    final matrix = List.generate(count, (i) => List.filled(count, 0.0));

    for (int i = 0; i < count; i++) {
      matrix[i][i] = 1.0; // 自相关为1

      for (int j = i + 1; j < count; j++) {
        final correlation = _calculateCorrelation(
          widget.historicalData[widget.indexCodes[i]] ?? [],
          widget.historicalData[widget.indexCodes[j]] ?? [],
        );
        matrix[i][j] = correlation;
        matrix[j][i] = correlation;
      }
    }

    return matrix;
  }

  /// 计算相关系数
  double _calculateCorrelation(
      List<MarketIndexData> data1, List<MarketIndexData> data2) {
    if (data1.isEmpty || data2.isEmpty || data1.length != data2.length) {
      return 0.0;
    }

    final returns1 = _calculateReturns(data1);
    final returns2 = _calculateReturns(data2);

    if (returns1.isEmpty || returns2.isEmpty) return 0.0;

    final mean1 = returns1.reduce((a, b) => a + b) / returns1.length;
    final mean2 = returns2.reduce((a, b) => a + b) / returns2.length;

    double covariance = 0;
    double variance1 = 0;
    double variance2 = 0;

    for (int i = 0; i < returns1.length; i++) {
      final diff1 = returns1[i] - mean1;
      final diff2 = returns2[i] - mean2;

      covariance += diff1 * diff2;
      variance1 += diff1 * diff1;
      variance2 += diff2 * diff2;
    }

    covariance /= returns1.length;
    variance1 /= returns1.length;
    variance2 /= returns1.length;

    if (variance1 == 0 || variance2 == 0) return 0.0;

    return covariance / math.sqrt(variance1 * variance2);
  }

  /// 计算收益率
  List<double> _calculateReturns(List<MarketIndexData> data) {
    final returns = <double>[];
    for (int i = 1; i < data.length; i++) {
      final prevValue = data[i - 1].currentValue.toDouble();
      final currValue = data[i].currentValue.toDouble();

      if (prevValue != 0) {
        returns.add((currValue - prevValue) / prevValue);
      }
    }
    return returns;
  }

  /// 生成相关洞察
  List<String> _generateCorrelationInsights() {
    final insights = <String>[];
    final matrix = _calculateCorrelationMatrix();

    // 找出高度相关的指数对
    for (int i = 0; i < matrix.length; i++) {
      for (int j = i + 1; j < matrix[i].length; j++) {
        final correlation = matrix[i][j];
        if (correlation.abs() > 0.8) {
          final index1 = _getIndexName(widget.indexCodes[i]);
          final index2 = _getIndexName(widget.indexCodes[j]);
          final direction = correlation > 0 ? '正相关' : '负相关';
          insights.add(
              '$index1 和 $index2 存在强$direction关系 (${correlation.toStringAsFixed(2)})');
        }
      }
    }

    if (insights.isEmpty) {
      insights.add('各指数间相关性较低，走势相对独立');
    }

    return insights;
  }

  /// 格式化平均变化
  String _formatAverageChange(List<IndexSummaryData> data) {
    if (data.isEmpty) return '0.00';
    final sum = data.map((d) => d.performance).reduce((a, b) => a + b);
    final avg = Decimal.parse((sum / Decimal.fromInt(data.length)).toString());
    return _formatChange(avg);
  }

  /// 格式化最佳表现
  String _formatBestPerformer(List<IndexSummaryData> data) {
    if (data.isEmpty) return '-';
    final best = data.reduce((a, b) => a.performance > b.performance ? a : b);
    return '${_getIndexName(best.code)} (+${_formatChange(best.performance)}%)';
  }

  /// 格式化最大波动
  String _formatMaxVolatility(List<IndexSummaryData> data) {
    if (data.isEmpty) return '0.0';
    final maxVol = data.map((d) => d.volatility).reduce(math.max);
    return '${(maxVol * 100).toStringAsFixed(1)}%';
  }

  /// 格式化变化
  String _formatChange(Decimal change) {
    final value = change.toDouble();
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}';
  }

  /// 格式化成交量
  String _formatVolume(int volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(1)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(1)}万';
    } else {
      return volume.toString();
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 获取排名颜色
  Color _getRankColor(int rank) {
    const colors = [
      Colors.amber, // 第一名金色
      Colors.grey, // 第二名银色
      Colors.brown, // 第三名铜色
      Colors.blue, // 其他
    ];
    return colors[rank.clamp(0, colors.length - 1)];
  }

  /// 获取相关性颜色
  Color _getCorrelationColor(double correlation) {
    if (correlation >= 0.8) {
      return Colors.green;
    } else if (correlation >= 0.5) {
      return Colors.lightGreen;
    } else if (correlation >= 0.2) {
      return Colors.yellow;
    } else if (correlation >= -0.2) {
      return Colors.grey;
    } else if (correlation >= -0.5) {
      return Colors.orange;
    } else if (correlation >= -0.8) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  /// 获取指数颜色
  Color _getIndexColor(int index) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  /// 获取指数名称
  String _getIndexName(String code) {
    final nameMap = {
      '000001.SH': '上证指数',
      '399001.SZ': '深证成指',
      '399006.SZ': '创业板指',
      '000300.SH': '沪深300',
      '000688.SH': '科创50',
      '000016.SH': '上证50',
    };
    return nameMap[code] ?? code;
  }
}

/// 指数摘要数据
class IndexSummaryData {
  final String code;
  final String name;
  final Decimal currentValue;
  final Decimal performance;
  final double volatility;
  final List<MarketIndexData> historicalData;

  IndexSummaryData({
    required this.code,
    required this.name,
    required this.currentValue,
    required this.performance,
    required this.volatility,
    required this.historicalData,
  });
}

/// 比较视图类型
enum ComparisonViewType {
  performance,
  trend,
  correlation,
  detail,
}

/// 比较视图样式
enum IndexComparisonStyle {
  list,
  grid,
  card,
}
