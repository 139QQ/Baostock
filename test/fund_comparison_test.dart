import 'package:flutter/material.dart';
import 'src/features/fund/domain/entities/fund_ranking.dart';
import 'src/features/fund/domain/entities/multi_dimensional_comparison_criteria.dart';
import 'src/features/fund/presentation/pages/fund_comparison_page.dart';
import 'src/features/fund/presentation/widgets/fund_comparison_entry.dart';

/// 基金对比功能测试页面
///
/// 用于测试基金对比功能的完整流程
class FundComparisonTestPage extends StatelessWidget {
  /// 测试用的基金数据
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
    const FundRanking(
      fundCode: '000311',
      fundName: '景顺长城沪深300增强',
      fundType: '指数增强型',
      totalReturn: 0.124,
      annualizedReturn: 0.118,
      volatility: 0.168,
      sharpeRatio: 0.702,
      maxDrawdown: -0.189,
      ranking: 22,
      period: RankingPeriod.oneYear,
      updateDate: '2024-01-15',
      benchmark: '沪深300',
      beatBenchmarkPercent: 3.1,
      beatCategoryPercent: 8.2,
      category: '指数增强型',
      categoryRanking: 8,
      totalCategoryCount: 67,
    ),
    const FundRanking(
      fundCode: '005827',
      fundName: '易方达蓝筹精选混合',
      fundType: '混合型',
      totalReturn: 0.192,
      annualizedReturn: 0.178,
      volatility: 0.201,
      sharpeRatio: 0.886,
      maxDrawdown: -0.221,
      ranking: 8,
      period: RankingPeriod.oneYear,
      updateDate: '2024-01-15',
      benchmark: '沪深300',
      beatBenchmarkPercent: 5.8,
      beatCategoryPercent: 12.3,
      category: '混合型',
      categoryRanking: 12,
      totalCategoryCount: 456,
    ),
  ];

  FundComparisonTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金对比功能测试'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _testFullComparison(context),
            icon: const Icon(Icons.play_arrow),
            tooltip: '测试完整流程',
          ),
        ],
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
                          '测试说明',
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
                      '此页面用于测试基金多维对比功能的各种使用场景。'
                      '包含了不同类型的入口组件和完整的对比流程演示。',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 基金数据概览
            _buildFundOverview(),
            const SizedBox(height: 16),

            // 入口组件测试
            _buildEntryTests(),
            const SizedBox(height: 16),

            // 对比条件预设
            _buildPresetScenarios(),
            const SizedBox(height: 16),

            // 快速操作
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildFundOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '测试基金数据 (${testFunds.length}只)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...testFunds.map((fund) => _buildFundItem(fund)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFundItem(FundRanking fund) {
    final isPositive = fund.totalReturn >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Text(
              fund.fundCode,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              fund.fundName,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(fund.totalReturn * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color:
                      isPositive ? Colors.green.shade700 : Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            width: 50,
            child: Text(
              fund.fundType,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTests() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '入口组件测试',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 按钮入口
            const Text('主要按钮入口：',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Center(
              child: FundComparisonEntryFactory.createPrimaryButton(
                availableFunds: testFunds,
                onTap: () => debugPrint('主要按钮点击'),
              ),
            ),
            const SizedBox(height: 16),

            // 功能卡片
            const Text('功能卡片入口：',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            FundComparisonEntryFactory.createFeatureCard(
              availableFunds: testFunds,
              onTap: () => debugPrint('功能卡片点击'),
            ),
            const SizedBox(height: 16),

            // 列表项
            const Text('列表项入口：', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            FundComparisonEntryFactory.createMenuListTile(
              availableFunds: testFunds,
              onTap: () => debugPrint('列表项点击'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetScenarios() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '预设对比场景',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 场景1：同类基金对比
            _buildScenarioCard(
              '同类基金对比',
              '对比同类型基金的表现差异',
              ['000001', '005827'], // 混合型基金
              Icons.category,
              Colors.blue,
            ),

            const SizedBox(height: 12),

            // 场景2：不同策略对比
            _buildScenarioCard(
              '不同策略对比',
              '对比主动和被动策略基金',
              ['110022', '161725'], // 股票型 vs 指数型
              Icons.swap_horiz,
              Colors.green,
            ),

            const SizedBox(height: 12),

            // 场景3：最佳表现对比
            _buildScenarioCard(
              '最佳表现对比',
              '对比表现最好的基金',
              ['005827', '000311', '000001'], // 收益率最高的三只
              Icons.trending_up,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard(String title, String description,
      List<String> fundCodes, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () => _testPresetScenario(fundCodes),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${fundCodes.length}只',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快速操作',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _testEmptyState(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('空状态测试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testWithPreselectedFunds(),
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('预选基金测试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testAllFunds(),
                  icon: const Icon(Icons.select_all),
                  label: const Text('全部基金测试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _testFullComparison(BuildContext context) {
    final criteria = MultiDimensionalComparisonCriteria(
      fundCodes: ['000001', '110022', '161725'],
      periods: [
        RankingPeriod.oneMonth,
        RankingPeriod.threeMonths,
        RankingPeriod.sixMonths,
        RankingPeriod.oneYear,
      ],
      metric: ComparisonMetric.totalReturn,
      includeStatistics: true,
      sortBy: ComparisonSortBy.totalReturn,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FundComparisonPage(
          availableFunds: testFunds,
          initialCriteria: criteria,
        ),
      ),
    );
  }

  void _testPresetScenario(List<String> fundCodes) {
    debugPrint('测试预设场景: ${fundCodes.join(', ')}');
    // 这里可以添加具体的场景测试逻辑
  }

  void _testEmptyState(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FundComparisonPage(
          availableFunds: [],
        ),
      ),
    );
  }

  void _testWithPreselectedFunds() {
    final criteria = MultiDimensionalComparisonCriteria(
      fundCodes: ['005827', '000311'],
      periods: [RankingPeriod.oneYear],
      metric: ComparisonMetric.annualizedReturn,
    );
    debugPrint('测试预选基金: ${criteria.fundCodes.join(', ')}');
  }

  void _testAllFunds() {
    final allFundCodes = testFunds.map((f) => f.fundCode).toList();
    debugPrint('测试全部基金: ${allFundCodes.join(', ')}');
  }
}

/// 运行测试的入口函数
void runFundComparisonTest() {
  runApp(
    MaterialApp(
      title: '基金对比功能测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: FundComparisonTestPage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
