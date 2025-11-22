import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/features/fund/presentation/fund_exploration/domain/models/fund.dart';
import '../../src/features/fund/presentation/fund_exploration/presentation/widgets/microinteractive_fund_card.dart';

/// 简化版微交互基金卡片演示
void main() {
  runApp(const MicrointeractionSimpleDemo());
}

class MicrointeractionSimpleDemo extends StatelessWidget {
  const MicrointeractionSimpleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '微交互基金卡片 - 简化演示',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MicrointeractionDemoPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MicrointeractionDemoPage extends StatefulWidget {
  const MicrointeractionDemoPage({super.key});

  @override
  State<MicrointeractionDemoPage> createState() =>
      _MicrointeractionDemoPageState();
}

class _MicrointeractionDemoPageState extends State<MicrointeractionDemoPage> {
  bool _enableAnimations = true;
  final ScrollController _scrollController = ScrollController();

  final List<Fund> _testFunds = [
    Fund(
      code: '110022',
      name: '易方达消费行业股票',
      type: '股票型',
      company: '易方达基金',
      manager: '萧楠',
      return1W: 0.5,
      return1M: 2.3,
      return3M: 5.6,
      return6M: 8.9,
      return1Y: 15.6,
      return3Y: 45.2,
      scale: 85.6,
      riskLevel: 'R3',
      status: '正常',
      isFavorite: false,
    ),
    Fund(
      code: '000001',
      name: '华夏成长混合',
      type: '混合型',
      company: '华夏基金',
      manager: '张坤',
      return1W: -0.2,
      return1M: 1.5,
      return3M: 3.8,
      return6M: 12.3,
      return1Y: 28.9,
      return3Y: 65.4,
      scale: 156.8,
      riskLevel: 'R4',
      status: '正常',
      isFavorite: true,
    ),
    Fund(
      code: '161725',
      name: '招商中证白酒指数分级',
      type: '指数型',
      company: '招商基金',
      manager: '侯昊',
      return1W: -1.8,
      return1M: -3.2,
      return3M: 8.5,
      return6M: 18.7,
      return1Y: -5.3,
      return3Y: 45.8,
      scale: 785.2,
      riskLevel: 'R4',
      status: '正常',
      isFavorite: false,
    ),
    Fund(
      code: '005827',
      name: '易方达蓝筹精选混合',
      type: '混合型',
      company: '易方达基金',
      manager: '张坤',
      return1W: 1.2,
      return1M: 4.5,
      return3M: 12.3,
      return6M: 23.4,
      return1Y: 35.7,
      return3Y: 125.6,
      scale: 268.9,
      riskLevel: 'R3',
      status: '正常',
      isFavorite: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('微交互基金卡片演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
                _enableAnimations ? Icons.animation : Icons.animation_outlined),
            onPressed: () {
              setState(() {
                _enableAnimations = !_enableAnimations;
              });
            },
            tooltip: _enableAnimations ? '禁用动画' : '启用动画',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoCard(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _testFunds.length,
              itemBuilder: (context, index) {
                final fund = _testFunds[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: MicrointeractiveFundCard(
                    fund: fund,
                    enableAnimations: _enableAnimations,
                    onTap: () => _showSnackBar('点击了 ${fund.name}'),
                    onAddToWatchlist: () {
                      _showSnackBar(
                          '${fund.isFavorite ? '取消' : '添加'}收藏 ${fund.name}');
                    },
                    onCompare: () {
                      _showSnackBar('将 ${fund.name} 加入对比');
                    },
                    onShare: () {
                      _showSnackBar('分享 ${fund.name}');
                    },
                    onSwipeLeft: () {
                      _showSnackBar('左滑收藏 ${fund.name}');
                      HapticFeedback.mediumImpact();
                    },
                    onSwipeRight: () {
                      _showSnackBar('右滑对比 ${fund.name}');
                      HapticFeedback.mediumImpact();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPerformanceInfo(),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '微交互基金卡片演示',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '展示悬停动画、数字滚动、手势操作等微交互效果',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureList(),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem('悬停动画', '卡片上浮 + 阴影渐变效果'),
        _buildFeatureItem('数字滚动', '收益率数字平滑动画'),
        _buildFeatureItem('触觉反馈', '点击时的震动反馈'),
        _buildFeatureItem('手势操作', '左滑收藏，右滑对比'),
        _buildFeatureItem('按钮动画', '收藏/对比按钮微动画'),
        _buildFeatureItem('性能优化', '设备自适应动画级别'),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '性能监控',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetric('动画状态', _enableAnimations ? '启用' : '禁用'),
              ),
              Expanded(
                child: _buildMetric('设备类型', _getDeviceType()),
              ),
              Expanded(
                child: _buildMetric('渲染模式', '优化中'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.7),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  String _getDeviceType() {
    final screenWidth = MediaQuery.of(context).size.width;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (screenWidth < 600 || pixelRatio < 2.0) {
      return '低端设备';
    } else if (screenWidth > 1200) {
      return '桌面设备';
    } else {
      return '标准设备';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
