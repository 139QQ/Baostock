import 'package:flutter/material.dart';

/// 增强版市场行情统计组件
///
/// 将传统的数字展示升级为可视化的柱状图+动态数字
/// - 使用百分比柱状图直观展示涨跌比例
/// - 添加动画效果增强数据变化感知
/// - 集成涨停跌停数据
class EnhancedMarketStats extends StatefulWidget {
  const EnhancedMarketStats({super.key});

  @override
  State<EnhancedMarketStats> createState() => _EnhancedMarketStatsState();
}

class _EnhancedMarketStatsState extends State<EnhancedMarketStats>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _upAnimation;
  late Animation<double> _downAnimation;
  late Animation<double> _limitUpAnimation;

  // 模拟数据
  final int upStocks = 2156;
  final int downStocks = 1843;
  final int limitUpStocks = 45;
  final int limitDownStocks = 12;
  final int totalStocks = 5000;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _upAnimation = Tween<double>(begin: 0, end: upStocks / totalStocks)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _downAnimation = Tween<double>(begin: 0, end: downStocks / totalStocks)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _limitUpAnimation = Tween<double>(
            begin: 0, end: limitUpStocks / totalStocks)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upPercent = (upStocks / totalStocks * 100).toStringAsFixed(1);
    final downPercent = (downStocks / totalStocks * 100).toStringAsFixed(1);
    final limitUpPercent =
        (limitUpStocks / totalStocks * 100).toStringAsFixed(2);

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
            '今日行情',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: '上涨',
                  count: upStocks,
                  percentage: upPercent,
                  color: const Color(0xFF4CAF50),
                  animation: _upAnimation,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  label: '下跌',
                  count: downStocks,
                  percentage: downPercent,
                  color: const Color(0xFFEF5350),
                  animation: _downAnimation,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  label: '涨停',
                  count: limitUpStocks,
                  percentage: limitUpPercent,
                  color: const Color(0xFFFF9800), // 涨停保持橙色特殊处理
                  animation: _limitUpAnimation,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 百分比柱状图
          const Text(
            '涨跌分布',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          _buildPercentageBar(),

          const SizedBox(height: 16),

          // 涨跌比例文字说明
          _buildStatsSummary(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required String percentage,
    required Color color,
    required Animation<double> animation,
    required IconData icon,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPercentageBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 上涨部分
          Expanded(
            flex: upStocks,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF4CAF50)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.horizontal(
                  left: const Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  '${(upStocks / totalStocks * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // 下跌部分
          Expanded(
            flex: downStocks,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEF5350), Color(0xFFEF5350)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.horizontal(
                  right: const Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  '${(downStocks / totalStocks * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '总股票数: $totalStocks',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          '平盘: ${totalStocks - upStocks - downStocks}',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
