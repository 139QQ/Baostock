/// 折线图组件简化测试
///
/// 测试折线图组件的核心功能
library line_chart_widget_simple_test;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/shared/widgets/charts/line_chart_widget.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/models/chart_data.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/chart_theme_manager.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/chart_di_container.dart';

void main() {
  group('LineChartWidget Basic Tests', () {
    setUp(() async {
      // 初始化依赖注入
      await ChartDIContainer.initialize();
    });

    testWidgets('should create LineChartWidget with default properties',
        (tester) async {
      // Arrange
      const chart = LineChartWidget(
        config: ChartConfig(title: 'Test Chart'),
        dataSeries: [],
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChartWidget), findsOneWidget);
    });

    testWidgets('should display empty state when no data provided',
        (tester) async {
      // Arrange
      const chart = LineChartWidget(
        config: ChartConfig(title: 'Empty Chart'),
        dataSeries: [],
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.text('暂无数据'), findsOneWidget);
      expect(find.text('请添加数据系列以显示图表'), findsOneWidget);
    });

    testWidgets('should handle single data series', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Test Series',
          color: Colors.blue,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Single Series Chart'),
        dataSeries: dataSeries,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.text('Single Series Chart'), findsOneWidget);
      expect(find.byType(LineChartWidget), findsOneWidget);
    });

    testWidgets('should handle multiple data series', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Series 1',
          color: Colors.blue,
        ),
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 15),
            ChartPoint(x: 2, y: 25),
            ChartPoint(x: 3, y: 20),
          ],
          name: 'Series 2',
          color: Colors.red,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Multi Series Chart'),
        dataSeries: dataSeries,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.text('Multi Series Chart'), findsOneWidget);
      expect(find.byType(LineChartWidget), findsOneWidget);
    });

    testWidgets('should respect custom theme', (tester) async {
      // Arrange
      final customTheme = ChartTheme.dark();
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Theme Test',
          color: Colors.orange,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Theme Test'),
        dataSeries: dataSeries,
        customTheme: customTheme,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChartWidget), findsOneWidget);
    });

    testWidgets('should handle configuration changes', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Config Test',
          color: Colors.green,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Config Test'),
        dataSeries: dataSeries,
        showGradient: false,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChartWidget), findsOneWidget);
    });

    testWidgets('should handle empty data series gracefully', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [],
          name: 'Empty Series',
          color: Colors.blue,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Empty Series Test'),
        dataSeries: dataSeries,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChartWidget), findsOneWidget);
    });

    testWidgets('should handle single data point', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
          ],
          name: 'Single Point',
          color: Colors.blue,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Single Point Test'),
        dataSeries: dataSeries,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChartWidget), findsOneWidget);
    });

    testWidgets('should handle negative values', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: -10),
            ChartPoint(x: 2, y: -20),
            ChartPoint(x: 3, y: -15),
          ],
          name: 'Negative Values',
          color: Colors.red,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Negative Values Test'),
        dataSeries: dataSeries,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChartWidget), findsOneWidget);
    });
  });

  group('LineChartStyle Tests', () {
    test('should create default style correctly', () {
      // Act
      const style = LineChartStyle();

      // Assert
      expect(style.showGradient, true);
      expect(style.showDots, true);
      expect(style.isCurved, true);
      expect(style.lineWidth, 2.0);
      expect(style.dotRadius, 3.0);
      expect(style.showArea, false);
      expect(style.areaOpacity, 0.3);
    });

    test('should create financial style correctly', () {
      // Act
      final style = LineChartStyle.financial();

      // Assert
      expect(style.showGradient, true);
      expect(style.showDots, false);
      expect(style.isCurved, true);
      expect(style.lineWidth, 2.5);
      expect(style.showArea, true);
      expect(style.areaOpacity, 0.2);
      expect(style.animationDuration, const Duration(milliseconds: 1000));
    });

    test('should create minimal style correctly', () {
      // Act
      final style = LineChartStyle.minimal();

      // Assert
      expect(style.showGradient, false);
      expect(style.showDots, true);
      expect(style.isCurved, false);
      expect(style.lineWidth, 1.5);
      expect(style.showArea, false);
      expect(style.areaOpacity, 0.0);
      expect(style.animationDuration, const Duration(milliseconds: 500));
    });

    test('should create presentation style correctly', () {
      // Act
      final style = LineChartStyle.presentation();

      // Assert
      expect(style.showGradient, true);
      expect(style.showDots, true);
      expect(style.isCurved, true);
      expect(style.lineWidth, 3.0);
      expect(style.showArea, true);
      expect(style.areaOpacity, 0.4);
      expect(style.animationDuration, const Duration(milliseconds: 1200));
    });
  });

  group('ChartData Integration Tests', () {
    setUp(() async {
      await ChartDIContainer.initialize();
    });

    test('should handle chart data export', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10, label: 'Point 1'),
            ChartPoint(x: 2, y: 20, label: 'Point 2'),
            ChartPoint(x: 3, y: 15, label: 'Point 3'),
          ],
          name: 'Export Test',
          color: Colors.blue,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Export Test'),
        dataSeries: dataSeries,
        key: Key('test_chart'),
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Get the chart widget state to test export functionality
      final chartWidget =
          tester.widget<LineChartWidget>(find.byKey(const Key('test_chart')));

      // Assert
      expect(chartWidget.dataSeries.length, 1);
      expect(chartWidget.dataSeries.first.name, 'Export Test');
      expect(chartWidget.dataSeries.first.data.length, 3);
    });

    test('should handle chart statistics', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Stats Test',
          color: Colors.blue,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Stats Test'),
        dataSeries: dataSeries,
        key: Key('stats_chart'),
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Get the chart widget state
      final chartWidget =
          tester.widget<LineChartWidget>(find.byKey(const Key('stats_chart')));

      // Assert
      expect(chartWidget.dataSeries.length, 1);
      expect(chartWidget.dataSeries.first.data.length, 3);
      expect(chartWidget.dataSeries.first.yRange.min, 10.0);
      expect(chartWidget.dataSeries.first.yRange.max, 20.0);
    });
  });
}
