import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jisu_fund_analyzer/src/bloc/fund_search_bloc.dart';
import 'package:jisu_fund_analyzer/src/services/fund_analysis_service.dart';
import 'package:jisu_fund_analyzer/src/core/theme/app_theme.dart';

/// 技术指标展示组件
class TechnicalIndicatorsWidget extends StatefulWidget {
  final String fundCode;
  final String fundName;

  const TechnicalIndicatorsWidget({
    super.key,
    required this.fundCode,
    required this.fundName,
  });

  @override
  State<TechnicalIndicatorsWidget> createState() =>
      _TechnicalIndicatorsWidgetState();
}

class _TechnicalIndicatorsWidgetState extends State<TechnicalIndicatorsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<MovingAverageData> _maData = [];
  List<RSIData> _rsiData = [];
  List<BollingerBandsData> _bbData = [];
  FundRiskMetrics? _riskMetrics;
  FundScore? _fundScore;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTechnicalIndicators();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTechnicalIndicators() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 并行加载所有技术指标数据
      final futures = await Future.wait([
        context
            .read<FundSearchBloc>()
            .analysisService
            .calculateMovingAverage(widget.fundCode, period: 20),
        context
            .read<FundSearchBloc>()
            .analysisService
            .calculateRSI(widget.fundCode, period: 14),
        context
            .read<FundSearchBloc>()
            .analysisService
            .calculateBollingerBands(widget.fundCode, period: 20),
        context
            .read<FundSearchBloc>()
            .analysisService
            .calculateRiskMetrics(widget.fundCode),
        context
            .read<FundSearchBloc>()
            .analysisService
            .calculateFundScore(widget.fundCode),
      ]);

      setState(() {
        _maData = futures[0] as List<MovingAverageData>;
        _rsiData = futures[1] as List<RSIData>;
        _bbData = futures[2] as List<BollingerBandsData>;
        _riskMetrics = futures[3] as FundRiskMetrics;
        _fundScore = futures[4] as FundScore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载技术指标失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fundName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '技术指标分析',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTechnicalIndicators,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.show_chart),
              text: '移动平均线',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'RSI指标',
            ),
            Tab(
              icon: Icon(Icons.tune),
              text: '布林带',
            ),
            Tab(
              icon: Icon(Icons.assessment),
              text: '风险评估',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMovingAverageTab(),
                _buildRSITab(),
                _buildBollingerBandsTab(),
                _buildRiskAssessmentTab(),
              ],
            ),
    );
  }

  Widget _buildMovingAverageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 指标说明卡片
          _buildIndicatorCard(
            title: '移动平均线 (MA)',
            description: '移动平均线是最常用的技术指标之一，用于平滑价格数据，识别趋势方向。',
            icon: Icons.show_chart,
            color: AppTheme.primaryColor,
          ),

          const SizedBox(height: 20),

          // MA图表
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '20日移动平均线',
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildMALineChart(),
                  ),
                ],
              ),
            ),
          ).animate().slideY().fadeIn(),

          const SizedBox(height: 20),

          // MA统计信息
          _buildMAStats(),
        ],
      ),
    );
  }

  Widget _buildMALineChart() {
    if (_maData.isEmpty) {
      return const Center(
        child: Text('暂无数据'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.1,
          verticalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _maData.length) {
                  return Text(
                    _maData[value.toInt()].date.day.toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (_maData.length - 1).toDouble(),
        minY:
            _maData.map((d) => d.value).reduce((a, b) => a < b ? a : b) * 0.95,
        maxY:
            _maData.map((d) => d.value).reduce((a, b) => a > b ? a : b) * 1.05,
        lineBarsData: [
          LineChartBarData(
            spots: _maData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8)
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.primaryColor.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMAStats() {
    if (_maData.isEmpty) return const SizedBox.shrink();

    final latestMA = _maData.last.value;
    final previousMA =
        _maData.length > 1 ? _maData[_maData.length - 2].value : latestMA;
    final change = latestMA - previousMA;
    final changePercent = previousMA != 0 ? (change / previousMA) * 100 : 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '移动平均线统计',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '最新MA20',
                    latestMA.toStringAsFixed(4),
                    change >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    '日变化',
                    '${change >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    change >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    '数据点',
                    '${_maData.length}',
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideX(delay: 200.ms).fadeIn();
  }

  Widget _buildRSITab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RSI指标说明
          _buildIndicatorCard(
            title: '相对强弱指数 (RSI)',
            description: 'RSI是衡量价格变动速度和变动幅度的技术指标，用于判断超买超卖状态。',
            icon: Icons.analytics,
            color: AppTheme.warningColor,
          ),

          const SizedBox(height: 20),

          // RSI图表
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '14日RSI指标',
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildRSILineChart(),
                  ),
                ],
              ),
            ),
          ).animate().slideY().fadeIn(),

          const SizedBox(height: 20),

          // RSI分析
          _buildRSIAnalysis(),
        ],
      ),
    );
  }

  Widget _buildRSILineChart() {
    if (_rsiData.isEmpty) {
      return const Center(
        child: Text('暂无数据'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            Color lineColor;
            if (value == 70) {
              lineColor = AppTheme.errorColor;
            } else if (value == 30) {
              lineColor = AppTheme.successColor;
            } else {
              lineColor = Colors.grey.withOpacity(0.3);
            }

            return FlLine(
              color: lineColor,
              strokeWidth: value == 70 || value == 30 ? 2 : 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _rsiData.length) {
                  return Text(
                    _rsiData[value.toInt()].date.day.toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (_rsiData.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: _rsiData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: AppTheme.warningColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < _rsiData.length) {
                  final rsi = _rsiData[index];
                  return LineTooltipItem(
                    'RSI: ${rsi.value.toStringAsFixed(2)}\n${rsi.date.day}日',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRSIAnalysis() {
    if (_rsiData.isEmpty) return const SizedBox.shrink();

    final latestRSI = _rsiData.last.value;
    String rsiStatus;
    Color statusColor;
    String statusDescription;

    if (latestRSI >= 70) {
      rsiStatus = '超买';
      statusColor = AppTheme.errorColor;
      statusDescription = 'RSI超过70，表示基金可能处于超买状态，建议谨慎投资。';
    } else if (latestRSI <= 30) {
      rsiStatus = '超卖';
      statusColor = AppTheme.successColor;
      statusDescription = 'RSI低于30，表示基金可能处于超卖状态，可能存在投资机会。';
    } else {
      rsiStatus = '正常';
      statusColor = AppTheme.primaryColor;
      statusDescription = 'RSI在30-70之间，价格走势相对正常。';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RSI分析',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        rsiStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        latestRSI.toStringAsFixed(2),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    statusDescription,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideX(delay: 200.ms).fadeIn();
  }

  Widget _buildBollingerBandsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 布林带指标说明
          _buildIndicatorCard(
            title: '布林带 (Bollinger Bands)',
            description: '布林带由三条线组成，用于判断价格相对高低点和波动性。',
            icon: Icons.tune,
            color: AppTheme.successColor,
          ),

          const SizedBox(height: 20),

          // 布林带图表
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '20日布林带',
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildBollingerBandsChart(),
                  ),
                ],
              ),
            ),
          ).animate().slideY().fadeIn(),

          const SizedBox(height: 20),

          // 布林带分析
          _buildBollingerBandsAnalysis(),
        ],
      ),
    );
  }

  Widget _buildBollingerBandsChart() {
    if (_bbData.isEmpty) {
      return const Center(
        child: Text('暂无数据'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _bbData.length) {
                  return Text(
                    _bbData[value.toInt()].date.day.toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (_bbData.length - 1).toDouble(),
        minY: _bbData.map((d) => d.lowerBand).reduce((a, b) => a < b ? a : b) *
            0.98,
        maxY: _bbData.map((d) => d.upperBand).reduce((a, b) => a > b ? a : b) *
            1.02,
        lineBarsData: [
          // 上轨
          LineChartBarData(
            spots: _bbData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.upperBand);
            }).toList(),
            isCurved: true,
            color: AppTheme.errorColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          // 中轨
          LineChartBarData(
            spots: _bbData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.middleBand);
            }).toList(),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          // 下轨
          LineChartBarData(
            spots: _bbData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.lowerBand);
            }).toList(),
            isCurved: true,
            color: AppTheme.successColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBollingerBandsAnalysis() {
    if (_bbData.isEmpty) return const SizedBox.shrink();

    final latestBB = _bbData.last;
    final bandwidth = latestBB.bandwidth;

    // 根据带宽判断波动性
    String volatilityLevel;
    Color volatilityColor;
    String volatilityDescription;

    // 这里需要根据实际数据计算平均带宽来判断
    if (bandwidth > 0.1) {
      volatilityLevel = '高波动';
      volatilityColor = AppTheme.errorColor;
      volatilityDescription = '带宽较大，价格波动性较高，投资风险较大。';
    } else if (bandwidth < 0.05) {
      volatilityLevel = '低波动';
      volatilityColor = AppTheme.successColor;
      volatilityDescription = '带宽较小，价格相对稳定，波动性较低。';
    } else {
      volatilityLevel = '中等波动';
      volatilityColor = AppTheme.warningColor;
      volatilityDescription = '带宽适中，价格波动性处于正常水平。';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '布林带分析',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBBStatItem(
                      '上轨',
                      latestBB.upperBand.toStringAsFixed(4),
                      AppTheme.errorColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBBStatItem(
                      '中轨',
                      latestBB.middleBand.toStringAsFixed(4),
                      AppTheme.primaryColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBBStatItem(
                      '下轨',
                      latestBB.lowerBand.toStringAsFixed(4),
                      AppTheme.successColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: volatilityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: volatilityColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        volatilityLevel,
                        style: TextStyle(
                          color: volatilityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '带宽: ${(bandwidth * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: volatilityColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    volatilityDescription,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideX(delay: 200.ms).fadeIn();
  }

  Widget _buildRiskAssessmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 风险评估说明
          _buildIndicatorCard(
            title: '风险评估',
            description: '基于历史数据计算的各项风险指标，帮助您全面了解基金的风险特征。',
            icon: Icons.assessment,
            color: AppTheme.neutralColor,
          ),

          const SizedBox(height: 20),

          // 综合评分卡片
          if (_fundScore != null)
            Card(
              elevation: 6,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '综合评分',
                          style: AppTheme.headlineMedium.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_fundScore!.totalScore}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      '风险等级: ${_fundScore!.riskLevel}',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildScoreItem('夏普比率', _fundScore!.sharpeScore),
                        _buildScoreItem('波动率', _fundScore!.volatilityScore),
                        _buildScoreItem('回撤', _fundScore!.drawdownScore),
                        _buildScoreItem('收益', _fundScore!.returnScore),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().scale().fadeIn(),

          const SizedBox(height: 20),

          // 风险指标详情
          if (_riskMetrics != null) ...[
            _buildRiskMetricsCard(),
            const SizedBox(height: 20),
          ],

          // 风险建议
          _buildRiskAdviceCard(),
        ],
      ),
    );
  }

  Widget _buildRiskMetricsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '风险指标详情',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildRiskMetric(
                '年化波动率',
                '${(_riskMetrics!.volatility * 100).toStringAsFixed(2)}%',
                '衡量基金收益的波动程度'),
            _buildRiskMetric(
                '最大回撤',
                '${(_riskMetrics!.maxDrawdown * 100).toStringAsFixed(2)}%',
                '历史上最大跌幅'),
            _buildRiskMetric('夏普比率',
                _riskMetrics!.sharpeRatio.toStringAsFixed(3), '风险调整后收益指标'),
            _buildRiskMetric(
                'Beta系数', _riskMetrics!.beta.toStringAsFixed(3), '相对市场敏感度'),
            _buildRiskMetric(
                '平均收益',
                '${(_riskMetrics!.averageReturn * 100).toStringAsFixed(2)}%',
                '日平均收益率'),
          ],
        ),
      ),
    ).animate().slideY(delay: 200.ms).fadeIn();
  }

  Widget _buildRiskMetric(String title, String value, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAdviceCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: AppTheme.warningColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '投资建议',
                  style: AppTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAdviceItem(
              '风险提示',
              '投资有风险，过往业绩不代表未来表现。请根据自身风险承受能力谨慎投资。',
              Icons.warning,
              AppTheme.warningColor,
            ),
            _buildAdviceItem(
              '分散投资',
              '建议将资金分散投资于不同类型的基金，降低单一基金的风险。',
              Icons.pie_chart,
              AppTheme.primaryColor,
            ),
            _buildAdviceItem(
              '长期持有',
              '基金投资适合长期持有，避免频繁交易带来的成本风险。',
              Icons.schedule,
              AppTheme.successColor,
            ),
          ],
        ),
      ),
    ).animate().slideX(delay: 400.ms).fadeIn();
  }

  Widget _buildAdviceItem(
      String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.headlineMedium.copyWith(
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBBStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int score) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              score.toString(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
