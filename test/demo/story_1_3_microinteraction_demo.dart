// ignore_for_file: directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/features/fund/presentation/fund_exploration/domain/models/fund.dart';
import '../../src/features/fund/presentation/fund_exploration/presentation/widgets/fund_card.dart';
import '../../src/features/fund/presentation/fund_exploration/presentation/widgets/microinteractive_fund_card.dart';
import '../../src/features/fund/presentation/fund_exploration/presentation/widgets/adaptive_fund_card.dart';

/// Story 1.3 微交互基金卡片演示应用
///
/// 展示微交互基金卡片的各种功能和效果：
/// - 对比原版、微交互版、自适应版
/// - 性能监控
/// - 不同屏幕尺寸适配
/// - 动画效果演示
void main() {
  runApp(const Story13MicrointeractionDemo());
}

class Story13MicrointeractionDemo extends StatelessWidget {
  const Story13MicrointeractionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story 1.3 - 微交互基金卡片演示',
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

class _MicrointeractionDemoPageState extends State<MicrointeractionDemoPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  bool _enableAnimations = true;
  bool _showPerformanceInfo = true;
  int _cardCount = 0;
  DateTime? _lastRenderTime;
  Duration? _renderDuration;

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
    Fund(
      code: '110011',
      name: '易方达上证50指数',
      type: '指数型',
      company: '易方达基金',
      manager: '林伟斌',
      return1W: 0.8,
      return1M: 3.1,
      return3M: 7.2,
      return6M: 15.8,
      return1Y: 22.4,
      return3Y: 58.9,
      scale: 325.6,
      riskLevel: 'R3',
      status: '正常',
      isFavorite: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startPerformanceMonitoring();
  }

  void _startPerformanceMonitoring() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureRenderPerformance();
    });
  }

  void _measureRenderPerformance() {
    _lastRenderTime = DateTime.now();
    _cardCount = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastRenderTime != null) {
        _renderDuration = DateTime.now().difference(_lastRenderTime!);
        setState(() {});
      }
    });
  }

  void _handleCardTap(Fund fund) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('点击了 ${fund.name}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleFavoriteToggle(Fund fund) {
    setState(() {
      // 这里应该更新收藏状态，为了演示我们只显示消息
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${fund.isFavorite ? '取消' : '添加'}收藏 ${fund.name}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleCompare(Fund fund) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('将 ${fund.name} 加入对比'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleShare(Fund fund) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('分享 ${fund.name}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleSwipeLeft(Fund fund) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('左滑收藏 ${fund.name}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleSwipeRight(Fund fund) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('右滑对比 ${fund.name}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story 1.3 - 微交互基金卡片'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '原版卡片'),
            Tab(text: '微交互卡片'),
            Tab(text: '自适应卡片'),
          ],
        ),
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
          IconButton(
            icon:
                Icon(_showPerformanceInfo ? Icons.speed : Icons.speed_outlined),
            onPressed: () {
              setState(() {
                _showPerformanceInfo = !_showPerformanceInfo;
              });
            },
            tooltip: _showPerformanceInfo ? '隐藏性能信息' : '显示性能信息',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOriginalCards(),
          _buildMicrointeractiveCards(),
          _buildAdaptiveCards(),
        ],
      ),
      bottomNavigationBar: _buildPerformanceInfo(),
    );
  }

  Widget _buildOriginalCards() {
    _measureRenderPerformance();

    return Column(
      children: [
        _buildInfoCard(
          '原版基金卡片',
          '展示基础的原版FundCard组件功能',
          Icons.card_giftcard,
        ),
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
                child: FundCard(
                  fund: fund,
                  onTap: () => _handleCardTap(fund),
                  onAddToWatchlist: () => _handleFavoriteToggle(fund),
                  onCompare: () => _handleCompare(fund),
                  onShare: () => _handleShare(fund),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMicrointeractiveCards() {
    return Column(
      children: [
        _buildInfoCard(
          '微交互基金卡片',
          '展示丰富的微交互效果：悬停动画、数字滚动、触觉反馈、手势操作等',
          Icons.touch_app,
        ),
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
                  onTap: () => _handleCardTap(fund),
                  onAddToWatchlist: () => _handleFavoriteToggle(fund),
                  onCompare: () => _handleCompare(fund),
                  onShare: () => _handleShare(fund),
                  onSwipeLeft: () => _handleSwipeLeft(fund),
                  onSwipeRight: () => _handleSwipeRight(fund),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveCards() {
    return Column(
      children: [
        _buildInfoCard(
          '自适应基金卡片',
          '根据设备性能自动调整动画和效果的智能卡片组件',
          Icons.auto_fix_high,
        ),
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
                child: AdaptiveFundCard(
                  fund: fund,
                  onTap: () => _handleCardTap(fund),
                  onAddToWatchlist: () => _handleFavoriteToggle(fund),
                  onCompare: () => _handleCompare(fund),
                  onShare: () => _handleShare(fund),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String description, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
    if (!_showPerformanceInfo) {
      return const SizedBox.shrink();
    }

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
                child: _buildPerformanceMetric(
                  '渲染时间',
                  _renderDuration?.inMilliseconds ?? 0,
                  'ms',
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  '动画状态',
                  _enableAnimations ? '启用' : '禁用',
                  '',
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  '设备类型',
                  _getDeviceType(),
                  '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, dynamic value, String unit) {
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
        Row(
          children: [
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.7),
                    ),
              ),
            ],
          ],
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

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
