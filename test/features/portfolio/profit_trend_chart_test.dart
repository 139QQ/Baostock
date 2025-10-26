import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/widgets/profit_trend_chart.dart';

/// ProfitTrendChart组件测试
///
/// 测试收益趋势图表组件的各种状态和交互功能
void main() {
  group('ProfitTrendChart UI测试', () {
    late PortfolioProfitMetrics testMetrics;
    late List<PortfolioHolding> testHoldings;

    setUp(() {
      // 创建测试用的收益指标数据
      final now = DateTime.now();
      testMetrics = PortfolioProfitMetrics(
        fundCode: 'TEST001',
        analysisDate: now,
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
        beta: 0.98,
        jensenAlpha: 0.0234,
        totalDividends: 234.5,
        dividendReinvestmentReturn: 0.0123,
        dividendYield: 0.0345,
        dataStartDate: now.subtract(const Duration(days: 365)),
        dataEndDate: now,
        analysisPeriodDays: 365,
        lastUpdated: now,
      );

      // 创建测试用的持仓数据
      testHoldings = [
        PortfolioHolding(
          fundCode: '110022',
          fundName: '易方达消费行业股票',
          fundType: '股票型基金',
          holdingAmount: 1000.0,
          costNav: 2.408,
          costValue: 2408.0,
          marketValue: 2865.0,
          currentNav: 2.865,
          accumulatedNav: 3.120,
          holdingStartDate: now.subtract(const Duration(days: 365)),
          lastUpdatedDate: now,
        ),
        PortfolioHolding(
          fundCode: '161039',
          fundName: '富国中证新能源汽车指数',
          fundType: '指数型基金',
          holdingAmount: 2000.0,
          costNav: 1.659,
          costValue: 3318.0,
          marketValue: 3084.0,
          currentNav: 1.542,
          accumulatedNav: 1.785,
          holdingStartDate: now.subtract(const Duration(days: 365)),
          lastUpdatedDate: now,
        ),
      ];
    });

    testWidgets('应该正确显示收益趋势图表', (WidgetTester tester) async {
      print('🔍 测试: 收益趋势图表正常显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      // 等待组件渲染完成
      await tester.pumpAndSettle();

      // 验证图表控件存在
      expect(find.byType(LineChart), findsOneWidget);
      print('   ✅ 线形图表显示正确');

      // 验证图表控制组件
      expect(find.byType(FilterChip), findsWidgets);
      expect(find.byType(PopupMenuButton<ChartType>), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      print('   ✅ 图表控制组件显示正确');

      // 验证导出按钮
      expect(find.byIcon(Icons.download), findsOneWidget);
      print('   ✅ 导出按钮显示正确');

      print('   🎉 收益趋势图表显示测试通过！');
    });

    testWidgets('应该正确显示加载状态', (WidgetTester tester) async {
      print('🔍 测试: 加载状态显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      print('   ✅ 加载指示器显示正确');

      print('   🎉 加载状态显示测试通过！');
    });

    testWidgets('应该正确切换时间段', (WidgetTester tester) async {
      print('🔍 测试: 时间段切换功能');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找并点击3个月时间段
      final threeMonthsChip = find.widgetWithText(FilterChip, '3个月');
      expect(threeMonthsChip, findsOneWidget);

      await tester.tap(threeMonthsChip);
      await tester.pumpAndSettle();

      print('   ✅ 时间段切换响应正确');

      print('   🎉 时间段切换测试通过！');
    });

    testWidgets('应该正确切换图表类型', (WidgetTester tester) async {
      print('🔍 测试: 图表类型切换功能');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找并点击图表类型选择器
      final chartTypeButton = find.byType(PopupMenuButton<ChartType>);
      expect(chartTypeButton, findsOneWidget);

      await tester.tap(chartTypeButton);
      await tester.pumpAndSettle();

      // 选择日收益率图表
      final dailyReturnOption = find.text('日收益率');
      expect(dailyReturnOption, findsOneWidget);

      await tester.tap(dailyReturnOption);
      await tester.pumpAndSettle();

      // 验证图表类型切换为柱状图
      expect(find.byType(BarChart), findsOneWidget);
      print('   ✅ 图表类型切换为柱状图正确');

      print('   🎉 图表类型切换测试通过！');
    });

    testWidgets('应该正确切换基准比较', (WidgetTester tester) async {
      print('🔍 测试: 基准比较开关功能');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找基准比较开关
      final benchmarkSwitch = find.byType(Switch);
      expect(benchmarkSwitch, findsOneWidget);

      // 获取开关的当前状态
      final switchWidget = tester.widget<Switch>(benchmarkSwitch);
      final initialValue = switchWidget.value;

      // 点击开关
      await tester.tap(benchmarkSwitch);
      await tester.pumpAndSettle();

      // 验证开关状态已改变
      final updatedSwitchWidget = tester.widget<Switch>(benchmarkSwitch);
      expect(updatedSwitchWidget.value, isNot(equals(initialValue)));
      print('   ✅ 基准比较开关切换正确');

      print('   🎉 基准比较开关测试通过！');
    });

    testWidgets('应该正确响应导出操作', (WidgetTester tester) async {
      print('🔍 测试: 导出操作响应');

      bool exportCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: false,
                onExportData: () {
                  exportCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找并点击导出按钮
      final exportButton = find.byIcon(Icons.download);
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(exportCalled, isTrue);
      print('   ✅ 导出操作响应正确');

      print('   🎉 导出操作测试通过！');
    });

    testWidgets('应该正确显示图表图例', (WidgetTester tester) async {
      print('🔍 测试: 图表图例显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证图例显示
      expect(find.text('投资组合'), findsOneWidget);
      expect(find.text('基准指数'), findsOneWidget);
      print('   ✅ 图例显示正确');

      // 验证统计数据显示
      expect(find.text('总收益'), findsOneWidget);
      expect(find.text('15.67%'), findsOneWidget);
      expect(find.text('年化收益'), findsOneWidget);
      expect(find.text('12.34%'), findsOneWidget);
      expect(find.text('日收益'), findsOneWidget);
      expect(find.text('0.12%'), findsOneWidget);
      print('   ✅ 统计数据显示正确');

      print('   🎉 图表图例显示测试通过！');
    });

    testWidgets('应该正确处理null数据', (WidgetTester tester) async {
      print('🔍 测试: null数据处理');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: null,
                metrics: null,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证图表仍能正常显示（使用模拟数据）
      expect(find.byType(LineChart), findsOneWidget);
      print('   ✅ null数据情况下图表显示正确');

      print('   🎉 null数据处理测试通过！');
    });

    testWidgets('应该正确显示工具提示', (WidgetTester tester) async {
      print('🔍 测试: 图表工具提示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找图表区域
      final chartArea = find.byType(LineChart);
      expect(chartArea, findsOneWidget);

      // 在图表区域内触发触摸事件
      await tester.tap(chartArea);
      await tester.pump();

      // 验证工具提示数据存在
      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(lineChart.data.lineTouchData.touchTooltipData, isNotNull);
      print('   ✅ 工具提示数据配置正确');

      print('   🎉 图表工具提示测试通过！');
    });

    testWidgets('应该正确响应不同时间段选择', (WidgetTester tester) async {
      print('🔍 测试: 不同时间段选择响应');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 测试所有时间段选项
      final timePeriods = ['1个月', '3个月', '6个月', '1年', '3年', '全部'];

      for (final period in timePeriods) {
        final chip = find.widgetWithText(FilterChip, period);
        expect(chip, findsOneWidget);

        await tester.tap(chip);
        await tester.pumpAndSettle();

        print('   ✅ $period 时间段选择响应正确');
      }

      print('   🎉 不同时间段选择测试通过！');
    });

    testWidgets('应该正确显示基准比较状态变化', (WidgetTester tester) async {
      print('🔍 测试: 基准比较状态变化');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProfitTrendChart(
                holdings: testHoldings,
                metrics: testMetrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 初始状态应该显示基准比较
      expect(find.text('基准指数'), findsOneWidget);
      expect(find.text('基准比较'), findsOneWidget);
      print('   ✅ 初始基准比较显示正确');

      // 关闭基准比较
      final benchmarkSwitch = find.byType(Switch);
      await tester.tap(benchmarkSwitch);
      await tester.pumpAndSettle();

      // 验证基准指数图例消失
      expect(find.text('基准指数'), findsNothing);
      print('   ✅ 基准比较关闭后图例隐藏正确');

      // 重新打开基准比较
      await tester.tap(benchmarkSwitch);
      await tester.pumpAndSettle();

      // 验证基准指数图例重新显示
      expect(find.text('基准指数'), findsOneWidget);
      print('   ✅ 基准比较重新打开后图例显示正确');

      print('   🎉 基准比较状态变化测试通过！');
    });
  });
}
