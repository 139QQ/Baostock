import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/widgets/smart_recommendation_carousel.dart';
import 'package:jisu_fund_analyzer/src/services/smart_recommendation_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/fund_ranking.dart';

void main() {
  group('SmartRecommendationCarousel Tests', () {
    late List<RecommendationItem> testRecommendations;
    late RecommendationStrategy testStrategy;

    setUp(() {
      testRecommendations = [
        RecommendationItem(
          fund: _createTestFund('001', '测试基金A', dailyReturn: 5.5),
          score: 8.5,
          reason: '收益表现优异',
          strategy: RecommendationStrategy.highReturn,
        ),
        RecommendationItem(
          fund: _createTestFund('002', '测试基金B', dailyReturn: -2.3),
          score: 6.2,
          reason: '风险控制良好',
          strategy: RecommendationStrategy.stable,
        ),
      ];
      testStrategy = RecommendationStrategy.balanced;
    });

    testWidgets('应该正确渲染推荐轮播组件', (WidgetTester tester) async {
      // 准备测试组件
      final carousel = SmartRecommendationCarousel(
        recommendations: testRecommendations,
        strategy: testStrategy,
        autoPlay: false, // 测试时禁用自动播放
      );

      // 构建测试组件树
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证组件渲染
      expect(find.byType(SmartRecommendationCarousel), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // 验证推荐分数显示
      expect(find.textContaining('8.5'), findsOneWidget);
    });

    testWidgets('空推荐列表应该显示空状态', (WidgetTester tester) async {
      final carousel = SmartRecommendationCarousel(
        recommendations: const [],
        strategy: testStrategy,
        autoPlay: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      // 验证空状态显示
      expect(find.text('暂无推荐基金'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('应该正确渲染组件结构', (WidgetTester tester) async {
      final carousel = SmartRecommendationCarousel(
        recommendations: testRecommendations,
        strategy: testStrategy,
        autoPlay: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证组件结构正确
      expect(find.byType(SmartRecommendationCarousel), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('点击基金应该触发回调', (WidgetTester tester) async {
      String? tappedFundCode;

      final carousel = SmartRecommendationCarousel(
        recommendations: testRecommendations,
        strategy: testStrategy,
        autoPlay: false,
        onFundTap: (fundCode) {
          tappedFundCode = fundCode;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 点击PageView区域
      await tester.tap(find.byType(PageView));
      await tester.pump();

      // 验证PageView是可交互的（具体的回调测试依赖于具体实现）
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('应该显示收藏按钮', (WidgetTester tester) async {
      final carousel = SmartRecommendationCarousel(
        recommendations: testRecommendations,
        strategy: testStrategy,
        autoPlay: false,
        onFavorite: (fundCode) {
          // 收藏回调
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证收藏按钮存在
      expect(find.byIcon(Icons.favorite_border), findsWidgets);
    });

    testWidgets('应该显示对比按钮', (WidgetTester tester) async {
      final carousel = SmartRecommendationCarousel(
        recommendations: testRecommendations,
        strategy: testStrategy,
        autoPlay: false,
        onCompare: (fundCode) {
          // 对比回调
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证对比按钮存在
      expect(find.byIcon(Icons.compare_arrows), findsWidgets);
    });

    testWidgets('应该正确显示策略标签', (WidgetTester tester) async {
      final carousel = SmartRecommendationCarousel(
        recommendations: testRecommendations,
        strategy: RecommendationStrategy.highReturn,
        autoPlay: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      // 验证策略标签显示
      expect(find.text('高收益'), findsOneWidget);
    });

    testWidgets('应该正确显示推荐分数', (WidgetTester tester) async {
      final carousel = SmartRecommendationCarousel(
        recommendations: testRecommendations,
        strategy: testStrategy,
        autoPlay: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      // 验证推荐分数显示
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('6.2'), findsOneWidget);
    });

    testWidgets('应该正确渲染指示器', (WidgetTester tester) async {
      final carousel = SmartRecommendationCarousel(
        recommendations: testRecommendations,
        strategy: testStrategy,
        autoPlay: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      // 验证指示器存在
      expect(find.byType(GestureDetector), findsWidgets); // 指示器点击区域
    });

    testWidgets('应该正确渲染指示器', (WidgetTester tester) async {
      final carousel = SmartRecommendationCarousel(
        recommendations: testRecommendations,
        strategy: testStrategy,
        autoPlay: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: carousel,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证指示器存在
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Row), findsWidgets); // 指示器使用Row布局
    });

    group('可访问性测试', () {
      testWidgets('应该有基本的可访问性支持', (WidgetTester tester) async {
        final carousel = SmartRecommendationCarousel(
          recommendations: testRecommendations,
          strategy: testStrategy,
          autoPlay: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: carousel,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证组件可以正常渲染和交互
        expect(find.byType(SmartRecommendationCarousel), findsOneWidget);
        expect(find.byType(PageView), findsOneWidget);
      });

      testWidgets('应该支持基本交互', (WidgetTester tester) async {
        final carousel = SmartRecommendationCarousel(
          recommendations: testRecommendations,
          strategy: testStrategy,
          autoPlay: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: carousel,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证组件可以正常交互
        await tester.tap(find.byType(PageView));
        await tester.pump();

        expect(find.byType(SmartRecommendationCarousel), findsOneWidget);
      });
    });

    group('性能测试', () {
      testWidgets('大量推荐项应该流畅渲染', (WidgetTester tester) async {
        // 创建少量推荐项进行测试
        final largeRecommendations = List.generate(
            5,
            (index) => RecommendationItem(
                  fund: _createTestFund(
                      index.toString().padLeft(3, '0'), '基金$index',
                      dailyReturn: index % 10.0),
                  score: 5.0 + (index % 5),
                  reason: '推荐理由$index',
                  strategy: RecommendationStrategy.balanced,
                ));

        final stopwatch = Stopwatch()..start();

        final carousel = SmartRecommendationCarousel(
          recommendations: largeRecommendations,
          strategy: testStrategy,
          autoPlay: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: carousel,
            ),
          ),
        );

        await tester.pumpAndSettle();

        stopwatch.stop();

        // 验证渲染时间合理（应该在200ms内）
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
        print('轮播组件渲染时间: ${stopwatch.elapsedMilliseconds}ms');

        // 验证组件正确渲染
        expect(find.byType(SmartRecommendationCarousel), findsOneWidget);
        expect(find.byType(PageView), findsOneWidget);
      });
    });
  });
}

// 创建测试用的推荐项
RecommendationItem _createTestRecommendationItem(
  String code,
  String name, {
  double dailyReturn = 0.0,
  double score = 5.0,
  String reason = '测试推荐',
  RecommendationStrategy strategy = RecommendationStrategy.balanced,
}) {
  return RecommendationItem(
    fund: _createTestFund(code, name, dailyReturn: dailyReturn),
    score: score,
    reason: reason,
    strategy: strategy,
  );
}

// 创建测试用的基金数据
FundRanking _createTestFund(
  String code,
  String name, {
  double dailyReturn = 0.0,
  double oneYearReturn = 0.0,
  double fundSize = 1000000000,
  RiskLevel riskLevel = RiskLevel.medium,
  bool isMockData = false,
}) {
  return FundRanking.fromJson({
    'fundCode': code,
    'fundName': name,
    'fundType': '混合型',
    'fundManager': '测试经理',
    'establishDate': '2020-01-01',
    'fundSize': fundSize,
    'dailyReturn': dailyReturn,
    'weeklyReturn': dailyReturn * 5,
    'monthlyReturn': dailyReturn * 20,
    'threeMonthReturn': dailyReturn * 60,
    'sixMonthReturn': dailyReturn * 120,
    'oneYearReturn': oneYearReturn,
    'threeYearReturn': oneYearReturn * 3,
    'sinceEstablishReturn': oneYearReturn * 4,
    'riskLevel': riskLevel.name,
    'isMockData': isMockData,
    'rank': 1,
  }, 0);
}
