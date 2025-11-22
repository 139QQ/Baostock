import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/models/fund.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/unified_fund_card.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/fund_card_factory.dart';

void main() {
  group('统一基金卡片测试 (替代MicrointeractiveCard)', () {
    late Fund testFund;

    setUp(() {
      testFund = Fund(
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
      );
    });

    testWidgets('应该正确渲染统一基金卡片', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedFundCard(
              fund: testFund,
              cardType: FundCardType.interactive, // 使用交互式卡片
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
              onShare: () {},
            ),
          ),
        ),
      );

      // 验证基本渲染
      expect(find.byType(UnifiedFundCard), findsOneWidget);
      expect(find.text('易方达消费行业股票'), findsOneWidget);
      expect(find.text('110022'), findsOneWidget);
      expect(find.text('股票型'), findsOneWidget);
      expect(find.text('+15.60%'), findsOneWidget);
    });

    testWidgets('应该能够点击卡片', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedFundCard(
              fund: testFund,
              cardType: FundCardType.interactive,
              onTap: () => tapped = true,
              onAddToWatchlist: () {},
              onCompare: () {},
              onShare: () {},
            ),
          ),
        ),
      );

      // 点击卡片
      await tester.tap(find.byType(UnifiedFundCard));
      await tester.pump();

      // 验证点击事件被触发
      expect(tapped, isTrue);
    });

    testWidgets('应该正确渲染自适应卡片类型', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedFundCard(
              fund: testFund,
              cardType: FundCardType.adaptive, // 使用自适应卡片
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
              onShare: () {},
            ),
          ),
        ),
      );

      // 验证基本渲染
      expect(find.byType(UnifiedFundCard), findsOneWidget);
      expect(find.text('易方达消费行业股票'), findsOneWidget);
      expect(find.text('110022'), findsOneWidget);
    });

    testWidgets('应该能够处理交互按钮', (WidgetTester tester) async {
      bool watchlistAdded = false;
      bool compareTapped = false;
      bool shareTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedFundCard(
              fund: testFund,
              cardType: FundCardType.interactive,
              onTap: () {},
              onAddToWatchlist: () => watchlistAdded = true,
              onCompare: () => compareTapped = true,
              onShare: () => shareTapped = true,
            ),
          ),
        ),
      );

      // 查找并点击收藏按钮
      final watchlistButton = find.byIcon(Icons.favorite_border);
      if (watchlistButton.evaluate().isNotEmpty) {
        await tester.tap(watchlistButton);
        await tester.pump();
        expect(watchlistAdded, isTrue);
      }

      // 查找并点击对比按钮
      final compareButton = find.byIcon(Icons.compare);
      if (compareButton.evaluate().isNotEmpty) {
        await tester.tap(compareButton);
        await tester.pump();
        expect(compareTapped, isTrue);
      }

      // 查找并点击分享按钮
      final shareButton = find.byIcon(Icons.share);
      if (shareButton.evaluate().isNotEmpty) {
        await tester.tap(shareButton);
        await tester.pump();
        expect(shareTapped, isTrue);
      }
    });

    testWidgets('应该能够渲染性能优化版本', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedFundCard(
              fund: testFund,
              cardType: FundCardType.minimal, // 使用最小化版本
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
              onShare: () {},
            ),
          ),
        ),
      );

      // 验证基本渲染
      expect(find.byType(UnifiedFundCard), findsOneWidget);
      expect(find.text('易方达消费行业股票'), findsOneWidget);
    });

    testWidgets('应该使用卡片工厂创建不同类型的卡片', (WidgetTester tester) async {
      // 测试工厂模式
      final interactiveCard = FundCardFactory.createCard(
        fund: testFund,
        cardType: FundCardType.interactive,
        onTap: () {},
        onAddToWatchlist: () {},
        onCompare: () {},
        onShare: () {},
      );

      expect(interactiveCard, isA<UnifiedFundCard>());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: interactiveCard,
          ),
        ),
      );

      // 验证工厂创建的卡片正常渲染
      expect(find.byType(UnifiedFundCard), findsOneWidget);
      expect(find.text('易方达消费行业股票'), findsOneWidget);
    });

    testWidgets('应该正确处理基金数据变更', (WidgetTester tester) async {
      Fund initialFund = testFund;
      Fund updatedFund = Fund(
        code: '110022',
        name: '易方达消费行业股票(更新)',
        type: '股票型',
        company: '易方达基金',
        manager: '萧楠',
        return1W: 1.2,
        return1M: 3.1,
        return3M: 6.2,
        return6M: 9.5,
        return1Y: 18.3,
        return3Y: 48.7,
        scale: 92.1,
        riskLevel: 'R3',
        status: '正常',
        isFavorite: true,
      );

      // 初始渲染
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedFundCard(
              fund: initialFund,
              cardType: FundCardType.adaptive,
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
              onShare: () {},
            ),
          ),
        ),
      );

      expect(find.text('易方达消费行业股票'), findsOneWidget);
      expect(find.text('易方达消费行业股票(更新)'), findsNothing);

      // 更新基金数据并重新渲染
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedFundCard(
              fund: updatedFund,
              cardType: FundCardType.adaptive,
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
              onShare: () {},
            ),
          ),
        ),
      );

      expect(find.text('易方达消费行业股票'), findsNothing);
      expect(find.text('易方达消费行业股票(更新)'), findsOneWidget);
      expect(find.text('+18.30%'), findsOneWidget);
    });

    testWidgets('批量渲染性能测试', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      // 创建20个基金数据
      final funds = List.generate(
          20,
          (index) => Fund(
                code: '00${index.toString().padLeft(4, '0')}',
                name: '测试基金${index + 1}',
                type: '股票型',
                company: '测试公司',
                manager: '测试经理',
                return1W: 0.1 * index,
                return1M: 1.0 * index,
                return3M: 2.0 * index,
                return6M: 3.0 * index,
                return1Y: 5.0 * index,
                return3Y: 15.0 * index,
                scale: 10.0 * index,
                riskLevel: 'R3',
                status: '正常',
                isFavorite: index % 2 == 0,
              ));

      // 批量渲染
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: funds.length,
              itemBuilder: (context, index) {
                return UnifiedFundCard(
                  fund: funds[index],
                  cardType: FundCardType.minimal,
                  onTap: () {},
                  onAddToWatchlist: () {},
                  onCompare: () {},
                  onShare: () {},
                );
              },
            ),
          ),
        ),
      );

      stopwatch.stop();

      // 验证所有卡片都渲染成功
      expect(find.byType(UnifiedFundCard), findsNWidgets(20));

      // 性能断言：20个卡片应该在500ms内渲染完成
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
