import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/widgets/profit_metrics_grid.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';

/// UI集成测试
///
/// 验证UI组件的基本功能和数据展示
void main() {
  group('UI集成测试', () {
    late PortfolioProfitMetrics testMetrics;

    setUp(() {
      // 创建简化的测试数据
      testMetrics = PortfolioProfitMetrics(
        fundCode: 'TEST001',
        analysisDate: DateTime.now(),
        totalReturnAmount: 1567.0,
        totalReturnRate: 0.1567,
        annualizedReturn: 0.1234,
        dailyReturn: 0.0012,
        weeklyReturn: 0.0089,
        monthlyReturn: 0.0156,
        quarterlyReturn: 0.0456,
        return1Week: 0.0089,
        return1Month: 0.0156,
        return3Months: 0.0489,
        return6Months: 0.0892,
        returnYTD: 0.1234,
        return1Year: 0.1567,
        return3Years: 0.4567,
        returnSinceInception: 1.2345,
        maxDrawdown: -0.0823,
        volatility: 0.1523,
        sharpeRatio: 1.85,
        sortinoRatio: 2.34,
        informationRatio: 0.67,
        excessReturnRate: 0.0345,
        beta: 0.98,
        jensenAlpha: 0.0234,
        totalDividends: 234.5,
        dividendReinvestmentReturn: 0.0123,
        dividendYield: 0.0345,
        dataStartDate: DateTime.now().subtract(const Duration(days: 365)),
        dataEndDate: DateTime.now(),
        analysisPeriodDays: 365,
        dataQuality: DataQuality.good,
        lastUpdated: DateTime.now(),
      );
    });

    testWidgets('应该正确渲染收益指标网格组件', (WidgetTester tester) async {
      print('🔍 测试: 收益指标网格组件渲染');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfitMetricsGrid(
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证主要模块显示
      expect(find.text('收益指标'), findsOneWidget);
      print('   ✅ 收益指标模块标题显示正确');

      // 验证基础收益指标
      expect(find.text('总收益率'), findsOneWidget);
      expect(find.text('15.67%'), findsOneWidget);
      print('   ✅ 总收益率显示正确');

      expect(find.text('年化收益率'), findsOneWidget);
      expect(find.text('12.34%'), findsOneWidget);
      print('   ✅ 年化收益率显示正确');

      expect(find.text('最大回撤'), findsOneWidget);
      expect(find.text('-8.23%'), findsOneWidget);
      print('   ✅ 最大回撤显示正确');

      expect(find.text('波动率'), findsOneWidget);
      expect(find.text('15.23%'), findsOneWidget);
      print('   ✅ 波动率显示正确');

      print('   🎉 收益指标网格组件渲染测试通过！');
    });

    testWidgets('应该正确显示风险调整收益指标', (WidgetTester tester) async {
      print('🔍 测试: 风险调整收益指标显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfitMetricsGrid(
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证风险调整收益指标
      expect(find.text('夏普比率'), findsOneWidget);
      expect(find.text('1.85'), findsOneWidget);
      print('   ✅ 夏普比率显示正确');

      expect(find.text('索提诺比率'), findsOneWidget);
      expect(find.text('2.34'), findsOneWidget);
      print('   ✅ 索提诺比率显示正确');

      expect(find.text('信息比率'), findsOneWidget);
      expect(find.text('0.67'), findsOneWidget);
      print('   ✅ 信息比率显示正确');

      expect(find.text('特雷纳比率'), findsOneWidget);
      print('   ✅ 特雷纳比率显示正确');

      print('   🎉 风险调整收益指标显示测试通过！');
    });

    testWidgets('应该正确显示基准比较指标', (WidgetTester tester) async {
      print('🔍 测试: 基准比较指标显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfitMetricsGrid(
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证基准比较指标
      expect(find.text('相对收益'), findsOneWidget);
      expect(find.text('3.45%'), findsOneWidget);
      print('   ✅ 相对收益显示正确');

      expect(find.text('贝塔系数'), findsOneWidget);
      expect(find.text('0.98'), findsOneWidget);
      print('   ✅ 贝塔系数显示正确');

      expect(find.text('阿尔法'), findsOneWidget);
      expect(find.text('2.34%'), findsOneWidget);
      print('   ✅ 阿尔法显示正确');

      print('   🎉 基准比较指标显示测试通过！');
    });

    testWidgets('应该正确显示加载状态', (WidgetTester tester) async {
      print('🔍 测试: 加载状态显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfitMetricsGrid(
                metrics: null,
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 验证加载状态
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      print('   ✅ 加载指示器显示正确');

      print('   🎉 加载状态显示测试通过！');
    });

    testWidgets('应该正确显示空状态', (WidgetTester tester) async {
      print('🔍 测试: 空状态显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfitMetricsGrid(
                metrics: null,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证空状态显示（应该显示0值）
      expect(find.text('收益指标'), findsOneWidget);
      expect(find.text('0.00%'), findsWidgets);
      print('   ✅ 空状态显示正确');

      print('   🎉 空状态显示测试通过！');
    });

    testWidgets('应该正确处理刷新操作', (WidgetTester tester) async {
      print('🔍 测试: 刷新操作响应');

      bool refreshCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfitMetricsGrid(
                metrics: testMetrics,
                isLoading: false,
                onRefresh: () {
                  refreshCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找并点击刷新按钮
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      expect(refreshCalled, isTrue);
      print('   ✅ 刷新操作响应正确');

      print('   🎉 刷新操作测试通过！');
    });
  });
}
