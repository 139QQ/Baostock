import 'package:flutter/material.dart';

import '../../domain/entities/fund_ranking.dart';

/// 排行榜统计信息组件
///
/// 显示当前排行榜的统计信息，包括：
/// - 总基金数量
/// - 平均收益率
/// - 最高/最低收益率
/// - 正负收益基金数量
/// - 更新时间
class RankingStatistics extends StatelessWidget {
  final RankingStatistics statistics;

  const RankingStatistics({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '排行榜统计',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '更新于 ${_formatTime(statistics.updateTime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 统计数据网格
          _buildStatisticsGrid(context),

          const SizedBox(height: 12),

          // 收益分布
          _buildReturnDistribution(context),
        ],
      ),
    );
  }

  /// 构建统计数据网格
  Widget _buildStatisticsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 1.5,
      children: [
        _buildStatItem(
          context,
          '总基金数',
          statistics.totalFunds.toString(),
          Icons.pie_chart_outline,
          Theme.of(context).colorScheme.primary,
        ),
        _buildStatItem(
          context,
          '平均收益',
          '${statistics.averageReturn.toStringAsFixed(2)}%',
          Icons.trending_up,
          _getReturnColor(statistics.averageReturn),
        ),
        _buildStatItem(
          context,
          '最高收益',
          '${statistics.maxReturn.toStringAsFixed(2)}%',
          Icons.arrow_upward,
          const Color(0xFF10B981),
        ),
        _buildStatItem(
          context,
          '最低收益',
          '${statistics.minReturn.toStringAsFixed(2)}%',
          Icons.arrow_downward,
          const Color(0xFFEF4444),
        ),
      ],
    );
  }

  /// 构建单个统计项
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建收益分布
  Widget _buildReturnDistribution(BuildContext context) {
    final positiveCount = statistics.positiveReturnCount;
    final negativeCount = statistics.negativeReturnCount;
    final total = statistics.totalFunds;

    final positivePercentage = total > 0 ? (positiveCount / total * 100) : 0;
    final negativePercentage = total > 0 ? (negativeCount / total * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '收益分布',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),

          // 进度条
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: positiveCount,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: negativeCount,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 分布详情
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDistributionItem(
                '盈利基金',
                positiveCount,
                positivePercentage,
                const Color(0xFF10B981),
              ),
              _buildDistributionItem(
                '亏损基金',
                negativeCount,
                negativePercentage,
                const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建分布项
  Widget _buildDistributionItem(
    String label,
    int count,
    double percentage,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '$count (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${dateTime.month}-${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 获取收益率颜色
  Color _getReturnColor(double returnValue) {
    if (returnValue > 0) {
      return const Color(0xFF10B981); // 绿色
    } else if (returnValue < 0) {
      return const Color(0xFFEF4444); // 红色
    } else {
      return Colors.grey[600]!; // 灰色
    }
  }
}
