import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fund_exploration_cubit.dart';

/// 市场动态区域组件
///
/// 展示基金市场的最新动态信息，包括：
/// - 市场概况统计
/// - 热门板块表现
/// - 资金流向分析
/// - 市场情绪指标
class MarketDynamicsSection extends StatefulWidget {
  const MarketDynamicsSection({super.key});

  @override
  State<MarketDynamicsSection> createState() => _MarketDynamicsSectionState();
}

class _MarketDynamicsSectionState extends State<MarketDynamicsSection> {
  @override
  void initState() {
    super.initState();
    // 暂时不加载市场动态数据，等待后续实现
    // context.read<FundExplorationCubit>().loadMarketDynamics();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingWidget();
        }

        // 暂时使用模拟数据，后续实现真实数据
        final marketData = _getMockMarketData();

        return Card(
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 380, // 最大高度限制
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12), // 减少内边距
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题区域
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Color(0xFF1E40AF),
                          size: 20, // 减小图标
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            '市场动态',
                            style: TextStyle(
                              fontSize: 16, // 减小字体
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // 刷新数据 - 暂时不实现，等待后续添加市场动态功能
                            // context.read<FundExplorationCubit>().loadMarketDynamics();
                          },
                          child:
                              const Text('刷新', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // 减少间距

                    // 市场概况卡片
                    _buildMarketOverviewCard(marketData),
                    const SizedBox(height: 12), // 减少间距

                    // 热门板块表现
                    _buildHotSectorsCard(marketData),
                    const SizedBox(height: 12), // 减少间距

                    // 资金流向分析
                    _buildFundFlowCard(marketData),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建市场概况卡片
  Widget _buildMarketOverviewCard(dynamic marketData) {
    return Container(
      padding: const EdgeInsets.all(12), // 减少内边距
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '市场概况',
            style: TextStyle(
              fontSize: 14, // 减小字体
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8), // 减少间距
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                '上涨基金',
                '1865', // 模拟数据
                Colors.red,
                Icons.trending_up,
              ),
              _buildMetricItem(
                '下跌基金',
                '3161', // 模拟数据
                Colors.green,
                Icons.trending_down,
              ),
              _buildMetricItem(
                '平均收益',
                '-0.89%', // 模拟数据
                _getReturnColor(-0.89),
                Icons.show_chart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建热门板块卡片
  Widget _buildHotSectorsCard(dynamic marketData) {
    // 使用模拟数据，后续实现真实数据加载
    final sectors = [
      {'name': '新能源', 'change': 2.34},
      {'name': '医疗健康', 'change': 1.89},
      {'name': '科技成长', 'change': -0.56},
      {'name': '消费升级', 'change': 1.23},
    ];

    return Container(
      padding: const EdgeInsets.all(12), // 减少内边距
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '热门板块',
            style: TextStyle(
              fontSize: 14, // 减小字体
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8), // 减少间距
          if (sectors.isEmpty)
            const Text('暂无板块数据', style: TextStyle(fontSize: 12))
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: sectors.map<Widget>((sector) {
                return _buildSectorItem(sector);
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// 构建资金流向卡片
  Widget _buildFundFlowCard(dynamic marketData) {
    return Container(
      padding: const EdgeInsets.all(12), // 减少内边距
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '资金流向',
            style: TextStyle(
              fontSize: 14, // 减小字体
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8), // 减少间距
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFlowItem(
                '主力流入',
                '125.6亿', // 模拟数据
                Colors.red,
              ),
              _buildFlowItem(
                '主力流出',
                '98.3亿', // 模拟数据
                Colors.green,
              ),
              _buildFlowItem(
                '净流入',
                '27.3亿', // 模拟数据
                _getReturnColor(27.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建指标项
  Widget _buildMetricItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18), // 减小图标
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, // 减小字体
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10, // 减小字体
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // 构建板块项
  Widget _buildSectorItem(dynamic sector) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // 减少垂直间距
      child: Row(
        children: [
          Expanded(
            child: Text(
              sector['name'] ?? '未知板块',
              style: const TextStyle(fontSize: 12), // 减小字体
            ),
          ),
          Text(
            '${sector['change']?.toStringAsFixed(2) ?? "0.00"}%',
            style: TextStyle(
              fontSize: 12, // 减小字体
              fontWeight: FontWeight.bold,
              color: _getReturnColor(sector['change'] ?? 0),
            ),
          ),
          const SizedBox(width: 6), // 减少间距
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 减少内边距
            decoration: BoxDecoration(
              color: _getRankingColor(1), // 模拟排名
              borderRadius: BorderRadius.circular(8), // 减小圆角
            ),
            child: const Text(
              'TOP', // 模拟排名
              style: TextStyle(
                fontSize: 10, // 减小字体
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建资金流向项
  Widget _buildFlowItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14, // 减小字体
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10, // 减小字体
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 构建加载组件
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载市场动态数据...'),
        ],
      ),
    );
  }

  /// 获取收益率颜色
  Color _getReturnColor(double returnValue) {
    if (returnValue > 0) {
      return const Color(0xFFEF4444); // 红色 - 上涨
    } else if (returnValue < 0) {
      return const Color(0xFF10B981); // 绿色 - 下跌
    } else {
      return const Color(0xFF6B7280); // 灰色 - 平盘
    }
  }

  /// 获取排名颜色
  Color _getRankingColor(int ranking) {
    if (ranking <= 3) return Colors.red;
    if (ranking <= 10) return Colors.orange;
    if (ranking <= 20) return Colors.blue;
    return Colors.grey;
  }

  /// 获取模拟市场数据
  dynamic _getMockMarketData() {
    return {
      'totalFunds': 8500,
      'avgReturn1Y': 12.5,
      'totalAsset': 25000.0,
      'marketSentiment': '中性',
      'hotSectors': [
        {'name': '新能源', 'change': 3.2, 'ranking': 1},
        {'name': '半导体', 'change': 2.8, 'ranking': 2},
        {'name': '医药生物', 'change': 1.9, 'ranking': 3},
        {'name': '消费电子', 'change': 1.5, 'ranking': 4},
        {'name': '人工智能', 'change': 1.2, 'ranking': 5},
      ],
      'mainInflow': 45.6,
      'mainOutflow': 38.2,
      'netInflow': 7.4,
      'retailInflow': 23.1,
      'retailOutflow': 19.8,
    };
  }
}
