import 'package:flutter/material.dart';

/// 今日行情概览组件
/// 展示A股市场今日涨跌、涨停跌停等关键数据
class MarketTodayOverview extends StatefulWidget {
  const MarketTodayOverview({super.key});

  @override
  State<MarketTodayOverview> createState() => _MarketTodayOverviewState();
}

class _MarketTodayOverviewState extends State<MarketTodayOverview> {
  MarketTodayData? _todayData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    // 模拟数据加载
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _todayData = MarketTodayData(
        upCount: 6,
        downCount: 3,
        flatCount: 1,
        limitUpCount: 2,
        limitDownCount: 0,
        totalCount: 10,
        upPercentage: '60.0',
        downPercentage: '30.0',
        flatPercentage: '10.0',
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
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
            '核心指数涨跌统计',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),

          // 三卡片均分布局
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: '上涨',
                  count: _todayData?.upCount ?? 0,
                  percentage: _todayData?.upPercentage ?? '0.0',
                  color: const Color(0xFFEF5350),
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: '下跌',
                  count: _todayData?.downCount ?? 0,
                  percentage: _todayData?.downPercentage ?? '0.0',
                  color: const Color(0xFF4CAF50),
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: '涨停',
                  count: _todayData?.limitUpCount ?? 0,
                  percentage: '${_todayData?.limitUpCount ?? 0}',
                  color: const Color(0xFFFF9800),
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 涨跌分布文字化信息
          if (_todayData != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '核心指数涨跌分布',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '上涨 ${_todayData!.upPercentage}%（${_todayData!.upCount}个指数） | '
                    '下跌 ${_todayData!.downPercentage}%（${_todayData!.downCount}个指数） | '
                    '平盘 ${_todayData!.flatPercentage}%（${_todayData!.flatCount}个指数）',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_todayData!.upCount / _todayData!.totalCount),
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFEF5350)),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required String percentage,
    required Color color,
    required IconData icon,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
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
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Icon(icon, size: 16, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
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
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// 今日行情数据
class MarketTodayData {
  final int upCount;
  final int downCount;
  final int flatCount;
  final int limitUpCount;
  final int limitDownCount;
  final int totalCount;
  final String upPercentage;
  final String downPercentage;
  final String flatPercentage;

  MarketTodayData({
    required this.upCount,
    required this.downCount,
    required this.flatCount,
    required this.limitUpCount,
    required this.limitDownCount,
    required this.totalCount,
    required this.upPercentage,
    required this.downPercentage,
    required this.flatPercentage,
  });
}
