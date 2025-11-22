import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/pages/minimalist_fund_exploration_page.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';

// 生成Mock类
@GenerateMocks([FundExplorationCubit])
import 'minimalist_fund_exploration_page_test.mocks.dart';

void main() {
  group('极简基金探索页面测试', () {
    late MockFundExplorationCubit mockFundExplorationCubit;

    setUp(() {
      mockFundExplorationCubit = MockFundExplorationCubit();
    });

    testWidgets('应该正确渲染极简布局页面基本组件', (WidgetTester tester) async {
      // 准备测试状态
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );

      // 构建测试widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 验证核心组件存在
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Container), findsWidgets);

      // 验证搜索区域
      expect(find.byType(TextField), findsOneWidget);

      // 验证快速筛选标签
      expect(find.byType(FilterChip), findsNWidgets(4));

      // 验证底部悬浮工具栏
      expect(find.text('筛选'), findsOneWidget);
      expect(find.text('对比'), findsOneWidget);
      expect(find.text('计算'), findsOneWidget);
      expect(find.text('更多'), findsOneWidget);
    });

    testWidgets('应该正确显示加载状态', (WidgetTester tester) async {
      // 准备加载状态
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.loading(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.loading()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 验证加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在加载基金数据...'), findsOneWidget);
    });

    testWidgets('应该正确显示错误状态', (WidgetTester tester) async {
      const errorMessage = '网络连接失败';

      // 准备错误状态
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.error(errorMessage: errorMessage),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(
            const FundExplorationState.error(errorMessage: errorMessage)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 验证错误状态显示
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('重新加载'), findsOneWidget);
    });

    testWidgets('应该能够点击重新加载按钮', (WidgetTester tester) async {
      const errorMessage = '加载失败';

      // 设置初始化方法的mock
      when(mockFundExplorationCubit.initialize()).thenAnswer((_) async {});

      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.error(errorMessage: errorMessage),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(
            const FundExplorationState.error(errorMessage: errorMessage)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 点击重新加载按钮
      await tester.tap(find.text('重新加载'));
      await tester.pump();

      // 验证初始化方法被调用
      verify(mockFundExplorationCubit.initialize()).called(1);
    });

    testWidgets('应该能够点击筛选按钮', (WidgetTester tester) async {
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 点击筛选按钮
      await tester.tap(find.text('筛选'));
      await tester.pump();

      // 验证点击事件被处理（通过状态变化或UI变化来验证）
      // 这里只是验证按钮可点击，不验证具体功能
    });

    testWidgets('应该能够点击对比按钮', (WidgetTester tester) async {
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 点击对比按钮
      await tester.tap(find.text('对比'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.text('基金对比工具'), findsOneWidget);
      expect(find.text('关闭'), findsOneWidget);
    });

    testWidgets('应该能够点击计算按钮', (WidgetTester tester) async {
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 点击计算按钮
      await tester.tap(find.text('计算'));
      await tester.pumpAndSettle();

      // 验证计算器对话框显示
      expect(find.text('定投计算器'), findsOneWidget);
      expect(find.text('关闭'), findsOneWidget);
    });

    testWidgets('应该能够点击更多按钮', (WidgetTester tester) async {
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 点击更多按钮
      await tester.tap(find.text('更多'));
      await tester.pumpAndSettle();

      // 验证底部菜单显示
      expect(find.text('更多工具'), findsOneWidget);
      expect(find.text('收益分析'), findsOneWidget);
      expect(find.text('风险评估'), findsOneWidget);
      expect(find.text('投资学堂'), findsOneWidget);
    });

    testWidgets('应该能够进行搜索操作', (WidgetTester tester) async {
      // 设置搜索方法的mock
      when(mockFundExplorationCubit.searchFunds(any)).thenAnswer((_) {});

      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 输入搜索关键词
      await tester.enterText(find.byType(TextField), '易方达');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // 验证搜索方法被调用
      verify(mockFundExplorationCubit.searchFunds('易方达')).called(1);
    });

    testWidgets('应该正确显示节标题', (WidgetTester tester) async {
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 验证节标题存在
      expect(find.text('热门推荐'), findsOneWidget);
      expect(find.text('基金排行'), findsOneWidget);
      expect(find.text('市场动态'), findsOneWidget);

      // 验证节标题图标
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('应该正确处理快速筛选标签点击', (WidgetTester tester) async {
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      // 点击快速筛选标签
      await tester.tap(find.text('热门基金'));
      await tester.pump();

      // 验证标签被选中（通过颜色变化判断）
      final filterChip = tester.widget<FilterChip>(find.text('热门基金'));
      expect(filterChip.selected, isTrue);
    });

    testWidgets('页面渲染性能测试', (WidgetTester tester) async {
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundExplorationCubit>.value(
            value: mockFundExplorationCubit,
            child: const MinimalistFundExplorationPage(),
          ),
        ),
      );

      stopwatch.stop();

      // 验证页面渲染时间在合理范围内（小于100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
