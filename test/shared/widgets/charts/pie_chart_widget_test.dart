import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/shared/widgets/charts/pie_chart_widget.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/models/chart_data.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/chart_theme_manager.dart';

void main() {
  group('PieChartWidget Tests', () {
    late List<PieChartDataItem> testData;
    late ChartConfig testConfig;

    setUp(() {
      testData = [
        PieChartDataItem(
          value: 30.0,
          label: '股票',
          color: Colors.blue,
          description: '股票投资',
        ),
        PieChartDataItem(
          value: 25.0,
          label: '债券',
          color: Colors.green,
          description: '债券投资',
        ),
        PieChartDataItem(
          value: 20.0,
          label: '现金',
          color: Colors.orange,
          description: '现金储备',
        ),
        PieChartDataItem(
          value: 25.0,
          label: '其他',
          color: Colors.purple,
          description: '其他投资',
        ),
      ];

      testConfig = const ChartConfig(
        title: '测试饼图',
        animationDuration: Duration(milliseconds: 100),
      );
    });

    testWidgets('饼图组件应该正确渲染', (WidgetTester tester) async {
      // Arrange
      int selectedSectorIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              onSectorSelected: (index, item) {
                selectedSectorIndex = index;
              },
            ),
          ),
        ),
      );

      // 等待动画完成
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // Assert
      expect(find.byType(PieChartWidget), findsOneWidget);
      expect(find.text('测试饼图'), findsOneWidget);
      expect(find.text('图例'), findsOneWidget);
      expect(find.text('股票'), findsOneWidget);
      expect(find.text('债券'), findsOneWidget);
      expect(find.text('现金'), findsOneWidget);
      expect(find.text('其他'), findsOneWidget);
    });

    testWidgets('饼图组件应该显示百分比', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
            ),
          ),
        ),
      );

      // 等待动画完成
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // Assert
      expect(find.text('30.0%'), findsOneWidget);
      expect(find.text('25.0%'), findsAtLeastNWidgets(1));
      expect(find.text('20.0%'), findsOneWidget);
    });

    testWidgets('饼图组件应该处理空数据', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: [],
              config: testConfig,
            ),
          ),
        ),
      );

      // Assert - 检查实际显示的文本
      expect(find.byIcon(Icons.pie_chart_outline), findsOneWidget);
      // 由于文本可能不完全匹配，我们检查空数据状态是否显示
      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('饼图组件应该支持点击交互', (WidgetTester tester) async {
      // Arrange
      int selectedSectorIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              onSectorSelected: (index, item) {
                selectedSectorIndex = index;
              },
            ),
          ),
        ),
      );

      // 等待动画完成
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // 点击饼图中心区域
      await tester.tap(find.byType(PieChartWidget));
      await tester.pump();

      // Assert
      expect(selectedSectorIndex, isNot(-1));
    });

    testWidgets('饼图组件应该支持环形图', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              innerRadius: 0.3, // 环形图
            ),
          ),
        ),
      );

      // 等待动画完成
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // Assert
      expect(find.byType(PieChartWidget), findsOneWidget);
      expect(find.text('测试饼图'), findsOneWidget);
    });

    testWidgets('饼图组件应该支持不同的图例位置', (WidgetTester tester) async {
      // 测试顶部图例
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              legendPosition: LegendPosition.top,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.byType(PieChartWidget), findsOneWidget);

      // 测试底部图例
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              legendPosition: LegendPosition.bottom,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.byType(PieChartWidget), findsOneWidget);

      // 测试左侧图例
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              legendPosition: LegendPosition.left,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.byType(PieChartWidget), findsOneWidget);
    });

    testWidgets('饼图组件应该支持禁用动画', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              enableAnimation: false,
            ),
          ),
        ),
      );

      // 不需要等待动画，直接检查
      await tester.pump();

      // Assert
      expect(find.byType(PieChartWidget), findsOneWidget);
      expect(find.text('测试饼图'), findsOneWidget);
    });

    testWidgets('饼图组件应该支持禁用图例', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              showLegend: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // Assert
      expect(find.byType(PieChartWidget), findsOneWidget);
      expect(find.text('测试饼图'), findsOneWidget);
      expect(find.text('图例'), findsNothing);
    });

    testWidgets('饼图组件应该支持禁用百分比标签', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              showPercentageLabels: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // Assert
      expect(find.byType(PieChartWidget), findsOneWidget);
      // 百分比标签应该不显示，但图例中的百分比仍然显示
    });

    testWidgets('饼图组件应该支持禁用交互', (WidgetTester tester) async {
      // Arrange
      int selectedSectorIndex = -1;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              enableInteraction: false,
              onSectorSelected: (index, item) {
                selectedSectorIndex = index;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // 点击饼图
      await tester.tap(find.byType(PieChartWidget));
      await tester.pump();

      // Assert
      expect(selectedSectorIndex, equals(-1)); // 回调不应该被调用
    });

    testWidgets('饼图组件应该支持预选中扇区', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PieChartWidget(
              data: testData,
              config: testConfig,
              selectedSectorIndex: 1, // 预选中第二个扇区
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // Assert
      expect(find.byType(PieChartWidget), findsOneWidget);
      // 第二个扇区应该处于选中状态
    });
  });

  group('PieChartDataItem Tests', () {
    test('PieChartDataItem应该正确计算百分比', () {
      // Arrange
      final item = PieChartDataItem(value: 25.0, label: 'Test');

      // Act
      final percentage = item.calculatePercentage(100.0);

      // Assert
      expect(percentage, equals(25.0));
    });

    test('PieChartDataItem应该处理零总数', () {
      // Arrange
      final item = PieChartDataItem(value: 25.0, label: 'Test');

      // Act
      final percentage = item.calculatePercentage(0.0);

      // Assert
      expect(percentage, equals(0.0));
    });

    test('PieChartDataItem应该支持相等比较', () {
      // Arrange
      final item1 =
          PieChartDataItem(value: 25.0, label: 'Test', color: Colors.blue);
      final item2 =
          PieChartDataItem(value: 25.0, label: 'Test', color: Colors.blue);
      final item3 =
          PieChartDataItem(value: 30.0, label: 'Test', color: Colors.blue);

      // Act & Assert
      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });
  });

  group('PieChartSector Tests', () {
    test('PieChartSector应该正确计算中心角度', () {
      // Arrange
      final sector = PieChartSector(
        item: PieChartDataItem(value: 25.0, label: 'Test'),
        startAngle: 0.0,
        sweepAngle: 1.57, // 90度
        percentage: 25.0,
      );

      // Act
      final centerAngle = sector.centerAngle;

      // Assert
      expect(centerAngle, equals(0.785)); // 45度
    });

    test('PieChartSector应该正确检测点是否在扇区内', () {
      // Arrange
      final sector = PieChartSector(
        item: PieChartDataItem(value: 25.0, label: 'Test'),
        startAngle: 0.0,
        sweepAngle: 1.57, // 90度
        percentage: 25.0,
      );

      final center = const Offset(100, 100);
      final radius = 50.0;

      // 测试扇区内的点
      final pointInside = const Offset(135, 100); // 45度方向上的点

      // 测试扇区外的点
      final pointOutside = const Offset(100, 10); // 扇区范围外的点

      // Act & Assert
      expect(sector.containsPoint(pointInside, center, radius), isTrue);
      expect(sector.containsPoint(pointOutside, center, radius), isFalse);
    });

    test('PieChartSector应该支持环形图检测', () {
      // Arrange
      final sector = PieChartSector(
        item: PieChartDataItem(value: 25.0, label: 'Test'),
        startAngle: 0.0,
        sweepAngle: 6.28, // 完整圆
        percentage: 100.0,
      );

      final center = const Offset(100, 100);
      final outerRadius = 50.0;
      final innerRadius = 20.0;

      // 测试环形区域内的点
      final pointInRing = const Offset(135, 100); // 45度方向，距离中心35

      // 测试内圆内的点
      final pointInInnerCircle = const Offset(110, 100); // 距离中心10

      // 测试外圆外的点
      final pointOutsideOuter = const Offset(160, 100); // 距离中心60

      // Act & Assert
      expect(
          sector.containsPoint(pointInRing, center, outerRadius, innerRadius),
          isTrue);
      expect(
          sector.containsPoint(
              pointInInnerCircle, center, outerRadius, innerRadius),
          isFalse);
      expect(
          sector.containsPoint(
              pointOutsideOuter, center, outerRadius, innerRadius),
          isFalse);
    });
  });
}
