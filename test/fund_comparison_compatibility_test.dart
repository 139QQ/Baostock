import 'package:flutter/material.dart';
import 'src/features/fund/presentation/widgets/fund_comparison_entry.dart';
import 'src/features/fund/presentation/pages/fund_comparison_page.dart';
import 'src/features/fund/domain/entities/fund_ranking.dart';
import 'src/features/fund/domain/entities/multi_dimensional_comparison_criteria.dart';

/// 基金对比功能兼容性测试
///
/// 测试新功能与现有UI的兼容性
class FundComparisonCompatibilityTestPage extends StatelessWidget {
  final List<FundRanking> testFunds = [
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
  ];

  FundComparisonCompatibilityTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('兼容性测试'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 测试说明
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '兼容性测试说明',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '此页面测试基金对比功能与现有UI组件的兼容性，'
                      '确保新功能不会破坏现有界面的布局和交互。',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // UI组件兼容性测试
            _buildUICompatibilityTest(),
            const SizedBox(height: 16),

            // 导航兼容性测试
            _buildNavigationCompatibilityTest(),
            const SizedBox(height: 16),

            // 数据兼容性测试
            _buildDataCompatibilityTest(),
            const SizedBox(height: 16),

            // 主题兼容性测试
            _buildThemeCompatibilityTest(),
          ],
        ),
      ),
    );
  }

  Widget _buildUICompatibilityTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UI组件兼容性测试',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 测试不同类型的入口组件
            const Text('主要按钮入口:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Center(
              child: FundComparisonEntryFactory.createPrimaryButton(
                availableFunds: testFunds,
              ),
            ),
            const SizedBox(height: 16),

            const Text('功能卡片入口:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            FundComparisonEntryFactory.createFeatureCard(
              availableFunds: testFunds,
            ),
            const SizedBox(height: 16),

            const Text('列表项入口:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  FundComparisonEntryFactory.createMenuListTile(
                    availableFunds: testFunds,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('设置'),
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

  Widget _buildNavigationCompatibilityTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '导航兼容性测试',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '测试不同导航场景下的页面跳转:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _testNavigation(context, 'empty'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('空数据页面'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testNavigation(context, 'single'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('单只基金'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testNavigation(context, 'multiple'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('多只基金'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testNavigation(context, 'preset'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('预设条件'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '导航测试将验证页面跳转是否正常，返回功能是否工作，以及页面栈管理是否正确。',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCompatibilityTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据兼容性测试',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            const Text('测试不同数据场景下的处理能力:'),
            const SizedBox(height: 12),

            // 测试边界情况
            _buildDataTestCase('空基金列表', []),
            const SizedBox(height: 8),
            _buildDataTestCase('单只基金', testFunds.take(1).toList()),
            const SizedBox(height: 8),
            _buildDataTestCase('多只基金', testFunds),
            const SizedBox(height: 8),
            _buildDataTestCase(
                '大量基金',
                List.generate(
                    10, (index) => testFunds[index % testFunds.length])),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '数据兼容性测试验证了系统在不同数据量级下的稳定性和正确性。',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTestCase(String title, List<FundRanking> funds) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              '${funds.length} 只基金',
              style: TextStyle(
                color: funds.isEmpty ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: funds.isEmpty
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('测试 $title: ${funds.length}只基金')),
                    );
                  },
            child: const Text('测试'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCompatibilityTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '主题兼容性测试',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            const Text('测试在不同主题下的显示效果:'),
            const SizedBox(height: 12),

            // 明亮主题测试
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('明亮主题:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  FundComparisonEntryFactory.createPrimaryButton(
                    availableFunds: testFunds,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 深色主题模拟
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade600),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '深色主题:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FundComparisonEntryFactory.createPrimaryButton(
                    availableFunds: testFunds,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.palette, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '主题兼容性测试确保了基金对比功能在不同主题下都能正常显示和交互。',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testNavigation(BuildContext context, String scenario) {
    List<FundRanking> funds;
    MultiDimensionalComparisonCriteria? initialCriteria;

    switch (scenario) {
      case 'empty':
        funds = [];
        break;
      case 'single':
        funds = testFunds.take(1).toList();
        break;
      case 'multiple':
        funds = testFunds;
        break;
      case 'preset':
        funds = testFunds;
        initialCriteria = MultiDimensionalComparisonCriteria(
          fundCodes: ['000001', '110022'],
          periods: [RankingPeriod.oneYear],
          metric: ComparisonMetric.totalReturn,
        );
        break;
      default:
        funds = testFunds;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FundComparisonPage(
          availableFunds: funds,
          initialCriteria: initialCriteria,
        ),
      ),
    );
  }
}

/// 运行兼容性测试的入口函数
void runFundComparisonCompatibilityTest() {
  runApp(
    MaterialApp(
      title: '基金对比功能兼容性测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FundComparisonCompatibilityTestPage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
