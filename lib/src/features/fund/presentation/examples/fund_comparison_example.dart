import 'package:flutter/material.dart';
import '../../domain/entities/fund_ranking.dart';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../widgets/fund_comparison_entry.dart';

/// 基金对比功能使用示例
///
/// 展示如何在现有页面中集成基金对比功能
class FundComparisonExample extends StatelessWidget {
  /// 示例基金数据
  final List<FundRanking> sampleFunds = [
    const FundRanking(
      fundCode: '000001',
      fundName: '华夏成长混合',
      fundType: '混合型',
      totalReturn: 0.156,
      annualizedReturn: 0.142,
      volatility: 0.186,
      sharpeRatio: 0.763,
      maxDrawdown: -0.213,
      ranking: 15,
      period: RankingPeriod.oneYear,
      updateDate: '2024-01-15',
      benchmark: '沪深300',
      beatBenchmarkPercent: 2.3,
      beatCategoryPercent: 5.7,
      category: '混合型',
      categoryRanking: 23,
      totalCategoryCount: 456,
    ),
    const FundRanking(
      fundCode: '110022',
      fundName: '易方达消费行业股票',
      fundType: '股票型',
      totalReturn: 0.089,
      annualizedReturn: 0.085,
      volatility: 0.195,
      sharpeRatio: 0.436,
      maxDrawdown: -0.245,
      ranking: 28,
      period: RankingPeriod.oneYear,
      updateDate: '2024-01-15',
      benchmark: '中证消费指数',
      beatBenchmarkPercent: -1.2,
      beatCategoryPercent: 1.8,
      category: '股票型',
      categoryRanking: 67,
      totalCategoryCount: 523,
    ),
    const FundRanking(
      fundCode: '161725',
      fundName: '招商中证白酒指数',
      fundType: '指数型',
      totalReturn: -0.034,
      annualizedReturn: -0.032,
      volatility: 0.221,
      sharpeRatio: -0.145,
      maxDrawdown: -0.312,
      ranking: 89,
      period: RankingPeriod.oneYear,
      updateDate: '2024-01-15',
      benchmark: '中证白酒指数',
      beatBenchmarkPercent: -0.5,
      beatCategoryPercent: -2.1,
      category: '指数型',
      categoryRanking: 134,
      totalCategoryCount: 289,
    ),
  ];

  FundComparisonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金对比示例'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 示例标题
            Text(
              '基金对比功能集成示例',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '以下展示了不同场景下基金对比功能的使用方式',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),

            // 示例1：主要按钮入口
            _buildExample1(),
            const SizedBox(height: 24),

            // 示例2：功能卡片入口
            _buildExample2(),
            const SizedBox(height: 24),

            // 示例3：预选基金对比
            _buildExample3(),
            const SizedBox(height: 24),

            // 示例4：列表菜单入口
            _buildExample4(),
            const SizedBox(height: 24),

            // 示例5：代码示例
            _buildCodeExample(),
          ],
        ),
      ),
      floatingActionButton: FundComparisonEntryFactory.createFloatingAction(
        availableFunds: sampleFunds,
      ),
    );
  }

  Widget _buildExample1() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '示例1：主要按钮入口',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在基金列表页面中添加主要的对比入口按钮',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: FundComparisonEntryFactory.createPrimaryButton(
                availableFunds: sampleFunds,
                onTap: () {
                  debugPrint('主要对比按钮被点击');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExample2() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '示例2：功能卡片入口',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在首页或功能展示页面使用卡片形式展示对比功能',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            FundComparisonEntryFactory.createFeatureCard(
              availableFunds: sampleFunds,
              onTap: () {
                debugPrint('功能卡片被点击');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExample3() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '示例3：预选基金对比',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在基金详情页面添加"加入对比"功能，支持预选基金',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            FundComparisonEntry(
              availableFunds: sampleFunds,
              preselectedFunds: ['000001', '110022'],
              entryType: FundComparisonEntryType.card,
              title: '对比已选择的基金',
              description: '点击查看详细对比分析',
              icon: Icons.compare_arrows,
              onTap: () {
                debugPrint('预选基金对比被点击');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExample4() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '示例4：列表菜单入口',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在抽屉菜单或设置页面中添加对比功能入口',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  FundComparisonEntryFactory.createMenuListTile(
                    availableFunds: sampleFunds,
                    onTap: () {
                      debugPrint('菜单列表项被点击');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('其他功能'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeExample() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '示例5：代码集成',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在现有页面中集成基金对比功能的代码示例',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '''// 1. 导入必要的包
import 'package:flutter/material.dart';
import '../widgets/fund_comparison_entry.dart';
import '../routes/fund_comparison_routes.dart';

// 2. 在build方法中添加对比入口
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // 其他内容...

        // 添加对比入口
        FundComparisonEntryFactory.createPrimaryButton(
          availableFunds: fundList,
          preselectedFunds: selectedFunds,
          onTap: () => _onComparisonTap(),
        ),
      ],
    ),
  );
}

// 3. 处理点击事件
void _onComparisonTap() {
  FundComparisonRoutes.navigateToComparison(
    context,
    availableFunds: fundList,
    initialCriteria: MultiDimensionalComparisonCriteria(
      fundCodes: ['000001', '110022'],
      periods: [RankingPeriod.oneYear],
    ),
  );
}''',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 基金对比功能演示页面
///
/// 使用方法：
/// 1. 在现有页面中导入FundComparisonEntryFactory
/// 2. 根据需要选择合适的入口类型
/// 3. 准备基金数据列表
/// 4. 调用对应的创建方法
class FundComparisonDemo extends StatelessWidget {
  const FundComparisonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基金对比示例',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: FundComparisonExample(),
    );
  }
}
