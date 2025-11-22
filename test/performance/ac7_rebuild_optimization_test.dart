import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/performance/component_monitor.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/cards/adaptive_fund_card.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/cards/fund_card_factory.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';

/// AC7验收标准测试: 不必要的重建减少60%+
///
/// 验证Story R.4的AC7验收标准：
/// - 监控组件重建频率
/// - 测量缓存效率
/// - 验证性能优化效果
void main() {
  group('Story R.4 AC7验收测试: 重建优化', () {
    late ComponentMonitor componentMonitor;
    late List<TestFund> testFunds;

    setUpAll(() {
      // 初始化性能监控器
      componentMonitor = ComponentMonitor();
      componentMonitor.startMonitoring();

      // 创建测试数据
      testFunds = [
        TestFund(code: 'FF001', name: '测试基金1', dailyReturn: 0.05),
        TestFund(code: 'FF002', name: '测试基金2', dailyReturn: -0.03),
        TestFund(code: 'FF003', name: '测试基金3', dailyReturn: 0.12),
        TestFund(code: 'FF004', name: '测试基金4', dailyReturn: -0.08),
        TestFund(code: 'FF005', name: '测试基金5', dailyReturn: 0.15),
      ];
    });

    tearDownAll(() {
      componentMonitor.dispose();
    });

    testWidgets('AC7.1: FundCardFactory缓存效率验证', (WidgetTester tester) async {
      // 测试工厂模式缓存优化
      final factoryKey = 'FundCardFactory_adaptive';

      // 第一次创建 - 应该缓存未命中
      final card1 = FundCardFactory.createCard(
        fund: testFunds[0],
        type: FundCardType.adaptive,
        onTap: () {},
      );

      // 第二次创建相同卡片 - 应该缓存命中
      final card2 = FundCardFactory.createCard(
        fund: testFunds[0],
        type: FundCardType.adaptive,
        onTap: () {},
      );

      // 等待监控器收集数据
      await tester.pump(const Duration(milliseconds: 100));

      final cacheEfficiency = componentMonitor.getCacheEfficiency(factoryKey);

      print('=== AC7.1 FundCardFactory缓存效率 ===');
      print('缓存键: $factoryKey');
      print('缓存效率: ${cacheEfficiency.toStringAsFixed(1)}%');

      expect(cacheEfficiency, greaterThan(50.0),
          reason: '工厂模式缓存效率应超过50% (AC7验证)');

      // 获取详细指标
      final metrics = componentMonitor.getMetrics(factoryKey);
      if (metrics != null) {
        print('缓存命中: ${metrics.cacheHits}');
        print('缓存未命中: ${metrics.cacheMisses}');
        print('总请求次数: ${metrics.cacheHits + metrics.cacheMisses}');
      }
    });

    testWidgets('AC7.2: 组件重建优化验证', (WidgetTester tester) async {
      const cardCount = 20;
      final componentKeys =
          testFunds.map((f) => 'AdaptiveFundCard_${f.code}').toList();

      // 构建包含多个卡片的界面
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: cardCount,
              itemBuilder: (context, index) {
                final fund = testFunds[index % testFunds.length];
                return AdaptiveFundCard(
                  key: ValueKey('card_${fund.code}_${index}'),
                  fund: fund,
                  onTap: () {},
                  enablePerformanceMonitoring: true,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 触发多次重建来测试优化效果
      for (int i = 0; i < 10; i++) {
        // 触发setState
        await tester.tap(find.byType(Scaffold));
        await tester.pump();
      }

      // 等待性能监控器收集数据
      await tester.pump(const Duration(milliseconds: 500));

      print('=== AC7.2 组件重建优化验证 ===');
      bool allComponentsComply = true;

      for (final componentKey in componentKeys) {
        final optimizationRate =
            componentMonitor.getRebuildOptimizationRate(componentKey);

        print('组件: $componentKey');
        print('  重建优化率: ${optimizationRate.toStringAsFixed(1)}%');

        if (optimizationRate < 60.0) {
          allComponentsComply = false;
          print('  ❌ 未达到AC7标准 (需要≥60%)');
        } else {
          print('  ✅ 达到AC7标准');
        }
      }

      expect(allComponentsComply, isTrue, reason: '所有组件的重建优化率应≥60% (AC7验收标准)');

      // 导出详细的性能数据
      final performanceData = componentMonitor.exportPerformanceData();
      print('=== AC7性能数据导出 ===');
      print('监控的组件数量: ${performanceData['summary']['totalComponents']}');
      print(
          '平均优化率: ${performanceData['summary']['averageOptimizationRate'].toStringAsFixed(1)}%');
      print(
          'AC7合规性: ${performanceData['summary']['ac7Compliance'] ? '✅ 通过' : '❌ 失败'}');
    });

    testWidgets('AC7.3: 综合性能基准测试', (WidgetTester tester) async {
      // 清除之前的监控数据
      componentMonitor.reset();

      final testApp = MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('AC7性能测试')),
          body: Column(
            children: [
              // 测试工厂模式缓存
              Expanded(
                child: ListView.builder(
                  itemCount: testFunds.length,
                  itemBuilder: (context, index) {
                    return FundCardFactory.createCard(
                      fund: testFunds[index],
                      type: FundCardType.adaptive,
                      onTap: () {},
                    );
                  },
                ),
              ),
              // 测试直接组件创建
              Expanded(
                child: ListView.builder(
                  itemCount: testFunds.length,
                  itemBuilder: (context, index) {
                    return AdaptiveFundCard(
                      fund: testFunds[index],
                      onTap: () {},
                      enablePerformanceMonitoring: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // 模拟用户交互，触发多次重建
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('AC7性能测试'));
        await tester.pump();
      }

      // 等待数据收集完成
      await tester.pump(const Duration(seconds: 2));

      // 生成最终报告
      final report = componentMonitor.exportPerformanceData();

      print('=== AC7.3 综合性能基准报告 ===');

      // 验证每个组件
      for (final entry in report['components'].entries) {
        final componentName = entry.key;
        final data = entry.value as Map<String, dynamic>;

        print('组件: $componentName');
        print('  渲染次数: ${data['renderCount']}');
        print('  不必要重建: ${data['unnecessaryRebuilds']}');
        print(
            '  重建优化率: ${data['rebuildOptimizationRate'].toStringAsFixed(1)}%');
        print('  缓存效率: ${data['cacheEfficiency'].toStringAsFixed(1)}%');
        print('  平均渲染时间: ${data['averageRenderTime'].toStringAsFixed(2)}ms');

        final optimizationRate = data['rebuildOptimizationRate'] as double;
        final cacheEfficiency = data['cacheEfficiency'] as double;

        // AC7验收标准：任一指标≥60%即为通过
        final passesAC7 = optimizationRate >= 60.0 || cacheEfficiency >= 60.0;
        print('  AC7状态: ${passesAC7 ? '✅ 通过' : '❌ 失败'}');
        print('');
      }

      print('=== AC7最终验收结果 ===');
      print('监控组件总数: ${report['summary']['totalComponents']}');
      print(
          '平均优化率: ${report['summary']['averageOptimizationRate'].toStringAsFixed(1)}%');
      print(
          'AC7合规性: ${report['summary']['ac7Compliance'] ? '🎉 完全通过' : '❌ 需要优化'}');

      expect(report['summary']['ac7Compliance'], isTrue,
          reason: 'AC7验收标准必须通过：不必要的重建减少60%+');
    });
  });
}

/// 测试用基金实体
class TestFund extends Fund {
  @override
  final String code;
  @override
  final String name;
  @override
  final double dailyReturn;
  @override
  final double return1Y;
  @override
  final String type;
  @override
  final String manager;
  @override
  final double scale;

  const TestFund({
    required this.code,
    required this.name,
    required this.dailyReturn,
    this.return1Y = 0.15,
    this.type = '混合型',
    this.manager = '测试经理',
    this.scale = 10.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestFund &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() =>
      'TestFund(code: $code, name: $name, dailyReturn: $dailyReturn)';
}
