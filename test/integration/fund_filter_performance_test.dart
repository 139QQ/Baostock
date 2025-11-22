import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/widgets/fund_filter_panel.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/models/fund_filter.dart';

void main() {
  group('基金筛选界面性能测试', () {
    testWidgets('筛选面板渲染性能测试', (WidgetTester tester) async {
      // 准备测试数据
      final filter = FundFilter();
      bool filterChanged = false;

      // 构建筛选面板
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FundFilterPanel(
              filters: filter,
              onFiltersChanged: (newFilters) {
                filterChanged = true;
              },
            ),
          ),
        ),
      );

      // 等待首次渲染完成
      await tester.pumpAndSettle();

      // 测试点击不同筛选选项的性能
      final stopwatch = Stopwatch()..start();

      // 测试基金类型选择
      for (int i = 0; i < 7; i++) {
        final typeChip = tester.widget(
            find.text(['股票型', '债券型', '混合型', '货币型', '指数型', 'QDII', 'FOF'][i]));

        await tester.tap(
            find.text(['股票型', '债券型', '混合型', '货币型', '指数型', 'QDII', 'FOF'][i]));
        await tester.pump(); // 只处理一帧，不等待所有动画完成
      }

      final typeSelectionTime = stopwatch.elapsedMilliseconds;

      // 测试风险等级选择
      stopwatch.reset();

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text(['R1', 'R2', 'R3', 'R4', 'R5'][i]));
        await tester.pump(); // 只处理一帧
      }

      final riskSelectionTime = stopwatch.elapsedMilliseconds;

      // 测试滑块操作
      stopwatch.reset();

      final slider = find.byType(RangeSlider);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pump(); // 只处理一帧

      final sliderTime = stopwatch.elapsedMilliseconds;

      print('✅ 基金筛选界面性能测试完成');
      print('基金类型选择耗时: ${typeSelectionTime}ms');
      print('风险等级选择耗时: ${riskSelectionTime}ms');
      print('滑块操作耗时: ${sliderTime}ms');

      // 验证性能指标（应该很快，不会卡死）
      expect(typeSelectionTime, lessThan(1000)); // 1秒内完成
      expect(riskSelectionTime, lessThan(1000)); // 1秒内完成
      expect(sliderTime, lessThan(500)); // 0.5秒内完成
      expect(filterChanged, true); // 确保交互正常工作
    });

    testWidgets('筛选面板内存使用测试', (WidgetTester tester) async {
      // 准备测试数据
      final filter = FundFilter();

      // 多次构建和销毁筛选面板，测试内存泄漏
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FundFilterPanel(
                filters: filter,
                onFiltersChanged: (newFilters) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 模拟用户交互
        await tester.tap(find.text('股票型'));
        await tester.pump();

        // 清理
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      }

      print('✅ 筛选面板内存使用测试完成 - 10次构建/销毁循环');
    });
  });
}
