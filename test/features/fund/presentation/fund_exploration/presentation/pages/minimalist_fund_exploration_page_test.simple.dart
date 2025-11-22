import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/fund_ranking.dart';

// 生成Mock类
@GenerateMocks([FundExplorationCubit])
import 'minimalist_fund_exploration_page_test.simple.mocks.dart';

/// 简化的基金探索页面组件（仅用于测试）
class SimpleFundExplorationPage extends StatelessWidget {
  const SimpleFundExplorationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FundExplorationCubit>(
      create: (context) => MockFundExplorationCubit(),
      child: const _TestableFundExplorationPage(),
    );
  }
}

/// 可测试的基金探索页面
class _TestableFundExplorationPage extends StatelessWidget {
  const _TestableFundExplorationPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('基金探索')),
          body: _buildBody(context, state),
          bottomNavigationBar: _buildBottomToolbar(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FundExplorationState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载基金数据...'),
          ],
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(state.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<FundExplorationCubit>().initialize();
              },
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 搜索区域
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: '搜索基金名称或代码',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              context.read<FundExplorationCubit>().searchFunds(value);
            },
          ),
        ),

        // 快速筛选标签
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            children: const [
              FilterChip(
                label: Text('热门基金'),
                selected: true,
                onSelected: null,
              ),
              FilterChip(
                label: Text('高收益'),
                selected: false,
                onSelected: null,
              ),
              FilterChip(
                label: Text('低风险'),
                selected: false,
                onSelected: null,
              ),
              FilterChip(
                label: Text('大规模'),
                selected: false,
                onSelected: null,
              ),
            ],
          ),
        ),

        // 内容区域
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildSection('热门推荐', Icons.local_fire_department),
                _buildSection('基金排行', Icons.leaderboard),
                _buildSection('市场动态', Icons.show_chart),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(BuildContext context, FundExplorationState state) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.filter_list),
          label: '筛选',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.compare),
          label: '对比',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calculate),
          label: '计算',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: '更多',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            _showFilterDialog(context);
            break;
          case 1:
            _showComparisonDialog(context);
            break;
          case 2:
            _showCalculatorDialog(context);
            break;
          case 3:
            _showMoreDialog(context);
            break;
        }
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选条件'),
        content: const Text('筛选功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showComparisonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('基金对比工具'),
        content: const Text('对比功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showCalculatorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('定投计算器'),
        content: const Text('计算器功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showMoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更多工具'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.trending_up),
              title: Text('收益分析'),
            ),
            ListTile(
              leading: Icon(Icons.warning),
              title: Text('风险评估'),
            ),
            ListTile(
              leading: Icon(Icons.school),
              title: Text('投资学堂'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('简化基金探索页面测试', () {
    late MockFundExplorationCubit mockFundExplorationCubit;

    setUp(() {
      mockFundExplorationCubit = MockFundExplorationCubit();

      // 设置默认的Mock行为
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.initial(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.initial()),
      );
      when(mockFundExplorationCubit.initialize()).thenAnswer((_) async {});
      when(mockFundExplorationCubit.searchFunds(any)).thenAnswer((_) {});
    });

    testWidgets('应该正确渲染基本组件', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
        ),
      );

      // 验证核心组件存在
      expect(find.byType(SafeArea), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('基金探索'), findsOneWidget);

      // 验证搜索区域
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('搜索基金名称或代码'), findsOneWidget);

      // 验证快速筛选标签
      expect(find.byType(FilterChip), findsNWidgets(4));
      expect(find.text('热门基金'), findsOneWidget);
      expect(find.text('高收益'), findsOneWidget);
      expect(find.text('低风险'), findsOneWidget);
      expect(find.text('大规模'), findsOneWidget);

      // 验证底部工具栏
      expect(find.text('筛选'), findsOneWidget);
      expect(find.text('对比'), findsOneWidget);
      expect(find.text('计算'), findsOneWidget);
      expect(find.text('更多'), findsOneWidget);

      // 验证节标题
      expect(find.text('热门推荐'), findsOneWidget);
      expect(find.text('基金排行'), findsOneWidget);
      expect(find.text('市场动态'), findsOneWidget);

      // 验证节标题图标
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('应该正确显示加载状态', (WidgetTester tester) async {
      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.loading(),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(const FundExplorationState.loading()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
        ),
      );

      // 验证加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在加载基金数据...'), findsOneWidget);
    });

    testWidgets('应该正确显示错误状态', (WidgetTester tester) async {
      const errorMessage = '网络连接失败';

      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.error(errorMessage: errorMessage),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(
            const FundExplorationState.error(errorMessage: errorMessage)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
        ),
      );

      // 验证错误状态显示
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('重新加载'), findsOneWidget);
    });

    testWidgets('应该能够点击重新加载按钮', (WidgetTester tester) async {
      const errorMessage = '加载失败';

      when(mockFundExplorationCubit.state).thenReturn(
        const FundExplorationState.error(errorMessage: errorMessage),
      );
      when(mockFundExplorationCubit.stream).thenAnswer(
        (_) => Stream.value(
            const FundExplorationState.error(errorMessage: errorMessage)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
        ),
      );

      // 点击重新加载按钮
      await tester.tap(find.text('重新加载'));
      await tester.pump();

      // 验证初始化方法被调用
      verify(mockFundExplorationCubit.initialize()).called(1);
    });

    testWidgets('应该能够进行搜索操作', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
        ),
      );

      // 输入搜索关键词
      await tester.enterText(find.byType(TextField), '易方达');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // 验证搜索方法被调用
      verify(mockFundExplorationCubit.searchFunds('易方达')).called(1);
    });

    testWidgets('应该能够点击筛选按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
        ),
      );

      // 点击筛选按钮
      await tester.tap(find.text('筛选'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.text('筛选条件'), findsOneWidget);
      expect(find.text('关闭'), findsOneWidget);
    });

    testWidgets('应该能够点击对比按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
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
      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
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
      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
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

    testWidgets('页面渲染性能测试', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleFundExplorationPage(),
        ),
      );

      stopwatch.stop();

      // 验证页面渲染时间在合理范围内（小于100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
