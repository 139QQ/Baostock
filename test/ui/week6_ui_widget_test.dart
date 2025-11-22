import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/bloc/fund_search_bloc.dart';
import 'package:jisu_fund_analyzer/src/bloc/portfolio_bloc.dart';
import 'package:jisu_fund_analyzer/src/services/fund_analysis_service.dart';
import 'package:jisu_fund_analyzer/src/services/portfolio_analysis_service.dart';
import 'package:jisu_fund_analyzer/src/services/high_performance_fund_service.dart';

import '../demo/week6_demo_dashboard.dart';
import '../demo/enhanced_portfolio_management_widget.dart';
import '../demo/technical_indicators_widget.dart';
import 'week6_ui_widget_test.mocks.dart';

// 生成Mock类
@GenerateMocks([
  FundSearchBloc,
  PortfolioBloc,
  FundAnalysisService,
  PortfolioAnalysisService,
  HighPerformanceFundService,
])
void main() {
  group('Week 6 UI Widget Tests', () {
    late MockFundSearchBloc mockFundSearchBloc;
    late MockPortfolioBloc mockPortfolioBloc;

    setUp(() {
      mockFundSearchBloc = MockFundSearchBloc();
      mockPortfolioBloc = MockPortfolioBloc();

      // 设置Mock状态
      when(mockFundSearchBloc.state).thenReturn(FundSearchInitial());
      when(mockFundSearchBloc.stream)
          .thenAnswer((_) => Stream.value(FundSearchInitial()));

      when(mockPortfolioBloc.state).thenReturn(PortfolioInitial());
      when(mockPortfolioBloc.stream)
          .thenAnswer((_) => Stream.value(PortfolioInitial()));
    });

    group('主界面仪表板测试', () {
      testWidgets('应该正确渲染Week6DemoDashboard', (WidgetTester tester) async {
        // 创建测试组件
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
                BlocProvider<PortfolioBloc>.value(value: mockPortfolioBloc),
              ],
              child: const Week6DemoDashboard(),
            ),
          ),
        );

        // 验证主要UI元素存在
        expect(find.text('Week 6 Demo'), findsOneWidget);
        expect(find.text('基金量化分析平台 - 业务逻辑层与表现层'), findsOneWidget);
        expect(find.text('首页'), findsAtLeastNWidgets(2)); // Tab和BottomBar中各有一个
        expect(find.text('基金推荐'), findsOneWidget);
        expect(find.text('投资组合'), findsOneWidget);
        expect(find.text('技术分析'), findsOneWidget);
        expect(find.text('Demo展示'), findsOneWidget);

        // 验证底部导航栏
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('首页'), findsAtLeastNWidgets(2)); // 在Tab和BottomBar中各有一个
      });

      testWidgets('欢迎卡片应该正确显示', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
                BlocProvider<PortfolioBloc>.value(value: mockPortfolioBloc),
              ],
              child: const Week6DemoDashboard(),
            ),
          ),
        );

        // 等待动画完成
        await tester.pumpAndSettle();

        // 验证欢迎卡片内容
        expect(find.text('欢迎使用 Week 6 Demo'), findsOneWidget);
        expect(find.text('业务逻辑层与表现层完整演示'), findsOneWidget);
      });
    });

    group('投资组合管理界面测试', () {
      testWidgets('应该正确渲染投资组合管理界面', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
                BlocProvider<PortfolioBloc>.value(value: mockPortfolioBloc),
              ],
              child: const EnhancedPortfolioManagementWidget(),
            ),
          ),
        );

        // 验证主要UI元素
        expect(find.text('投资组合管理'), findsOneWidget);
        expect(find.text('智能配置，优化收益'), findsOneWidget);
        expect(find.text('创建组合'), findsOneWidget);
        expect(find.text('我的组合'), findsOneWidget);
        expect(find.text('智能优化'), findsOneWidget);
      });

      testWidgets('应该正确显示基本信息表单', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
                BlocProvider<PortfolioBloc>.value(value: mockPortfolioBloc),
              ],
              child: const EnhancedPortfolioManagementWidget(),
            ),
          ),
        );

        // 验证表单元素
        expect(find.text('基本信息'), findsOneWidget);
        expect(find.text('投资组合名称'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
      });
    });

    group('技术指标展示界面测试', () {
      testWidgets('应该正确渲染技术指标界面', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
              ],
              child: const TechnicalIndicatorsWidget(
                fundCode: '000001',
                fundName: '华夏成长混合',
              ),
            ),
          ),
        );

        // 验证主要UI元素
        expect(find.text('华夏成长混合'), findsOneWidget);
        expect(find.text('技术指标分析'), findsOneWidget);
        expect(find.text('移动平均线'), findsOneWidget);
        expect(find.text('RSI指标'), findsOneWidget);
        expect(find.text('布林带'), findsOneWidget);
        expect(find.text('风险评估'), findsOneWidget);
      });

      testWidgets('应该正确显示刷新按钮', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
              ],
              child: const TechnicalIndicatorsWidget(
                fundCode: '000001',
                fundName: '华夏成长混合',
              ),
            ),
          ),
        );

        // 验证刷新按钮
        final refreshButton = find.byIcon(Icons.refresh);
        expect(refreshButton, findsOneWidget);
      });

      testWidgets('移动平均线标签页应该正确显示', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
              ],
              child: const TechnicalIndicatorsWidget(
                fundCode: '000001',
                fundName: '华夏成长混合',
              ),
            ),
          ),
        );

        // 默认应该在移动平均线标签页
        expect(find.text('移动平均线 (MA)'), findsOneWidget);
        expect(find.text('移动平均线是最常用的技术指标之一，用于平滑价格数据，识别趋势方向。'), findsOneWidget);
        expect(find.text('20日移动平均线'), findsOneWidget);
      });
    });

    group('UI交互测试', () {
      testWidgets('标签页切换应该正常工作', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
                BlocProvider<PortfolioBloc>.value(value: mockPortfolioBloc),
              ],
              child: const Week6DemoDashboard(),
            ),
          ),
        );

        // 等待初始渲染完成
        await tester.pumpAndSettle();

        // 切换到基金推荐标签页
        await tester.tap(find.text('基金推荐'));
        await tester.pumpAndSettle();

        // 验证切换成功
        expect(find.text('为您推荐'), findsOneWidget);

        // 切换到投资组合标签页
        await tester.tap(find.text('投资组合'));
        await tester.pumpAndSettle();

        // 验证切换成功
        expect(find.text('投资组合管理'), findsOneWidget);

        // 切换到技术分析标签页
        await tester.tap(find.text('技术分析'));
        await tester.pumpAndSettle();

        // 验证切换成功
        expect(find.text('技术分析演示'), findsOneWidget);

        // 切换到Demo展示标签页
        await tester.tap(find.text('Demo展示'));
        await tester.pumpAndSettle();

        // 验证切换成功
        expect(find.text('Week 6 开发成果展示'), findsOneWidget);
      });
    });

    group('响应式布局测试', () {
      testWidgets('小屏幕设备上应该正确适配', (WidgetTester tester) async {
        // 设置小屏幕尺寸
        await tester.binding.setSurfaceSize(const Size(320, 568));

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
                BlocProvider<PortfolioBloc>.value(value: mockPortfolioBloc),
              ],
              child: const Week6DemoDashboard(),
            ),
          ),
        );

        // 验证主要元素仍然可见
        expect(find.text('Week 6 Demo'), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // 恢复默认屏幕尺寸
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('大屏幕设备上应该正确显示', (WidgetTester tester) async {
        // 设置大屏幕尺寸
        await tester.binding.setSurfaceSize(const Size(1200, 800));

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
                BlocProvider<PortfolioBloc>.value(value: mockPortfolioBloc),
              ],
              child: const Week6DemoDashboard(),
            ),
          ),
        );

        // 验证大屏幕下的布局
        expect(find.text('Week 6 Demo'), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // 恢复默认屏幕尺寸
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('性能测试', () {
      testWidgets('界面渲染应该在合理时间内完成', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FundSearchBloc>.value(value: mockFundSearchBloc),
                BlocProvider<PortfolioBloc>.value(value: mockPortfolioBloc),
              ],
              child: const Week6DemoDashboard(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // 验证渲染时间在合理范围内（小于2秒）
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });
  });
}
