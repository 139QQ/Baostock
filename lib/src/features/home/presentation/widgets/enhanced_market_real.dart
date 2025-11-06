import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/services/market_real_service.dart';
import '../../../../core/services/market_data_models.dart';
import '../../../../core/utils/logger.dart';

/// 真实数据市场概览组件
/// 基于AKShare API获取沪深市场核心指数实时行情数据
class EnhancedMarketReal extends StatefulWidget {
  const EnhancedMarketReal({super.key});

  @override
  State<EnhancedMarketReal> createState() => _EnhancedMarketRealState();
}

class _EnhancedMarketRealState extends State<EnhancedMarketReal> {
  late final MarketRealService _marketService;
  MarketIndicesData? _marketData;
  List<ChartPoint> _mainIndexChart = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _autoRefreshEnabled = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _marketService = marketRealService;
    _loadMarketData();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoRefresh(bool enabled) {
    setState(() {
      _autoRefreshEnabled = enabled;
    });

    if (enabled) {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted) {
          _refreshData();
        }
      });
    } else {
      _autoRefreshTimer?.cancel();
    }
  }

  Future<void> _loadMarketData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _marketService.getRealTimeIndices();
      final chartData = await _marketService.getIndexRecentHistory('000001');

      if (mounted) {
        setState(() {
          _marketData = data;
          _mainIndexChart = chartData.take(5).toList();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      AppLogger.debug('加载市场数据失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    await _loadMarketData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '市场行情',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    // 自动刷新开关
                    Row(
                      children: [
                        const Text(
                          '自动刷新',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _autoRefreshEnabled,
                          onChanged: _toggleAutoRefresh,
                          activeColor: const Color(0xFF3B82F6),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // 刷新按钮
                    GestureDetector(
                      onTap: _refreshData,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _isRefreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF3B82F6),
                                  ),
                                ),
                              )
                            : const Icon(Icons.refresh,
                                size: 16, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 刷新状态提示
            if (_autoRefreshEnabled)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '自动刷新已开启 (30秒)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // 主指数区域：上证指数
            _buildRealMainIndexCard(),
            const SizedBox(height: 20),

            // 其他指数水平滚动列表
            _buildOtherIndicesScrollList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
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
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildRealMainIndexCard() {
    if (_marketData == null) return const SizedBox();

    final index = _marketData!.mainIndex;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
        children: [
          Row(
            children: [
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
                    // 核心数据突出显示：上证指数数值
                    Text(
                      index.latestPrice.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${index.changeAmount >= 0 ? '+' : '-'}${index.changeAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: index.isPositive
                                ? const Color(0xFFEF5350)
                                : const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                    const SizedBox(height: 16),
                    Text(
                      '成交量：${(index.volume / 10000).toStringAsFixed(0)}万手',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '成交额：${(index.amount / 100000000).toStringAsFixed(1)}亿',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 120,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 20,
                        verticalInterval: 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFFE2E8F0),
                          strokeWidth: 0.5,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: const Color(0xFFE2E8F0),
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _mainIndexChart
                              .asMap()
                              .entries
                              .map((e) =>
                                  FlSpot(e.key.toDouble(), e.value.price))
                              .toList(),
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
                      maxX: _mainIndexChart.length.toDouble() - 1,
                      minY: _mainIndexChart
                              .map((e) => e.price)
                              .reduce((a, b) => a < b ? a : b) -
                          5,
                      maxY: _mainIndexChart
                              .map((e) => e.price)
                              .reduce((a, b) => a > b ? a : b) +
                          5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherIndicesScrollList() {
    if (_marketData == null) return const SizedBox();

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
                      child: _buildExpandedIndexCard(subIndex),
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
                      return _buildExpandedIndexCard(subIndex);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildExpandedIndexCard(IndexData index) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 指数名称
                Text(
                  index.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // 价格信息
                Text(
                  index.latestPrice.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                // 涨跌幅
                Row(
                  children: [
                    Icon(
                      index.isPositive
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 12,
                      color: index.isPositive
                          ? const Color(0xFFEF5350)
                          : const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 2),
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
                const SizedBox(height: 4),
                // 成交量 - 简化显示
                Text(
                  '${(index.volume / 100000000).toStringAsFixed(1)}亿',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
