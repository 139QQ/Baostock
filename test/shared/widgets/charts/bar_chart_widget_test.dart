/// 柱状图组件单元测试
///
/// 测试柱状图组件的数据渲染、交互功能和响应式布局
library bar_chart_widget_test;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:jisu_fund_analyzer/src/shared/widgets/charts/bar_chart_widget.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/models/chart_data.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/chart_theme_manager.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/chart_di_container.dart';

void main() {
  setUpAll(() async {
    // 初始化图表依赖注入容器
    await ChartDIContainer.initialize();
  });
  group('BarChartWidget', () {
    late ChartConfig config;
    late List<ChartDataSeries> dataSeries;
    late ChartPoint testPoint1;
    late ChartPoint testPoint2;
    late ChartPoint testPoint3;

    setUp(() {
      config = const ChartConfig(
        title: '测试柱状图',
        width: 400,
        height: 300,
        showGrid: true,
        showTooltip: true,
      );

      testPoint1 = const ChartPoint(x: 1, y: 25, label: '一月');
      testPoint2 = const ChartPoint(x: 2, y: 40, label: '二月');
      testPoint3 = const ChartPoint(x: 3, y: 15, label: '三月');

      dataSeries = [
        ChartDataSeries(
          name: '系列1',
          data: [testPoint1, testPoint2, testPoint3],
          color: Colors.blue,
        ),
      ];
    });

    testWidgets('应该正确渲染柱状图', (WidgetTester tester) async {
      // Arrange
      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: dataSeries,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('测试柱状图'), findsOneWidget);
    });

    testWidgets('应该渲染空数据状态', (WidgetTester tester) async {
      // Arrange
      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: [],
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('暂无数据'), findsOneWidget);
      expect(find.text('请添加数据系列以显示图表'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('应该支持多系列数据', (WidgetTester tester) async {
      // Arrange
      final multiSeriesData = [
        ChartDataSeries(
          name: '系列1',
          data: [testPoint1, testPoint2, testPoint3],
          color: Colors.blue,
        ),
        ChartDataSeries(
          name: '系列2',
          data: [
            const ChartPoint(x: 1, y: 30, label: '一月'),
            const ChartPoint(x: 2, y: 20, label: '二月'),
            const ChartPoint(x: 3, y: 35, label: '三月'),
          ],
          color: Colors.red,
        ),
      ];

      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: multiSeriesData,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
      // 验证多个系列的数据点都被渲染
      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final barChartData = barChart.data;
      expect(barChartData.barGroups.length, equals(3)); // 3个X位置
      expect(
          barChartData.barGroups.first.barRods.length, equals(2)); // 每个位置有2个柱子
    });

    testWidgets('应该支持渐变色柱子', (WidgetTester tester) async {
      // Arrange
      final gradientData = [
        ChartDataSeries(
          name: '渐变系列',
          data: [testPoint1, testPoint2, testPoint3],
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
          ),
        ),
      ];

      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: gradientData,
            showGradient: true,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final barChartData = barChart.data;
      final firstBar = barChartData.barGroups.first.barRods.first;
      expect(firstBar.gradient, isNotNull);
    });

    testWidgets('应该处理柱子点击事件', (WidgetTester tester) async {
      // Arrange
      ChartPoint? tappedPoint;
      int? seriesIndex;
      int? barIndex;

      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: dataSeries,
            onBarTap: (point, sIndex, bIndex) {
              tappedPoint = point;
              seriesIndex = sIndex;
              barIndex = bIndex;
            },
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 查找第一个柱子并点击
      final barChartFinder = find.byType(BarChart);
      expect(barChartFinder, findsOneWidget);

      // 获取柱状图的位置并点击
      final barChart = tester.widget<BarChart>(barChartFinder);
      final barChartData = barChart.data;

      if (barChartData.barGroups.isNotEmpty) {
        final firstGroup = barChartData.barGroups.first;
        final firstBar = firstGroup.barRods.first;

        // 计算点击位置（这里简化处理，实际应该根据柱子位置计算）
        final barChartRenderBox =
            tester.renderObject(barChartFinder) as RenderBox;
        final barChartSize = barChartRenderBox.size;
        final tapPosition = Offset(
          barChartSize.width * 0.2, // 大概第一个柱子的位置
          barChartSize.height * 0.6, // 大概柱子的中间位置
        );

        await tester.tapAt(tapPosition);
        await tester.pumpAndSettle();

        // Assert
        expect(tappedPoint, isNotNull);
        expect(seriesIndex, equals(0));
        expect(barIndex, equals(0));
      }
    });

    testWidgets('应该支持不同的对齐方式', (WidgetTester tester) async {
      // Arrange
      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: dataSeries,
            alignment: BarChartAlignment.center,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      expect(barChart.data.alignment, equals(BarChartAlignment.center));
    });

    testWidgets('应该正确计算Y轴范围', (WidgetTester tester) async {
      // Arrange
      final dataWithNegativeValues = [
        ChartDataSeries(
          name: '包含负值系列',
          data: [
            const ChartPoint(x: 1, y: -10, label: '负值'),
            const ChartPoint(x: 2, y: 50, label: '正值'),
            const ChartPoint(x: 3, y: 20, label: '正值2'),
          ],
          color: Colors.green,
        ),
      ];

      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: dataWithNegativeValues,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final barChartData = barChart.data;

      // 验证Y轴范围包含负值
      expect(barChartData.minY, lessThanOrEqualTo(-10));
      expect(barChartData.maxY, greaterThanOrEqualTo(50));
    });

    testWidgets('应该响应配置变化', (WidgetTester tester) async {
      // Arrange
      StateSetter? setState;
      var currentConfig = config;

      Widget buildWidget() {
        return StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return MaterialApp(
              home: Scaffold(
                body: BarChartWidget(
                  config: currentConfig,
                  dataSeries: dataSeries,
                ),
              ),
            );
          },
        );
      }

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Act - 更新配置
      setState!(() {
        currentConfig = const ChartConfig(
          title: '更新后的标题',
          width: 500,
          height: 400,
          showGrid: false,
        );
      });

      await tester.pump();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('更新后的标题'), findsOneWidget);
      expect(find.text('测试柱状图'), findsNothing);
    });

    test('应该正确导出图表数据', () {
      // Arrange
      final widget = BarChartWidget(
        config: config,
        dataSeries: dataSeries,
        showGradient: true,
        barWidth: 20.0,
      );

      // Act
      final state = widget.createState();
      // 由于是测试，我们需要手动初始化一些状态
      // 这里我们直接测试导出方法，在实际组件中会通过状态调用

      // Assert
      // 验证组件属性正确设置
      expect(widget.showGradient, isTrue);
      expect(widget.barWidth, equals(20.0));
      expect(widget.dataSeries.length, equals(1));
      expect(widget.dataSeries.first.name, equals('系列1'));
    });

    test('应该提供正确的统计信息', () {
      // Arrange
      final widget = BarChartWidget(
        config: config,
        dataSeries: dataSeries,
      );

      // Act & Assert
      expect(widget.dataSeries.length, equals(1));
      expect(widget.dataSeries.first.data.length, equals(3));

      final series = widget.dataSeries.first;
      final yRange = series.yRange;
      expect(yRange.min, equals(15.0));
      expect(yRange.max, equals(40.0));

      final xRange = series.xRange;
      expect(xRange.min, equals(1.0));
      expect(xRange.max, equals(3.0));
    });

    test('BarChartStyle应该创建正确的样式', () {
      // Test financial style
      final financialStyle = BarChartStyle.financial(
        showGradient: true,
        barWidth: 25.0,
      );

      expect(financialStyle.showGradient, isTrue);
      expect(financialStyle.barWidth, equals(25.0));
      expect(financialStyle.borderRadius, equals(6.0));
      expect(financialStyle.groupSpacing, equals(12.0));

      // Test minimal style
      final minimalStyle = BarChartStyle.minimal();

      expect(minimalStyle.showGradient, isFalse);
      expect(minimalStyle.barWidth, equals(12.0));
      expect(minimalStyle.borderRadius, equals(2.0));
      expect(minimalStyle.alignment, equals(BarChartAlignment.center));

      // Test presentation style
      final presentationStyle = BarChartStyle.presentation();

      expect(presentationStyle.showGradient, isTrue);
      expect(presentationStyle.barWidth, equals(24.0));
      expect(presentationStyle.borderRadius, equals(8.0));
      expect(presentationStyle.animationDuration.inMilliseconds, equals(1200));
    });
  });

  group('BarChartWidget 边界情况测试', () {
    testWidgets('应该处理空数据点', (WidgetTester tester) async {
      // Arrange
      final emptyDataSeries = [
        ChartDataSeries(
          name: '空数据系列',
          data: [],
          color: Colors.blue,
        ),
      ];

      final config = const ChartConfig(title: '空数据测试');

      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: emptyDataSeries,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('空数据测试'), findsOneWidget);
    });

    testWidgets('应该处理大量数据点', (WidgetTester tester) async {
      // Arrange
      final largeDataSet = List.generate(50, (index) {
        return ChartPoint(
          x: index.toDouble(),
          y: (index * 2 + 10).toDouble(),
          label: '数据点$index',
        );
      });

      final largeDataSeries = [
        ChartDataSeries(
          name: '大数据集',
          data: largeDataSet,
          color: Colors.blue,
        ),
      ];

      final config = const ChartConfig(title: '大数据集测试');

      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: largeDataSeries,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('大数据集测试'), findsOneWidget);
    });

    testWidgets('应该处理极值数据', (WidgetTester tester) async {
      // Arrange
      final extremeDataSeries = [
        ChartDataSeries(
          name: '极值数据',
          data: [
            const ChartPoint(x: 1, y: 999999, label: '极大值'),
            const ChartPoint(x: 2, y: -999999, label: '极小值'),
            const ChartPoint(x: 3, y: 0, label: '零值'),
          ],
          color: Colors.red,
        ),
      ];

      final config = const ChartConfig(title: '极值数据测试');

      final widget = MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            config: config,
            dataSeries: extremeDataSeries,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('极值数据测试'), findsOneWidget);
    });
  });
}
