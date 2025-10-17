import 'package:flutter/material.dart';

/// 简化版热门板块组件
///
/// 提供基本的热门板块展示功能，不依赖外部数据源
class HotSectorsWidget extends StatelessWidget {
  final String? title;
  final EdgeInsetsGeometry? padding;
  final int maxItems;

  const HotSectorsWidget({
    super.key,
    this.title,
    this.padding,
    this.maxItems = 5,
  });

  // 模拟热门板块数据
  static const List<Map<String, dynamic>> _mockSectorsData = [
    {'name': '新能源', 'changePercent': 3.45, 'price': 2846.32},
    {'name': '半导体', 'changePercent': 2.18, 'price': 1876.54},
    {'name': '医药生物', 'changePercent': -1.23, 'price': 3267.89},
    {'name': '人工智能', 'changePercent': 4.67, 'price': 4231.76},
    {'name': '5G通信', 'changePercent': 1.89, 'price': 2345.67},
    {'name': '新材料', 'changePercent': -0.45, 'price': 1987.34},
    {'name': '云计算', 'changePercent': 2.91, 'price': 3567.12},
    {'name': '物联网', 'changePercent': 1.56, 'price': 2789.43},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title ?? '热门板块',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 板块列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mockSectorsData.length > maxItems
                ? maxItems
                : _mockSectorsData.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sector = _mockSectorsData[index];
              return _buildSectorItem(sector, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectorItem(Map<String, dynamic> sector, int index) {
    final name = sector['name'] as String;
    final changePercent = sector['changePercent'] as double;
    final price = sector['price'] as double;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 排名
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getRankColor(index + 1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 板块名称
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // 价格
          Text(
            price.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),

          // 涨跌幅
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: changePercent >= 0
                  ? const Color(0xFFEF5350).withOpacity(0.1)
                  : const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: changePercent >= 0
                    ? const Color(0xFFEF5350)
                    : const Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFF9800); // 金色
      case 2:
        return const Color(0xFF9E9E9E); // 银色
      case 3:
        return const Color(0xFF795548); // 铜色
      default:
        return const Color(0xFF2563EB); // 蓝色
    }
  }
}
