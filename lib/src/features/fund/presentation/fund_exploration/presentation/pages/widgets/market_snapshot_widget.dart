import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 市场快照组件
///
/// 展示关键市场指数和行情数据，采用微动交互设计
class MarketSnapshotWidget extends StatefulWidget {
  const MarketSnapshotWidget({super.key});

  @override
  State<MarketSnapshotWidget> createState() => _MarketSnapshotWidgetState();
}

class _MarketSnapshotWidgetState extends State<MarketSnapshotWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题区域
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.show_chart_rounded,
                color: Colors.blue[600],
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '市场快照',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            Text(
              '实时更新',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 指数卡片网格
        _buildIndexGrid(),
      ],
    );
  }

  Widget _buildIndexGrid() {
    final indices = [
      MarketIndex(
        name: '上证指数',
        code: 'SH000001',
        value: 3087.53,
        change: 1.24,
        changePercent: 0.04,
        trend: MarketTrend.up,
      ),
      MarketIndex(
        name: '深证成指',
        code: 'SZ399001',
        value: 9787.99,
        change: 15.42,
        changePercent: 0.16,
        trend: MarketTrend.up,
      ),
      MarketIndex(
        name: '创业板指',
        code: 'SZ399006',
        value: 1934.87,
        change: 8.97,
        changePercent: 0.47,
        trend: MarketTrend.up,
      ),
      MarketIndex(
        name: '科创50',
        code: 'SH000688',
        value: 873.31,
        change: -3.45,
        changePercent: -0.39,
        trend: MarketTrend.down,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: indices.length,
      itemBuilder: (context, index) {
        return _buildIndexCard(indices[index], index);
      },
    );
  }

  Widget _buildIndexCard(MarketIndex index, int cardIndex) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value.dy * (cardIndex + 1) * 10),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + cardIndex * 100),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              _showIndexDetails(index);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: index.trend == MarketTrend.up
                      ? [
                          Colors.green[50]!,
                          Colors.green[100]!,
                        ]
                      : [
                          Colors.red[50]!,
                          Colors.red[100]!,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: index.trend == MarketTrend.up
                      ? Colors.green[200]!
                      : Colors.red[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        index.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: index.trend == MarketTrend.up
                              ? Colors.green[600]
                              : Colors.red[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          index.trend == MarketTrend.up
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    index.value.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${index.change > 0 ? '+' : ''}${index.change.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: index.trend == MarketTrend.up
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: index.trend == MarketTrend.up
                              ? Colors.green[600]
                              : Colors.red[600],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${index.changePercent > 0 ? '+' : ''}${index.changePercent.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showIndexDetails(MarketIndex index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildIndexDetailsSheet(index),
    );
  }

  Widget _buildIndexDetailsSheet(MarketIndex index) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示器
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      index.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: index.trend == MarketTrend.up
                            ? Colors.green[100]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        index.code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: index.trend == MarketTrend.up
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow('当前值', index.value.toStringAsFixed(2)),
                _buildDetailRow('涨跌额',
                    '${index.change > 0 ? '+' : ''}${index.change.toStringAsFixed(2)}'),
                _buildDetailRow('涨跌幅',
                    '${index.changePercent > 0 ? '+' : ''}${index.changePercent.toStringAsFixed(2)}%'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  '相关基金推荐',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildRelatedFunds(index),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedFunds(MarketIndex index) {
    // 模拟相关基金
    final funds = ['科技先锋混合A', '创新成长股票', '数字经济ETF'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: funds.map((fund) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            fund,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MarketIndex {
  final String name;
  final String code;
  final double value;
  final double change;
  final double changePercent;
  final MarketTrend trend;

  MarketIndex({
    required this.name,
    required this.code,
    required this.value,
    required this.change,
    required this.changePercent,
    required this.trend,
  });
}

enum MarketTrend {
  up,
  down,
  flat,
}
