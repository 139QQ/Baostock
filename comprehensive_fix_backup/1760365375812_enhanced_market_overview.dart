import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 增强版市场指数组件
///
/// 展示主要市场指数的实时数据、涨跌情况，并集成微型趋势图
/// - 支持悬停动效
/// - 渐变色彩系统
/// - 响应式布局
class EnhancedMarketOverview extends StatelessWidget {
  const EnhancedMarketOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '市场指数',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 20),

          // 主要指数区域（两行布局）
          Row(
            children: [
              // 上证指数（突出显示）
              Expanded(
                flex: 2,
                child: _PrimaryIndexCard(
                  name: '上证指数',
                  value: '3,256.78',
                  change: '+1.25%',
                  isPositive: true,
                  trendData: [3200, 3220, 3240, 3230, 3256],
                ),
              ),
              SizedBox(width: 16),

              // 右侧紧凑排列
              Expanded(
                child: Column(
                  children: [
                    _CompactIndexCard(
                      name: '深证成指',
                      value: '10,875.43',
                      change: '-0.85%',
                      isPositive: false,
                      trendData: [10900, 10850, 10900, 10880, 10875],
                    ),
                    SizedBox(height: 16),
                    _CompactIndexCard(
                      name: '创业板指',
                      value: '2,145.67',
                      change: '+2.34%',
                      isPositive: true,
                      trendData: [2100, 2110, 2120, 2130, 2145],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),

              // 沪深300
              Expanded(
                child: _CompactIndexCard(
                  name: '沪深300',
                  value: '4,123.45',
                  change: '+0.56%',
                  isPositive: true,
                  trendData: [4100, 4110, 4120, 4115, 4123],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 主要指数卡片（大号显示）
class _PrimaryIndexCard extends StatelessWidget {
  final String name;
  final String value;
  final String change;
  final bool isPositive;
  final List<double> trendData;

  const _PrimaryIndexCard({
    required this.name,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.trendData,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPositive
                  ? [
                      Color(0xFFE8F5E8),
                      Color(0xFFF0F9F0),
                    ]
                  : [
                      Color(0xFFFFEBEE),
                      Color(0xFFFFF3F3),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPositive
                  ? Color(0xFF4CAF50).withOpacity(0.2)
                  : Color(0xFFF44336).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 指数名称
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Color(0xFF4CAF50) : Color(0xFFF44336),
                  ),
                ),
                SizedBox(height: 12),

                // 数值
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8),

                // 涨跌幅
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isPositive ? Color(0xFFEF5350) : Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isPositive ? Color(0xFFEF5350) : Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),

                Spacer(),

                // 微型趋势图
                SizedBox(
                  height: 40,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateTrendSpots(trendData),
                          isCurved: true,
                          color: isPositive
                              ? Color(0xFFEF5350)
                              : Color(0xFF4CAF50),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: (isPositive
                                    ? Color(0xFFEF5350)
                                    : Color(0xFF4CAF50))
                                .withOpacity(0.1),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: 4,
                      minY: trendData.reduce((a, b) => a < b ? a : b),
                      maxY: trendData.reduce((a, b) => a > b ? a : b),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateTrendSpots(List<double> data) {
    return List.generate(
      data.length,
      (index) => FlSpot(index.toDouble(), data[index]),
    );
  }
}

/// 紧凑型指数卡片
class _CompactIndexCard extends StatelessWidget {
  final String name;
  final String value;
  final String change;
  final bool isPositive;
  final List<double> trendData;

  const _CompactIndexCard({
    required this.name,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.trendData,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                // 微型趋势图
                SizedBox(
                  width: 60,
                  height: 30,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateTrendSpots(trendData),
                          isCurved: true,
                          color: isPositive
                              ? Color(0xFFEF5350)
                              : Color(0xFF4CAF50),
                          barWidth: 1.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                      minX: 0,
                      maxX: 4,
                      minY: trendData.reduce((a, b) => a < b ? a : b),
                      maxY: trendData.reduce((a, b) => a > b ? a : b),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // 涨跌幅
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Color(0xFFEF5350).withOpacity(0.1)
                        : Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? Color(0xFFEF5350) : Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateTrendSpots(List<double> data) {
    return List.generate(
      data.length,
      (index) => FlSpot(index.toDouble(), data[index]),
    );
  }
}
