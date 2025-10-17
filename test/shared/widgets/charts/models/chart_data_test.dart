/// 图表数据模型测试
///
/// 测试图表数据模型的功能和行为
library chart_data_test;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/shared/widgets/charts/models/chart_data.dart';

void main() {
  group('ChartPoint', () {
    test('should create ChartPoint with required properties', () {
      // Arrange
      const chartPoint = ChartPoint(
        x: 1.0,
        y: 2.5,
        label: 'Test Point',
        color: Colors.blue,
      );

      // Assert
      expect(chartPoint.x, 1.0);
      expect(chartPoint.y, 2.5);
      expect(chartPoint.label, 'Test Point');
      expect(chartPoint.color, Colors.blue);
    });

    test('should create ChartPoint without optional properties', () {
      // Arrange & Act
      const chartPoint = ChartPoint(x: 1.0, y: 2.5);

      // Assert
      expect(chartPoint.x, 1.0);
      expect(chartPoint.y, 2.5);
      expect(chartPoint.label, null);
      expect(chartPoint.color, null);
    });

    test('should create copy with updated properties', () {
      // Arrange
      const originalPoint = ChartPoint(x: 1.0, y: 2.5, label: 'Original');

      // Act
      final copiedPoint = originalPoint.copyWith(
        x: 2.0,
        label: 'Copied',
      );

      // Assert
      expect(copiedPoint.x, 2.0);
      expect(copiedPoint.y, 2.5); // unchanged
      expect(copiedPoint.label, 'Copied');
      expect(originalPoint.x, 1.0); // original unchanged
    });

    test('should have correct equality implementation', () {
      // Arrange
      const point1 = ChartPoint(x: 1.0, y: 2.5, label: 'Test');
      const point2 = ChartPoint(x: 1.0, y: 2.5, label: 'Test');
      const point3 = ChartPoint(x: 1.0, y: 2.5, label: 'Different');

      // Assert
      expect(point1, equals(point2));
      expect(point1, isNot(equals(point3)));
    });

    test('should have correct toString implementation', () {
      // Arrange
      const chartPoint = ChartPoint(x: 1.0, y: 2.5, label: 'Test');

      // Act & Assert
      expect(chartPoint.toString(), 'ChartPoint(x: 1.0, y: 2.5, label: Test)');
    });
  });

  group('ChartDataSeries', () {
    test('should create ChartDataSeries with required properties', () {
      // Arrange
      final data = [
        const ChartPoint(x: 1, y: 2),
        const ChartPoint(x: 2, y: 4),
        const ChartPoint(x: 3, y: 6),
      ];

      // Act
      const series = ChartDataSeries(
        data: [
          ChartPoint(x: 1, y: 2),
          ChartPoint(x: 2, y: 4),
          ChartPoint(x: 3, y: 6),
        ],
        name: 'Test Series',
        color: Colors.blue,
      );

      // Assert
      expect(series.name, 'Test Series');
      expect(series.color, Colors.blue);
      expect(series.data.length, 3);
      expect(series.showDots, true);
      expect(series.showArea, false);
      expect(series.lineWidth, 2.0);
    });

    test('should calculate correct yRange', () {
      // Arrange
      const series = ChartDataSeries(
        data: [
          ChartPoint(x: 1, y: 2.5),
          ChartPoint(x: 2, y: 8.7),
          ChartPoint(x: 3, y: -1.2),
        ],
        name: 'Test Series',
      );

      // Act
      final range = series.yRange;

      // Assert
      expect(range.min, -1.2);
      expect(range.max, 8.7);
    });

    test('should calculate correct xRange', () {
      // Arrange
      const series = ChartDataSeries(
        data: [
          ChartPoint(x: -2, y: 1),
          ChartPoint(x: 5, y: 2),
          ChartPoint(x: 3, y: 3),
        ],
        name: 'Test Series',
      );

      // Act
      final range = series.xRange;

      // Assert
      expect(range.min, -2.0);
      expect(range.max, 5.0);
    });

    test('should handle empty data for ranges', () {
      // Arrange
      const series = ChartDataSeries(
        data: [],
        name: 'Empty Series',
      );

      // Act
      final yRange = series.yRange;
      final xRange = series.xRange;

      // Assert
      expect(yRange.min, 0.0);
      expect(yRange.max, 0.0);
      expect(xRange.min, 0.0);
      expect(xRange.max, 0.0);
    });

    test('should have correct toString implementation', () {
      // Arrange
      const series = ChartDataSeries(
        data: [
          ChartPoint(x: 1, y: 2),
          ChartPoint(x: 2, y: 4),
        ],
        name: 'Test Series',
      );

      // Act & Assert
      expect(series.toString(),
          'ChartDataSeries(name: Test Series, dataPoints: 2)');
    });
  });

  group('PieChartDataItem', () {
    test('should create PieChartDataItem with required properties', () {
      // Arrange & Act
      const item = PieChartDataItem(
        value: 25.5,
        label: 'Test Item',
        color: Colors.green,
        description: 'Test Description',
      );

      // Assert
      expect(item.value, 25.5);
      expect(item.label, 'Test Item');
      expect(item.color, Colors.green);
      expect(item.description, 'Test Description');
    });

    test('should calculate percentage correctly', () {
      // Arrange
      const item = PieChartDataItem(value: 25, label: 'Test Item');

      // Act & Assert
      expect(item.calculatePercentage(100), 25.0);
      expect(item.calculatePercentage(200), 12.5);
      expect(item.calculatePercentage(50), 50.0);
    });

    test('should handle zero total for percentage calculation', () {
      // Arrange
      const item = PieChartDataItem(value: 25, label: 'Test Item');

      // Act & Assert
      expect(item.calculatePercentage(0), 0.0);
    });

    test('should have correct toString implementation', () {
      // Arrange
      const item = PieChartDataItem(value: 25.5, label: 'Test Item');

      // Act & Assert
      expect(
          item.toString(), 'PieChartDataItem(label: Test Item, value: 25.5)');
    });
  });

  group('ChartConfig', () {
    test('should create ChartConfig with default values', () {
      // Arrange & Act
      const config = ChartConfig(
        title: 'Test Chart',
        width: 300,
        height: 200,
      );

      // Assert
      expect(config.title, 'Test Chart');
      expect(config.width, 300);
      expect(config.height, 200);
      expect(config.showGrid, true);
      expect(config.showLegend, true);
      expect(config.showTooltip, true);
      expect(config.enableZoom, true);
      expect(config.enablePan, true);
      expect(config.padding, const EdgeInsets.all(16.0));
      expect(config.margin, const EdgeInsets.all(8.0));
    });

    test('should create copy with updated properties', () {
      // Arrange
      const originalConfig = ChartConfig(
        title: 'Original',
        showGrid: true,
      );

      // Act
      final copiedConfig = originalConfig.copyWith(
        title: 'Copied',
        showGrid: false,
      );

      // Assert
      expect(copiedConfig.title, 'Copied');
      expect(copiedConfig.showGrid, false);
      expect(originalConfig.title, 'Original'); // original unchanged
      expect(originalConfig.showGrid, true); // original unchanged
    });

    test('should have correct equality implementation', () {
      // Arrange
      const config1 = ChartConfig(title: 'Test', width: 300);
      const config2 = ChartConfig(title: 'Test', width: 300);
      const config3 = ChartConfig(title: 'Test', width: 400);

      // Assert
      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });

  group('ChartInteractionEvent', () {
    test('should create ChartInteractionEvent with all properties', () {
      // Arrange & Act
      const event = ChartInteractionEvent(
        type: ChartInteractionType.tap,
        position: Offset(100, 200),
        dataPoint: ChartPoint(x: 1, y: 2),
        seriesIndex: 0,
        pointIndex: 1,
        scaleFactor: 1.5,
      );

      // Assert
      expect(event.type, ChartInteractionType.tap);
      expect(event.position, const Offset(100, 200));
      expect(event.dataPoint, const ChartPoint(x: 1, y: 2));
      expect(event.seriesIndex, 0);
      expect(event.pointIndex, 1);
      expect(event.scaleFactor, 1.5);
    });

    test('should create ChartInteractionEvent with minimal properties', () {
      // Arrange & Act
      const event = ChartInteractionEvent(
        type: ChartInteractionType.tap,
      );

      // Assert
      expect(event.type, ChartInteractionType.tap);
      expect(event.position, null);
      expect(event.dataPoint, null);
      expect(event.seriesIndex, null);
      expect(event.pointIndex, null);
      expect(event.scaleFactor, null);
    });

    test('should have correct toString implementation', () {
      // Arrange
      const event = ChartInteractionEvent(
        type: ChartInteractionType.tap,
        position: Offset(100, 200),
      );

      // Act & Assert
      expect(
        event.toString(),
        'ChartInteractionEvent(type: ChartInteractionType.tap, position: Offset(100.0, 200.0))',
      );
    });
  });

  group('ChartType enum', () {
    test('should have correct enum values', () {
      expect(ChartType.values, contains(ChartType.line));
      expect(ChartType.values, contains(ChartType.bar));
      expect(ChartType.values, contains(ChartType.pie));
      expect(ChartType.values, contains(ChartType.scatter));
      expect(ChartType.values, contains(ChartType.radar));
    });
  });

  group('ChartInteractionType enum', () {
    test('should have correct enum values', () {
      expect(ChartInteractionType.values, contains(ChartInteractionType.tap));
      expect(ChartInteractionType.values,
          contains(ChartInteractionType.longPress));
      expect(ChartInteractionType.values,
          contains(ChartInteractionType.doubleTap));
      expect(
          ChartInteractionType.values, contains(ChartInteractionType.panStart));
      expect(ChartInteractionType.values,
          contains(ChartInteractionType.panUpdate));
      expect(
          ChartInteractionType.values, contains(ChartInteractionType.panEnd));
      expect(ChartInteractionType.values,
          contains(ChartInteractionType.scaleStart));
      expect(ChartInteractionType.values,
          contains(ChartInteractionType.scaleUpdate));
      expect(
          ChartInteractionType.values, contains(ChartInteractionType.scaleEnd));
    });
  });
}
