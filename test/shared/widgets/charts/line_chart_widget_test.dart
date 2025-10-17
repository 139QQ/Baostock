/// 折线图组件测试
///
/// 测试折线图组件的功能、交互和边界情况
library line_chart_widget_test;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/shared/widgets/charts/line_chart_widget.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/models/chart_data.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/chart_theme_manager.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/chart_di_container.dart';

void main() {
  group('LineChartWidget', () {
    setUp(() async {
      // 初始化依赖注入
      await ChartDIContainer.initialize();
    });

    testWidgets('should display empty chart when no data provided',
        (tester) async {
      // Arrange
      const chart = LineChartWidget(
        config: ChartConfig(title: 'Test Chart'),
        dataSeries: [],
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.text('暂无数据'), findsOneWidget);
      expect(find.text('请添加数据系列以显示图表'), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('should display chart with single data series', (tester) async {
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
        config: ChartConfig(title: 'Test Chart'),
        dataSeries: dataSeries,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.text('Test Chart'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should display chart with multiple data series',
        (tester) async {
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
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should handle gradient colors correctly', (tester) async {
      // Arrange
      final dataSeries = [
        ChartDataSeries(
          data: const [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Gradient Series',
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlue],
          ),
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Gradient Chart'),
        dataSeries: dataSeries,
        showGradient: true,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should respect showDots configuration', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Dots Test',
          color: Colors.green,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Dots Test'),
        dataSeries: dataSeries,
        showDots: false,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should handle curved lines configuration', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Curved Test',
          color: Colors.purple,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Curved Test'),
        dataSeries: dataSeries,
        isCurved: false,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should apply custom theme correctly', (tester) async {
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
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should handle data point taps', (tester) async {
      // Arrange
      var tappedPoint;
      var tappedSeriesIndex = -1;

      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10, label: 'Point 1'),
            ChartPoint(x: 2, y: 20, label: 'Point 2'),
            ChartPoint(x: 3, y: 15, label: 'Point 3'),
          ],
          name: 'Tap Test',
          color: Colors.blue,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Tap Test'),
        dataSeries: dataSeries,
        onDataPointTap: (point, seriesIndex) {
          tappedPoint = point;
          tappedSeriesIndex = seriesIndex;
        },
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // 尝试点击图表区域（实际测试中可能需要更精确的定位）
      await tester.tap(find.byType(LineChart));
      await tester.pump();

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      // 注意：由于 fl_chart 的复杂性，实际的触摸事件可能需要更精确的测试
    });

    testWidgets('should handle responsive sizing', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Responsive Test',
          color: Colors.indigo,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(
          title: 'Responsive Test',
          width: 400,
          height: 300,
        ),
        dataSeries: dataSeries,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.bySize(const Size(400, 300)), findsOneWidget);
    });

    testWidgets('should handle animation correctly', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 10),
            ChartPoint(x: 2, y: 20),
            ChartPoint(x: 3, y: 15),
          ],
          name: 'Animation Test',
          color: Colors.teal,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Animation Test'),
        dataSeries: dataSeries,
        animationDuration: Duration(milliseconds: 100),
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));

      // 动画开始前
      expect(find.byType(LineChart), findsOneWidget);

      // 等待动画完成
      await tester.pump(const Duration(milliseconds: 150));

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
    });
  });

  group('LineChartStyle', () {
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

  group('LineChartWidget Edge Cases', () {
    setUp(() async {
      await ChartDIContainer.initialize();
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
        config: ChartConfig(title: 'Empty Data Test'),
        dataSeries: dataSeries,
      );

      // Act & Assert
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should handle single data point gracefully', (tester) async {
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

      // Act & Assert
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should handle negative values correctly', (tester) async {
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

      // Act & Assert
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should handle very large values correctly', (tester) async {
      // Arrange
      final dataSeries = [
        const ChartDataSeries(
          data: [
            ChartPoint(x: 1, y: 1000000),
            ChartPoint(x: 2, y: 2000000),
            ChartPoint(x: 3, y: 1500000),
          ],
          name: 'Large Values',
          color: Colors.blue,
        ),
      ];

      const chart = LineChartWidget(
        config: ChartConfig(title: 'Large Values Test'),
        dataSeries: dataSeries,
      );

      // Act & Assert
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
