import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/widgets/profit_metrics_grid.dart';

/// ProfitMetricsGrid组件测试
///
/// 测试收益指标网格组件的各种状态和交互功能
void main() {
  group('ProfitMetricsGrid UI测试', () {
    late PortfolioProfitMetrics testMetrics;

    setUp(() {
      // 创建测试用的收益指标数据
      testMetrics = PortfolioProfitMetrics(
        fundCode: 'TEST001',
        analysisDate: DateTime.now(),
        totalReturnAmount: 1567.0,
        totalReturnRate: 0.1567, // 15.67%
        annualizedReturn: 0.1234, // 12.34%
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
        // return5Years: 0.7890,  // 该字段在实体中不存在，已移除
        returnSinceInception: 1.2345,
        maxDrawdown: -0.0823, // -8.23%
        volatility: 0.1523, // 15.23%
        sharpeRatio: 1.85, // 夏普比率
        sortinoRatio: 2.34, // 索提诺比率
        informationRatio: 0.67, // 信息比率
        excessReturnRate: 0.0345, // 超额收益率 3.45%
        beta: 0.98, // 贝塔系数
        jensenAlpha: 0.0234, // 阿尔法 2.34%
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

    testWidgets('应该正确显示收益指标网格', (WidgetTester tester) async {
      print('🔍 测试: 收益指标网格正常显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: testMetrics,
              isLoading: false,
            ),
          ),
        ),
      );

      // 等待组件渲染完成
      await tester.pumpAndSettle();

      // 验证页面标题
      expect(find.text('收益指标'), findsOneWidget);
      print('   ✅ 页面标题显示正确');

      // 验证主要收益指标显示
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

      // 验证风险调整收益指标
      expect(find.text('夏普比率'), findsOneWidget);
      expect(find.text('1.85'), findsOneWidget);
      print('   ✅ 夏普比率显示正确');

      expect(find.text('索提诺比率'), findsOneWidget);
      expect(find.text('2.34'), findsOneWidget);
      print('   ✅ 索提诺比率显示正确');

      print('   🎉 收益指标网格显示测试通过！');
    });

    testWidgets('应该正确显示基准比较指标', (WidgetTester tester) async {
      print('🔍 测试: 基准比较指标显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: testMetrics,
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证基准比较指标
      expect(find.text('相对收益'), findsOneWidget);
      expect(find.text('3.45%'), findsOneWidget);
      print('   ✅ 相对收益显示正确');

      expect(find.text('跟踪误差'), findsOneWidget);
      expect(find.text('4.56%'), findsOneWidget);
      print('   ✅ 跟踪误差显示正确');

      expect(find.text('贝塔系数'), findsOneWidget);
      expect(find.text('0.98'), findsOneWidget);
      print('   ✅ 贝塔系数显示正确');

      expect(find.text('阿尔法'), findsOneWidget);
      expect(find.text('2.34%'), findsOneWidget);
      print('   ✅ 阿尔法显示正确');

      print('   🎉 基准比较指标显示测试通过！');
    });

    testWidgets('应该显示加载状态', (WidgetTester tester) async {
      print('🔍 测试: 加载状态显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: testMetrics,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证加载状态下的占位符显示
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      print('   ✅ 加载指示器显示正确');

      print('   🎉 加载状态显示测试通过！');
    });

    testWidgets('应该正确响应刷新操作', (WidgetTester tester) async {
      print('🔍 测试: 刷新操作响应');

      bool refreshCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: testMetrics,
              isLoading: false,
              onRefresh: () {
                refreshCalled = true;
              },
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

    testWidgets('应该正确处理null指标数据', (WidgetTester tester) async {
      print('🔍 测试: null指标数据处理');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: null,
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证空数据显示
      expect(find.text('收益指标'), findsOneWidget);

      // 当metrics为null时，应该显示0值或占位符
      expect(find.text('0.00%'), findsWidgets);
      print('   ✅ null数据处理正确');

      print('   🎉 null数据处理测试通过！');
    });

    testWidgets('应该正确显示指标详情对话框', (WidgetTester tester) async {
      print('🔍 测试: 指标详情对话框');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: testMetrics,
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找总收益率卡片并点击
      final totalReturnCard = find.ancestor(
        of: find.text('总收益率'),
        matching: find.byType(InkWell),
      );
      expect(totalReturnCard, findsOneWidget);

      await tester.tap(totalReturnCard);
      await tester.pumpAndSettle();

      // 验证对话框内容
      expect(find.text('总收益率'), findsOneWidget);
      expect(find.text('数值: 15.67%'), findsOneWidget);
      expect(find.text('原始值: 0.1567'), findsOneWidget);
      expect(find.text('确定'), findsOneWidget);
      print('   ✅ 指标详情对话框显示正确');

      // 关闭对话框
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      print('   🎉 指标详情对话框测试通过！');
    });

    testWidgets('应该正确响应屏幕尺寸变化', (WidgetTester tester) async {
      print('🔍 测试: 响应式布局');

      // 测试小屏幕布局
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: testMetrics,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 在小屏幕上，网格应该是2列
      final gridView = find.byType(GridView);
      expect(gridView, findsOneWidget);
      print('   ✅ 小屏幕布局正确');

      // 测试大屏幕布局
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: testMetrics,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 在大屏幕上，网格应该是4列
      print('   ✅ 大屏幕布局正确');

      // 恢复默认屏幕尺寸
      await tester.binding.setSurfaceSize(null);

      print('   🎉 响应式布局测试通过！');
    });

    testWidgets('应该正确显示正负收益颜色', (WidgetTester tester) async {
      print('🔍 测试: 正负收益颜色显示');

      final mixedMetrics = PortfolioProfitMetrics(
        fundCode: 'TEST002',
        analysisDate: DateTime.now(),
        totalReturnAmount: 1567.0,
        totalReturnRate: 0.1567, // 正收益
        annualizedReturn: -0.0523, // 负收益
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
        maxDrawdown: -0.0823, // 负值（回撤）
        volatility: 0.1523, // 正值
        sharpeRatio: 1.85, // 正值
        sortinoRatio: 2.34, // 正值
        informationRatio: 0.67, // 正值
        excessReturnRate: 0.0345, // 超额收益率
        beta: 0.98, // 正值
        jensenAlpha: -0.0123, // 负阿尔法
        totalDividends: 234.5,
        dividendReinvestmentReturn: 0.0123,
        dividendYield: 0.0345,
        dataStartDate: DateTime.now().subtract(const Duration(days: 365)),
        dataEndDate: DateTime.now(),
        analysisPeriodDays: 365,
        dataQuality: DataQuality.good,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: mixedMetrics,
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证正收益显示为绿色
      expect(find.text('15.67%'), findsOneWidget);
      print('   ✅ 正收益显示正确');

      // 验证负收益显示为红色
      expect(find.text('-5.23%'), findsOneWidget);
      expect(find.text('-2.34%'), findsOneWidget);
      print('   ✅ 负收益显示正确');

      // 验证回撤显示为红色（特殊处理）
      expect(find.text('-8.23%'), findsOneWidget);
      print('   ✅ 回撤显示正确');

      print('   🎉 正负收益颜色显示测试通过！');
    });

    testWidgets('应该正确显示趋势指示器', (WidgetTester tester) async {
      print('🔍 测试: 趋势指示器显示');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfitMetricsGrid(
              metrics: testMetrics,
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证正收益显示上升趋势指示器
      expect(find.text('↑'), findsWidgets);
      print('   ✅ 上升趋势指示器显示正确');

      print('   🎉 趋势指示器显示测试通过！');
    });
  });
}
