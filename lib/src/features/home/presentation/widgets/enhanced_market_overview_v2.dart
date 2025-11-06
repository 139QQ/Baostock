import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/market_real_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/market_data_models.dart';

/// 增强版市场概览组件V2
///
/// 强化核心数据层级，以上证指数为主展示，
/// 其他指数作为紧凑列表展示在右侧
class EnhancedMarketOverviewV2 extends StatefulWidget {
  const EnhancedMarketOverviewV2({super.key});

  @override
  State<EnhancedMarketOverviewV2> createState() =>
      _EnhancedMarketOverviewV2State();
}

class _EnhancedMarketOverviewV2State extends State<EnhancedMarketOverviewV2> {
  late final MarketRealService _marketService;
  MarketIndicesData? _marketData;
  List<ChartPoint> _mainIndexChart = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _marketService = marketRealService;
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _marketService.getRealTimeIndices();
      final chartData = await _marketService.getIndexRecentHistory('000001');

      setState(() {
        _marketData = data;
        _mainIndexChart = chartData.take(24).toList();
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.debug('加载市场数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '市场行情',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),

          // 主指数区域：上证指数
          _buildMainIndexCard(),
          const SizedBox(height: 20),

          // 子指数紧凑列表
          _buildSubIndicesList(),
        ],
      ),
    );
  }

  Widget _buildMainIndexCard() {
    if (_marketData == null) {
      return const SizedBox();
    }

    final index = _marketData!.mainIndex;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 左侧：指数信息
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  index.latestPrice.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${index.changePercent >= 0 ? '+' : '-'}${index.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: index.isPositive
                            ? const Color(0xFFEF5350)
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: index.isPositive
                            ? const Color(0xFFEF5350).withOpacity(0.1)
                            : const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index.changePercent >= 0 ? '+' : '-'}${index.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: index.isPositive
                              ? const Color(0xFFEF5350)
                              : const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '成交量：${(index.volume / 10000).toStringAsFixed(0)}万手',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '成交额：${(index.amount / 100000000).toStringAsFixed(1)}亿',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // 右侧：趋势图表
          Expanded(
            flex: 3,
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 0.5,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: false,
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _mainIndexChart.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.price);
                      }).toList(),
                      isCurved: true,
                      color: index.isPositive
                          ? const Color(0xFFEF5350)
                          : const Color(0xFF4CAF50),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (index.isPositive
                                ? const Color(0xFFEF5350)
                                : const Color(0xFF4CAF50))
                            .withOpacity(0.1),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: _mainIndexChart.isNotEmpty
                      ? _mainIndexChart.length - 1
                      : 0,
                  minY: _mainIndexChart.isNotEmpty
                      ? _mainIndexChart
                              .map((e) => e.price)
                              .reduce((a, b) => a < b ? a : b) -
                          5
                      : 0,
                  maxY: _mainIndexChart.isNotEmpty
                      ? _mainIndexChart
                              .map((e) => e.price)
                              .reduce((a, b) => a > b ? a : b) +
                          5
                      : 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubIndicesList() {
    if (_marketData == null) {
      return const SizedBox();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '其他指数',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isSmallScreen)
              // 小屏幕：网格布局，自动换行
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _marketData!.subIndices.map((subIndex) {
                    return SizedBox(
                      width: (constraints.maxWidth - 12) / 2 - 6,
                      child: _buildRealSubIndexCard(subIndex),
                    );
                  }).toList(),
                ),
              )
            else
              // 大屏幕：水平滚动
              SizedBox(
                height: 120,
                child: Scrollbar(
                  controller: ScrollController(),
                  thumbVisibility: false,
                  trackVisibility: false,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _marketData!.subIndices.length,
                    itemBuilder: (context, index) {
                      final subIndex = _marketData!.subIndices[index];
                      return _buildRealSubIndexCard(subIndex);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRealSubIndexCard(IndexData index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            index.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            index.latestPrice.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${index.changePercent >= 0 ? '+' : '-'}${index.changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: index.isPositive
                  ? const Color(0xFFEF5350)
                  : const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}
