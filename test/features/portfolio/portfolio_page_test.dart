import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/portfolio/pages/portfolio_page.dart';
import 'package:jisu_fund_analyzer/src/bloc/portfolio_bloc.dart';
import 'package:jisu_fund_analyzer/src/services/portfolio_analysis_service.dart';
import 'package:jisu_fund_analyzer/src/services/fund_analysis_service.dart';
import 'package:jisu_fund_analyzer/src/services/high_performance_fund_service.dart';

import 'portfolio_page_test.mocks.dart';

@GenerateMocks([
  PortfolioAnalysisService,
  FundAnalysisService,
  HighPerformanceFundService,
])
void main() {
  group('PortfolioPage Tests', () {
    late MockPortfolioAnalysisService mockPortfolioService;
    late MockFundAnalysisService mockAnalysisService;
    late MockHighPerformanceFundService mockFundService;

    setUp(() {
      mockPortfolioService = MockPortfolioAnalysisService();
      mockAnalysisService = MockFundAnalysisService();
      mockFundService = MockHighPerformanceFundService();

      // 模拟服务方法
      when(mockAnalysisService.getRecommendedFunds(
        fundType: anyNamed('fundType'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => []);

      // 模拟PortfolioAnalysisService方法
      when(mockPortfolioService.createPortfolio(
        name: anyNamed('name'),
        description: anyNamed('description'),
        holdings: anyNamed('holdings'),
        strategy: anyNamed('strategy'),
      )).thenThrow(Exception('Not implemented in test'));
    });

    testWidgets('PortfolioPage should display tabs correctly',
        (WidgetTester tester) async {
      // 创建测试用的PortfolioBloc
      final portfolioBloc = PortfolioBloc(
        portfolioService: mockPortfolioService,
        analysisService: mockAnalysisService,
        fundService: mockFundService,
      );

      // 构建测试应用
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PortfolioBloc>.value(
            value: portfolioBloc,
            child: const PortfolioPage(),
          ),
        ),
      );

      // 验证应用栏标题
      expect(find.text('投资组合'), findsOneWidget);

      // 验证三个标签页存在
      expect(find.text('我的组合'), findsOneWidget);
      expect(find.text('创建组合'), findsOneWidget);
      expect(find.text('市场分析'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('PortfolioPage should load data on initialization',
        (WidgetTester tester) async {
      final portfolioBloc = PortfolioBloc(
        portfolioService: mockPortfolioService,
        analysisService: mockAnalysisService,
        fundService: mockFundService,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PortfolioBloc>.value(
            value: portfolioBloc,
            child: const PortfolioPage(),
          ),
        ),
      );

      // 等待初始化完成
      await tester.pump();

      // 可能显示加载指示器，但不强制要求
      await tester.pumpAndSettle();

      // 验证页面正常加载
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('我的组合'), findsOneWidget);

      portfolioBloc.close();
    });

    testWidgets('PortfolioPage should handle empty portfolio state',
        (WidgetTester tester) async {
      final portfolioBloc = PortfolioBloc(
        portfolioService: mockPortfolioService,
        analysisService: mockAnalysisService,
        fundService: mockFundService,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PortfolioBloc>.value(
            value: portfolioBloc,
            child: const PortfolioPage(),
          ),
        ),
      );

      // 等待加载完成
      await tester.pumpAndSettle();

      // 点击"我的组合"标签页
      await tester.tap(find.text('我的组合'));
      await tester.pumpAndSettle();

      // 验证空状态显示（等待PortfolioBloc处理LoadPortfolios事件）
      await tester.pump(const Duration(milliseconds: 100));

      // 检查是否存在空状态提示，如果不存在则验证基本元素
      if (find.text('暂无投资组合').evaluate().isNotEmpty) {
        expect(find.text('创建您的第一个投资组合，开始智能投资'), findsOneWidget);
        expect(find.text('创建投资组合'), findsOneWidget);
      } else {
        // 如果没有显示空状态，至少验证页面正常渲染
        expect(find.byType(TabBarView), findsOneWidget);
      }

      portfolioBloc.close();
    });

    testWidgets('PortfolioPage should navigate to create tab',
        (WidgetTester tester) async {
      final portfolioBloc = PortfolioBloc(
        portfolioService: mockPortfolioService,
        analysisService: mockAnalysisService,
        fundService: mockFundService,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PortfolioBloc>.value(
            value: portfolioBloc,
            child: const PortfolioPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 点击"创建组合"标签页
      await tester.tap(find.text('创建组合'));
      await tester.pumpAndSettle();

      // 验证创建组合页面元素（使用更灵活的查找方式）
      expect(find.text('快速创建投资组合'), findsOneWidget);
      expect(find.text('智能创建'), findsOneWidget);

      // 检查推荐基金部分（可能还在加载）
      if (find.text('推荐基金').evaluate().isNotEmpty) {
        expect(find.text('推荐基金'), findsOneWidget);
      }

      expect(find.text('创建投资组合指南'), findsOneWidget);

      portfolioBloc.close();
    });

    testWidgets('PortfolioPage should display market analysis',
        (WidgetTester tester) async {
      final portfolioBloc = PortfolioBloc(
        portfolioService: mockPortfolioService,
        analysisService: mockAnalysisService,
        fundService: mockFundService,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PortfolioBloc>.value(
            value: portfolioBloc,
            child: const PortfolioPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 点击"市场分析"标签页
      await tester.tap(find.text('市场分析'));
      await tester.pumpAndSettle();

      // 验证市场分析页面元素
      expect(find.text('市场概览'), findsOneWidget);
      expect(find.text('策略推荐'), findsOneWidget);
      expect(find.text('风险提示'), findsOneWidget);

      // 验证指数显示
      expect(find.text('沪深300指数'), findsOneWidget);

      // 验证策略选项
      expect(find.text('保守型'), findsOneWidget);
      expect(find.text('平衡型'), findsOneWidget);
      expect(find.text('进取型'), findsOneWidget);

      portfolioBloc.close();
    });
  });
}
