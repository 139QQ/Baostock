import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../../../../core/services/market_real_service.dart';

import '../../../../core/services/market_data_models.dart';

/// 真实数据市场概览组件（修复版）
/// 基于东方财富网API获取沪深市场核心指数实时行情数据
class EnhancedMarketRealFixed extends StatefulWidget {
  const EnhancedMarketRealFixed({super.key});

  @override
  State<EnhancedMarketRealFixed> createState() =>
      _EnhancedMarketRealFixedState();
}

class _EnhancedMarketRealFixedState extends State<EnhancedMarketRealFixed> {
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
      debugPrint('加载市场数据失败: $e');
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
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '市场行情',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    Row(
                      children: [
                        Text(
                          '自动刷新',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Switch(
                          value: _autoRefreshEnabled,
                          onChanged: _toggleAutoRefresh,
                          activeColor: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: _refreshData,
                      icon: _isRefreshing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.refresh, size: 16),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_autoRefreshEnabled)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF2563EB).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '自动刷新已开启 (30秒)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            _buildRealMainIndexCard(),
            SizedBox(height: 20),
            _buildOtherIndicesList(),
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
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildRealMainIndexCard() {
    if (_marketData == null) return const SizedBox();

    final mainIndex = _marketData!.mainIndex;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mainIndex.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            mainIndex.latestPrice.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                mainIndex.isPositive ? Icons.trending_up : Icons.trending_down,
                size: 20,
                color: mainIndex.isPositive ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                '${mainIndex.changeAmount >= 0 ? '+' : ''}${mainIndex.changeAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              Text(
                '${mainIndex.changePercent >= 0 ? '+' : ''}${mainIndex.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: mainIndex.isPositive ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherIndicesList() {
    if (_marketData == null) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '其他指数',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            if (isSmallScreen)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    _marketData!.subIndices.map(_buildSubIndexCard).toList(),
              )
            else
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      _marketData!.subIndices.map(_buildSubIndexCard).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSubIndexCard(IndexData index) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            index.latestPrice.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                index.isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: index.isPositive ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                '${index.changeAmount >= 0 ? '+' : ''}${index.changeAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: index.isPositive ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${index.changePercent >= 0 ? '+' : ''}${index.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: index.isPositive ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateTrendSpots(List<double> data) {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }
}
