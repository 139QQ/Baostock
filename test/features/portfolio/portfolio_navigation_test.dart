import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/widgets/portfolio_manager.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_data_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/repositories/portfolio_profit_repository_impl.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_profit_api_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_profit_cache_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/services/portfolio_profit_calculation_engine.dart';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/portfolio_holding_adapter.dart';

void main() {
  group('持仓导航测试', () {
    late PortfolioAnalysisCubit portfolioCubit;

    setUpAll(() async {
      // 初始化Hive测试环境
      Hive.init('test_portfolio_navigation');

      // 注册适配器
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PortfolioHoldingAdapter());
      }
    });

    setUp(() async {
      // 初始化缓存服务
      final cacheService = PortfolioProfitCacheService.defaultService();
      await cacheService.initialize();

      // 创建Cubit实例
      final repository = PortfolioProfitRepositoryImpl(
        apiService: PortfolioProfitApiService(),
        cacheService: cacheService,
        calculationEngine: PortfolioProfitCalculationEngine(),
      );

      portfolioCubit = PortfolioAnalysisCubit(
        repository: repository,
        dataService: PortfolioDataService(),
      );
    });

    tearDown(() async {
      portfolioCubit.close();
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    testWidgets('PortfolioManager应该正确显示', (WidgetTester tester) async {
      // 提供Cubit给PortfolioManager
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PortfolioAnalysisCubit>(
            create: (context) => portfolioCubit,
            child: const PortfolioManager(),
          ),
        ),
      );

      // 等待组件初始化
      await tester.pump(const Duration(seconds: 1));

      // 验证PortfolioManager显示
      expect(find.text('持仓管理'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget); // 添加按钮是图标，不是文本
    });

    testWidgets('应该能够通过按钮导航到持仓管理', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('测试页面'),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              BlocProvider<PortfolioAnalysisCubit>(
                            create: (context) => portfolioCubit,
                            child: const PortfolioManager(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    tooltip: '管理持仓',
                  ),
                ),
              ],
            ),
            body: const Center(child: Text('测试页面')),
          ),
        ),
      );

      // 点击管理持仓按钮
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump(); // 只执行一次frame构建
      await tester.pump(const Duration(seconds: 1)); // 等待1秒

      // 验证导航到持仓管理页面
      expect(find.text('持仓管理'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget); // 添加按钮是图标，不是文本
    });

    testWidgets('应该能够添加持仓', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PortfolioAnalysisCubit>(
            create: (context) => portfolioCubit,
            child: const PortfolioManager(),
          ),
        ),
      );

      // 等待组件初始化
      await tester.pump(const Duration(seconds: 1));

      // 点击添加持仓按钮（使用图标而不是文本）
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(); // 只执行一次frame构建
      await tester.pump(const Duration(milliseconds: 500)); // 等待对话框显示

      // 验证添加持仓对话框显示
      expect(find.text('添加持仓'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // 基金代码、名称、份额、成本净值
      expect(find.text('基金代码'), findsOneWidget);
      expect(find.text('基金名称'), findsOneWidget);
      expect(find.text('持有份额'), findsOneWidget);
      expect(find.text('成本净值'), findsOneWidget);
    });

    testWidgets('应该能够填写并提交持仓表单', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PortfolioAnalysisCubit>(
            create: (context) => portfolioCubit,
            child: const PortfolioManager(),
          ),
        ),
      );

      // 等待组件初始化
      await tester.pump(const Duration(seconds: 1));

      // 点击添加持仓按钮（使用图标而不是文本）
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(); // 只执行一次frame构建
      await tester.pump(const Duration(milliseconds: 500)); // 等待对话框显示

      // 填写表单 - 通过文本标签查找字段
      await tester.enterText(
          find.ancestor(
              of: find.text('基金代码'), matching: find.byType(TextFormField)),
          '000001');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
          find.ancestor(
              of: find.text('基金名称'), matching: find.byType(TextFormField)),
          '华夏成长混合');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
          find.ancestor(
              of: find.text('持有份额'), matching: find.byType(TextFormField)),
          '1000.0');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
          find.ancestor(
              of: find.text('成本净值'), matching: find.byType(TextFormField)),
          '1.2500');
      await tester.pump(const Duration(milliseconds: 100));

      // 点击添加按钮
      await tester.tap(find.text('添加'));
      await tester.pump(); // 执行一次frame构建
      await tester.pump(const Duration(milliseconds: 500)); // 等待对话框关闭

      // 验证对话框关闭
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
