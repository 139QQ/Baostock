import 'package:flutter/material.dart';
import 'lib/src/features/fund/domain/entities/fund_ranking.dart';
import 'lib/src/features/fund/presentation/widgets/fund_ranking_card.dart';
import 'lib/src/features/fund/presentation/widgets/optimized_fund_ranking_card.dart';

/// 基金卡片测试应用
class FundCardTestApp extends StatelessWidget {
  const FundCardTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基金卡片测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FundCardTestPage(),
    );
  }
}

class FundCardTestPage extends StatefulWidget {
  const FundCardTestPage({super.key});

  @override
  State<FundCardTestPage> createState() => _FundCardTestPageState();
}

class _FundCardTestPageState extends State<FundCardTestPage> {
  // 创建测试数据
  final List<FundRanking> testRankings = [
    FundRanking(
      fundCode: '000001',
      fundName: '华夏成长混合',
      fundType: '混合型',
      company: '华夏基金',
      rankingPosition: 1,
      totalCount: 100,
      unitNav: 1.2345,
      accumulatedNav: 2.3456,
      dailyReturn: 0.0123,
      return1W: 0.0234,
      return1M: 0.0456,
      return3M: 0.0678,
      return6M: 0.0890,
      return1Y: 0.1234,
      return2Y: 0.2345,
      return3Y: 0.3456,
      returnYTD: 0.0567,
      returnSinceInception: 0.4567,
      rankingDate: DateTime.now(),
      rankingPeriod: RankingPeriod.oneYear,
      rankingType: RankingType.overall,
    ),
    FundRanking(
      fundCode: '110022',
      fundName: '易方达蓝筹精选',
      fundType: '股票型',
      company: '易方达基金',
      rankingPosition: 2,
      totalCount: 100,
      unitNav: 2.3456,
      accumulatedNav: 3.4567,
      dailyReturn: -0.0123,
      return1W: 0.0345,
      return1M: -0.0234,
      return3M: 0.0567,
      return6M: 0.0789,
      return1Y: 0.2345,
      return2Y: 0.3456,
      return3Y: 0.4567,
      returnYTD: 0.0678,
      returnSinceInception: 0.5678,
      rankingDate: DateTime.now(),
      rankingPeriod: RankingPeriod.oneYear,
      rankingType: RankingType.overall,
    ),
  ];

  final Set<String> favoriteFunds = {'000001'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金卡片测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '标准版基金卡片',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...testRankings.asMap().entries.map((entry) {
            final index = entry.key;
            final ranking = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FundRankingCard(
                ranking: ranking,
                position: index + 1,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('点击了基金: ${ranking.fundName}')),
                  );
                },
                onFavorite: (isFavorite) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${isFavorite ? '收藏' : '取消收藏'}: ${ranking.fundName}')),
                  );
                },
              ),
            );
          }).toList(),

          const SizedBox(height: 32),
          const Text(
            '优化版基金卡片',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...testRankings.asMap().entries.map((entry) {
            final index = entry.key;
            final ranking = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OptimizedFundRankingCard(
                ranking: ranking,
                position: index + 1,
                isFavorite: favoriteFunds.contains(ranking.fundCode),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('点击了基金: ${ranking.fundName}')),
                  );
                },
                onFavorite: (isFavorite) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${isFavorite ? '收藏' : '取消收藏'}: ${ranking.fundName}')),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

void main() {
  runApp(const FundCardTestApp());
}