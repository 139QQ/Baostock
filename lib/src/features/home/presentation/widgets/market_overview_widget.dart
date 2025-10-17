import 'package:flutter/material.dart';

/// 市场概览组件
///
/// 展示主要市场指数的实时数据和涨跌情况，包括：
/// - 上证指数
/// - 深证成指
/// - 创业板指
/// - 沪深300指数
class MarketOverviewWidget extends StatelessWidget {
  /// 构造函数
  const MarketOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '市场指数',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIndexCard(
                  '上证指数',
                  '3,256.78',
                  '+1.25%',
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIndexCard(
                  '深证成指',
                  '10,875.43',
                  '-0.85%',
                  false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIndexCard(
                  '创业板指',
                  '2,145.67',
                  '+2.34%',
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIndexCard(
                  '沪深300',
                  '4,123.45',
                  '+0.56%',
                  true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建指数卡片
  ///
  /// [name] 指数名称
  /// [value] 当前数值
  /// [change] 涨跌幅字符串
  /// [isPositive] 是否为正增长
  Widget _buildIndexCard(
    String name,
    String value,
    String change,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
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
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isPositive
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isPositive
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFEF5350),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
